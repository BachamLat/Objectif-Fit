// Bibliothèque d'exercices Basic-Fit, programme en split et charges suggérées.
import 'calc.dart';
import 'models.dart';

class ExoDef {
  final String id, nom, categorie, muscles, zone, cue;
  final double inc;
  final String unit; // 'reps', 's' ou 'min'
  final bool parCote;
  final bool inverse; // true : la charge est une assistance (moins = plus dur)
  const ExoDef({
    required this.id,
    required this.nom,
    required this.categorie,
    required this.muscles,
    required this.zone,
    required this.cue,
    this.inc = 2.5,
    this.unit = 'reps',
    this.parCote = false,
    this.inverse = false,
  });
  String get anim => id;
  bool get avecCharge => inc > 0;
}

const categories = ['Pecs', 'Épaules', 'Biceps', 'Triceps', 'Dos', 'Jambes', 'Abdos', 'Cardio'];

const bibliotheque = <String, ExoDef>{
  'chest_press': ExoDef(id: 'chest_press', nom: 'Chest press (presse pectorale)', categorie: 'Pecs', muscles: 'Pectoraux, triceps, avant des épaules', zone: 'Machines guidées',
      cue: 'Règle le siège pour que les poignées soient au milieu de la poitrine. Omoplates serrées contre le dossier, pousse sans verrouiller les coudes, reviens lentement.'),
  'incline_smith': ExoDef(id: 'incline_smith', nom: 'Développé incliné à la Smith machine', categorie: 'Pecs', muscles: 'Haut des pectoraux, épaules, triceps', zone: 'Smith machine',
      cue: 'Banc incliné à 30°, place-le pour que la barre descende sur le haut de la poitrine. Coudes à 45° du buste. Tourne la barre pour la décrocher et la raccrocher.'),
  'pec_deck': ExoDef(id: 'pec_deck', nom: 'Pec deck (butterfly)', categorie: 'Pecs', muscles: 'Pectoraux', zone: 'Machines guidées',
      cue: 'Avant-bras ou mains sur les poignées, coudes légèrement fléchis et fixes. Ramène les bras devant toi, serre 1 s, ouvre lentement.'),
  'shoulder_press': ExoDef(id: 'shoulder_press', nom: 'Shoulder press machine', categorie: 'Épaules', muscles: 'Épaules, triceps', zone: 'Machines guidées',
      cue: 'Dos collé au dossier, abdos serrés, ne cambre pas. Pousse au-dessus de la tête sans verrouiller.'),
  'face_pull': ExoDef(id: 'face_pull', nom: 'Face pull à la poulie', categorie: 'Épaules', muscles: 'Arrière des épaules, haut du dos, posture', zone: 'Poulies',
      cue: 'Corde réglée à hauteur des yeux. Tire vers le visage en écartant les mains, coudes hauts. Charge légère, mouvement propre.'),
  'curl_machine': ExoDef(id: 'curl_machine', nom: 'Curl biceps à la machine (pupitre)', categorie: 'Biceps', muscles: 'Biceps', zone: 'Machines guidées',
      cue: 'Aisselles calées en haut du pupitre, coudes alignés avec l\'axe de la machine. Monte sans décoller les bras, redescends en 2 à 3 s.'),
  'curl_poulie': ExoDef(id: 'curl_poulie', nom: 'Curl biceps à la poulie basse', categorie: 'Biceps', muscles: 'Biceps, avant-bras', zone: 'Poulies',
      cue: 'Barre ou corde sur la poulie basse. Coudes fixes le long du corps, pas de balancement du buste.'),
  'triceps_poulie': ExoDef(id: 'triceps_poulie', nom: 'Extension triceps à la poulie haute', categorie: 'Triceps', muscles: 'Triceps', zone: 'Poulies',
      cue: 'Corde ou barre sur la poulie haute, buste légèrement penché. Coudes collés au corps, seuls les avant-bras bougent.'),
  'triceps_machine': ExoDef(id: 'triceps_machine', nom: 'Dips assis à la machine (triceps)', categorie: 'Triceps', muscles: 'Triceps, bas des pectoraux', zone: 'Machines guidées',
      cue: 'Assis, poignées de chaque côté. Pousse vers le bas jusqu\'aux bras tendus, épaules basses, remonte lentement.'),
  'lat_pulldown': ExoDef(id: 'lat_pulldown', nom: 'Tirage vertical (lat pulldown)', categorie: 'Dos', muscles: 'Grand dorsal, biceps', zone: 'Machines guidées',
      cue: 'Cuisses bloquées sous le boudin, buste légèrement incliné. Tire la barre vers le haut de la poitrine en descendant les coudes. Pas d\'élan.'),
  'seated_row': ExoDef(id: 'seated_row', nom: 'Rowing assis machine', categorie: 'Dos', muscles: 'Milieu du dos, arrière des épaules, biceps', zone: 'Machines guidées',
      cue: 'Poitrine contre l\'appui. Tire les coudes vers l\'arrière en serrant les omoplates, reviens bras tendus sans arrondir le dos.'),
  'cable_row': ExoDef(id: 'cable_row', nom: 'Tirage horizontal poulie basse', categorie: 'Dos', muscles: 'Dos, biceps', zone: 'Poulies',
      cue: 'Pieds sur les cales, genoux légèrement fléchis, dos droit. Ramène la poignée vers le nombril, épaules basses.'),
  'tractions_assist': ExoDef(id: 'tractions_assist', nom: 'Tractions assistées (machine)', categorie: 'Dos', muscles: 'Grand dorsal, biceps', zone: 'Machines guidées', inverse: true,
      cue: 'Genoux sur le plateau. La charge choisie t\'aide : moins de kg = plus difficile. Monte jusqu\'au menton au-dessus des poignées, redescends lentement.'),
  'lombaires': ExoDef(id: 'lombaires', nom: 'Extension lombaire (banc à 45°)', categorie: 'Dos', muscles: 'Lombaires, fessiers', zone: 'Zone fonctionnelle', inc: 0,
      cue: 'Bord du coussin juste sous les hanches. Descends dos plat, remonte jusqu\'à l\'alignement du corps, pas plus haut.'),
  'presse': ExoDef(id: 'presse', nom: 'Presse à cuisses', categorie: 'Jambes', muscles: 'Quadriceps, fessiers', zone: 'Machines guidées', inc: 5,
      cue: 'Pieds à largeur d\'épaules au milieu du plateau. Descends jusqu\'à 90° aux genoux sans décoller le bas du dos, pousse dans les talons.'),
  'squat_smith': ExoDef(id: 'squat_smith', nom: 'Squat à la Smith machine', categorie: 'Jambes', muscles: 'Quadriceps, fessiers, gainage', zone: 'Smith machine', inc: 5,
      cue: 'Barre sur le haut du dos, pieds un peu en avant de la barre. Dos droit, descends cuisses parallèles au sol, remonte en poussant le sol.'),
  'leg_ext': ExoDef(id: 'leg_ext', nom: 'Leg extension', categorie: 'Jambes', muscles: 'Quadriceps', zone: 'Machines guidées',
      cue: 'Genou aligné avec l\'axe de la machine, boudin sur le bas des tibias. Monte sans à-coup, redescends en 2 à 3 s.'),
  'leg_curl': ExoDef(id: 'leg_curl', nom: 'Leg curl assis', categorie: 'Jambes', muscles: 'Ischio-jambiers', zone: 'Machines guidées',
      cue: 'Boudin du haut bien serré sur les cuisses, boudin du bas derrière les chevilles. Ramène les talons vers toi, contrôle le retour.'),
  'rdl_smith': ExoDef(id: 'rdl_smith', nom: 'Soulevé de terre jambes tendues à la Smith', categorie: 'Jambes', muscles: 'Ischios, fessiers, lombaires', zone: 'Smith machine', inc: 5,
      cue: 'Genoux légèrement fléchis, pousse les fesses vers l\'arrière, la barre glisse le long des cuisses. Dos toujours plat, arrête-toi sous les genoux.'),
  'hip_thrust': ExoDef(id: 'hip_thrust', nom: 'Hip thrust (Smith ou machine fessiers)', categorie: 'Jambes', muscles: 'Fessiers, ischios', zone: 'Smith machine', inc: 5,
      cue: 'Haut du dos sur le banc, barre sur les hanches avec un coussin. Monte le bassin en poussant dans les talons, serre les fessiers 1 s en haut.'),
  'mollets': ExoDef(id: 'mollets', nom: 'Mollets debout (machine ou Smith)', categorie: 'Jambes', muscles: 'Mollets', zone: 'Machines guidées', inc: 5,
      cue: 'Avant des pieds sur la marche, talons dans le vide. Monte le plus haut possible, descends lentement sous la marche.'),
  'crunch': ExoDef(id: 'crunch', nom: 'Machine abdominale (crunch)', categorie: 'Abdos', muscles: 'Grand droit de l\'abdomen', zone: 'Machines guidées',
      cue: 'Enroule le buste en soufflant, comme pour rapprocher les côtes du bassin. Ne tire pas avec les bras.'),
  'planche': ExoDef(id: 'planche', nom: 'Gainage planche', categorie: 'Abdos', muscles: 'Sangle abdominale', zone: 'Zone stretching', inc: 0, unit: 's',
      cue: 'Avant-bras sous les épaules, corps aligné de la tête aux talons. Serre fessiers et abdos, respire normalement.'),
  'releves': ExoDef(id: 'releves', nom: 'Relevés de genoux (chaise romaine)', categorie: 'Abdos', muscles: 'Bas des abdos', zone: 'Zone fonctionnelle', inc: 0,
      cue: 'Dos collé au dossier, avant-bras sur les appuis. Monte les genoux vers la poitrine sans balancer, redescends lentement.'),
  'tapis': ExoDef(id: 'tapis', nom: 'Tapis de course (marche inclinée)', categorie: 'Cardio', muscles: 'Cardio, fessiers, mollets', zone: 'Zone cardio', inc: 0, unit: 'min',
      cue: 'Pente 8 à 12 %, vitesse 4,5 à 5,5 km/h. Ne te tiens pas aux barres : la dépense chute. Grandis-toi, petits pas.'),
  'velo': ExoDef(id: 'velo', nom: 'Vélo', categorie: 'Cardio', muscles: 'Cardio, quadriceps', zone: 'Zone cardio', inc: 0, unit: 'min',
      cue: 'Selle à hauteur de hanche : jambe presque tendue en bas du pédalage. Bon pour les intervalles sans choc pour les genoux.'),
  'elliptique': ExoDef(id: 'elliptique', nom: 'Elliptique', categorie: 'Cardio', muscles: 'Cardio, tout le corps', zone: 'Zone cardio', inc: 0, unit: 'min',
      cue: 'Pousse et tire les poignées, talons au contact des pédales. Augmente la résistance plutôt que la vitesse.'),
  'rameur': ExoDef(id: 'rameur', nom: 'Rameur', categorie: 'Cardio', muscles: 'Cardio, dos, jambes', zone: 'Zone cardio', inc: 0, unit: 'min',
      cue: 'Ordre : jambes, buste, bras. Puis au retour : bras, buste, jambes. 60 % de la force vient des jambes.'),
  'escalier': ExoDef(id: 'escalier', nom: 'Escalier (stair climber)', categorie: 'Cardio', muscles: 'Cardio, fessiers, cuisses', zone: 'Zone cardio', inc: 0, unit: 'min',
      cue: 'Très efficace mais intense : commence à vitesse basse, 10 min. Ne t\'appuie pas sur les barres.'),
};

