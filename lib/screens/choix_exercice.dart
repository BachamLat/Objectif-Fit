// Choix visuel d'un exercice : grille de machines avec leur schéma, par groupe musculaire.
import 'package:flutter/material.dart';

import '../programme.dart';
import '../store.dart';
import '../widgets/common.dart';
import '../widgets/exercise_anim.dart';
import 'exercice_page.dart';

/// Renvoie l'id de l'exercice choisi (Navigator.pop), ou null.
class ChoixExercicePage extends StatefulWidget {
  final Set<String> dejaAjoutes;
  const ChoixExercicePage({super.key, this.dejaAjoutes = const {}});
  @override
  State<ChoixExercicePage> createState() => _ChoixExercicePageState();
}

class _ChoixExercicePageState extends State<ChoixExercicePage> {
  String _cat = 'Tous';

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = Couleurs.of(context);
    final t = Theme.of(context);
    final compteur = st.compteurExos;
    final cats = ['Tous', 'Mes habituels', ...categories.where((x) => x != 'Cardio')];
    var liste = bibliotheque.values.where((e) => e.categorie != 'Cardio').toList();
    if (_cat == 'Mes habituels') {
      liste = liste.where((e) => (compteur[e.id] ?? 0) > 0).toList()..sort((a, b) => (compteur[b.id] ?? 0).compareTo(compteur[a.id] ?? 0));
    } else if (_cat != 'Tous') {
      liste = liste.where((e) => e.categorie == _cat).toList();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Quel exercice as-tu fait ?')),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final k in cats)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(k), selected: _cat == k, onSelected: (_) => setState(() => _cat = k)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Text('Touche une machine pour l\'ajouter. Le bouton ⓘ montre le mouvement animé et les consignes.', style: TextStyle(fontSize: 12.5, color: c.muted)),
        ),
        Expanded(
          child: liste.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Les exercices que tu fais souvent apparaîtront ici.', textAlign: TextAlign.center, style: TextStyle(color: c.muted))))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.86),
                  itemCount: liste.length,
                  itemBuilder: (context, i) {
                    final e = liste[i];
                    final n = compteur[e.id] ?? 0;
                    final deja = widget.dejaAjoutes.contains(e.id);
                    return Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      color: deja ? t.colorScheme.secondaryContainer : null,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(e.id),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(e.categorie.toUpperCase(), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: c.muted))),
                              IconButton(
                                tooltip: 'Voir le mouvement',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.info_outline, size: 20),
                                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExercicePage(id: e.id))),
                              ),
                            ]),
                            ExerciseAnimation(id: e.anim, animer: false),
                            const SizedBox(height: 6),
                            Text(e.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const Spacer(),
                            Text(
                              deja ? 'Déjà dans ta séance' : (n > 0 ? 'Fait $n fois' : e.muscles),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: n > 0 && !deja ? c.good : c.muted, fontWeight: n > 0 ? FontWeight.w600 : FontWeight.w400),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
