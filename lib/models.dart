// Modèles de données et conversion JSON.
import 'calc.dart';

double dbl(dynamic v, [double def = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return parseNum(v) ?? def;
  return def;
}

double? dblOrNull(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return parseNum(v);
  return null;
}

int integer(dynamic v, [int def = 0]) {
  if (v is num) return v.round();
  if (v is String) return parseNum(v)?.round() ?? def;
  return def;
}

String str(dynamic v, [String def = '']) => v == null ? def : v.toString();

List<Map<String, dynamic>> maps(dynamic v) =>
    v is List ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList() : <Map<String, dynamic>>[];

String nouvelId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

class Profil {
  String sexe;
  int age;
  double taille;
  double poidsDepart;
  String debut;
  double activite;
  int deficit;
  double imcCible;
  double? poidsObjectif;
  bool tapisSeul;
  bool confirme;

  Profil({
    required this.sexe,
    required this.age,
    required this.taille,
    required this.poidsDepart,
    required this.debut,
    required this.activite,
    required this.deficit,
    required this.imcCible,
    this.poidsObjectif,
    required this.tapisSeul,
    required this.confirme,
  });

  factory Profil.defaut() => Profil(
        sexe: 'H',
        age: 21,
        taille: 179,
        poidsDepart: 96,
        debut: aujourdhui(),
        activite: 1.375,
        deficit: 500,
        imcCible: 24.9,
        tapisSeul: true,
        confirme: false,
      );

  factory Profil.fromJson(Map<String, dynamic> j) {
    final d = Profil.defaut();
    return Profil(
      sexe: str(j['sexe'], d.sexe),
      age: integer(j['age'], d.age),
      taille: dbl(j['taille'], d.taille),
      poidsDepart: dbl(j['poidsDepart'], d.poidsDepart),
      debut: str(j['debut'], d.debut),
      activite: dbl(j['activite'], d.activite),
      deficit: integer(j['deficit'], d.deficit),
      imcCible: dbl(j['imcCible'], d.imcCible),
      poidsObjectif: dblOrNull(j['poidsObjectif']),
      tapisSeul: j['tapisSeul'] is bool ? j['tapisSeul'] as bool : d.tapisSeul,
      confirme: j['confirme'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'sexe': sexe,
        'age': age,
        'taille': taille,
        'poidsDepart': poidsDepart,
        'debut': debut,
        'activite': activite,
        'deficit': deficit,
        'imcCible': imcCible,
        'poidsObjectif': poidsObjectif,
        'tapisSeul': tapisSeul,
        'confirme': confirme,
      };
}

class Repas {
  String id, heure, nom, source, detail;
  int kcal, p, g, l;
  String? photo;

  Repas({required this.id, required this.heure, required this.nom, required this.kcal, this.p = 0, this.g = 0, this.l = 0, this.source = 'manuel', this.detail = '', this.photo});

  factory Repas.fromJson(Map<String, dynamic> j) => Repas(
        id: str(j['id'], nouvelId()),
        heure: str(j['heure'] ?? j['t']),
        nom: str(j['nom'], 'Repas'),
        kcal: integer(j['kcal']),
        p: integer(j['p']),
        g: integer(j['g']),
        l: integer(j['l']),
        source: str(j['source'], 'manuel'),
        detail: str(j['detail']),
        photo: j['photo'] is String ? j['photo'] as String : null,
      );

  Map<String, dynamic> toJson() => {'id': id, 'heure': heure, 'nom': nom, 'kcal': kcal, 'p': p, 'g': g, 'l': l, 'source': source, 'detail': detail, 'photo': photo};
}

class SetLog {
  double kg;
  int reps;
  SetLog(this.kg, this.reps);
  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog(dbl(j['kg']), integer(j['reps']));
  Map<String, dynamic> toJson() => {'kg': kg, 'reps': reps};
}

class ExoLog {
  String id, unit;
  int lo, hi;
  List<SetLog> sets;
  ExoLog({required this.id, required this.lo, required this.hi, required this.unit, required this.sets});
  factory ExoLog.fromJson(Map<String, dynamic> j) => ExoLog(
        id: str(j['id']),
        lo: integer(j['lo'], 10),
        hi: integer(j['hi'], 12),
        unit: str(j['unit'], 'reps'),
        sets: maps(j['sets']).map(SetLog.fromJson).toList(),
      );
  Map<String, dynamic> toJson() => {'id': id, 'lo': lo, 'hi': hi, 'unit': unit, 'sets': sets.map((s) => s.toJson()).toList()};
}

class CardioLog {
  String machine;
  int minutes, intensite, kcal;
  double vitesse, pente;
  CardioLog({required this.machine, required this.minutes, this.vitesse = 0, this.pente = 0, this.intensite = 1, this.kcal = 0});
  factory CardioLog.fromJson(Map<String, dynamic> j) => CardioLog(
        machine: str(j['machine'], 'tapis'),
        minutes: integer(j['minutes'] ?? j['min']),
        vitesse: dbl(j['vitesse']),
        pente: dbl(j['pente']),
        intensite: integer(j['intensite'], 1),
        kcal: integer(j['kcal']),
      );
  Map<String, dynamic> toJson() => {'machine': machine, 'minutes': minutes, 'vitesse': vitesse, 'pente': pente, 'intensite': intensite, 'kcal': kcal};
}

class Seance {
  String id, type, titre, phase, heure;
  int semaine, duree, kcal, echauffementMin;
  List<ExoLog> exos;
  List<CardioLog> cardio;
  Seance({required this.id, required this.type, required this.titre, required this.semaine, required this.phase, required this.heure, required this.duree, required this.exos, required this.cardio, required this.kcal, this.echauffementMin = 0});
  factory Seance.fromJson(Map<String, dynamic> j) => Seance(
        id: str(j['id'], nouvelId()),
        type: str(j['type'], 'libre'),
        titre: str(j['titre'], 'Séance'),
        semaine: integer(j['semaine'], 1),
        phase: str(j['phase']),
        heure: str(j['heure'] ?? j['t']),
        duree: integer(j['duree']),
        exos: maps(j['exos']).map(ExoLog.fromJson).toList(),
        cardio: maps(j['cardio']).map(CardioLog.fromJson).toList(),
        kcal: integer(j['kcal']),
        echauffementMin: integer(j['echauffementMin']),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'titre': titre,
        'echauffementMin': echauffementMin,
        'semaine': semaine,
        'phase': phase,
        'heure': heure,
        'duree': duree,
        'exos': exos.map((e) => e.toJson()).toList(),
        'cardio': cardio.map((c) => c.toJson()).toList(),
        'kcal': kcal,
      };
  int get minutesCardio => cardio.fold(0, (t, c) => t + c.minutes);
  double get tonnage => exos.fold(0.0, (t, e) => t + e.sets.fold(0.0, (u, s) => u + s.kg * s.reps));
}

class ActiviteLog {
  String id, nom, source, detail;
  int minutes, kcal;
  ActiviteLog({required this.id, required this.nom, required this.minutes, required this.kcal, this.source = 'met', this.detail = ''});
  factory ActiviteLog.fromJson(Map<String, dynamic> j) => ActiviteLog(
        id: str(j['id'], nouvelId()),
        nom: str(j['nom'], 'Activité'),
        minutes: integer(j['minutes']),
        kcal: integer(j['kcal']),
        source: str(j['source'], 'met'),
        detail: str(j['detail']),
      );
  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'minutes': minutes, 'kcal': kcal, 'source': source, 'detail': detail};
}

class Jour {
  final String date;
  double? poids;
  int? pas;
  bool pasAuto;
  List<Repas> repas;
  List<Seance> seances;
  List<ActiviteLog> activites;

  Jour({required this.date, this.poids, this.pas, this.pasAuto = false, List<Repas>? repas, List<Seance>? seances, List<ActiviteLog>? activites})
      : repas = repas ?? [],
        seances = seances ?? [],
        activites = activites ?? [];

  factory Jour.fromJson(String date, Map<String, dynamic> j) => Jour(
        date: date,
        poids: dblOrNull(j['poids']),
        pas: j['pas'] == null ? null : integer(j['pas']),
        pasAuto: j['pasAuto'] == true,
        repas: maps(j['repas']).map(Repas.fromJson).toList(),
        seances: maps(j['seances']).map(Seance.fromJson).toList(),
        activites: maps(j['activites']).map(ActiviteLog.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'poids': poids,
        'pas': pas,
        'pasAuto': pasAuto,
        'repas': repas.map((r) => r.toJson()).toList(),
        'seances': seances.map((s) => s.toJson()).toList(),
        'activites': activites.map((a) => a.toJson()).toList(),
      };

  int get kcalMangees => repas.fold(0, (t, r) => t + r.kcal);
  int get proteines => repas.fold(0, (t, r) => t + r.p);
  int get glucides => repas.fold(0, (t, r) => t + r.g);
  int get lipides => repas.fold(0, (t, r) => t + r.l);
  int get kcalSport => seances.fold(0, (t, s) => t + s.kcal) + activites.fold(0, (t, a) => t + a.kcal);
}

// ---------------- Brouillon de séance ----------------
class SetDraft {
  double? kg;
  int? reps;
  bool fait;
  SetDraft({this.kg, this.reps, this.fait = false});
  factory SetDraft.fromJson(Map<String, dynamic> j) => SetDraft(kg: dblOrNull(j['kg']), reps: j['reps'] == null ? null : integer(j['reps']), fait: j['fait'] == true);
  Map<String, dynamic> toJson() => {'kg': kg, 'reps': reps, 'fait': fait};
}

class ExoDraft {
  String id, role, unit, suggTexte;
  int lo, hi, rest;
  double? suggKg;
  List<SetDraft> sets;
  ExoDraft({required this.id, required this.role, required this.lo, required this.hi, required this.rest, required this.unit, this.suggKg, this.suggTexte = '', required this.sets});
  factory ExoDraft.fromJson(Map<String, dynamic> j) => ExoDraft(
        id: str(j['id']),
        role: str(j['role'], 'acc'),
        lo: integer(j['lo'], 10),
        hi: integer(j['hi'], 12),
        rest: integer(j['rest'], 60),
        unit: str(j['unit'], 'reps'),
        suggKg: dblOrNull(j['suggKg']),
        suggTexte: str(j['suggTexte']),
        sets: maps(j['sets']).map(SetDraft.fromJson).toList(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'lo': lo,
        'hi': hi,
        'rest': rest,
        'unit': unit,
        'suggKg': suggKg,
        'suggTexte': suggTexte,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
}

class CardioDraft {
  String machine;
  int minutes, intensite;
  double vitesse, pente;
  CardioDraft({this.machine = 'tapis', this.minutes = 20, this.vitesse = 5.0, this.pente = 8, this.intensite = 1});
  factory CardioDraft.fromJson(Map<String, dynamic> j) => CardioDraft(
        machine: str(j['machine'], 'tapis'),
        minutes: integer(j['minutes'], 20),
        vitesse: dbl(j['vitesse'], 5),
        pente: dbl(j['pente'], 8),
        intensite: integer(j['intensite'], 1),
      );
  Map<String, dynamic> toJson() => {'machine': machine, 'minutes': minutes, 'vitesse': vitesse, 'pente': pente, 'intensite': intensite};

  int kcal(double kg) {
    if (minutes <= 0) return 0;
    if (machine == 'tapis') return kcalTapis(vitesseKmh: vitesse, pentePct: pente, minutes: minutes, kg: kg).round();
    final m = machineCardio(machine);
    return kcalMet(m.met[intensite.clamp(0, 2).toInt()], kg, minutes).round();
  }
}

class SeanceDraft {
  String id, type, titre, phase, date, cardioTexte;
  int semaine;
  bool allegee;
  int debutMs;
  int? dureeManuelle;
  int echauffementMin;
  String echauffementType;
  List<ExoDraft> exos;
  List<CardioDraft> cardio;
  SeanceDraft({
    required this.id,
    required this.type,
    required this.titre,
    required this.phase,
    required this.date,
    required this.cardioTexte,
    required this.semaine,
    required this.allegee,
    required this.debutMs,
    this.dureeManuelle,
    this.echauffementMin = 0,
    this.echauffementType = 'tapis',
    required this.exos,
    required this.cardio,
  });
  factory SeanceDraft.fromJson(Map<String, dynamic> j) => SeanceDraft(
        id: str(j['id'], nouvelId()),
        type: str(j['type'], 'libre'),
        titre: str(j['titre'], 'Séance'),
        phase: str(j['phase']),
        date: str(j['date'], aujourdhui()),
        cardioTexte: str(j['cardioTexte']),
        semaine: integer(j['semaine'], 1),
        allegee: j['allegee'] == true,
        debutMs: integer(j['debutMs'], DateTime.now().millisecondsSinceEpoch),
        dureeManuelle: j['dureeManuelle'] == null ? null : integer(j['dureeManuelle']),
        echauffementMin: integer(j['echauffementMin']),
        echauffementType: str(j['echauffementType'], 'tapis'),
        exos: maps(j['exos']).map(ExoDraft.fromJson).toList(),
        cardio: maps(j['cardio']).map(CardioDraft.fromJson).toList(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'titre': titre,
        'phase': phase,
        'date': date,
        'cardioTexte': cardioTexte,
        'semaine': semaine,
        'allegee': allegee,
        'debutMs': debutMs,
        'dureeManuelle': dureeManuelle,
        'echauffementMin': echauffementMin,
        'echauffementType': echauffementType,
        'exos': exos.map((e) => e.toJson()).toList(),
        'cardio': cardio.map((c) => c.toJson()).toList(),
      };

  int get dureeAuto {
    final m = ((DateTime.now().millisecondsSinceEpoch - debutMs) / 60000).round();
    return m.clamp(1, 240).toInt();
  }

  int get duree => dureeManuelle ?? dureeAuto;
  int get minutesCardio => cardio.fold(0, (t, c) => t + c.minutes);
  bool get aDesSeries => exos.any((e) => e.sets.any((s) => (s.reps ?? 0) > 0));

  /// Musculation : durée totale moins cardio et échauffement (au moins 10 min s'il y a des séries).
  int kcalEstimees(double kg) {
    final cardioK = cardio.fold(0, (t, c) => t + c.kcal(kg));
    final int muscuMin = aDesSeries ? (duree - minutesCardio - echauffementMin).clamp(10, 240).toInt() : 0;
    final echauffK = kcalMet(3.5, kg, echauffementMin).round();
    return cardioK + echauffK + kcalMet(metMuscu(type), kg, muscuMin).round();
  }
}
