// Cinématique des schémas animés (sans dépendance Flutter, testable en Dart pur).
// Même calcul que anim/preview.py.
import 'dart:convert';
import 'dart:math' as math;

import 'anim_data.dart';

final Map<String, dynamic> anims = Map<String, dynamic>.from(jsonDecode(animJson) as Map);

bool animDisponible(String id) => anims.containsKey(id);

class Pt {
  final double x, y;
  const Pt(this.x, this.y);
}

const _lUa = 12.0, _lFa = 11.0, _lTh = 15.0, _lSh = 15.0, _lFoot = 4.5;

double toD(dynamic v) => (v as num).toDouble();

Pt _polar(Pt b, double l, double a) {
  final r = a * math.pi / 180;
  return Pt(b.x + l * math.cos(r), b.y - l * math.sin(r));
}

double _angle(Pt f, Pt t) => math.atan2(-(t.y - f.y), t.x - f.x) * 180 / math.pi;

class _Ik {
  final Pt mid, end;
  final double a2;
  const _Ik(this.mid, this.end, this.a2);
}

_Ik _ik(Pt root, Pt target, double l1, double l2, double bend) {
  final dx = target.x - root.x, dy = target.y - root.y;
  final d = math.sqrt(dx * dx + dy * dy).clamp(0.01, l1 + l2 - 0.05).toDouble();
  final base = _angle(root, target);
  final c = ((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)).clamp(-1.0, 1.0).toDouble();
  final a1 = base + bend * math.acos(c) * 180 / math.pi;
  final mid = _polar(root, l1, a1);
  final endT = _polar(root, d, base);
  final a2 = _angle(mid, endT);
  return _Ik(mid, _polar(mid, l2, a2), a2);
}

dynamic _lerp(dynamic a, dynamic b, double t) {
  if (a is num && b is num) return a + (b - a) * t;
  if (a is List && b is List && a.length == b.length) {
    return [for (var i = 0; i < a.length; i++) toD(a[i]) + (toD(b[i]) - toD(a[i])) * t];
  }
  if (a is Map && b is Map && a['j'] == b['j']) {
    return {'j': a['j'], 'd': _lerp(a['d'] ?? const [0, 0], b['d'] ?? const [0, 0], t)};
  }
  return t < 0.5 ? a : b;
}

Pt res(dynamic spec, Map<String, Pt> j) {
  if (spec is String) return j[spec] ?? const Pt(0, 0);
  if (spec is Map) {
    final b = j[spec['j']?.toString() ?? ''] ?? const Pt(0, 0);
    final d = spec['d'] is List ? spec['d'] as List : const [0, 0];
    return Pt(b.x + toD(d[0]), b.y + toD(d[1]));
  }
  final l = spec as List;
  return Pt(toD(l[0]), toD(l[1]));
}