// ---------------- Phases ----------------
class Presc {
  final int sets, lo, hi, rest;
  const Presc(this.sets, this.lo, this.hi, this.rest);
}

class Phase {
  final String key, nom, but, tapisApres, tapisSeul;
  final Presc main, acc, core, planche;
  final int minApres, minSeul;
  const Phase({
    required this.key,
    required this.nom,
    required this.but,
    required this.main,
    required this.acc,
    required this.core,
    required this.planche,
    required this.tapisApres,
    required this.minApres,
    required this.tapisSeul,
    required this.minSeul,
  });
}

const phases = <String, Phase>{
  'fond': Phase(
    key: 'fond',
    nom: 'Fondations',
    but: 'Apprendre les machines et habituer articulations et tendons. Garde 2 à 3 répétitions en réserve.',
    main: Presc(3, 12, 15, 75),
    acc: Presc(2, 12, 15, 60),
    core: Presc(3, 12, 15, 45),
    planche: Presc(3, 20, 30, 45),
    tapisApres: '20 min de marche inclinée : pente 8 à 12 %, 4,5 à 5,5 km/h. Tu dois pouvoir parler par phrases courtes.',
    minApres: 20,
    tapisSeul: '35 min de marche inclinée régulière (pente 10 %, 5 km/h), puis 5 min à plat pour récupérer.',
    minSeul: 40,
  ),
  'vol': Phase(
    key: 'vol',
    nom: 'Volume',
    but: 'Plus de séries pour construire du muscle et dépenser davantage. La dernière répétition est difficile mais propre.',
    main: Presc(4, 10, 12, 90),
    acc: Presc(3, 12, 15, 60),
    core: Presc(3, 12, 15, 45),
    planche: Presc(3, 30, 45, 45),
    tapisApres: '20 min : 4 min d\'échauffement, puis 6 × (1 min pente 12 % à 5,5 km/h + 1 min pente 4 %), puis 4 min au calme.',
    minApres: 20,
    tapisSeul: '40 min de marche inclinée (pente 10 à 12 %, 5 à 5,5 km/h), avec 1 min plus rapide (6 km/h) toutes les 5 min.',
    minSeul: 40,
  ),
  'force': Phase(
    key: 'force',
    nom: 'Force',
    but: 'Charges plus lourdes sur les exercices principaux. Repos complet entre les séries, technique impeccable.',
    main: Presc(4, 6, 8, 120),
    acc: Presc(3, 10, 12, 75),
    core: Presc(3, 10, 15, 45),
    planche: Presc(3, 40, 60, 45),
    tapisApres: '15 à 20 min de marche inclinée régulière (pente 10 %) : la séance de musculation est plus lourde.',
    minApres: 18,
    tapisSeul: '45 min de marche inclinée (pente 10 à 15 %) à rythme régulier.',
    minSeul: 45,
  ),
};

