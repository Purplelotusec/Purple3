// Mobile nav toggle — shared by every page
(function () {
  var header = document.querySelector('header');
  var btn = header && header.querySelector('.nav-toggle');
  var nav = header && header.querySelector('nav');
  if (!btn || !nav) return;

  var setOpen = function (open) {
    header.classList.toggle('nav-open', open);
    btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    btn.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  };

  btn.addEventListener('click', function () { setOpen(!header.classList.contains('nav-open')); });
  nav.addEventListener('click', function (e) { if (e.target.closest('a')) setOpen(false); });
  document.addEventListener('click', function (e) { if (!header.contains(e.target)) setOpen(false); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') setOpen(false); });

  var mq = window.matchMedia('(max-width: 960px)');
  var onChange = function (e) { if (!e.matches) setOpen(false); };
  if (mq.addEventListener) mq.addEventListener('change', onChange); else mq.addListener(onChange);
})();