Map<String, Pt> solvePose(Map<String, dynamic> ex, double t) {
  final a = Map<String, dynamic>.from(ex['a'] as Map);
  final b = ex['b'] is Map ? Map<String, dynamic>.from(ex['b'] as Map) : <String, dynamic>{};
  final loop = ex['loop'] == true;
  final p = <String, dynamic>{};
  for (final k in a.keys) {
    p[k] = loop ? a[k] : _lerp(a[k], b.containsKey(k) ? b[k] : a[k], t);
  }
  final j = <String, Pt>{};
  final hip = res(p['hip'], j);
  final tor = toD(p['torso']);
  j['hip'] = hip;
  j['neck'] = _polar(hip, 22, tor);
  j['shoulder'] = _polar(hip, 19.5, tor);
  j['head'] = _polar(hip, 28, tor);
  final sh = j['shoulder']!;
  final theta = t * 360;
  final eb = p['eb'] is num ? toD(p['eb']) : -1.0;
  final kb = p['kb'] is num ? toD(p['kb']) : 1.0;

  Pt crankPt(Map c, double th) {
    final r = th * math.pi / 180;
    final cc = c['c'] as List, rr = c['r'] as List;
    return Pt(toD(cc[0]) + toD(rr[0]) * math.cos(r), toD(cc[1]) - toD(rr[1]) * math.sin(r));
  }

  // Bras
  Pt el, hd, el2, hd2;
  if (loop && ex['handCrank'] is Map) {
    final hc = ex['handCrank'] as Map;
    final ph = hc['phase'] is num ? toD(hc['phase']) : 0.0;
    final i1 = _ik(sh, crankPt(hc, theta + ph), _lUa, _lFa, eb);
    final i2 = _ik(sh, crankPt(hc, theta + ph + 180), _lUa, _lFa, eb);
    el = i1.mid;
    hd = i1.end;
    el2 = i2.mid;
    hd2 = i2.end;
  } else {
    if (p.containsKey('handAt')) {
      final i1 = _ik(sh, res(p['handAt'], j), _lUa, _lFa, eb);
      el = i1.mid;
      hd = i1.end;
    } else if (p.containsKey('uaR')) {
      el = _polar(sh, _lUa, tor + toD(p['uaR']));
      hd = _polar(el, _lFa, tor + toD(p['faR']));
    } else {
      el = _polar(sh, _lUa, toD(p['ua']));
      hd = _polar(el, _lFa, toD(p['fa']));
    }
    if (p.containsKey('handAt2')) {
      final i2 = _ik(sh, res(p['handAt2'], j), _lUa, _lFa, eb);
      el2 = i2.mid;
      hd2 = i2.end;
    } else if (p.containsKey('ua2')) {
      el2 = _polar(sh, _lUa, toD(p['ua2']));
      hd2 = _polar(el2, _lFa, toD(p['fa2']));
    } else {
      el2 = el;
      hd2 = hd;
    }
  }
  j['elbow'] = el;
  j['hand'] = hd;
  j['elbow2'] = el2;
  j['hand2'] = hd2;

  // Jambes
  Pt kn, an, kn2, an2;
  double sa, sa2;
  if (loop && ex['crank'] is Map) {
    final cr = ex['crank'] as Map;
    final i1 = _ik(hip, crankPt(cr, theta), _lTh, _lSh, kb);
    final i2 = _ik(hip, crankPt(cr, theta + 180), _lTh, _lSh, kb);
    kn = i1.mid;
    an = i1.end;
    sa = i1.a2;
    kn2 = i2.mid;
    an2 = i2.end;
    sa2 = i2.a2;
  } else {
    if (p.containsKey('footAt')) {
      final i1 = _ik(hip, res(p['footAt'], j), _lTh, _lSh, kb);
      kn = i1.mid;
      an = i1.end;
      sa = i1.a2;
    } else {
      kn = _polar(hip, _lTh, toD(p['th']));
      sa = toD(p['sh']);
      an = _polar(kn, _lSh, sa);
    }
    if (p.containsKey('footAt2')) {
      final i2 = _ik(hip, res(p['footAt2'], j), _lTh, _lSh, kb);
      kn2 = i2.mid;
      an2 = i2.end;
      sa2 = i2.a2;
    } else if (p.containsKey('th2')) {
      kn2 = _polar(hip, _lTh, toD(p['th2']));
      sa2 = toD(p['sh2']);
      an2 = _polar(kn2, _lSh, sa2);
    } else {
      kn2 = kn;
      an2 = an;
      sa2 = sa;
    }
  }
  j['knee'] = kn;
  j['foot'] = an;
  j['knee2'] = kn2;
  j['foot2'] = an2;
  final ft = p['ft'] is num ? toD(p['ft']) : sa + 90;
  final ft2 = p['ft2'] is num ? toD(p['ft2']) : sa2 + 90;
  j['toe'] = _polar(an, _lFoot, ft);
  j['toe2'] = _polar(an2, _lFoot, ft2);
  return j;
}

