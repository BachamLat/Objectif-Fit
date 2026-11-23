import 'package:flutter_test/flutter_test.dart';

import 'package:objectif_fit/calc.dart';
import 'package:objectif_fit/programme.dart';

void main() {
  test('IMC et poids cible', () {
    expect(imc(96, 179).toStringAsFixed(2), '29.96');
    expect(poidsCible(179, 24.9), 79.7);
  });

  test('Programme : split et semaine allégée', () {
    final s4 = programmeSemaine(4, true);
    expect(s4.phase.allegee, isTrue);
    expect(s4.seances.map((s) => s.cle).toList(), ['bras', 'dos', 'jambes', 'tapis']);
  });

  test('Dépense sur tapis (ACSM)', () {
    final k = kcalTapis(vitesseKmh: 5, pentePct: 10, minutes: 30, kg: 96);
    expect(k.round(), 386);
  });
}
