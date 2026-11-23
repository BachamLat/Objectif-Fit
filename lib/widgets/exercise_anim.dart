// Schéma animé d'un exercice : silhouette + machine, dessinés à partir de anim_data.dart.
// Même cinématique que anim/preview.py (prévisualisation).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'anim_solver.dart';

class AnimPalette {
  final Color frame, metal, pad, stack, cable, floor, fig, fig2;
  const AnimPalette({required this.frame, required this.metal, required this.pad, required this.stack, required this.cable, required this.floor, required this.fig, required this.fig2});

  factory AnimPalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const AnimPalette(
            frame: Color(0xFF5E6878),
            metal: Color(0xFFAEB7C4),
            pad: Color(0xFF55607A),
            stack: Color(0xFF3A4352),
            cable: Color(0xFF8C96A8),
            floor: Color(0xFF2E3746),
            fig: Color(0xFF7E98FF),
            fig2: Color(0xFF3E4F8F))
        : const AnimPalette(
            frame: Color(0xFF9AA3B2),
            metal: Color(0xFF505966),
            pad: Color(0xFF2E3440),
            stack: Color(0xFFC3C9D3),
            cable: Color(0xFF7A8496),
            floor: Color(0xFFC9CFD8),
            fig: Color(0xFF2446D4),
            fig2: Color(0xFF96A8EB));
  }

  Color couleur(String? c) {
    switch (c) {
      case 'metal':
        return metal;
      case 'pad':
        return pad;
      case 'stack':
        return stack;
      case 'cable':
        return cable;
      case 'floor':
        return floor;
      default:
        return frame;
    }
  }
}

class _AnimPainter extends CustomPainter {
  final Map<String, dynamic> ex;
  final Animation<double>? anim;
  final double tFixe;
  final AnimPalette pal;
  _AnimPainter(this.ex, this.anim, this.tFixe, this.pal) : super(repaint: anim);

  bool get _loop => ex['loop'] == true;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 120, size.height / 80);
    canvas.save();
    canvas.translate((size.width - 120 * s) / 2, (size.height - 80 * s) / 2);
    canvas.scale(s);
    final v = anim?.value ?? tFixe;
    final t = _loop ? v : 0.5 - 0.5 * math.cos(2 * math.pi * v);
    final j = solvePose(ex, t);
    _items(canvas, ex['items'], j);
    // membres éloignés (plus clairs), puis corps
    _seg(canvas, j['hip']!, j['knee2']!, 3.4, pal.fig2);
    _seg(canvas, j['knee2']!, j['foot2']!, 3.0, pal.fig2);
    _seg(canvas, j['foot2']!, j['toe2']!, 2.2, pal.fig2);
    _seg(canvas, j['shoulder']!, j['elbow2']!, 2.8, pal.fig2);
    _seg(canvas, j['elbow2']!, j['hand2']!, 2.5, pal.fig2);
    _seg(canvas, j['hip']!, j['neck']!, 4.4, pal.fig);
    _seg(canvas, j['hip']!, j['knee']!, 3.6, pal.fig);
    _seg(canvas, j['knee']!, j['foot']!, 3.2, pal.fig);
    _seg(canvas, j['foot']!, j['toe']!, 2.4, pal.fig);
    canvas.drawCircle(j['head']!.off, 4.6, Paint()..color = pal.fig);
    _seg(canvas, j['shoulder']!, j['elbow']!, 3.0, pal.fig);
    _seg(canvas, j['elbow']!, j['hand']!, 2.7, pal.fig);
    _items(canvas, ex['front'], j);
    canvas.restore();
  }

  void _seg(Canvas c, Pt a, Pt b, double w, Color col) {
    c.drawLine(
        a.off,
        b.off,
        Paint()
          ..color = col
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round);
  }

  void _items(Canvas canvas, dynamic items, Map<String, Pt> j) {
    if (items is! List) return;
    for (final raw in items) {
      if (raw is! Map) continue;
      final it = raw;
      final type = it['t']?.toString();
      final col = type == 'pad' ? pal.pad : pal.couleur(it['c']?.toString());
      if (type == 'line' || type == 'pad') {
        final pts = (it['p'] as List).map((e) => res(e, j).off).toList();
        if (pts.length < 2) continue;
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final o in pts.skip(1)) {
          path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(
            path,
            Paint()
              ..color = col
              ..style = PaintingStyle.stroke
              ..strokeWidth = it['w'] is num ? toD(it['w']) : 2.0
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round);
      } else if (type == 'rect') {
        final r = it['r'] as List;
        final rect = Rect.fromLTWH(toD(r[0]), toD(r[1]), toD(r[2]), toD(r[3]));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), Paint()..color = col);
        if (it['c'] == 'stack') {
          final lp = Paint()
            ..color = pal.floor
            ..strokeWidth = 0.6;
          for (var y = rect.top + 3; y < rect.bottom - 1; y += 3) {
            canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), lp);
          }
        }
      } else if (type == 'circle') {
        final c = res(it['p'], j).off;
        final r = it['r'] is num ? toD(it['r']) : 2.0;
        final fill = it['fill'] != false;
        canvas.drawCircle(
            c,
            r,
            Paint()
              ..color = col
              ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
              ..strokeWidth = 1.6);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnimPainter old) => old.ex != ex || old.tFixe != tFixe || old.pal.fig != pal.fig;
}

/// Schéma animé d'un exercice. [animer] = false pour une vignette fixe.
class ExerciseAnimation extends StatefulWidget {
  final String id;
  final bool animer;
  const ExerciseAnimation({super.key, required this.id, this.animer = true});

  @override
  State<ExerciseAnimation> createState() => _ExerciseAnimationState();
}

class _ExerciseAnimationState extends State<ExerciseAnimation> with TickerProviderStateMixin {
  AnimationController? _c;

  Map<String, dynamic>? get _ex => anims[widget.id] is Map ? Map<String, dynamic>.from(anims[widget.id] as Map) : null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _majController();
  }

  @override
  void didUpdateWidget(covariant ExerciseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _majController();
  }

  void _majController() {
    final reduire = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final doit = widget.animer && !reduire && _ex != null;
    if (doit && _c == null) {
      final loop = _ex!['loop'] == true;
      _c = AnimationController(vsync: this, duration: Duration(milliseconds: loop ? 1700 : 2800))..repeat();
    } else if (!doit && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    final pal = AnimPalette.of(context);
    if (ex == null) {
      return AspectRatio(aspectRatio: 1.5, child: Center(child: Icon(Icons.fitness_center, color: pal.frame)));
    }
    return AspectRatio(
      aspectRatio: 1.5,
      child: CustomPaint(painter: _AnimPainter(ex, _c, ex['loop'] == true ? 0.3 : 0.62, pal)),
    );
  }
}

extension on Pt {
  Offset get off => Offset(x, y);
}
