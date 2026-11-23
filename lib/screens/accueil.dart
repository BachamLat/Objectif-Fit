import 'package:flutter/material.dart';

import '../calc.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'activite_page.dart';
import 'salle.dart';
import 'seance_page.dart';

class AccueilPage extends StatefulWidget {
  final void Function(int) allerA;
  const AccueilPage({super.key, required this.allerA});
  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _Entree {
  final String date, titre, type;
  final int kcal;
  const _Entree(this.date, this.titre, this.type, this.kcal);
}

class _AccueilPageState extends State<AccueilPage> {
  final _poids = TextEditingController();
  final _pas = TextEditingController();
  bool _hier = false;

  @override
  void dispose() {
    _poids.dispose();
    _pas.dispose();
    super.dispose();
  }

  void _noterSeance(AppState st) {
    if (st.brouillon == null) st.demarrerSeance('libre');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeancePage()));
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final t = Theme.of(context);
    final c = Couleurs.of(context);
    final p = st.profil;
    final today = st.today;
    final pts = st.seriePoids;
    final actuel = pts.last.kg;
    final cib = st.cibles;
    final cible = st.cible;
    final perdu = p.poidsDepart - actuel;
    final reste = actuel - cible > 0 ? actuel - cible : 0.0;
    final total = p.poidsDepart - cible > 0.1 ? p.poidsDepart - cible : 0.1;
    final pct = (perdu / total).clamp(0.0, 1.0).toDouble();
    final tr = tendance(pts, today);
    final reel = tr != null && tr < -0.05;
    final rythme = reel ? -tr : cib.perteSem;
    final est = estimationArrivee(actuel, cible, rythme, pts.last.date);
    final j = st.jourSiExiste(today);
    final mange = j?.kcalMangees ?? 0;
    final prot = j?.proteines ?? 0;
    final pasDate = _hier ? addDays(today, -1) : today;
    final pasVal = st.jourSiExiste(pasDate)?.pas ?? 0;
    final pasObjectif = st.programme.pas;
    final sportJour = (j?.kcalSport ?? 0) + pasKcal(j?.pas ?? 0, actuel);

