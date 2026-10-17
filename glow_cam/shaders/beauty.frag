#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Real-time beauty + look shader, used as an ImageFilter over the camera
// preview and over still photos so live view and saved photo match.
// Positions are normalized to the filtered box (0..1); lengths are a
// fraction of the box width.

uniform vec2 uSize;        // set by the engine: input texture size in pixels
uniform vec4 uFace;        // face center uv.xy, half-axes (width fraction) zw
uniform float uRoll;       // face roll in radians
uniform vec4 uEyes;        // eye centers uv: first.xy, second.zw
uniform float uEyeRadius;  // width fraction
uniform vec4 uJaw;         // jaw anchors uv: first.xy, second.zw
uniform vec4 uCheeks;      // cheek centers uv
uniform vec4 uLips;        // lips center uv.xy, half-size (width fraction) zw
uniform vec4 uAmt1;        // smooth, eyes, slim, blush
uniform vec4 uAmt2;        // lips, brighten, vignette, face weight (0 = no face)
uniform vec4 uAmt3;        // glow, unused...
uniform mat4 uColor;       // color grade (rgb part of a 4x5 color matrix)
uniform vec4 uColorOffset; // color grade offset (0..1)
uniform vec4 uWashA;       // wash gradient start rgb, a = opacity
uniform vec4 uWashB;       // wash gradient end rgb

uniform sampler2D uTexture;

out vec4 fragColor;

