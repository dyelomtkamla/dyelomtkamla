/* ===========================================================
   بروق الشرقية — إعلان موشن جرافيك 25 ثانية
   محرّك تايم-لاين حتمي (deterministic) : seek(t) يرسم أي لحظة
   =========================================================== */
const DUR = 25.0;

/* ---------- easings ---------- */
const EZ = {
  l: t => t,
  q3: t => 1 - Math.pow(1 - t, 3),
  q5: t => 1 - Math.pow(1 - t, 5),
  xo: t => (t >= 1 ? 1 : 1 - Math.pow(2, -11 * t)),
  io: t => (t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2),
  b:  t => { const c = 1.9; return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2); },
  s:  t => t * t * (3 - 2 * t),
};
/* keyframe lerp */
function k(t, t0, t1, a, b, e = 'q5') {
  if (t <= t0) return a;
  if (t >= t1) return b;
  return a + (b - a) * EZ[e]((t - t0) / (t1 - t0));
}
const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
/* bell pulse: 0 -> 1 -> 0 */
function pulse(t, t0, up, down) {
  if (t < t0 || t > t0 + up + down) return 0;
  return t < t0 + up ? EZ.s((t - t0) / up) : 1 - EZ.s((t - t0 - up) / down);
}
const $ = s => document.querySelector(s);
const C = {}; const q = s => (C[s] || (C[s] = $(s)));

/* arabic-indic digits */
const AR = '٠١٢٣٤٥٦٧٨٩';
const toAr = n => String(n).replace(/\d/g, d => AR[+d]);

/* ---------- element animator ----------
   o:[inStart,dur] | y,x,s,rot = from-values | out:[start,dur] + oy,os  */
function an(sel, t, c) {
  const el = q(sel); if (!el) return;
  const [a, d] = c.i, e = c.e || 'q5';
  let o = k(t, a, a + d, 0, 1, e === 'b' ? 'q3' : e);
  let y = k(t, a, a + d, c.y || 0, 0, e);
  let x = k(t, a, a + d, c.x || 0, 0, e);
  let s = k(t, a, a + d, c.s == null ? 1 : c.s, 1, e);
  let r = k(t, a, a + d, c.rot || 0, 0, e);
  if (c.out) {
    const [b, od] = c.out;
    o *= 1 - k(t, b, b + od, 0, 1, 'q3');
    y += k(t, b, b + od, 0, c.oy == null ? -34 : c.oy, 'q3');
    s *= k(t, b, b + od, 1, c.os == null ? 1.03 : c.os, 'q3');
  }
  el.style.opacity = o;
  el.style.transform = `translate3d(${x.toFixed(2)}px,${y.toFixed(2)}px,0) rotate(${r.toFixed(2)}deg) scale(${s.toFixed(4)})`;
}
/* clip reveal right -> left (RTL) */
function reveal(sel, t, a, d, c) {
  const el = q(sel); if (!el) return;
  const p = k(t, a, a + d, 100, 0, 'xo');
  el.style.clipPath = `inset(-18% ${0}% -22% ${p}%)`;
  el.style.opacity = k(t, a, a + .18, 0, 1, 'l');
  if (c && c.out) { const [b, od] = c.out; el.style.opacity *= 1 - k(t, b, b + od, 0, 1, 'q3'); }
}
/* stroke draw for svg paths */
const LEN = new WeakMap();
function draw(el, t, a, d) {
  if (!el) return;
  let L = LEN.get(el); if (L == null) { L = el.getTotalLength ? el.getTotalLength() : 100; LEN.set(el, L); }
  el.style.strokeDasharray = L;
  el.style.strokeDashoffset = k(t, a, a + d, L, 0, 'q3');
}

/* ---------- scene windows ---------- */
const SC = [
  ['#s1', 0.00, 3.60],
  ['#s2', 3.50, 7.45],
  ['#s3', 7.38, 13.25],
  ['#s4', 13.18, 17.45],
  ['#s5', 17.38, 21.00],
  ['#s6', 20.92, 25.01],
];
const TR = [3.45, 7.30, 13.08, 17.28, 20.84];