    // Les 7 derniers jours
    var nbSeances = 0, kcalSemaine = 0, minCardio = 0, pasTotal = 0, joursPas = 0;
    final entrees = <_Entree>[];
    for (var i = 0; i < 7; i++) {
      final d = addDays(today, -i);
      final jj = st.jourSiExiste(d);
      if (jj == null) continue;
      nbSeances += jj.seances.length;
      kcalSemaine += jj.kcalSport;
      minCardio += jj.seances.fold<int>(0, (a, s) => a + s.minutesCardio) + jj.activites.fold<int>(0, (a, x) => a + x.minutes);
      if ((jj.pas ?? 0) > 0) {
        pasTotal += jj.pas!;
        joursPas++;
      }
    }
    final dates = st.jours.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final d in dates) {
      final jj = st.jours[d]!;
      for (final s in jj.seances.reversed) {
        entrees.add(_Entree(d, s.titre, s.type, s.kcal));
      }
      for (final a in jj.activites.reversed) {
        entrees.add(_Entree(d, a.nom, 'activite', a.kcal));
      }
      if (entrees.length >= 4) break;
    }

    Widget espace() => const SizedBox(height: 14);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Etiquette(dateLongue(today)),
        const SizedBox(height: 4),
        Text('Objectif Fit', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        espace(),
        if (!p.confirme) ...[
          Section(children: [
            const Text('Vérifie ton profil : âge, taille et poids objectif. Tes calories du jour en dépendent.'),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: () => widget.allerA(4), child: const Text('Vérifier mon profil'))),
          ]),
          espace(),
        ],
        Section(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Etiquette('Poids actuel'),
                const SizedBox(height: 4),
                Gros(fmt(actuel, 1), 'kg', taille: 44),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Etiquette('Objectif'),
              const SizedBox(height: 4),
              Gros(fmt(cible, 1), 'kg', taille: 30),
            ]),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: pct, minHeight: 12, color: c.good, backgroundColor: t.colorScheme.surfaceContainerHighest),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: Text('${fmt(perdu > 0 ? perdu : 0, 1)} kg perdus', style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(reste > 0 ? '${fmt(reste, 1)} kg à perdre' : 'Objectif atteint', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          Text('Départ : ${fmt(p.poidsDepart, 1)} kg le ${dateCourte(p.debut)}', style: TextStyle(fontSize: 12.5, color: c.muted)),
          const SizedBox(height: 8),
          if (reste <= 0)
            Text('Bravo ! Passe en maintien : remonte tes calories de 100 à 200 kcal par semaine.', style: TextStyle(color: c.good, fontWeight: FontWeight.w600))
          else if (est != null)
            Text(
                '${reel ? 'À ton rythme réel (${fmt(-tr, 2)} kg/semaine)' : 'Au rythme prévu (${fmt(cib.perteSem, 2)} kg/semaine)'}, objectif vers ${moisAnnee(est.date)}.',
                style: TextStyle(color: t.colorScheme.onSurfaceVariant))
          else
            Text('Ton poids ne baisse pas depuis 4 semaines. Vérifie que tous tes repas sont notés, ou baisse ta cible de 150 kcal dans le profil.', style: TextStyle(color: c.warn)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _poids,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Poids du jour (kg)', hintText: j?.poids != null ? fmt(j!.poids, 1) : null),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () {
                final kg = parseNum(_poids.text);
                if (kg == null || kg < 30 || kg > 250) {
                  message(context, 'Entre un poids entre 30 et 250 kg.');
                  return;
                }
                st.setPoids(today, kg);
                _poids.clear();
                FocusScope.of(context).unfocus();
                message(context, 'Poids enregistré.');
              },
              child: const Text('Peser'),
            ),
          ]),
          const SizedBox(height: 6),
          Text('Pèse-toi le matin à jeun, 2 à 3 fois par semaine. C\'est la tendance qui compte.', style: TextStyle(fontSize: 12.5, color: c.muted)),
        ]),
        espace(),
        Section(titre: 'Aujourd\'hui', children: [
          Jauge(
            label: 'Calories mangées',
            valeur: mange,
            max: cib.kcal,
            unite: 'kcal',
            alerteSiDepasse: true,
            pied: mange <= cib.kcal ? 'Il te reste ${fmt(cib.kcal - mange)} kcal.' : 'Dépassement de ${fmt(mange - cib.kcal)} kcal : marche un peu plus et compense légèrement demain.',
          ),
          const SizedBox(height: 12),
          Jauge(label: 'Protéines', valeur: prot, max: cib.prot, unite: 'g', vertSiAtteint: true),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.local_fire_department_outlined, color: c.warn, size: 20),
            const SizedBox(width: 6),
            Expanded(child: Text('Dépensé en bougeant : ≈ ${fmt(sportJour)} kcal (salle, activités et pas)')),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => widget.allerA(1), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Photographier un repas')),
        ]),
        espace(),
        Section(titre: 'Ta semaine (7 derniers jours)', children: [
          Row(children: [
            Expanded(child: _Chiffre(valeur: '$nbSeances', label: nbSeances > 1 ? 'séances' : 'séance')),
            Expanded(child: _Chiffre(valeur: fmt(kcalSemaine), label: 'kcal dépensées')),
            Expanded(child: _Chiffre(valeur: '$minCardio', label: 'min de cardio')),
          ]),
          const SizedBox(height: 8),
          Text(joursPas > 0 ? 'Pas : ${fmt(pasTotal / joursPas)} par jour en moyenne (objectif ${fmt(pasObjectif)}).' : 'Pas : pas encore de données cette semaine.',
              style: TextStyle(color: c.muted)),
          if (entrees.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Etiquette('Dernières activités'),
            for (final e in entrees.take(4))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(e.type == 'activite' ? Icons.directions_bike_outlined : iconeType(e.type)),
                title: Text(e.titre),
                subtitle: Text(jourCourt(e.date)),
                trailing: Text('≈ ${fmt(e.kcal)} kcal', style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular)),
              ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _noterSeance(st),
                icon: Icon(st.brouillon != null ? Icons.play_arrow : Icons.fitness_center),
                label: Text(st.brouillon != null ? 'Reprendre ma séance' : 'Noter une séance'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivitePage())),
                icon: const Icon(Icons.add),
                label: const Text('Autre activité'),
              ),
            ),
          ]),
        ]),
        espace(),
        Section(
          titre: 'Pas',
          action: SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, label: Text('Aujourd\'hui')), ButtonSegment(value: true, label: Text('Hier'))],
            selected: {_hier},
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: (s) => setState(() => _hier = s.first),
          ),
          children: [
            Jauge(
              label: 'Objectif du jour',
              valeur: pasVal,
              max: pasObjectif,
              unite: 'pas',
              vertSiAtteint: true,
              pied: pasVal > 0 ? '≈ ${fmt(pasKcal(pasVal, actuel))} kcal dépensées en marchant${st.jourSiExiste(pasDate)?.pasAuto == true ? ' · lu automatiquement' : ''}.' : null,
            ),
            const SizedBox(height: 10),
            if (st.pasAutoActif)
              Row(children: [
                Expanded(child: Text(st.pasEnCours ? 'Lecture des pas…' : 'Pas lus depuis Health Connect / Santé.', style: TextStyle(color: c.muted))),
                IconButton(tooltip: 'Relire les pas', onPressed: st.pasEnCours ? null : st.synchroniserPas, icon: const Icon(Icons.sync)),
              ])
            else
              OutlinedButton.icon(
                onPressed: st.activerPasAuto,
                icon: const Icon(Icons.directions_walk),
                label: const Text('Lire mes pas automatiquement'),
              ),
            if (st.pasMessage != null) ...[
              const SizedBox(height: 6),
              Text(st.pasMessage!, style: TextStyle(color: c.warn)),
              if (st.pasMessage!.contains('Health Connect est absent'))
                TextButton(onPressed: st.steps.installerHealthConnect, child: const Text('Installer ou mettre à jour Health Connect')),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _pas,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Saisir à la main', hintText: pasVal > 0 ? fmt(pasVal) : null),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                onPressed: () {
                  final n = parseNum(_pas.text);
                  if (n == null || n < 0 || n > 100000) {
                    message(context, 'Entre un nombre de pas valide.');
                    return;
                  }
                  st.setPas(pasDate, n.round());
                  _pas.clear();
                  FocusScope.of(context).unfocus();
                  message(context, 'Pas enregistrés.');
                },
                child: const Text('OK'),
              ),
            ]),
          ],
        ),
        espace(),
        Section(titre: 'Évolution du poids', children: [CourbePoids(points: pts, cible: cible)]),
      ],
    );
  }
}

class _Chiffre extends StatelessWidget {
  final String valeur, label;
  const _Chiffre({required this.valeur, required this.label});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(valeur, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, fontFeatures: tabular)),
        Text(label, style: TextStyle(fontSize: 12.5, color: Couleurs.of(context).muted)),
      ]);
}
