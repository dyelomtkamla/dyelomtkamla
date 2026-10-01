// Service worker: makes the public site open offline after the first visit.
// Bump CACHE when the precached files change.
const CACHE = 'lulua-v1';
const PAGES = ['/', '/pest-control', '/cleaning', '/maintenance', '/insulation',
  '/moving-storage', '/pools', '/contracting', '/decor-painting'];
const ASSETS = ['/manifest.webmanifest', '/img/logo.svg', '/img/icon-192.png', '/img/icon-512.png',
  '/img/apple-touch-icon.png', '/img/favicon-32.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(PAGES.concat(ASSETS))).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  const url = new URL(req.url);
  if (req.method !== 'GET' || url.origin !== location.origin) return;
  // Never cache the dashboard or booking flow: they are private or one-off.
  if (url.pathname.startsWith('/admin') || url.pathname.startsWith('/book')) return;

  if (req.mode === 'navigate') {
    // Network first so content stays fresh; cache is the offline fallback.
    e.respondWith(
      fetch(req).then(res => {
        if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
        return res;
      }).catch(() => caches.match(req).then(hit => hit || caches.match('/')))
    );
    return;
  }
  e.respondWith(
    caches.match(req).then(hit => hit || fetch(req).then(res => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
      return res;
    }))
  );
});
