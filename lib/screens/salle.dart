// Onglet Salle : choix de la séance du jour, autres activités, historique avec kcal.
import 'package:flutter/material.dart';

import '../calc.dart';
import '../models.dart';
import '../programme.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'activite_page.dart';
import 'seance_page.dart';

IconData iconeType(String type) {
  switch (type) {
    case 'bras':
      return Icons.sports_gymnastics;
    case 'dos':
      return Icons.rowing;
    case 'jambes':
      return Icons.directions_run;
    case 'tapis':
      return Icons.directions_walk;
    default:
      return Icons.fitness_center;
  }
}

class SallePage extends StatelessWidget {
  const SallePage({super.key});

  void _demarrer(BuildContext context, AppState st, String type) {
    if (st.brouillon != null) {
      message(context, 'Une séance est déjà en cours : termine-la ou abandonne-la d\'abord.');
    } else {
      st.demarrerSeance(type);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeancePage()));
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final t = Theme.of(context);
    final c = Couleurs.of(context);
    final sem = st.semaine;
    final prog = st.programme;
    final semaineSeances = st.seancesSemaine(sem);
    final faites = <String, String>{};
    for (final e in semaineSeances) {
      faites[e.value.type] = e.key;
    }
    // Totaux de la semaine
    final d0 = st.debutSemaine(sem);
    var kcalSem = 0, minCardio = 0, nbSeances = 0;
    for (var i = 0; i < 7; i++) {
      final j = st.jourSiExiste(addDays(d0, i));
      if (j == null) continue;
      kcalSem += j.kcalSport;
      nbSeances += j.seances.length;
      minCardio += j.seances.fold<int>(0, (a, s) => a + s.minutesCardio);
      minCardio += j.activites.fold<int>(0, (a, x) => a + x.minutes);
    }
    // Historique (60 derniers jours avec des entrées)
    final dates = st.jours.keys.where((d) {
      final j = st.jours[d]!;
      return (j.seances.isNotEmpty || j.activites.isNotEmpty) && diffDays(d, st.today) <= 60;
    }).toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Etiquette('Semaine $sem · ${prog.phase.nom}${prog.phase.allegee ? ' (allégée)' : ''}'),
        const SizedBox(height: 4),
        Text('Salle', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        if (st.brouillon != null) ...[
          Card(
            color: t.colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text('En cours : ${st.brouillon!.titre}'),
              subtitle: Text('Commencée il y a ${st.brouillon!.dureeAuto} min'),
              trailing: FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeancePage())), child: const Text('Reprendre')),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (st.brouillon == null) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => _demarrer(context, st, 'libre'),
            icon: const Icon(Icons.fitness_center),
            label: const Text('Noter ma séance', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(height: 6),
          Text('Choisis les machines que tu as utilisées, en image, puis note tes séries, ton échauffement et ton cardio. Tu peux remplir pendant ou après la salle.',
              style: TextStyle(color: c.muted)),
          const SizedBox(height: 14),
        ],
        Section(titre: 'Idées de séance (facultatif)', children: [
          Text('Si tu ne sais pas quoi faire, pars d\'une de ces séances : les exercices sont pré-remplis et tu peux en retirer ou en ajouter.', style: TextStyle(color: c.muted)),
          const SizedBox(height: 10),
          for (final s in prog.seances) ...[
            Row(children: [
              CircleAvatar(
                backgroundColor: faites.containsKey(s.cle) ? c.good : t.colorScheme.secondaryContainer,
                foregroundColor: faites.containsKey(s.cle) ? Colors.white : t.colorScheme.onSecondaryContainer,
                child: Icon(faites.containsKey(s.cle) ? Icons.check : iconeType(s.cle)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(
                    faites.containsKey(s.cle) ? 'Faite ${jourCourt(faites[s.cle]!)}' : '${s.exos.length} exercices + ${s.cardioMin} min de tapis',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ]),
              ),
              OutlinedButton(onPressed: () => _demarrer(context, st, s.cle), child: const Text('Utiliser')),
            ]),
            const SizedBox(height: 12),
          ],
        ]),
        const SizedBox(height: 14),
        Section(titre: 'Autre activité', children: [
          Text('Foot, marche, vélo dehors, cours collectif… Note-la pour estimer les calories dépensées.', style: TextStyle(color: c.muted)),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivitePage())),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une activité'),
          ),
        ]),
        const SizedBox(height: 14),
        Section(titre: 'Cette semaine', children: [
          Row(children: [
            Expanded(child: _Stat(valeur: fmt(kcalSem), label: 'kcal dépensées')),
            Expanded(child: _Stat(valeur: '$nbSeances', label: 'séances')),
            Expanded(child: _Stat(valeur: '$minCardio', label: 'min de cardio')),
          ]),
          const SizedBox(height: 6),
          Text('Hors pas. Estimations : valeurs MET du Compendium et équation ACSM pour le tapis.', style: TextStyle(fontSize: 12, color: c.muted)),
        ]),
        const SizedBox(height: 14),
        Section(
          titre: 'Historique',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: dates.isEmpty
              ? [Text('Tes séances et activités apparaîtront ici.', style: TextStyle(color: c.muted))]
              : [for (final d in dates) _JourHistorique(date: d, jour: st.jours[d]!)],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String valeur, label;
  const _Stat({required this.valeur, required this.label});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(valeur, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, fontFeatures: tabular)),
        Text(label, style: TextStyle(fontSize: 12.5, color: Couleurs.of(context).muted)),
      ]);
}

class _JourHistorique extends StatelessWidget {
  final String date;
  final Jour jour;
  const _JourHistorique({required this.date, required this.jour});

  Future<bool> _confirmer(BuildContext context, String quoi) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Supprimer $quoi ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.read(context);
    final c = Couleurs.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.only(top: 8, bottom: 2), child: Etiquette(dateLongue(date))),
      for (final s in jour.seances)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: Icon(iconeType(s.type)),
          title: Text(s.titre, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${s.exos.length} exercices${s.tonnage > 0 ? ' · ${fmt(s.tonnage)} kg soulevés' : ''}${s.minutesCardio > 0 ? ' · ${s.minutesCardio} min cardio' : ''} · ≈ ${fmt(s.kcal)} kcal'),
          childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in s.exos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${bibliotheque[e.id]?.nom ?? e.id} : ${e.sets.map((x) => x.kg > 0 ? '${fmtKg(x.kg)}×${x.reps}' : '${x.reps}${e.unit == 's' ? ' s' : ''}').join(', ')}',
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
            for (final k in s.cardio)
              Text('${machineCardio(k.machine).nom} : ${k.minutes} min${k.machine == 'tapis' && k.vitesse > 0 ? ' à ${fmt(k.vitesse, 1)} km/h, pente ${fmt(k.pente)} %' : ''} · ≈ ${fmt(k.kcal)} kcal',
                  style: const TextStyle(fontSize: 13.5)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  if (await _confirmer(context, 'cette séance')) st.supprimerSeance(date, s.id);
                },
                child: Text('Supprimer', style: TextStyle(color: c.bad)),
              ),
            ),
          ],
        ),
      for (final a in jour.activites)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.directions_bike_outlined),
          title: Text(a.nom),
          subtitle: Text('${a.minutes} min · ≈ ${fmt(a.kcal)} kcal${a.source == 'claude' ? ' · estimé par Claude' : ''}'),
          trailing: IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await _confirmer(context, 'cette activité')) st.supprimerActivite(date, a.id);
            },
          ),
        ),
      const Divider(height: 16),
    ]);
  }
}