/* ---------- background build ---------- */
let seed = 20251011;
const rnd = () => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff);
const PT = [];
(function buildParticles() {
  const host = $('#particles');
  for (let i = 0; i < 54; i++) {
    const d = document.createElement('div');
    d.className = 'particle';
    const sz = 2 + rnd() * 6;
    const o = { x: rnd() * 1920, y: rnd() * 1080, sz, sp: 14 + rnd() * 46, ph: rnd() * 6.28, am: 14 + rnd() * 54, op: .10 + rnd() * .42, el: d };
    d.style.width = d.style.height = sz + 'px';
    host.appendChild(d); PT.push(o);
  }
})();
const RIPPLE = ['#p1', '#p2', '#p3', '#p4', '#p5', '#p6'];

/* ---------- main ---------- */
function seek(t) {
  t = clamp(t, 0, DUR);

  /* ===== background ===== */
  q('#bg-grid').style.backgroundPosition = `${(t * 13).toFixed(1)}px ${(-t * 8).toFixed(1)}px`;
  q('#bg-grad').style.transform = `scale(${(1 + .035 * Math.sin(t * .22)).toFixed(4)}) translate3d(${(Math.sin(t * .17) * 22).toFixed(1)}px,0,0)`;
  q('#bg-arc').style.transform = `translate3d(${(-t * 16).toFixed(1)}px,${(Math.sin(t * .3) * 10).toFixed(1)}px,0)`;
  q('#sweep').style.transform = `rotate(14deg) translate3d(${(-700 + ((t * 230) % 3200)).toFixed(0)}px,0,0)`;
  for (const p of PT) {
    const y = ((p.y - t * p.sp) % 1180 + 1180) % 1180 - 60;
    const x = p.x + Math.sin(t * .6 + p.ph) * p.am;
    p.el.style.transform = `translate3d(${x.toFixed(1)}px,${y.toFixed(1)}px,0)`;
    p.el.style.opacity = p.op * (.55 + .45 * Math.sin(t * 1.3 + p.ph));
  }

  /* ===== scene visibility + slow push-in ===== */
  for (const [sel, a, b] of SC) {
    const el = q(sel);
    const on = t >= a - .25 && t <= b + .25;
    el.style.display = on ? 'block' : 'none';
    if (!on) continue;
    const p = clamp((t - a) / (b - a), 0, 1);
    el.style.transform = `scale(${(1 + .028 * p).toFixed(4)})`;
    const fo = b >= DUR ? 1 : 1 - k(t, b - .22, b, 0, 1, 'q3');   /* المشهد الأخير يثبت ولا يختفي */
    el.style.opacity = Math.min(k(t, a, a + .22, 0, 1, 'q3'), fo);
  }

  /* ===== SCENE 1 — hook ===== */
  if (t < 3.9) {
    an('#s1a', t, { i: [.30, .85], y: 86, e: 'q5', out: [3.22, .34], oy: -40 });
    an('#s1b', t, { i: [.66, .85], y: 86, e: 'q5', out: [3.28, .34], oy: -40 });
    an('#s1c1', t, { i: [1.52, .55], y: 34, s: .92, out: [3.18, .3], oy: -20 });
    an('#s1c2', t, { i: [1.67, .55], y: 34, s: .92, out: [3.20, .3], oy: -20 });
    an('#s1c3', t, { i: [1.82, .55], y: 34, s: .92, out: [3.22, .3], oy: -20 });
    const fl = (sel, a, amp, sp, ph) => {
      const el = q(sel);
      el.style.opacity = k(t, a, a + 1.0, 0, 1, 'q3') * (1 - k(t, 3.1, 3.4, 0, 1, 'q3'));
      el.style.transform = `translate3d(${(Math.sin(t * sp + ph) * amp).toFixed(1)}px,${(Math.cos(t * sp * .8 + ph) * amp * .7).toFixed(1)}px,0) rotate(${(Math.sin(t * sp * .5 + ph) * 3).toFixed(2)}deg)`;
    };
    fl('#g1', .15, 16, .7, 0); fl('#g2', .35, 20, .55, 1.6); fl('#g3', .55, 13, .85, 3.1);
    const qm = (sel, a, sc) => {
      const el = q(sel);
      el.style.opacity = (k(t, a, a + .5, 0, .85, 'b')) * (1 - k(t, 3.05, 3.35, 0, 1, 'q3'));
      el.style.transform = `scale(${(sc * (1 + .07 * Math.sin(t * 2.4))).toFixed(3)}) rotate(${(Math.sin(t * 1.1) * 5).toFixed(2)}deg)`;
    };
    qm('#qm1', 1.05, 1); qm('#qm2', 1.25, 1);
  }

  /* ===== SCENE 2 — logo ===== */
  if (t > 3.3 && t < 7.7) {
    const m = q('#s2mark');
    const sIn = k(t, 3.58, 4.42, .55, 1, 'b');
    const fl = Math.sin((t - 3.6) * 1.5) * 7;
    m.style.opacity = k(t, 3.58, 3.85, 0, 1, 'q3') * (1 - k(t, 7.18, 7.42, 0, 1, 'q3'));
    m.style.transform = `translate3d(0,${fl.toFixed(1)}px,0) rotate(${k(t, 3.58, 4.5, -14, 0, 'b').toFixed(2)}deg) scale(${sIn.toFixed(4)})`;
    const g = 16 + 22 * (.5 + .5 * Math.sin(t * 2.1));
    q('#boltFill').style.filter = `drop-shadow(0 0 ${g.toFixed(1)}px rgba(247,183,51,.85))`;
    q('#boltFill').style.opacity = k(t, 4.18, 4.46, 0, 1, 'q3');
    draw(q('#hexLine'), t, 3.70, .95);
    draw(q('#boltLine'), t, 3.98, .70);
    q('#hexFill').style.opacity = k(t, 4.05, 4.6, 0, .55, 'q3');
    const r = q('#s2ring');
    r.style.opacity = k(t, 4.3, 5.0, 0, 1, 'q3') * (1 - k(t, 7.1, 7.4, 0, 1, 'q3'));
    r.style.transform = `rotate(${(t * 26).toFixed(1)}deg) scale(${k(t, 4.3, 5.2, .82, 1, 'q3').toFixed(3)})`;
    reveal('#s2word', t, 4.46, .80, { out: [7.12, .3] });
    an('#s2tag', t, { i: [4.95, .6], y: 26, out: [7.14, .3], oy: -18 });
    const ru = q('#s2rule');
    ru.style.width = k(t, 5.22, 6.0, 0, 560, 'xo') + 'px';
    ru.style.opacity = 1 - k(t, 7.1, 7.35, 0, 1, 'q3');
    const rg = q('#s2reg');
    rg.style.opacity = k(t, 5.42, 6.1, 0, 1, 'q3') * (1 - k(t, 7.12, 7.38, 0, 1, 'q3'));
    rg.style.letterSpacing = k(t, 5.42, 6.4, 26, 9, 'q5').toFixed(1) + 'px';
  }

  /* ===== SCENE 3 — services ===== */
  if (t > 7.2 && t < 13.5) {
    an('#s3k', t, { i: [7.55, .55], y: 22, out: [12.98, .3] });
    reveal('#s3t', t, 7.72, .85, { out: [13.0, .3] });
    const cards = document.querySelectorAll('#s3cards .card');
    cards.forEach((cd, i) => {
      const a = 8.12 + i * .16;
      const o = k(t, a, a + .45, 0, 1, 'q3') * (1 - k(t, 12.92 + i * .05, 13.2 + i * .05, 0, 1, 'q3'));
      const y = k(t, a, a + .75, 92, 0, 'b') + k(t, 12.92 + i * .05, 13.22, 0, -26, 'q3');
      cd.style.opacity = o;
      cd.style.transform = `translate3d(0,${y.toFixed(1)}px,0) scale(${k(t, a, a + .75, .9, 1, 'b').toFixed(4)})`;
      /* icon stroke draw */
      cd.querySelectorAll('.ico path, .ico circle, .ico rect').forEach(p => draw(p, t, a + .30, .75));
      /* light sweep across the card (twice) */
      const w1 = pulse(t, 8.7 + i * .16, .35, .55), w2 = pulse(t, 11.45 + i * .16, .35, .55);
      const w = Math.max(w1, w2);
      const sh = cd.querySelector('.shine');
      sh.style.opacity = w;
      sh.style.transform = `rotate(16deg) translate3d(${(-260 + (w1 > 0 ? EZ.io(clamp((t - 8.7 - i * .16) / .9, 0, 1)) : EZ.io(clamp((t - 11.45 - i * .16) / .9, 0, 1))) * 680).toFixed(0)}px,0,0)`;
      /* icon tile breathe */
      const ic = cd.querySelector('.ico');
      ic.style.transform = `scale(${(1 + .035 * Math.sin(t * 2.2 + i)).toFixed(4)})`;
    });
  }

  /* ===== SCENE 4 — coverage ===== */
  if (t > 13.0 && t < 17.7) {
    an('#s4k', t, { i: [13.32, .5], y: 20, out: [17.18, .28] });
    reveal('#s4t', t, 13.48, .85, { out: [17.2, .28] });
    const mb = q('#s4map');
    mb.style.opacity = k(t, 13.42, 13.9, 0, 1, 'q3') * (1 - k(t, 17.16, 17.42, 0, 1, 'q3'));
    mb.style.transform = `scale(${k(t, 13.42, 14.6, .93, 1, 'q5').toFixed(4)}) translate3d(0,${k(t, 13.42, 14.6, 26, 0, 'q5').toFixed(1)}px,0)`;
    draw(q('#land'), t, 13.58, 1.30);
    q('#sea').style.opacity = k(t, 13.9, 14.8, 0, 1, 'q3');
    q('#waves').style.opacity = k(t, 14.4, 15.2, 0, .55, 'q3');
    const ro = q('#route');
    ro.style.strokeDashoffset = (-t * 70).toFixed(0);
    ro.style.opacity = k(t, 14.5, 15.2, 0, .9, 'q3');
    RIPPLE.forEach((sel, i) => {
      const a = 14.25 + i * .22;
      const el = q(sel);
      el.style.opacity = k(t, a, a + .3, 0, 1, 'q3');
      el.style.transform = `translate3d(0,${k(t, a, a + .55, -44, 0, 'b').toFixed(1)}px,0) scale(${k(t, a, a + .55, .5, 1, 'b').toFixed(3)})`;
      const ph = Math.max(0, (t - a - .3)) % 1.5 / 1.5;
      const dot = el.querySelector('.dot');
      dot.style.boxShadow = t > a + .3
        ? `0 0 0 ${(7 + ph * 26).toFixed(1)}px rgba(247,183,51,${(.28 * (1 - ph)).toFixed(3)}),0 8px 22px rgba(0,0,0,.6)`
        : `0 0 0 7px rgba(247,183,51,.22)`;
    });
    an('#s4l1', t, { i: [15.62, .5], x: -30, out: [17.14, .26] });
    an('#s4l2', t, { i: [15.80, .5], x: -30, out: [17.16, .26] });
    an('#s4l3', t, { i: [15.98, .5], x: -30, out: [17.18, .26] });
  }

  /* ===== SCENE 5 — trust ===== */
  if (t > 17.2 && t < 21.2) {
    reveal('#s5t', t, 17.52, .8, { out: [20.74, .28] });
    an('#s5s', t, { i: [17.86, .55], y: 22, out: [20.76, .28] });
    [['#st1', 17.98], ['#st2', 18.14], ['#st3', 18.30]].forEach(([s, a]) =>
      an(s, t, { i: [a, .6], y: 44, s: .9, e: 'b', out: [20.7, .3] }));
    ['#dv1', '#dv2'].forEach((s, i) => {
      const el = q(s);
      el.style.opacity = k(t, 18.2 + i * .1, 18.9, 0, 1, 'q3') * (1 - k(t, 20.7, 20.95, 0, 1, 'q3'));
    });
    q('#n1').textContent = '+' + toAr(Math.round(k(t, 18.12, 19.62, 0, 5000, 'q5') / 25) * 25);
    q('#n2').textContent = toAr(Math.round(k(t, 18.28, 19.62, 0, 100, 'q5'))) + '٪';
    [['#ch1', 19.52], ['#ch2', 19.66], ['#ch3', 19.80]].forEach(([s, a]) =>
      an(s, t, { i: [a, .5], y: 26, s: .94, out: [20.66, .28] }));
  }

  /* ===== SCENE 6 — CTA ===== */
  if (t > 20.7) {
    an('#s6mark', t, { i: [21.08, .75], y: 40, s: .82, e: 'b' });
    reveal('#s6slog', t, 21.52, .8);
    const b = q('#s6btn');
    const bp = 1 + .035 * Math.sin((t - 22.0) * 4.6) * (t > 22.5 ? 1 : 0);
    b.style.opacity = k(t, 21.92, 22.3, 0, 1, 'q3');
    b.style.transform = `translate3d(0,${k(t, 21.92, 22.6, 36, 0, 'b').toFixed(1)}px,0) scale(${(k(t, 21.92, 22.6, .86, 1, 'b') * bp).toFixed(4)})`;
    b.style.boxShadow = `0 26px ${(60 + 26 * (.5 + .5 * Math.sin((t - 22) * 4.6))).toFixed(0)}px rgba(247,183,51,${(.34 + .16 * (.5 + .5 * Math.sin((t - 22) * 4.6))).toFixed(3)}),inset 0 2px 0 rgba(255,255,255,.55)`;
    an('#s6phone', t, { i: [22.34, .6], y: 26 });
    an('#s6foot', t, { i: [22.72, .6], y: 20 });
    /* lightning strike behind the lock-up */
    const st = q('#strike');
    const f1 = pulse(t, 21.00, .05, .22) * (Math.sin(t * 120) > -.4 ? 1 : .35);
    const f2 = pulse(t, 23.26, .05, .20);
    const f3 = pulse(t, 24.18, .04, .16);
    st.style.opacity = Math.max(f1, f2 * .9, f3 * .7);
    st.style.transform = `translate3d(${(f2 > 0 ? -140 : f3 > 0 ? 180 : 0)}px,0,0) scale(${1 + (f3 > 0 ? .1 : 0)})`;
  }

  /* ===== transitions : flash + bolt wipe ===== */
  let fo = 0, bw = 0, bx = 0;
  TR.forEach(a => {
    const p = pulse(t, a, .05, .30);
    if (p > fo) fo = p;
    const w = pulse(t, a - .06, .14, .34);
    if (w > bw) { bw = w; bx = -760 + EZ.io(clamp((t - a + .06) / .48, 0, 1)) * 3400; }
  });
  q('#flash').style.opacity = (fo * .42).toFixed(3);
  const bwe = q('#bolt-wipe');
  bwe.style.opacity = bw.toFixed(3);
  bwe.style.transform = `rotate(12deg) translate3d(${bx.toFixed(0)}px,0,0)`;
}

/* ---------- fit & drive ---------- */
function fit() {
  const s = Math.min(innerWidth / 1920, innerHeight / 1080);
  $('#fit').style.transform = `scale(${s})`;
}
addEventListener('resize', fit); fit();

window.seek = seek;
window.__ready = true;
const RENDER = location.search.indexOf('render') >= 0;
if (!RENDER) {
  let t0 = null;
  const loop = ts => {
    if (t0 === null) t0 = ts;
    seek(((ts - t0) / 1000) % (DUR + .6));
    requestAnimationFrame(loop);
  };
  requestAnimationFrame(loop);
} else {
  seek(0);
}
