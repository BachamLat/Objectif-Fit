// Composants communs : cartes, jauges, échelle IMC, courbe de poids.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../calc.dart';

const accent = Color(0xFF2446D4);

class Couleurs {
  final Color good, warn, bad, under, normal, surpoids, ob1, ob2, muted;
  const Couleurs(this.good, this.warn, this.bad, this.under, this.normal, this.surpoids, this.ob1, this.ob2, this.muted);
  static Couleurs of(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const Couleurs(Color(0xFF4CC38A), Color(0xFFE3B04F), Color(0xFFF2766B), Color(0xFF7FA8FF), Color(0xFF3FB57A), Color(0xFFE3B04F), Color(0xFFEE7A3E), Color(0xFFD9534A), Color(0xFF8A95A8))
      : const Couleurs(Color(0xFF1B7F46), Color(0xFF9A6412), Color(0xFFB42318), Color(0xFF5B8DEF), Color(0xFF1E8A4C), Color(0xFFD9A23A), Color(0xFFC2410C), Color(0xFF8F1D1D), Color(0xFF6B7587));

  Color zone(String key) {
    switch (key) {
      case 'maigreur':
        return under;
      case 'normal':
        return normal;
      case 'surpoids':
        return warn;
      case 'ob1':
        return ob1;
      default:
        return ob2;
    }
  }
}

const tabular = [FontFeature.tabularFigures()];

void message(BuildContext context, String texte) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texte), behavior: SnackBarBehavior.floating));
}

class Section extends StatelessWidget {
  final String? titre;
  final Widget? action;
  final List<Widget> children;
  final EdgeInsets padding;
  const Section({super.key, this.titre, this.action, required this.children, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: t.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: t.colorScheme.outlineVariant)),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titre != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(child: Text(titre!.toUpperCase(), style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8))),
                  if (action != null) action!,
                ]),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class Gros extends StatelessWidget {
  final String valeur, unite;
  final double taille;
  const Gros(this.valeur, this.unite, {super.key, this.taille = 40});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: valeur, style: TextStyle(fontSize: taille, fontWeight: FontWeight.w800, height: 1, fontFeatures: tabular)),
        TextSpan(text: ' $unite', style: TextStyle(fontSize: taille * 0.42, fontWeight: FontWeight.w600, color: t.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class Etiquette extends StatelessWidget {
  final String texte;
  const Etiquette(this.texte, {super.key});
  @override
  Widget build(BuildContext context) => Text(texte.toUpperCase(),
      style: TextStyle(fontSize: 11.5, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant));
}

class Pastille extends StatelessWidget {
  final String texte;
  final Color couleur;
  const Pastille(this.texte, this.couleur, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: couleur)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(texte, style: TextStyle(color: couleur, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
}

/// Jauge horizontale « valeur / objectif ».
class Jauge extends StatelessWidget {
  final String label, unite;
  final num valeur, max;
  final bool alerteSiDepasse, vertSiAtteint;
  final String? pied;
  const Jauge({super.key, required this.label, required this.valeur, required this.max, this.unite = '', this.alerteSiDepasse = false, this.vertSiAtteint = false, this.pied});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = Couleurs.of(context);
    final pct = max > 0 ? (valeur / max).clamp(0.0, 1.0).toDouble() : 0.0;
    Color fill = t.colorScheme.primary;
    if (alerteSiDepasse && valeur > max) fill = c.warn;
    if (vertSiAtteint && valeur >= max) fill = c.good;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 14))),
        Text.rich(TextSpan(children: [
          TextSpan(text: fmt(valeur), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, fontFeatures: tabular)),
          TextSpan(text: ' / ${fmt(max)} $unite', style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 14)),
        ])),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: pct, minHeight: 10, color: fill, backgroundColor: t.colorScheme.surfaceContainerHighest),
      ),
      if (pied != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(pied!, style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant))),
    ]);
  }
}

/// Échelle IMC de 16 à 40 avec la position actuelle et l'objectif.
class EchelleImc extends StatelessWidget {
  final double imcActuel, imcCible;
  const EchelleImc({super.key, required this.imcActuel, required this.imcCible});

