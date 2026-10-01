// Dashboard: confirm destructive actions (kept out of inline handlers so the CSP can forbid inline script).
document.querySelectorAll('form[data-confirm]').forEach(function (f) {
  f.addEventListener('submit', function (e) {
    if (!window.confirm(f.dataset.confirm)) e.preventDefault();
  });
});
