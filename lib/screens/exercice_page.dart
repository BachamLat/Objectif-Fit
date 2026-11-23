// Fiche d'un exercice : schéma animé de la machine, consignes, liens photos/vidéos, historique.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../calc.dart';
import '../programme.dart';
import '../store.dart';
import '../widgets/common.dart';
import '../widgets/exercise_anim.dart';

class ExercicePage extends StatelessWidget {
  final String id;
  const ExercicePage({super.key, required this.id});

  Future<void> _ouvrir(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) message(context, 'Impossible d\'ouvrir le lien.');
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final def = bibliotheque[id];
    final t = Theme.of(context);
    final c = Couleurs.of(context);
    if (def == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Exercice inconnu.')));
    final hist = historiqueExo(id, st.jours, max: 12);
    final requete = Uri.encodeComponent('${def.nom} machine salle de sport');
    final unite = def.unit == 's' ? 's' : 'reps';
    return Scaffold(
      appBar: AppBar(title: Text(def.categorie)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(def.nom, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${def.muscles} · ${def.zone}', style: TextStyle(color: c.muted)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: t.colorScheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.colorScheme.outlineVariant)),
            padding: const EdgeInsets.all(8),
            child: ExerciseAnimation(id: def.anim),
          ),
          const SizedBox(height: 6),
          Text('Schéma simplifié : la silhouette bleue montre le mouvement, la machine est en gris. Les modèles du club peuvent être un peu différents.',
              style: TextStyle(fontSize: 12.5, color: c.muted)),
          const SizedBox(height: 14),
          Section(titre: 'Comment faire', children: [Text(def.cue, style: const TextStyle(height: 1.4))]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _ouvrir(context, 'https://www.google.com/search?tbm=isch&q=$requete'),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Photos'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _ouvrir(context, 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${def.nom} technique')}'),
                icon: const Icon(Icons.smart_display_outlined),
                label: const Text('Vidéos'),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text('Au club, un coach Basic-Fit peut aussi te montrer le réglage de la machine la première fois.', style: TextStyle(fontSize: 12.5, color: c.muted)),
          if (def.unit != 'min') ...[
            const SizedBox(height: 14),
            Section(
              titre: 'Mon historique',
              children: hist.isEmpty
                  ? [Text('Pas encore fait. Il apparaîtra ici après ta première séance.', style: TextStyle(color: c.muted))]
                  : [
                      for (final h in hist)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            SizedBox(width: 92, child: Text(jourCourt(h.date), style: const TextStyle(fontWeight: FontWeight.w600))),
                            Expanded(
                              child: Text(
                                h.log.sets.map((s) => def.avecCharge && s.kg > 0 ? '${fmtKg(s.kg)} kg × ${s.reps}' : '${s.reps} $unite').join('  ·  '),
                                style: const TextStyle(fontFeatures: tabular),
                              ),
                            ),
                          ]),
                        ),
                    ],
            ),
          ],
        ],
      ),
    );
  }
}
