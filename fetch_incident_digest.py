"""
Builds a narrative "notable incidents" digest by web-searching for recent
open-source supply chain attack coverage and summarizing it with a local,
open-weight LLM (via Ollama) — no paid search API, no paid LLM API.

Pipeline:
  1. duckduckgo-search  -> free-text web search, no API key
  2. trafilatura         -> pulls clean article text out of the result pages
  3. Ollama (local)       -> summarizes ONLY from the collected excerpts

This is intentionally kept separate from fetch_attacks.py. That script reads
structured fields straight out of the GitHub Advisory Database, so a
version range is either correct or the database is wrong. This script asks
a small local model to synthesize prose from web search snippets, which is
a fundamentally less reliable process — a 3B model on a CPU runner can still
misstate a detail even when told to stick to the source text. Treat the
output as "leads to go read the real article," not as a verified record.
"""
import json
import os
import sys
from datetime import datetime, timezone

import requests
import trafilatura
from ddgs import DDGS

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = os.environ.get("OLLAMA_MODEL", "llama3.2:3b")

QUERIES = [
    "open source software supply chain attack this month",
    "npm package compromised malware",
    "PyPI package compromised malicious",
    "GitHub Actions pipeline supply chain attack",
]

MAX_RESULTS_PER_QUERY = 4
MAX_CHARS_PER_SOURCE = 2500
MAX_TOTAL_SOURCES = 12


def search_and_collect() -> list[dict]:
    sources = []
    seen_urls = set()

    with DDGS() as ddgs:
        for query in QUERIES:
            if len(sources) >= MAX_TOTAL_SOURCES:
                break
            try:
                results = ddgs.text(query, max_results=MAX_RESULTS_PER_QUERY, timelimit="m")
            except Exception as e:
                print(f"Search failed for '{query}': {e}", file=sys.stderr)
                continue

            for r in results:
                url = r.get("href")
                if not url or url in seen_urls:
                    continue
                seen_urls.add(url)

                text = None
                try:
                    downloaded = trafilatura.fetch_url(url)
                    if downloaded:
                        text = trafilatura.extract(downloaded)
                except Exception as e:
                    print(f"Extraction failed for {url}: {e}", file=sys.stderr)

                if not text:
                    text = r.get("body", "")  # fall back to the search snippet

                if not text:
                    continue

                sources.append({
                    "title": r.get("title", url),
                    "url": url,
                    "text": text[:MAX_CHARS_PER_SOURCE],
                })

                if len(sources) >= MAX_TOTAL_SOURCES:
                    break

    return sources


def build_prompt(sources: list[dict]) -> str:
    blocks = [
        f"[Source {i}] {s['title']} ({s['url']})\n{s['text']}"
        for i, s in enumerate(sources, start=1)
    ]
    joined = "\n\n".join(blocks)

    return f"""You are a careful security news summarizer. Using ONLY the source \
excerpts below, write up to 5 bullet points about notable open-source \
software supply chain attacks or compromises.

Strict rules:
- Only state facts that are directly supported by the excerpts below.
- If a detail (a number, a date, a company name, an attacker name) is not \
explicitly present in the excerpts, do not include it.
- Never invent a CVE ID, a byte/record count, or an attribution that isn't \
in the text.
- After every bullet, cite the source number(s) it came from, like [1] or [2][3].
- If the excerpts don't support 5 solid bullets, write fewer. Fewer accurate \
bullets is better than more speculative ones.
- Do not add commentary, opinions, or a conclusion — bullets only.

SOURCE EXCERPTS:
{joined}

BULLET DIGEST:"""


def call_ollama(prompt: str) -> str:
    resp = requests.post(
        OLLAMA_URL,
        json={
            "model": MODEL,
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.2},
        },
        timeout=300,
    )
    resp.raise_for_status()
    return resp.json().get("response", "").strip()


def main():
    sources = search_and_collect()

    if not sources:
        digest = "No sources were found in this run — check back after the next scheduled run."
    else:
        try:
            digest = call_ollama(build_prompt(sources))
        except Exception as e:
            print(f"Ollama call failed: {e}", file=sys.stderr)
            digest = "The local summarizer was unavailable this run. Raw sources are listed below."

    output = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "model": MODEL,
        "search_backend": "DuckDuckGo via duckduckgo-search (open source, no API key)",
        "digest_markdown": digest,
        "sources": [{"title": s["title"], "url": s["url"]} for s in sources],
    }

    os.makedirs("data", exist_ok=True)
    with open("data/incident_digest.json", "w") as f:
        json.dump(output, f, indent=2)

    print(f"Wrote data/incident_digest.json with {len(sources)} sources")


if __name__ == "__main__":
    main()
