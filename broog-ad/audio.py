# -*- coding: utf-8 -*-
"""موسيقى + مؤثرات صوتية للإعلان (25 ثانية) — تُولَّد برمجياً بدون أي ملفات خارجية."""
import numpy as np, wave, struct, sys

SR = 48000
DUR = 25.0
N = int(SR * DUR)
t = np.arange(N) / SR
L = np.zeros(N); R = np.zeros(N)
rng = np.random.default_rng(7)

def idx(s): return int(s * SR)
def env_ad(n, a, d, curve=2.0):
    e = np.zeros(n); a = max(1, int(a * SR)); d = max(1, int(d * SR))
    a = min(a, n); e[:a] = np.linspace(0, 1, a) ** 0.8
    rest = n - a
    if rest > 0:
        k = np.linspace(0, 1, rest)
        e[a:] = np.exp(-curve * 4 * k)
    return e
def add(buf, start, sig, gain=1.0):
    i = idx(start); n = min(len(sig), len(buf) - i)
    if n > 0 and i >= 0: buf[i:i+n] += sig[:n] * gain

NOTE = {'C':0,'C#':1,'D':2,'D#':3,'E':4,'F':5,'F#':6,'G':7,'G#':8,'A':9,'A#':10,'B':11}
def f(name):          # 'A3' -> Hz
    return 440.0 * 2 ** ((NOTE[name[:-1]] + (int(name[-1]) - 4) * 12 - 9) / 12.0)

# ---------- PAD : chords per scene ----------
CH = [(0.0, 4.2, ['D3','F3','A3','D4']),      # Dm   – الافتتاحية
      (3.3, 4.6, ['A#2','D3','F3','A#3']),    # Bb   – اللوجو
      (7.2, 6.4, ['F2','A3','C4','F3']),      # F    – الخدمات
      (13.0, 4.8, ['C3','E3','G3','C4']),     # C    – التغطية
      (17.2, 4.2, ['A#2','D3','F3','A#3']),   # Bb   – الثقة
      (20.8, 4.4, ['D3','F3','A3','D4'])]     # Dm   – الخاتمة
def pad_voice(freq, n, det):
    x = np.arange(n) / SR
    s = np.zeros(n)
    for h, a in ((1,1.0), (2,.42), (3,.22), (4,.12), (5,.07)):
        s += a * np.sin(2*np.pi*freq*h*x + np.sin(2*np.pi*0.12*x + h) * .4)
    s *= (1 + .035*np.sin(2*np.pi*4.6*x))          # chorus/vibrato خفيف
    return s / 1.9
for (st, ln, notes) in CH:
    n = idx(ln)
    e = np.minimum(np.linspace(0, 1, n) * 4, 1.0)            # fade-in
    e *= np.minimum(np.linspace(1, 0, n) * 5, 1.0)           # fade-out
    e *= 1 + .06*np.sin(2*np.pi*0.3*np.arange(n)/SR)
    for j, nm in enumerate(notes):
        fr = f(nm); det = 1 + (j - 1.5) * .0012
        v = pad_voice(fr*det, n, det) * e * (0.26 if j else 0.32)
        pan = .5 + (j - 1.5) * .16
        add(L, st, v * (1-pan)*1.5); add(R, st, v * pan*1.5)

# ---------- ARPEGGIO (طاقة أثناء الخدمات والتغطية) ----------
arp_notes = ['F4','A4','C5','A4','D5','C5','A4','F4']
bt = 0.30                                        # 100 BPM / 8th
k = 0
for s in np.arange(7.5, 17.3, bt):
    fr = f(arp_notes[k % len(arp_notes)]); k += 1
    n = idx(0.34); x = np.arange(n)/SR
    v = (np.sin(2*np.pi*fr*x) + .3*np.sin(2*np.pi*fr*2*x) + .12*np.sin(2*np.pi*fr*3*x))
    v *= env_ad(n, .004, .30, 2.6)
    g = .085 * (0.55 + 0.45*np.sin((s-7.5)*0.6))
    pan = .5 + .25*np.sin(k*1.1)
    add(L, s, v*g*(1-pan)*1.6); add(R, s, v*g*pan*1.6)

# ---------- KICK / PULSE ----------
def kick(dur=.30, f0=78, f1=42, d=2.4):
    n = idx(dur); x = np.arange(n)/SR
    fr = f1 + (f0-f1)*np.exp(-9*x)
    return np.sin(2*np.pi*np.cumsum(fr)/SR) * env_ad(n, .002, dur, d)
for s in np.arange(7.5, 21.0, 0.60):
    g = .34 if (round((s-7.5)/0.6) % 2 == 0) else .17
    kv = kick()*g
    add(L, s, kv); add(R, s, kv)
# نبضة منخفضة مستمرة (هارت-بيت) في المقدمة
for s in np.arange(0.35, 3.4, 0.75):
    kv = kick(.34, 62, 36, 2.0)*.3
    add(L, s, kv); add(R, s, kv)

