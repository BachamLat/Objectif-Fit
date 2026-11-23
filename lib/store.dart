// État de l'appli : chargement, sauvegarde (fichier JSON local) et actions.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'calc.dart';
import 'models.dart';
import 'programme.dart';
import 'services/steps_service.dart';

class AppState extends ChangeNotifier {
  Profil profil = Profil.defaut();
  final Map<String, Jour> jours = {};
  SeanceDraft? brouillon;
  String cleApi = '';
  String modele = 'claude-sonnet-5-5';
  bool pasAutoActif = false;
  String? pasMessage;
  bool pasEnCours = false;

  final StepsService steps = StepsService();
  File? _fichier;
  Directory? dossierPhotos;
  Timer? _timer;

  // ---------- Chargement / sauvegarde ----------
  Future<void> charger() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _fichier = File('${dir.path}/objectif_fit.json');
      dossierPhotos = Directory('${dir.path}/photos');
      if (!await dossierPhotos!.exists()) await dossierPhotos!.create(recursive: true);
      if (await _fichier!.exists()) {
        final j = jsonDecode(await _fichier!.readAsString());
        if (j is Map) _depuisJson(Map<String, dynamic>.from(j));
      }
    } catch (e) {
      debugPrint('Chargement impossible : $e');
    }
  }

  void _depuisJson(Map<String, dynamic> j) {
    if (j['profil'] is Map) profil = Profil.fromJson(Map<String, dynamic>.from(j['profil'] as Map));
    jours.clear();
    if (j['jours'] is Map) {
      (j['jours'] as Map).forEach((k, v) {
        if (v is Map) jours[k.toString()] = Jour.fromJson(k.toString(), Map<String, dynamic>.from(v));
      });
    }
    brouillon = j['brouillon'] is Map ? SeanceDraft.fromJson(Map<String, dynamic>.from(j['brouillon'] as Map)) : null;
    cleApi = str(j['cleApi']);
    modele = str(j['modele'], 'claude-sonnet-5-5');
    pasAutoActif = j['pasAutoActif'] == true;
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'profil': profil.toJson(),
        'jours': jours.map((k, v) => MapEntry(k, v.toJson())),
        'brouillon': brouillon?.toJson(),
        'cleApi': cleApi,
        'modele': modele,
        'pasAutoActif': pasAutoActif,
      };

  /// Export sans la clé API (pour sauvegarde ou partage).
  String exporter() {
    final j = toJson()..remove('cleApi');
    return const JsonEncoder.withIndent(' ').convert(j);
  }

  void changer({bool sauver = true}) {
    notifyListeners();
    if (sauver) _planifierSauvegarde();
  }

  void _planifierSauvegarde() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), sauverMaintenant);
  }

  Future<void> sauverMaintenant() async {
    final f = _fichier;
    if (f == null) return;
    try {
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(toJson()), flush: true);
      await tmp.rename(f.path);
    } catch (e) {
      debugPrint('Sauvegarde impossible : $e');
    }
  }

  // ---------- Données dérivées ----------
  String get today => aujourdhui();
  Jour jour(String date) => jours.putIfAbsent(date, () => Jour(date: date));
  Jour? jourSiExiste(String date) => jours[date];

  List<PointPoids> get seriePoids {
    final pts = <PointPoids>[PointPoids(profil.debut, profil.poidsDepart, depart: true)];
    final dates = jours.keys.toList()..sort();
    for (final d in dates) {
      final kg = jours[d]!.poids;
      if (kg == null || kg <= 0) continue;
      if (d == profil.debut) {
        pts[0] = PointPoids(d, kg);
      } else if (d.compareTo(profil.debut) > 0) {
        pts.add(PointPoids(d, kg));
      }
    }
    return pts;
  }

  double get poidsActuel => seriePoids.last.kg;
  int get semaine {
    final d = diffDays(profil.debut, today);
    return d < 0 ? 1 : d ~/ 7 + 1;
  }

  String debutSemaine(int sem) => addDays(profil.debut, (sem - 1) * 7);
  SemainePlan get programme => programmeSemaine(semaine, profil.tapisSeul);
  /// Poids objectif choisi dans le profil, sinon le poids d'un IMC de 24,9.
  double get cible => profil.poidsObjectif ?? poidsCible(profil.taille, profil.imcCible);
  double get cibleImc => poidsCible(profil.taille, profil.imcCible);
  Cibles get cibles => calculerCibles(
        sexe: profil.sexe,
        age: profil.age,
        taille: profil.taille,
        kg: poidsActuel,
        activite: profil.activite,
        deficit: profil.deficit,
        poidsVise: cible,
      );

  /// Séances enregistrées pendant la semaine de programme [sem].
  List<MapEntry<String, Seance>> seancesSemaine(int sem) {
    final d0 = debutSemaine(sem), d1 = addDays(d0, 6);
    final out = <MapEntry<String, Seance>>[];
    final dates = jours.keys.where((d) => d.compareTo(d0) >= 0 && d.compareTo(d1) <= 0).toList()..sort();
    for (final d in dates) {
      for (final s in jours[d]!.seances) {
        out.add(MapEntry(d, s));
      }
    }
    return out;
  }

  // ---------- Poids, pas ----------
  void setPoids(String date, double kg) {
    jour(date).poids = (kg * 10).round() / 10;
    changer();
  }

  void setPas(String date, int pas, {bool auto = false}) {
    final j = jour(date);
    j.pas = pas;
    j.pasAuto = auto;
    changer();
  }

  Future<void> activerPasAuto() async {
    pasMessage = await steps.verifierDisponibilite();
    if (pasMessage != null) {
      changer(sauver: false);
      return;
    }
    final ok = await steps.autoriser();
    pasAutoActif = ok;
    pasMessage = ok ? null : 'Autorisation refusée. Ouvre Health Connect > Autorisations des applis > Objectif Fit.';
    changer();
    if (ok) await synchroniserPas();
  }

  Future<void> synchroniserPas() async {
    if (!pasAutoActif || pasEnCours) return;
    pasEnCours = true;
    changer(sauver: false);
    final r = await steps.lirePas(jours: 7);
    pasEnCours = false;
    pasMessage = r.erreur;
    r.pas.forEach((date, v) {
      final j = jour(date);
      // Une saisie manuelle n'est remplacée que si la valeur lue est plus grande.
      if (j.pasAuto || j.pas == null || v > (j.pas ?? 0)) {
        j.pas = v;
        j.pasAuto = true;
      }
    });
    changer();
  }

  // ---------- Repas ----------
  void ajouterRepas(String date, Repas r) {
    jour(date).repas.add(r);
    changer();
  }

  void supprimerRepas(String date, String id) {
    final j = jours[date];
    if (j == null) return;
    final r = j.repas.where((x) => x.id == id).toList();
    for (final x in r) {
      final p = x.photo;
      if (p != null) {
        try {
          File(p).deleteSync();
        } catch (_) {}
      }
    }
    j.repas.removeWhere((x) => x.id == id);
    changer();
  }

  // ---------- Séances ----------
  SeanceDraft demarrerSeance(String type, {List<String>? exosLibres, String? date}) {
    final sem = semaine;
    final prog = programme;
    final ph = prog.phase;
    final plan = prog.seances.where((s) => s.cle == type).toList();
    final List<ExoPlan> exos;
    final String cardioTexte;
    final int cardioMin;
    if (plan.isNotEmpty) {
      exos = plan.first.exos;
      cardioTexte = plan.first.cardioTexte;
      cardioMin = plan.first.cardioMin;
    } else {
      exos = (exosLibres ?? const <String>[]).where(bibliotheque.containsKey).map((id) => planPour(id, 'acc', ph)).toList();
      cardioTexte = '';
      cardioMin = 0;
    }
    final d = SeanceDraft(
      id: nouvelId(),
      type: type,
      titre: typeSeance(type).titre,
      phase: ph.nom,
      date: date ?? today,
      cardioTexte: cardioTexte,
      semaine: sem,
      allegee: ph.allegee,
      debutMs: DateTime.now().millisecondsSinceEpoch,
      exos: exos.map((e) => exoDraftDepuis(e, ph.allegee)).toList(),
      cardio: cardioMin > 0 ? [CardioDraft(machine: 'tapis', minutes: cardioMin, vitesse: 5.0, pente: ph.allegee ? 5 : 10)] : <CardioDraft>[],
    );
    brouillon = d;
    changer();
    return d;
  }

  ExoDraft exoDraftDepuis(ExoPlan e, bool allegee) {
    final s = suggestion(e.def, e.lo, e.hi, jours, allegee);
    return ExoDraft(
      id: e.def.id,
      role: e.role,
      lo: e.lo,
      hi: e.hi,
      rest: e.rest,
      unit: e.def.unit,
      suggKg: s.kg,
      suggTexte: s.texte,
      sets: List.generate(e.sets, (_) => SetDraft(kg: s.kg)),
    );
  }

  void ajouterExoAuBrouillon(String id) {
    final d = brouillon;
    if (d == null || !bibliotheque.containsKey(id)) return;
    final ph = phasePour(d.semaine);
    d.exos.add(exoDraftDepuis(planPour(id, 'acc', ph), d.allegee));
    changer();
  }

  void brouillonModifie() => changer();

  /// Sauvegarde différée sans reconstruire l'interface (saisie au clavier).
  void sauverSansNotifier() => _planifierSauvegarde();

  void abandonnerSeance() {
    brouillon = null;
    changer();
  }

  /// Enregistre la séance en cours. Renvoie un message d'erreur ou null.
  String? terminerSeance() {
    final d = brouillon;
    if (d == null) return 'Aucune séance en cours.';
    final exos = <ExoLog>[];
    for (final e in d.exos) {
      final sets = e.sets.where((s) => (s.reps ?? 0) > 0).map((s) => SetLog(s.kg ?? 0, s.reps ?? 0)).toList();
      if (sets.isNotEmpty) exos.add(ExoLog(id: e.id, lo: e.lo, hi: e.hi, unit: e.unit, sets: sets));
    }
    final kg = poidsActuel;
    final cardio = d.cardio
        .where((c) => c.minutes > 0)
        .map((c) => CardioLog(machine: c.machine, minutes: c.minutes, vitesse: c.vitesse, pente: c.pente, intensite: c.intensite, kcal: c.kcal(kg)))
        .toList();
    if (exos.isEmpty && cardio.isEmpty) return 'Note au moins une série ou du cardio.';
    var titre = d.titre;
    if (d.type == 'libre') {
      final cats = <String>[];
      for (final e in exos) {
        final c = bibliotheque[e.id]?.categorie;
        if (c != null && !cats.contains(c)) cats.add(c);
      }
      titre = cats.isEmpty ? 'Cardio' : '${cats.take(3).join(', ')}${cardio.isNotEmpty ? ' + cardio' : ''}';
    }
    final s = Seance(
      id: d.id,
      type: d.type,
      titre: titre,
      echauffementMin: d.echauffementMin,
      semaine: d.semaine,
      phase: d.phase,
      heure: heureMinute(DateTime.fromMillisecondsSinceEpoch(d.debutMs)),
      duree: d.duree,
      exos: exos,
      cardio: cardio,
      kcal: d.kcalEstimees(kg),
    );
    jour(d.date).seances.add(s);
    brouillon = null;
    changer();
    return null;
  }

  /// Nombre de séances où chaque exercice a été fait.
  Map<String, int> get compteurExos {
    final m = <String, int>{};
    for (final j in jours.values) {
      for (final s in j.seances) {
        for (final e in s.exos.map((x) => x.id).toSet()) {
          m[e] = (m[e] ?? 0) + 1;
        }
      }
    }
    return m;
  }

  void supprimerSeance(String date, String id) {
    jours[date]?.seances.removeWhere((s) => s.id == id);
    changer();
  }

  // ---------- Autres activités ----------
  void ajouterActivite(String date, ActiviteLog a) {
    jour(date).activites.add(a);
    changer();
  }

  void supprimerActivite(String date, String id) {
    jours[date]?.activites.removeWhere((a) => a.id == id);
    changer();
  }

  // ---------- Profil, réglages ----------
  void enregistrerProfil(Profil p) {
    profil = p;
    changer();
  }

  void setClaude(String cle, String mod) {
    cleApi = cle.trim();
    modele = mod;
    changer();
  }

  /// Importe l'export JSON de l'appli web (Cap IMC 25) ou de cette appli.
  /// Renvoie le nombre de jours importés.
  int importer(String texte) {
    final v = jsonDecode(texte);
    if (v is! Map) throw const FormatException('Ce texte n\'est pas un export Objectif Fit.');
    final j = Map<String, dynamic>.from(v);
    if (j['profil'] is Map) {
      final p = Profil.fromJson(Map<String, dynamic>.from(j['profil'] as Map));
      p.confirme = true;
      profil = p;
    }
    var n = 0;
    if (j['jours'] is Map) {
      (j['jours'] as Map).forEach((k, val) {
        if (val is! Map) return;
        final date = k.toString();
        final m = Map<String, dynamic>.from(val);
        // L'appli web nomme les séances par lettre (A, B, C) : on les garde comme séances libres.
        if (m['seances'] is List) {
          m['seances'] = maps(m['seances']).map((s) {
            if (s['type'] == null) {
              s['type'] = 'libre';
              s['titre'] = 'Séance ${s['cle'] ?? ''} (appli web)'.trim();
            }
            return s;
          }).toList();
        }
        final imp = Jour.fromJson(date, m);
        final ex = jours[date];
        if (ex == null) {
          jours[date] = imp;
        } else {
          ex.poids ??= imp.poids;
          ex.pas ??= imp.pas;
          final idsR = ex.repas.map((r) => r.id).toSet();
          ex.repas.addAll(imp.repas.where((r) => !idsR.contains(r.id)));
          final idsS = ex.seances.map((s) => s.id).toSet();
          ex.seances.addAll(imp.seances.where((s) => !idsS.contains(s.id)));
          final idsA = ex.activites.map((a) => a.id).toSet();
          ex.activites.addAll(imp.activites.where((a) => !idsA.contains(a.id)));
        }
        n++;
      });
    }
    changer();
    return n;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
