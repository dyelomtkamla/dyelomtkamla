// Shared behaviour for public pages: service search, install prompt, offline cache.
(function () {
  // Live search over the department cards on the home page
  var search = document.getElementById('svcSearch');
  if (search) {
    var cards = document.querySelectorAll('#svcGrid .svc'), empty = document.getElementById('svcEmpty');
    search.addEventListener('input', function () {
      var q = search.value.trim(), shown = 0;
      cards.forEach(function (c) {
        var ok = !q || c.dataset.search.indexOf(q) !== -1;
        c.hidden = !ok; if (ok) shown++;
      });
      empty.hidden = shown > 0;
    });
  }

  // Prevent double submission of the booking form
  document.querySelectorAll('form[method=post]').forEach(function (f) {
    f.addEventListener('submit', function () {
      var btn = f.querySelector('button[type=submit]');
      if (btn) setTimeout(function () { btn.disabled = true; }, 0);
    });
  });

  // "Install app" button (Android / desktop Chrome)
  var installBtn = document.getElementById('installBtn'), deferred;
  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault(); deferred = e;
    if (installBtn) installBtn.hidden = false;
  });
  if (installBtn) installBtn.addEventListener('click', function () {
    if (!deferred) return;
    deferred.prompt(); deferred = null; installBtn.hidden = true;
  });

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function () { navigator.serviceWorker.register('/sw.js'); });
  }
})();
