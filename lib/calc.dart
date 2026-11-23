// Calculs purs : dates, formats français, IMC, énergie, dépense des activités.
import 'dart:math' as math;

// ---------------- Dates ----------------
String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseYmd(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]), 12);
}

String aujourdhui() => ymd(DateTime.now());

String addDays(String s, int n) {
  final d = parseYmd(s);
  return ymd(DateTime(d.year, d.month, d.day + n, 12));
}

int diffDays(String a, String b) {
  final da = parseYmd(a), db = parseYmd(b);
  return (db.difference(da).inHours / 24).round();
}

const _mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
const _moisCourt = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
const _joursSem = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _joursCourts = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

String dateLongue(String s) {
  final d = parseYmd(s);
  return '${_joursSem[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';
}

String dateCourte(String s) {
  final d = parseYmd(s);
  return '${d.day} ${_moisCourt[d.month - 1]}';
}

String jourCourt(String s) {
  final d = parseYmd(s);
  return '${_joursCourts[d.weekday - 1]} ${d.day} ${_moisCourt[d.month - 1]}';
}

String moisAnnee(String s) {
  final d = parseYmd(s);
  return '${_mois[d.month - 1]} ${d.year}';
}

String heureMinute(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// ---------------- Nombres ----------------
String fmt(num? x, [int dec = 0]) {
  if (x == null || x.isNaN || x.isInfinite) return '–';
  final neg = x < 0;
  final s = x.abs().toStringAsFixed(dec);
  final parts = s.split('.');
  final ent = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < ent.length; i++) {
    if (i > 0 && (ent.length - i) % 3 == 0) buf.write(' ');
    buf.write(ent[i]);
  }
  var r = buf.toString();
  if (dec > 0) r = '$r,${parts[1]}';
  return neg ? '−$r' : r;
}

/// Affiche 1 décimale seulement si nécessaire (ex. 2,5 kg mais 80 kg).
String fmtKg(num x) => (x - x.round()).abs() < 0.001 ? fmt(x, 0) : fmt(x, 1);

double? parseNum(String s) => double.tryParse(s.replaceAll(',', '.').replaceAll(' ', '').trim());

double roundTo(double x, double step) => (x / step).round() * step;
double floorTo(double x, double step) => (x / step + 1e-9).floorToDouble() * step;

// ---------------- IMC ----------------
double imc(double kg, double cm) {
  final m = cm / 100;
  return kg / (m * m);
}

class ImcZone {
  final String key, label;
  final double min, max;
  const ImcZone(this.key, this.label, this.min, this.max);
}

const imcZones = [
  ImcZone('maigreur', 'Insuffisance pondérale', 0, 18.5),
  ImcZone('normal', 'Corpulence normale', 18.5, 25),
  ImcZone('surpoids', 'Surpoids', 25, 30),
  ImcZone('ob1', 'Obésité modérée', 30, 35),
  ImcZone('ob2', 'Obésité sévère', 35, 99),
];

ImcZone imcZone(double v) => imcZones.firstWhere((z) => v >= z.min && v < z.max, orElse: () => imcZones.last);

double poidsCible(double cm, double imcCible) {
  final m = cm / 100;
  return (imcCible * m * m * 10).floorToDouble() / 10;
}

// ---------------- Énergie ----------------
class Activite {
  final double f;
  final String label;
  const Activite(this.f, this.label);
}

const activites = [
  Activite(1.2, 'Sédentaire (peu de marche, pas de sport)'),
  Activite(1.375, 'Légère (1 à 3 séances par semaine)'),
  Activite(1.55, 'Modérée (3 à 5 séances + beaucoup de marche)'),
  Activite(1.725, 'Élevée (sport presque tous les jours)'),
];

class Cibles {
  final int bmr, tdee, kcal, prot, lip, gluc;
  final double perteSem;
  const Cibles(this.bmr, this.tdee, this.kcal, this.prot, this.lip, this.gluc, this.perteSem);
}

Cibles calculerCibles({required String sexe, required int age, required double taille, required double kg, required double activite, required int deficit, required double poidsVise}) {
  final bmr = 10 * kg + 6.25 * taille - 5 * age + (sexe == 'F' ? -161 : 5);
  final tdee = bmr * activite;
  final plancher = math.max(bmr, sexe == 'F' ? 1200.0 : 1500.0);
  final kcal = roundTo(math.max(tdee - deficit, plancher), 50);
  final ref = poidsVise;
  final prot = roundTo(1.8 * ref, 5);
  final lip = roundTo(0.8 * ref, 5);
  final gluc = math.max(0.0, roundTo((kcal - prot * 4 - lip * 9) / 4, 5));
  final perte = (tdee - kcal) * 7 / 7700;
  return Cibles(bmr.round(), tdee.round(), kcal.round(), prot.round(), lip.round(), gluc.round(), perte);
}

