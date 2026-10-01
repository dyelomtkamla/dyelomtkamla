// Shared behaviour for every page: booking via WhatsApp, service search, install prompt, offline cache.
(function () {
  var yr = document.getElementById('yr');
  if (yr) yr.textContent = new Date().getFullYear();

  // Booking form -> WhatsApp message
  var form = document.getElementById('bookForm');
  if (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var f = form.elements, err = document.getElementById('formErr');
      var name = f.name.value.trim(), phone = f.phone.value.trim(), area = f.area.value.trim();
      if (!name || !phone || !area) { err.hidden = false; return; }
      err.hidden = true;
      var lines = [
        'طلب خدمة جديد - مؤسسة لؤلؤة المستقل',
        'القسم: ' + f.section.value,
        'الاسم: ' + name,
        'الجوال: ' + phone,
        'الحي / المدينة: ' + area
      ];
      if (f.date.value) lines.push('الموعد المفضّل: ' + f.date.value);
      if (f.notes.value.trim()) lines.push('التفاصيل: ' + f.notes.value.trim());
      window.open('https://wa.me/' + form.dataset.wa + '?text=' + encodeURIComponent(lines.join('\n')), '_blank', 'noopener');
    });
  }

  // Live search over the department cards
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
    var base = document.querySelector('link[rel=manifest]').getAttribute('href').replace('manifest.webmanifest', '');
    window.addEventListener('load', function () { navigator.serviceWorker.register(base + 'sw.js', { scope: base || './' }); });
  }
})();
