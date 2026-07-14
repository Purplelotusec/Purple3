"""
Fetches recent security advisories from the GitHub Advisory Database
(public, free, no LLM involved) and writes a normalized JSON file for
the frontend to render.

Data source: https://api.github.com/advisories
Docs: https://docs.github.com/en/rest/security-advisories/global-advisories
"""
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from urllib.request import Request, urlopen
from urllib.error import HTTPError

API_URL = "https://api.github.com/advisories"
DAYS_BACK = 30
PER_PAGE = 50
MAX_PAGES = 4  # up to 200 advisories scanned per run

# Ecosystems we care about for "supply chain" framing (package registries).
# GitHub also returns advisories for things like "actions" / "docker" — kept in
# since GH Actions supply-chain issues are very on-topic for this site.
RELEVANT_ECOSYSTEMS = {
    "npm", "pip", "rubygems", "maven", "nuget", "go", "composer",
    "actions", "rust", "erlang", "swift", "pub"
}


def fetch_page(page: int, token: str | None):
    url = f"{API_URL}?per_page={PER_PAGE}&page={page}&sort=published&direction=desc"
    req = Request(url, headers={
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "purplelotus-threat-feed",
    })
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urlopen(req, timeout=20) as resp:
            return json.loads(resp.read().decode())
    except HTTPError as e:
        print(f"GitHub API error on page {page}: {e.code} {e.reason}", file=sys.stderr)
        return []


def normalize(advisory: dict) -> list[dict]:
    rows = []
    published = advisory.get("published_at")
    severity = (advisory.get("severity") or "unknown").upper()
    summary = advisory.get("summary") or ""
    ghsa_id = advisory.get("ghsa_id")
    html_url = advisory.get("html_url")
    cve_id = advisory.get("cve_id")

    for vuln in advisory.get("vulnerabilities") or []:
        if not isinstance(vuln, dict):
            continue
        pkg = vuln.get("package") or {}
        if not isinstance(pkg, dict):
            pkg = {}
        ecosystem = (pkg.get("ecosystem") or "").lower()
        if ecosystem not in RELEVANT_ECOSYSTEMS:
            continue

        # GitHub's API has been observed returning first_patched_version as
        # either {"identifier": "..."} or a bare string — handle both.
        fpv = vuln.get("first_patched_version")
        if isinstance(fpv, dict):
            first_patched = fpv.get("identifier")
        elif isinstance(fpv, str):
            first_patched = fpv
        else:
            first_patched = None
        rows.append({
            "name": pkg.get("name", "unknown"),
            "ecosystem": pkg.get("ecosystem", "unknown"),
            "affected_range": vuln.get("vulnerable_version_range", "unknown"),
            "patched_version": first_patched or "No fix yet",
            "severity": severity,
            "summary": summary,
            "published": published,
            "ghsa_id": ghsa_id,
            "cve_id": cve_id,
            "source_url": html_url,
        })
    return rows


def main():
    token = os.environ.get("GITHUB_TOKEN")
    cutoff = datetime.now(timezone.utc) - timedelta(days=DAYS_BACK)

    all_rows = []
    for page in range(1, MAX_PAGES + 1):
        advisories = fetch_page(page, token)
        if not advisories:
            break

        stop = False
        for adv in advisories:
            pub_raw = adv.get("published_at")
            if not pub_raw:
                continue
            pub_dt = datetime.fromisoformat(pub_raw.replace("Z", "+00:00"))
            if pub_dt < cutoff:
                stop = True
                continue
            all_rows.extend(normalize(adv))

        if stop:
            break

    # Sort newest first, cap output size
    all_rows.sort(key=lambda r: r["published"], reverse=True)
    all_rows = all_rows[:100]

    output = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "window_days": DAYS_BACK,
        "source": "GitHub Advisory Database (api.github.com/advisories)",
        "count": len(all_rows),
        "advisories": all_rows,
    }

    os.makedirs("data", exist_ok=True)
    with open("data/attacks.json", "w") as f:
        json.dump(output, f, indent=2)

    print(f"Wrote {len(all_rows)} advisories to data/attacks.json")


if __name__ == "__main__":
    main()