class PhaseInfo {
  final String key, nom, variante;
  final int bloc, semBloc;
  final bool allegee;
  const PhaseInfo(this.key, this.nom, this.bloc, this.semBloc, this.allegee, this.variante);
}

PhaseInfo phasePour(int semaine) {
  final bloc = ((semaine - 1) ~/ 4) + 1;
  final semBloc = ((semaine - 1) % 4) + 1;
  String key, variante;
  if (bloc == 1) {
    key = 'fond';
    variante = 'A';
  } else {
    key = bloc % 2 == 0 ? 'vol' : 'force';
    variante = ((bloc - 2) ~/ 2) % 2 == 0 ? 'A' : 'B';
  }
  return PhaseInfo(key, phases[key]!.nom, bloc, semBloc, semBloc == 4, variante);
}

// ---------------- Types de séance (split) ----------------
class TypeSeance {
  final String cle, titre, court, description;
  const TypeSeance(this.cle, this.titre, this.court, this.description);
}

const typesSeance = [
  TypeSeance('bras', 'Bras + pecs + gainage', 'Bras', 'Biceps, triceps, un peu de pectoraux et la planche'),
  TypeSeance('dos', 'Dos', 'Dos', 'Dorsaux, arrière des épaules, lombaires'),
  TypeSeance('jambes', 'Jambes', 'Jambes', 'Quadriceps, ischios, fessiers, mollets'),
  TypeSeance('tapis', 'Tapis (cardio seul)', 'Tapis', 'Marche inclinée longue et gainage'),
];