  @override
  Widget build(BuildContext context) {
    final c = Couleurs.of(context);
    final t = Theme.of(context);
    const lo = 16.0, hi = 40.0;
    double pos(double v) => ((v.clamp(lo, hi) - lo) / (hi - lo)).toDouble();
    final zones = [
      [16.0, 18.5, c.under],
      [18.5, 25.0, c.normal],
      [25.0, 30.0, c.surpoids],
      [30.0, 35.0, c.ob1],
      [35.0, 40.0, c.ob2],
    ];
    return Semantics(
      label: 'IMC ${fmt(imcActuel, 1)}, objectif ${fmt(imcCible, 1)}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, cons) {
          final w = cons.maxWidth;
          return SizedBox(
            height: 26,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 0,
                right: 0,
                top: 6,
                height: 14,
                child: Row(children: [
                  for (final z in zones)
                    Expanded(
                      flex: (((z[1] as double) - (z[0] as double)) * 10).round(),
                      child: Container(margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: z[2] as Color, borderRadius: BorderRadius.circular(3))),
                    ),
                ]),
              ),
              Positioned(
                left: w * pos(imcCible) - 6,
                top: 7,
                child: Container(width: 12, height: 12, decoration: BoxDecoration(color: t.colorScheme.surface, shape: BoxShape.circle, border: Border.all(color: t.colorScheme.onSurface, width: 2))),
              ),
              Positioned(
                left: w * pos(imcActuel) - 2,
                top: 0,
                child: Container(width: 4, height: 26, decoration: BoxDecoration(color: t.colorScheme.onSurface, borderRadius: BorderRadius.circular(2))),
              ),
            ]),
          );
        }),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, cons) {
          final w = cons.maxWidth;
          return SizedBox(
            height: 16,
            child: Stack(children: [
              for (final v in [18.5, 25.0, 30.0, 35.0])
                Positioned(left: w * pos(v) - 14, width: 28, child: Text(fmt(v, v % 1 == 0 ? 0 : 1), textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: c.muted))),
            ]),
          );
        }),
        const SizedBox(height: 4),
        Wrap(spacing: 12, runSpacing: 2, children: [
          _leg(c.normal, 'Normal 18,5–25', c),
          _leg(c.surpoids, 'Surpoids 25–30', c),
          _leg(c.ob1, 'Obésité modérée 30–35', c),
          Text('▮ toi · ○ objectif', style: TextStyle(fontSize: 12, color: c.muted)),
        ]),
      ]),
    );
  }

  Widget _leg(Color col, String txt, Couleurs c) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(txt, style: TextStyle(fontSize: 12, color: c.muted)),
      ]);
}

/// Courbe du poids avec ligne d'objectif. Toucher la courbe affiche la valeur.
class CourbePoids extends StatefulWidget {
  final List<PointPoids> points;
  final double cible;
  const CourbePoids({super.key, required this.points, required this.cible});
  @override
  State<CourbePoids> createState() => _CourbePoidsState();
}

class _CourbePoidsState extends State<CourbePoids> {
  int? _sel;

  void _toucher(Offset p, Size size) {
    final pts = widget.points;
    if (pts.isEmpty) return;
    final geo = _Geo(pts, widget.cible, size);
    var best = 0;
    for (var i = 1; i < pts.length; i++) {
      if ((geo.x(pts[i].date) - p.dx).abs() < (geo.x(pts[best].date) - p.dx).abs()) best = i;
    }
    setState(() => _sel = best);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = Couleurs.of(context);
    final sel = _sel != null && _sel! < widget.points.length ? widget.points[_sel!] : widget.points.last;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${dateCourte(sel.date)} · ${fmt(sel.kg, 1)} kg${sel.depart ? ' (départ)' : ''}', style: TextStyle(fontWeight: FontWeight.w700, color: t.colorScheme.onSurfaceVariant, fontFeatures: tabular)),
      const SizedBox(height: 6),
      AspectRatio(
        aspectRatio: 1.8,
        child: LayoutBuilder(builder: (context, cons) {
          final size = Size(cons.maxWidth, cons.maxHeight);
          return GestureDetector(
            onPanDown: (d) => _toucher(d.localPosition, size),
            onPanUpdate: (d) => _toucher(d.localPosition, size),
            child: CustomPaint(
              size: size,
              painter: _CourbePainter(
                widget.points,
                widget.cible,
                _sel,
                ligne: t.colorScheme.primary,
                grille: t.colorScheme.outlineVariant,
                texte: c.muted,
                objectif: c.normal,
                fond: t.colorScheme.surfaceContainerLow,
              ),
            ),
          );
        }),
      ),
    ]);
  }
}

