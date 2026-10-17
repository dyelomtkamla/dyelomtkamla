import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Face key points normalized to a target box: positions are 0..1 of the box,
/// lengths are a fraction of the box width. This lets the same geometry drive
/// the shader on the live preview and on a captured photo of the same framing.
class FaceGeometry {
  const FaceGeometry({
    required this.center,
    required this.radius,
    required this.roll,
    required this.eye1,
    required this.eye2,
    required this.eyeRadius,
    required this.jaw1,
    required this.jaw2,
    required this.cheek1,
    required this.cheek2,
    required this.lips,
    required this.lipsHalf,
    this.weight = 1,
  });

  final Offset center;
  final Size radius;
  final double roll;
  final Offset eye1;
  final Offset eye2;
  final double eyeRadius;
  final Offset jaw1;
  final Offset jaw2;
  final Offset cheek1;
  final Offset cheek2;
  final Offset lips;
  final Size lipsHalf;

  /// 0..1, fades the effect in/out when tracking starts or is lost.
  final double weight;

  FaceGeometry withWeight(double w) => FaceGeometry(
    center: center,
    radius: radius,
    roll: roll,
    eye1: eye1,
    eye2: eye2,
    eyeRadius: eyeRadius,
    jaw1: jaw1,
    jaw2: jaw2,
    cheek1: cheek1,
    cheek2: cheek2,
    lips: lips,
    lipsHalf: lipsHalf,
    weight: w,
  );

  /// Blends towards [next] by [t]; used to remove frame-to-frame jitter.
  FaceGeometry lerpTo(FaceGeometry next, double t) {
    Offset o(Offset a, Offset b) => Offset.lerp(a, b, t)!;
    Size s(Size a, Size b) => Size.lerp(a, b, t)!;
    double d(double a, double b) => a + (b - a) * t;
    return FaceGeometry(
      center: o(center, next.center),
      radius: s(radius, next.radius),
      roll: d(roll, next.roll),
      eye1: o(eye1, next.eye1),
      eye2: o(eye2, next.eye2),
      eyeRadius: d(eyeRadius, next.eyeRadius),
      jaw1: o(jaw1, next.jaw1),
      jaw2: o(jaw2, next.jaw2),
      cheek1: o(cheek1, next.cheek1),
      cheek2: o(cheek2, next.cheek2),
      lips: o(lips, next.lips),
      lipsHalf: s(lipsHalf, next.lipsHalf),
      weight: d(weight, next.weight),
    );
  }

  /// Builds geometry from an ML Kit [face]. [map] converts a detector point
  /// into pixels of the target box of size [box].
  static FaceGeometry? fromFace(Face face, Size box, Offset Function(math.Point<int>) map) {
    List<Offset>? pts(FaceContourType t) {
      final c = face.contours[t];
      if (c == null || c.points.isEmpty) return null;
      return c.points.map(map).toList();
    }

    final oval = pts(FaceContourType.face);
    final eyeA = pts(FaceContourType.leftEye);
    final eyeB = pts(FaceContourType.rightEye);
    if (oval == null || eyeA == null || eyeB == null) return null;

    final lipPts = [...?pts(FaceContourType.upperLipTop), ...?pts(FaceContourType.lowerLipBottom)];
    return fromPoints(box: box, oval: oval, eyeA: eyeA, eyeB: eyeB, lips: lipPts);
  }

  /// Pure geometry from contour points already in box pixels.
  static FaceGeometry? fromPoints({
    required Size box,
    required List<Offset> oval,
    required List<Offset> eyeA,
    required List<Offset> eyeB,
    required List<Offset> lips,
  }) {
    if (box.isEmpty || oval.length < 8) return null;
    var e1 = _centroid(eyeA);
    var e2 = _centroid(eyeB);
    if (e1.dx > e2.dx) {
      final t = e1;
      e1 = e2;
      e2 = t;
    }
    final eyeVec = e2 - e1;
    final interocular = eyeVec.distance;
    if (interocular < 2) return null;
    final roll = math.atan2(eyeVec.dy, eyeVec.dx);

    // Work in a face-aligned frame (rotated so the eyes are horizontal).
    final pivot = _centroid(oval);
    Offset toFace(Offset p) => _rotate(p - pivot, -roll);
    Offset fromFace(Offset p) => _rotate(p, roll) + pivot;

    final ovalF = oval.map(toFace).toList();
    final bounds = _bounds(ovalF);
    final centerF = bounds.center;
    final rx = bounds.width / 2, ry = bounds.height / 2;

    // Jaw anchors: widest points in the lower part of the face.
    final lower = ovalF.where((p) => p.dy > centerF.dy + ry * 0.2 && p.dy < centerF.dy + ry * 0.75).toList();
    final jawSrc = lower.length >= 2 ? lower : ovalF;
    final jaw1F = jawSrc.reduce((a, b) => a.dx < b.dx ? a : b);
    final jaw2F = jawSrc.reduce((a, b) => a.dx > b.dx ? a : b);

    final e1F = toFace(e1), e2F = toFace(e2);
    Offset lipsF;
    Size lipsHalf;
    if (lips.length >= 4) {
      final lb = _bounds(lips.map(toFace).toList());
      lipsF = lb.center;
      lipsHalf = Size(lb.width / 2, lb.height / 2);
    } else {
      lipsF = Offset(centerF.dx, centerF.dy + ry * 0.55);
      lipsHalf = Size(rx * 0.35, ry * 0.12);
    }

    // Cheeks: below and slightly outside each eye, ~60% of the way to the mouth.
    final eyeY = (e1F.dy + e2F.dy) / 2;
    final cheekY = eyeY + (lipsF.dy - eyeY) * 0.6;
    final cheek1F = Offset(e1F.dx - rx * 0.12, cheekY);
    final cheek2F = Offset(e2F.dx + rx * 0.12, cheekY);

    final w = box.width;
    Offset n(Offset facePt) {
      final p = fromFace(facePt);
      return Offset(p.dx / box.width, p.dy / box.height);
    }

    return FaceGeometry(
      center: n(centerF),
      radius: Size(rx / w, ry / w),
      roll: roll,
      eye1: n(e1F),
      eye2: n(e2F),
      eyeRadius: interocular * 0.38 / w,
      jaw1: n(jaw1F),
      jaw2: n(jaw2F),
      cheek1: n(cheek1F),
      cheek2: n(cheek2F),
      lips: n(lipsF),
      lipsHalf: Size(lipsHalf.width / w, lipsHalf.height / w),
    );
  }

  static Offset _centroid(List<Offset> pts) {
    var x = 0.0, y = 0.0;
    for (final p in pts) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / pts.length, y / pts.length);
  }

  static Rect _bounds(List<Offset> pts) {
    var l = double.infinity, t = double.infinity;
    var r = -double.infinity, b = -double.infinity;
    for (final p in pts) {
      l = math.min(l, p.dx);
      t = math.min(t, p.dy);
      r = math.max(r, p.dx);
      b = math.max(b, p.dy);
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  static Offset _rotate(Offset v, double a) {
    final c = math.cos(a), s = math.sin(a);
    return Offset(c * v.dx - s * v.dy, s * v.dx + c * v.dy);
  }
}