TypeSeance typeSeance(String cle) =>
    typesSeance.firstWhere((t) => t.cle == cle, orElse: () => const TypeSeance('libre', 'Ma séance', 'Libre', 'Les exercices que tu choisis'));

class Slot {
  final String id, role;
  const Slot(this.id, this.role);
}

const templates = <String, Map<String, List<Slot>>>{
  'A': {
    'bras': [Slot('chest_press', 'main'), Slot('pec_deck', 'acc'), Slot('curl_machine', 'acc'), Slot('triceps_poulie', 'acc'), Slot('curl_poulie', 'acc'), Slot('planche', 'core')],
    'dos': [Slot('lat_pulldown', 'main'), Slot('seated_row', 'main'), Slot('cable_row', 'acc'), Slot('face_pull', 'acc'), Slot('lombaires', 'core')],
    'jambes': [Slot('presse', 'main'), Slot('squat_smith', 'main'), Slot('leg_curl', 'acc'), Slot('leg_ext', 'acc'), Slot('mollets', 'acc')],
    'tapis': [Slot('planche', 'core'), Slot('crunch', 'core')],
  },
  'B': {
    'bras': [Slot('incline_smith', 'main'), Slot('curl_poulie', 'acc'), Slot('triceps_machine', 'acc'), Slot('curl_machine', 'acc'), Slot('planche', 'core'), Slot('crunch', 'core')],
    'dos': [Slot('tractions_assist', 'main'), Slot('cable_row', 'main'), Slot('seated_row', 'acc'), Slot('face_pull', 'acc'), Slot('lombaires', 'core'), Slot('releves', 'core')],
    'jambes': [Slot('squat_smith', 'main'), Slot('rdl_smith', 'main'), Slot('presse', 'acc'), Slot('leg_curl', 'acc'), Slot('hip_thrust', 'acc'), Slot('mollets', 'acc')],
    'tapis': [Slot('planche', 'core'), Slot('releves', 'core')],
  },
};