# ---------- SUB BOOMS عند اللوجو والنداء ----------
def boom(dur=1.5, f0=58, f1=27):
    n = idx(dur); x = np.arange(n)/SR
    fr = f1 + (f0-f1)*np.exp(-3.4*x)
    return np.sin(2*np.pi*np.cumsum(fr)/SR) * env_ad(n, .006, dur, 1.5)
for s, g in ((3.47, .52), (20.90, .60), (24.0, .22)):
    b = boom()*g; add(L, s, b); add(R, s, b)

# ---------- WHOOSH (انتقالات البرق) ----------
def svf_sweep(n, c0, c1, q=1.4, noise=None):
    """فلتر متغيّر لإنتاج صوت مرور/وووش"""
    x = noise if noise is not None else rng.normal(0, 1, n)
    out = np.zeros(n); lo = bp = 0.0
    cut = np.linspace(c0, c1, n)
    for i in range(n):
        ff = 2*np.sin(np.pi*min(cut[i], SR*0.45)/SR)
        hp = x[i] - lo - q*bp
        bp += ff*hp
        lo += ff*bp
        out[i] = bp
    return out
TRANS = [3.45, 7.30, 13.08, 17.28, 20.84]
for s in TRANS:
    n = idx(.70); x = np.arange(n)/SR
    w = svf_sweep(n, 350, 5200)
    w *= np.exp(-((x-.42)/.21)**2)                 # جرس زمني
    w /= (np.max(np.abs(w)) + 1e-9)
    pan = np.linspace(0, 1, n)
    add(L, s-.42, w*.30*(1-pan)*1.5); add(R, s-.42, w*.30*pan*1.5)

# ---------- RISER قبل الخاتمة ----------
n = idx(1.5); x = np.arange(n)/SR
ns = svf_sweep(n, 600, 9000)
ns /= (np.max(np.abs(ns))+1e-9)
sweep = np.sin(2*np.pi*np.cumsum(180*2**(x*3.2))/SR)
ris = (ns*.55 + sweep*.30) * (x/x[-1])**2.0
add(L, 19.45, ris*.30); add(R, 19.45, ris*.30)

# ---------- IMPACT + CYMBAL عند النداء ----------
n = idx(2.2); x = np.arange(n)/SR
cym = svf_sweep(n, 7000, 2500, q=.7)
cym /= (np.max(np.abs(cym))+1e-9)
cym *= np.exp(-2.1*x)
add(L, 20.88, cym*.26); add(R, 20.88, cym*.24)

# ---------- TICKS عند ظهور البطاقات ----------
for i, s in enumerate([8.12, 8.28, 8.44, 8.60]):
    n = idx(.12); x = np.arange(n)/SR
    fr = 1500 + i*230
    v = np.sin(2*np.pi*fr*x) * env_ad(n, .001, .10, 3.2) * .12
    pan = .25 + i*.17
    add(L, s, v*(1-pan)*1.6); add(R, s, v*pan*1.6)

# ---------- REVERB (تلافيف مع ذيل صناعي) ----------
def reverb(sig, dec=1.5, mix=.22):
    ir_n = idx(dec)
    ir = rng.normal(0, 1, ir_n) * np.exp(-np.linspace(0, 6.0, ir_n))
    ir[:idx(.012)] = 0
    ir /= np.sqrt(np.sum(ir**2))
    nfft = 1 << int(np.ceil(np.log2(len(sig) + ir_n)))
    wet = np.fft.irfft(np.fft.rfft(sig, nfft) * np.fft.rfft(ir, nfft))[:len(sig)]
    wet /= (np.max(np.abs(wet)) + 1e-9); wet *= np.max(np.abs(sig))
    return sig*(1-mix) + wet*mix
L = reverb(L); R = reverb(R, dec=1.6)

# ---------- MASTER ----------
master = np.minimum(1.0, np.linspace(0, 1, N)*40)          # fade-in 25ms
master *= np.minimum(1.0, np.linspace(1, 0, N)*45)         # fade-out
L *= master; R *= master
mx = max(np.max(np.abs(L)), np.max(np.abs(R)))
L, R = L/mx*0.92, R/mx*0.92
L, R = np.tanh(L*1.12)/1.12, np.tanh(R*1.12)/1.12
peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
L, R = L/peak*0.86, R/peak*0.86
rms = np.sqrt(np.mean((L**2 + R**2)/2))
print('peak %.3f  rms %.4f (%.1f dBFS)' % (peak, rms, 20*np.log10(rms)))

out = sys.argv[1] if len(sys.argv) > 1 else 'music_bed.wav'
inter = np.empty(N*2, dtype=np.int16)
inter[0::2] = np.clip(L*32767, -32768, 32767).astype(np.int16)
inter[1::2] = np.clip(R*32767, -32768, 32767).astype(np.int16)
with wave.open(out, 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(inter.tobytes())
print('wrote', out)