class PointPoids {
  final String date;
  final double kg;
  final bool depart;
  const PointPoids(this.date, this.kg, {this.depart = false});
}

/// Pente de la régression linéaire sur les 28 derniers jours, en kg par semaine.
double? tendance(List<PointPoids> pts, String fin) {
  final p = pts.where((x) {
    final d = diffDays(x.date, fin);
    return d >= 0 && d <= 28;
  }).toList();
  if (p.length < 3) return null;
  final xs = p.map((x) => diffDays(p.first.date, x.date).toDouble()).toList();
  if (xs.last - xs.first < 7) return null;
  final n = p.length;
  final mx = xs.reduce((a, b) => a + b) / n;
  final my = p.map((x) => x.kg).reduce((a, b) => a + b) / n;
  var sxy = 0.0, sxx = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (xs[i] - mx) * (p[i].kg - my);
    sxx += (xs[i] - mx) * (xs[i] - mx);
  }
  return sxx == 0 ? null : sxy / sxx * 7;
}

class Estimation {
  final int semaines;
  final String date;
  const Estimation(this.semaines, this.date);
}

Estimation? estimationArrivee(double actuel, double cible, double perteSem, String depuis) {
  final reste = actuel - cible;
  if (reste <= 0) return Estimation(0, depuis);
  if (perteSem <= 0.05) return null;
  final s = (reste / perteSem).ceil();
  return Estimation(s, addDays(depuis, s * 7));
}

// ---------------- Dépense des activités ----------------
double kcalMet(double met, double kg, num minutes) => met * kg * minutes / 60;

/// Tapis : équations ACSM (marche < 7,5 km/h, course au-delà). Dépense brute.
double kcalTapis({required double vitesseKmh, required double pentePct, required num minutes, required double kg}) {
  final s = vitesseKmh * 1000 / 60;
  final g = pentePct / 100;
  final vo2 = vitesseKmh < 7.5 ? 0.1 * s + 1.8 * s * g + 3.5 : 0.2 * s + 0.9 * s * g + 3.5;
  return vo2 * kg / 1000 * 5 * minutes;
}

const intensites = ['Léger', 'Modéré', 'Intense'];

class MachineCardio {
  final String id, nom;
  final List<double> met; // léger, modéré, intense
  const MachineCardio(this.id, this.nom, this.met);
}

const machinesCardio = [
  MachineCardio('tapis', 'Tapis de course', [3.5, 4.5, 6.0]),
  MachineCardio('velo', 'Vélo', [4.0, 6.8, 8.8]),
  MachineCardio('elliptique', 'Elliptique', [4.0, 5.0, 7.0]),
  MachineCardio('rameur', 'Rameur', [4.8, 7.0, 8.5]),
  MachineCardio('escalier', 'Escalier (stair climber)', [6.0, 9.0, 10.0]),
];

MachineCardio machineCardio(String id) => machinesCardio.firstWhere((m) => m.id == id, orElse: () => machinesCardio.first);

/// MET de la musculation selon le type de séance (Compendium des activités physiques).
double metMuscu(String type) {
  switch (type) {
    case 'jambes':
      return 5.0;
    case 'dos':
      return 3.8;
    default:
      return 3.5;
  }
}

class AutreActivite {
  final String nom;
  final List<double> met;
  const AutreActivite(this.nom, this.met);
}

const autresActivites = [
  AutreActivite('Marche', [3.0, 3.5, 4.3]),
  AutreActivite('Course à pied', [7.0, 9.0, 11.0]),
  AutreActivite('Football', [5.0, 7.0, 10.0]),
  AutreActivite('Basket', [4.5, 6.5, 8.0]),
  AutreActivite('Natation', [4.5, 5.8, 9.8]),
  AutreActivite('Vélo en extérieur', [4.0, 6.8, 10.0]),
  AutreActivite('Cours collectif (GXR, vélo virtuel)', [4.0, 6.0, 8.0]),
  AutreActivite('Boxe / sac de frappe', [5.5, 7.8, 9.0]),
  AutreActivite('Corde à sauter', [8.8, 11.0, 12.3]),
  AutreActivite('Badminton', [4.5, 5.5, 7.0]),
  AutreActivite('Danse', [3.5, 5.0, 7.3]),
  AutreActivite('Musculation (poids libres)', [3.5, 5.0, 6.0]),
  AutreActivite('Étirements / mobilité', [2.3, 2.5, 3.0]),
];

int pasKcal(int pas, double kg) => (pas * kg * 0.0005).round();