class ExoPlan {
  final ExoDef def;
  final String role;
  final int sets, lo, hi, rest;
  const ExoPlan(this.def, this.role, this.sets, this.lo, this.hi, this.rest);
  String get plage => '$lo–$hi${def.unit == 's' ? ' s' : ''}${def.parCote ? ' / côté' : ''}';
}

class SeancePlan {
  final String cle, titre;
  final List<ExoPlan> exos;
  final int cardioMin;
  final String cardioTexte;
  const SeancePlan(this.cle, this.titre, this.exos, this.cardioMin, this.cardioTexte);
}

class SemainePlan {
  final int semaine, pas;
  final PhaseInfo phase;
  final String but;
  final List<SeancePlan> seances;
  const SemainePlan(this.semaine, this.phase, this.but, this.seances, this.pas);
}

Presc prescription(Phase p, String role, String id, bool allegee) {
  final Presc base = id == 'planche' ? p.planche : (role == 'main' ? p.main : (role == 'core' ? p.core : p.acc));
  final sets = allegee ? (base.sets - 1 < 2 ? 2 : base.sets - 1) : base.sets;
  return Presc(sets, base.lo, base.hi, base.rest);
}

ExoPlan planPour(String id, String role, PhaseInfo ph) {
  final pr = prescription(phases[ph.key]!, role, id, ph.allegee);
  return ExoPlan(bibliotheque[id]!, role, pr.sets, pr.lo, pr.hi, pr.rest);
}

int pasCible(int semaine) {
  final v = 7000 + 500 * (semaine - 1);
  return v > 10000 ? 10000 : v;
}

SemainePlan programmeSemaine(int semaine, bool tapisSeul) {
  final ph = phasePour(semaine);
  final p = phases[ph.key]!;
  final cles = ['bras', 'dos', 'jambes', if (tapisSeul) 'tapis'];
  final seances = cles.map((cle) {
    final slots = templates[ph.variante]![cle]!;
    final exos = slots.map((s) => planPour(s.id, s.role, ph)).toList();
    final String texte;
    final int min;
    if (cle == 'tapis') {
      texte = ph.allegee ? 'Semaine allégée : 30 min de marche tranquille (pente 5 %).' : p.tapisSeul;
      min = ph.allegee ? 30 : p.minSeul;
    } else {
      texte = ph.allegee ? 'Semaine allégée : 20 min de marche tranquille (pente 5 %).' : p.tapisApres;
      min = ph.allegee ? 20 : p.minApres;
    }
    return SeancePlan(cle, typeSeance(cle).titre, exos, min, texte);
  }).toList();
  return SemainePlan(semaine, ph, p.but, seances, pasCible(semaine));
}