vec4 sampleAt(vec2 p) {
  vec2 uv = clamp(p / uSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

vec2 rotate(vec2 v, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

// Local magnification around c (eyes).
vec2 bulge(vec2 p, vec2 c, float r, float amount) {
  vec2 d = p - c;
  float dist = length(d);
  if (dist >= r) return p;
  float t = dist / r;
  return c + d * (1.0 - amount * (1.0 - t * t));
}

// Moves content near `anchor` by `v` (liquify-style push).
vec2 push(vec2 p, vec2 anchor, vec2 v, float r) {
  vec2 d = p - anchor;
  float q = dot(d, d) / (r * r);
  if (q >= 1.0) return p;
  float w = (1.0 - q) * (1.0 - q);
  return p - v * w;
}

float skinMask(vec3 c) {
  float y = dot(c, vec3(0.299, 0.587, 0.114));
  float cb = 0.5 - 0.168736 * c.r - 0.331264 * c.g + 0.5 * c.b;
  float cr = 0.5 + 0.5 * c.r - 0.418688 * c.g - 0.081312 * c.b;
  float m = smoothstep(0.26, 0.31, cb) * (1.0 - smoothstep(0.50, 0.54, cb));
  m *= smoothstep(0.515, 0.545, cr) * (1.0 - smoothstep(0.68, 0.72, cr));
  // Leave dark hair / beard alone.
  m *= smoothstep(0.14, 0.26, y);
  return m;
}

vec3 softLight(vec3 b, vec3 s) {
  vec3 lo = 2.0 * b * s + b * b * (1.0 - 2.0 * s);
  vec3 hi = sqrt(b) * (2.0 * s - 1.0) + 2.0 * b * (1.0 - s);
  return mix(lo, hi, step(0.5, s));
}

// Edge-preserving (bilateral) blur: averages only similar colors, so skin
// gets smooth while eyes, brows, beard and edges stay sharp.
vec3 bilateral(vec2 p, vec3 center, float radius) {
  vec3 sum = center;
  float wsum = 1.0;
  for (int i = 0; i < 16; i++) {
    float fi = float(i);
    float ang = fi * 0.785398 + (mod(fi, 2.0) * 0.392699);
    float rr = (fi < 8.0) ? radius : radius * 0.45;
    vec3 s = sampleAt(p + vec2(cos(ang), sin(ang)) * rr).rgb;
    vec3 diff = s - center;
    float w = exp(-dot(diff, diff) * 30.0);
    sum += s * w;
    wsum += w;
  }
  return sum / wsum;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  float W = uSize.x;
  float faceWeight = uAmt2.w;

  vec2 faceC = uFace.xy * uSize;
  vec2 faceR = uFace.zw * W;

  // ---- Geometry (only with a tracked face) ----
  vec2 q = p;
  if (faceWeight > 0.0) {
    float slim = uAmt1.z * faceWeight;
    if (slim > 0.0) {
      vec2 j1 = uJaw.xy * uSize;
      vec2 j2 = uJaw.zw * uSize;
      float r = faceR.x * 0.8;
      q = push(q, j1, normalize(faceC - j1) * slim * faceR.x * 0.10, r);
      q = push(q, j2, normalize(faceC - j2) * slim * faceR.x * 0.10, r);
    }
    float eyes = uAmt1.y * faceWeight;
    if (eyes > 0.0) {
      float er = uEyeRadius * W;
      q = bulge(q, uEyes.xy * uSize, er, eyes * 0.22);
      q = bulge(q, uEyes.zw * uSize, er, eyes * 0.22);
    }
  }

  vec4 base = sampleAt(q);
  vec3 col = base.rgb;

  // ---- Face region ----
  float faceMask = 0.0;
  if (faceWeight > 0.0) {
    vec2 d = rotate(p - faceC, -uRoll) / (faceR * vec2(1.25, 1.35));
    faceMask = (1.0 - smoothstep(0.8, 1.0, length(d))) * faceWeight;
  }
  float skin = skinMask(col);
  float skinW = skin * max(faceMask, 0.35);

  // ---- Skin smoothing ----
  float smoothAmt = uAmt1.x;
  if (smoothAmt > 0.0 && skinW > 0.01) {
    float radius = faceWeight > 0.0 ? max(faceR.x * 0.07, 2.0) : W * 0.012;
    vec3 sm = bilateral(q, col, radius);
    col = mix(col, sm, clamp(smoothAmt * 0.95 * skinW, 0.0, 1.0));
  }

  // ---- Skin brightening (even, luminous tone) ----
  float bright = uAmt2.y;
  if (bright > 0.0) {
    vec3 lifted = col + (1.0 - col) * 0.16;
    lifted = mix(lifted, lifted * vec3(1.02, 0.995, 0.985), 0.6);
    col = mix(col, lifted, bright * skinW);
  }

  // ---- Blush ----
  float blush = uAmt1.w * faceWeight;
  if (blush > 0.0) {
    float br = faceR.x * 0.42;
    float b1 = 1.0 - smoothstep(0.0, 1.0, length(p - uCheeks.xy * uSize) / br);
    float b2 = 1.0 - smoothstep(0.0, 1.0, length(p - uCheeks.zw * uSize) / br);
    float b = max(b1, b2) * blush * max(skin, 0.3);
    col = mix(col, softLight(col, vec3(0.95, 0.45, 0.48)), b * 0.55);
  }

  // ---- Lip tint ----
  float lips = uAmt2.x * faceWeight;
  if (lips > 0.0 && uLips.z > 0.0) {
    vec2 d = rotate(p - uLips.xy * uSize, -uRoll) / (uLips.zw * W * 1.1);
    float m = 1.0 - smoothstep(0.65, 1.0, length(d));
    m *= smoothstep(0.0, 0.07, col.r - col.g);
    vec3 tinted = softLight(col, vec3(0.86, 0.26, 0.36));
    col = mix(col, tinted, m * lips * 0.65);
  }

  // ---- Glow (soft bloom) ----
  float glow = uAmt3.x;
  if (glow > 0.0) {
    vec3 g = vec3(0.0);
    float gr = W * 0.025;
    for (int i = 0; i < 8; i++) {
      float ang = float(i) * 0.785398;
      g += sampleAt(q + vec2(cos(ang), sin(ang)) * gr).rgb;
    }
    g = (g / 8.0 + col) * 0.5;
    col = 1.0 - (1.0 - col) * (1.0 - g * glow * 0.45);
  }

  // ---- Color grade ----
  col = clamp((uColor * vec4(col, 1.0)).rgb + uColorOffset.rgb, 0.0, 1.0);

  // ---- Wash (soft-light gradient tint) ----
  if (uWashA.a > 0.0) {
    vec2 uv = p / uSize;
    vec3 w = mix(uWashA.rgb, uWashB.rgb, clamp((uv.x + uv.y) * 0.5, 0.0, 1.0));
    col = mix(col, softLight(col, w), uWashA.a);
  }

  // ---- Vignette ----
  float vig = uAmt2.z;
  if (vig > 0.0) {
    float L = max(uSize.x, uSize.y) * 0.72;
    float t = smoothstep(0.45, 1.0, length(p - uSize * 0.5) / L);
    col *= 1.0 - t * vig * 0.75;
  }

  fragColor = vec4(col * base.a, base.a);
}