class _Geo {
  final List<PointPoids> pts;
  final Size size;
  final double left = 34, right = 12, top = 12, bottom = 22;
  late final String first;
  late final int span;
  late final double y0, y1, step;
  _Geo(this.pts, double cible, this.size) {
    first = pts.first.date;
    span = math.max(14, diffDays(first, pts.last.date));
    final vals = [...pts.map((p) => p.kg), cible];
    var lo = vals.reduce(math.min).floorToDouble() - 1;
    var hi = vals.reduce(math.max).ceilToDouble() + 1;
    final r = hi - lo;
    step = r > 16 ? 5.0 : (r > 8 ? 2.0 : 1.0);
    lo = (lo / step).floorToDouble() * step;
    hi = (hi / step).ceilToDouble() * step;
    y0 = lo;
    y1 = hi;
  }
  double x(String d) => left + diffDays(first, d) / span * (size.width - left - right);
  double y(double v) => top + (1 - (v - y0) / (y1 - y0)) * (size.height - top - bottom);
}

class _CourbePainter extends CustomPainter {
  final List<PointPoids> pts;
  final double cible;
  final int? sel;
  final Color ligne, grille, texte, objectif, fond;
  _CourbePainter(this.pts, this.cible, this.sel, {required this.ligne, required this.grille, required this.texte, required this.objectif, required this.fond});

  void _txt(Canvas c, String s, Offset o, {TextAlign align = TextAlign.left, Color? col, FontWeight w = FontWeight.w400}) {
    final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(fontSize: 10.5, color: col ?? texte, fontWeight: w)), textDirection: TextDirection.ltr)..layout();
    var dx = o.dx;
    if (align == TextAlign.right) dx -= tp.width;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(c, Offset(dx, o.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.isEmpty) return;
    final g = _Geo(pts, cible, size);
    final gp = Paint()
      ..color = grille
      ..strokeWidth = 1;
    for (var v = g.y0; v <= g.y1 + 0.001; v += g.step) {
      canvas.drawLine(Offset(g.left, g.y(v)), Offset(size.width - g.right, g.y(v)), gp);
      _txt(canvas, fmt(v), Offset(g.left - 6, g.y(v)), align: TextAlign.right);
    }
    _txt(canvas, dateCourte(g.first), Offset(g.left, size.height - 8));
    _txt(canvas, dateCourte(addDays(g.first, g.span)), Offset(size.width - g.right, size.height - 8), align: TextAlign.right);
    // objectif
    final yc = g.y(cible);
    final dp = Paint()
      ..color = objectif
      ..strokeWidth = 1.5;
    for (var x = g.left; x < size.width - g.right; x += 9) {
      canvas.drawLine(Offset(x, yc), Offset(math.min(x + 5, size.width - g.right), yc), dp);
    }
    _txt(canvas, 'Objectif ${fmt(cible, 1)} kg', Offset(size.width - g.right, yc - 9), align: TextAlign.right, w: FontWeight.w700);
    // courbe
    final p = pts.map((e) => Offset(g.x(e.date), g.y(e.kg))).toList();
    if (p.length > 1) {
      final path = Path()..moveTo(p.first.dx, p.first.dy);
      for (final o in p.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      final area = Path.from(path)
        ..lineTo(p.last.dx, size.height - g.bottom)
        ..lineTo(p.first.dx, size.height - g.bottom)
        ..close();
      canvas.drawPath(area, Paint()..color = ligne.withValues(alpha: 0.10));
      canvas.drawPath(
          path,
          Paint()
            ..color = ligne
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round);
    }
    for (var i = 0; i < p.length; i++) {
      final last = i == p.length - 1;
      final r = last ? 5.5 : 3.0;
      canvas.drawCircle(p[i], r + 1.5, Paint()..color = fond);
      canvas.drawCircle(p[i], r, Paint()..color = ligne);
    }
    if (sel != null && sel! < p.length) {
      canvas.drawLine(Offset(p[sel!].dx, g.top), Offset(p[sel!].dx, size.height - g.bottom), Paint()..color = texte);
    }
  }

  @override
  bool shouldRepaint(covariant _CourbePainter old) => true;
}