// ---------------- Charges suggérées (double progression) ----------------
class Suggestion {
  final double? kg;
  final String texte;
  const Suggestion(this.kg, this.texte);
}

class LogDate {
  final String date;
  final ExoLog log;
  const LogDate(this.date, this.log);
}

List<LogDate> historiqueExo(String id, Map<String, Jour> jours, {int max = 12}) {
  final dates = jours.keys.toList()..sort((a, b) => b.compareTo(a));
  final out = <LogDate>[];
  for (final d in dates) {
    for (final s in jours[d]!.seances.reversed) {
      for (final e in s.exos) {
        if (e.id == id && e.sets.any((x) => x.reps > 0)) {
          out.add(LogDate(d, e));
          if (out.length >= max) return out;
        }
      }
    }
  }
  return out;
}

Suggestion suggestion(ExoDef def, int lo, int hi, Map<String, Jour> jours, bool allegee) {
  final h = historiqueExo(def.id, jours, max: 1);
  if (h.isEmpty) {
    if (def.unit == 's') return Suggestion(null, 'Tiens $lo s par série pour commencer.');
    if (!def.avecCharge) return const Suggestion(null, 'Au poids du corps.');
    if (def.inverse) return Suggestion(null, 'Première fois : prends assez d\'assistance pour faire $hi répétitions propres.');
    return const Suggestion(null, 'Première fois : choisis une charge qui laisse 2 à 3 répétitions en réserve.');
  }
  final last = h.first.log;
  final sets = last.sets.where((s) => s.reps > 0).toList();
  final kg = sets.map((s) => s.kg).reduce((a, b) => a > b ? a : b);
  final minReps = sets.map((s) => s.reps).reduce((a, b) => a < b ? a : b);
  final u = def.unit == 's' ? 's' : 'reps';
  if (!def.avecCharge || kg == 0) {
    return Suggestion(null, minReps >= hi ? 'Objectif atteint la dernière fois : ralentis le mouvement ou ajoute 5 $u.' : 'Dernière fois : $minReps $u minimum. Vise $hi.');
  }
  final memePlage = last.lo == lo && last.hi == hi;
  Suggestion out;
  if (def.inverse) {
    if (minReps >= hi) {
      final k = kg - def.inc < 0 ? 0.0 : kg - def.inc;
      out = Suggestion(k, 'Haut de la plage atteint : ${fmtKg(def.inc)} kg d\'assistance en moins.');
    } else {
      out = Suggestion(kg, 'Même assistance, vise $hi répétitions.');
    }
  } else if (memePlage) {
    if (minReps >= hi) {
      out = Suggestion(kg + def.inc, 'Haut de la plage atteint sur toutes les séries : +${fmtKg(def.inc)} kg.');
    } else if (minReps < lo) {
      out = Suggestion(kg, 'Plage pas encore atteinte : même charge, vise $lo répétitions partout.');
    } else {
      out = Suggestion(kg, 'Même charge, ajoute 1 répétition par série.');
    }
  } else {
    var best = 0.0;
    for (final s in sets) {
      final e = s.kg * (1 + s.reps / 30);
      if (e > best) best = e;
    }
    final k = floorTo(best / (1 + hi / 30), def.inc);
    out = Suggestion(k < def.inc ? def.inc : k, 'Nouvelle plage de répétitions : charge recalculée depuis ta dernière séance.');
  }
  if (allegee && out.kg != null) {
    final base = out.kg!;
    final k = def.inverse ? base + def.inc : floorTo(base * 0.9, def.inc);
    out = Suggestion(k < def.inc && !def.inverse ? def.inc : k, def.inverse ? 'Semaine allégée : un peu plus d\'assistance.' : 'Semaine allégée : −10 % sur la charge.');
  }
  return out;
}
