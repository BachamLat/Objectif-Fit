// Onglet Programme : la semaine (split + tapis) et la bibliothèque d'exercices avec schémas animés.
import 'package:flutter/material.dart';

import '../calc.dart';
import '../programme.dart';
import '../store.dart';
import '../widgets/common.dart';
import '../widgets/exercise_anim.dart';
import 'exercice_page.dart';
import 'salle.dart';
import 'seance_page.dart';

class ProgrammePage extends StatefulWidget {
  const ProgrammePage({super.key});
  @override
  State<ProgrammePage> createState() => _ProgrammePageState();
}

class _ProgrammePageState extends State<ProgrammePage> {
  bool _biblio = true;
  int? _sem;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final t = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const Etiquette('Salle de sport'),
        const SizedBox(height: 4),
        Text('Machines', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Machines'), icon: Icon(Icons.menu_book_outlined)),
            ButtonSegment(value: false, label: Text('Idées de séances'), icon: Icon(Icons.lightbulb_outline)),
          ],
          selected: {_biblio},
          onSelectionChanged: (s) => setState(() => _biblio = s.first),
        ),
        const SizedBox(height: 14),
        if (_biblio) ..._bibliotheque(context) else ..._semaine(context, st),
      ],
    );
  }

  List<Widget> _semaine(BuildContext context, AppState st) {
    final c = Couleurs.of(context);
    final actuelle = st.semaine;
    final w = _sem ?? actuelle;
    final pr = programmeSemaine(w, st.profil.tapisSeul);
    final ph = pr.phase;
    final d0 = st.debutSemaine(w);
    return [
      Row(children: [
        IconButton.outlined(tooltip: 'Semaine précédente', onPressed: w <= 1 ? null : () => setState(() => _sem = w - 1), icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Column(children: [
            Text('Semaine $w${w == actuelle ? ' (en cours)' : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('du ${dateCourte(d0)} au ${dateCourte(addDays(d0, 6))}', style: TextStyle(color: c.muted)),
          ]),
        ),
        IconButton.outlined(tooltip: 'Semaine suivante', onPressed: () => setState(() => _sem = w + 1), icon: const Icon(Icons.chevron_right)),
      ]),
      if (w != actuelle) Center(child: TextButton(onPressed: () => setState(() => _sem = null), child: const Text('Revenir à cette semaine'))),
      const SizedBox(height: 10),
      Section(titre: 'Bloc ${ph.bloc} · ${ph.nom} · semaine ${ph.semBloc}/4', children: [
        Text(pr.but),
        if (ph.allegee) ...[
          const SizedBox(height: 8),
          Text('Semaine allégée : une série de moins et −10 % sur les charges. Le corps récupère pour repartir plus fort.', style: TextStyle(color: c.warn, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 8),
        Text('Objectif de pas : ${fmt(pr.pas)} par jour.', style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),
      for (final s in pr.seances) ...[
        Section(
          titre: s.titre,
          action: w == actuelle
              ? TextButton(
                  onPressed: () {
                    if (st.brouillon == null) st.demarrerSeance(s.cle);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeancePage()));
                  },
                  child: Text(st.brouillon == null ? 'Commencer' : 'Séance en cours'),
                )
              : null,
          children: [
            for (final e in s.exos) _LigneExo(plan: e, semaineCourante: w == actuelle, allegee: ph.allegee),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(iconeType('tapis'), size: 20, color: c.good),
              const SizedBox(width: 8),
              Expanded(child: Text('Tapis : ${s.cardioTexte}')),
            ]),
          ],
        ),
        const SizedBox(height: 12),
      ],
      Section(titre: 'Le ventre, honnêtement', children: [
        const Text(
            'Aucun exercice d\'abdos ne fait fondre la graisse du ventre à lui seul. Elle diminue avec le déficit calorique, les pas, le tapis et la musculation de tout le corps, qui augmente ta dépense et garde tes muscles pendant la perte de poids.'),
        const SizedBox(height: 8),
        const Text('La planche et la machine à abdos renforcent la sangle abdominale : plus solide pour soulever, et visible quand la graisse aura baissé.'),
        const SizedBox(height: 8),
        Text('Progression : blocs de 4 semaines. Fondations (12–15 reps), puis Volume (10–12) et Force (6–8) en alternance, avec une semaine allégée à la fin de chaque bloc et des variantes d\'exercices tous les deux blocs.',
            style: TextStyle(color: c.muted)),
      ]),
    ];
  }

  List<Widget> _bibliotheque(BuildContext context) {
    final c = Couleurs.of(context);
    final compteur = AppScope.of(context).compteurExos;
    return [
      Text('Touche une machine pour voir le mouvement animé, les consignes, des photos et ton historique.', style: TextStyle(color: c.muted)),
      const SizedBox(height: 10),
      for (final cat in categories) ...[
        Padding(padding: const EdgeInsets.fromLTRB(2, 10, 2, 6), child: Etiquette(cat)),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.92,
          children: [
            for (final e in bibliotheque.values.where((e) => e.categorie == cat))
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExercicePage(id: e.id))),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ExerciseAnimation(id: e.anim, animer: false),
                      const SizedBox(height: 6),
                      Text(e.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      Text((compteur[e.id] ?? 0) > 0 ? 'Fait ${compteur[e.id]} fois' : e.muscles,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: (compteur[e.id] ?? 0) > 0 ? c.good : c.muted)),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ],
    ];
  }
}

class _LigneExo extends StatelessWidget {
  final ExoPlan plan;
  final bool semaineCourante, allegee;
  const _LigneExo({required this.plan, required this.semaineCourante, required this.allegee});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.read(context);
    final c = Couleurs.of(context);
    final sg = semaineCourante && plan.def.avecCharge ? suggestion(plan.def, plan.lo, plan.hi, st.jours, allegee) : null;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExercicePage(id: plan.def.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 72, child: ExerciseAnimation(id: plan.def.anim, animer: false)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.def.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${plan.def.muscles}${sg?.kg != null ? ' · ${plan.def.inverse ? 'assistance' : 'charge'} ${fmtKg(sg!.kg!)} kg' : ''}',
                style: TextStyle(fontSize: 12.5, color: c.muted),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${plan.sets} × ${plan.plage}', style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: tabular)),
            Text('repos ${plan.rest} s', style: TextStyle(fontSize: 12, color: c.muted)),
          ]),
        ]),
      ),
    );
  }
}
