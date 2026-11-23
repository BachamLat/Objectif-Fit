// Séance en cours : séries, charges suggérées, minuteur de repos, cardio et kcal estimées.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc.dart';
import '../models.dart';
import '../programme.dart';
import '../store.dart';
import '../widgets/common.dart';
import '../widgets/exercise_anim.dart';
import 'choix_exercice.dart';
import 'exercice_page.dart';

class SeancePage extends StatefulWidget {
  const SeancePage({super.key});
  @override
  State<SeancePage> createState() => _SeancePageState();
}

class _SeancePageState extends State<SeancePage> {
  Timer? _timer;
  int _repos = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _lancerRepos(int secondes) {
    _timer?.cancel();
    setState(() => _repos = secondes);
    _timer = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (!mounted) {
        tm.cancel();
        return;
      }
      setState(() => _repos--);
      if (_repos <= 0) {
        tm.cancel();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _arreterRepos() {
    _timer?.cancel();
    setState(() => _repos = 0);
  }

  Future<void> _abandonner(AppState st) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Abandonner la séance ?'),
        content: const Text('Les séries notées seront perdues.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Continuer')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Abandonner')),
        ],
      ),
    );
    if (ok == true && mounted) {
      st.abandonnerSeance();
      Navigator.of(context).pop();
    }
  }

  Future<void> _ajouterExo(AppState st, SeanceDraft d) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ChoixExercicePage(dejaAjoutes: d.exos.map((e) => e.id).toSet())),
    );
    if (id != null) st.ajouterExoAuBrouillon(id);
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.brouillon;
    if (d == null) {
      return Scaffold(appBar: AppBar(title: const Text('Séance')), body: const Center(child: Text('Aucune séance en cours.')));
    }
    final kg = st.poidsActuel;
    final c = Couleurs.of(context);
    final kcal = d.kcalEstimees(kg);
    return Scaffold(
      appBar: AppBar(
        title: Text(d.type == 'libre' ? 'Ma séance' : d.titre),
        actions: [IconButton(tooltip: 'Abandonner la séance', onPressed: () => _abandonner(st), icon: const Icon(Icons.delete_outline))],
      ),
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
          children: [
            _Infos(d: d, onChange: () => setState(() {})),
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(child: Etiquette('Exercices')),
              Text('${d.exos.length}', style: TextStyle(color: c.muted)),
            ]),
            const SizedBox(height: 6),
            if (d.exos.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('Ajoute les exercices que tu as faits : choisis la machine en image, puis note tes séries.', style: TextStyle(color: c.muted)),
              ),
            for (var i = 0; i < d.exos.length; i++) ...[
              _CarteExo(
                key: ValueKey('${d.id}-exo-$i-${d.exos[i].id}'),
                seanceId: d.id,
                index: i,
                exo: d.exos[i],
                onRepos: _lancerRepos,
                onRetirer: () {
                  d.exos.removeAt(i);
                  st.brouillonModifie();
                },
              ),
              const SizedBox(height: 10),
            ],
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => _ajouterExo(st, d),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un exercice'),
            ),
            const SizedBox(height: 16),
            Section(titre: 'Cardio', children: [
              if (d.cardioTexte.isNotEmpty) ...[
                Text('Idée : ${d.cardioTexte}', style: TextStyle(color: c.muted)),
                const SizedBox(height: 10),
              ],
              if (d.cardio.isEmpty) Text('Tapis, vélo, rameur… ajoute ce que tu as fait.', style: TextStyle(color: c.muted)),
              for (var i = 0; i < d.cardio.length; i++)
                _CarteCardio(
                  key: ValueKey('${d.id}-cardio-$i'),
                  cardio: d.cardio[i],
                  kg: kg,
                  onChange: () => setState(() {}),
                  onRetirer: () {
                    d.cardio.removeAt(i);
                    st.brouillonModifie();
                  },
                ),
              TextButton.icon(
                onPressed: () {
                  d.cardio.add(CardioDraft(machine: d.cardio.isEmpty ? 'tapis' : 'velo', minutes: d.cardio.isEmpty ? 20 : 10));
                  st.brouillonModifie();
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter du cardio'),
              ),
            ]),
            const SizedBox(height: 12),
            Section(titre: 'Bilan', children: [
              Text('Durée : ${d.duree} min${d.dureeManuelle == null ? ' (depuis l\'ouverture de la séance)' : ''}'),
              Text('Dépense estimée : ≈ ${fmt(kcal)} kcal', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Musculation : MET ${fmt(metMuscu(d.type), 1)} × ${fmt(kg, 1)} kg × durée hors cardio et échauffement. Tapis : équation ACSM (vitesse et pente).',
                  style: TextStyle(fontSize: 12, color: c.muted)),
            ]),
          ],
        ),
        if (_repos > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: Material(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(99),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Repos ${_repos ~/ 60}:${(_repos % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 20, fontWeight: FontWeight.w800, fontFeatures: tabular)),
                    const SizedBox(width: 10),
                    FilledButton.tonal(onPressed: _arreterRepos, child: const Text('Passer')),
                  ]),
                ),
              ),
            ),
          ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () {
              final err = st.terminerSeance();
              if (err != null) {
                message(context, err);
                return;
              }
              Navigator.of(context).pop();
              message(context, 'Séance enregistrée : ≈ ${fmt(kcal)} kcal. Bravo !');
            },
            icon: const Icon(Icons.check),
            label: Text('Terminer et enregistrer · ≈ ${fmt(kcal)} kcal'),
          ),
        ),
      ),
    );
  }
}

class _CarteExo extends StatefulWidget {
  final String seanceId;
  final int index;
  final ExoDraft exo;
  final void Function(int) onRepos;
  final VoidCallback onRetirer;
  const _CarteExo({super.key, required this.seanceId, required this.index, required this.exo, required this.onRepos, required this.onRetirer});
  @override
  State<_CarteExo> createState() => _CarteExoState();
}

class _CarteExoState extends State<_CarteExo> {
  @override
  Widget build(BuildContext context) {
    final st = AppScope.read(context);
    final e = widget.exo;
    final def = bibliotheque[e.id];
    final t = Theme.of(context);
    final c = Couleurs.of(context);
    if (def == null) return const SizedBox.shrink();
    final h = historiqueExo(e.id, st.jours, max: 1);
    final derniere = h.isEmpty ? null : h.first;
    final seul = !def.avecCharge || e.unit == 's';
    final plage = '${e.lo}–${e.hi}${e.unit == 's' ? ' s' : ' reps'}${def.parCote ? ' / côté' : ''}';
    return Section(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExercicePage(id: e.id))),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 92, child: ExerciseAnimation(id: e.id, animer: false)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(def.nom, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('${def.muscles} · ${def.zone}', style: TextStyle(fontSize: 12.5, color: c.muted)),
              const SizedBox(height: 4),
              Text('${e.sets.length} × $plage · repos ${e.rest} s', style: TextStyle(color: t.colorScheme.primary, fontWeight: FontWeight.w700, fontFeatures: tabular)),
            ]),
          ),
        ]),
        if (derniere != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Dernière fois (${jourCourt(derniere.date)}) : ${derniere.log.sets.map((x) => x.kg > 0 ? '${fmtKg(x.kg)} kg × ${x.reps}' : '${x.reps}${e.unit == 's' ? ' s' : ''}').join(', ')}',
              style: TextStyle(fontSize: 13, color: c.muted, fontFeatures: tabular),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: t.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Text('${e.suggKg != null ? (def.inverse ? 'Assistance suggérée : ${fmtKg(e.suggKg!)} kg. ' : 'Charge suggérée : ${fmtKg(e.suggKg!)} kg. ') : ''}${e.suggTexte}', style: const TextStyle(fontSize: 13.5)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExercicePage(id: e.id))),
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('Voir le mouvement et la machine'),
          ),
        ),
        for (var si = 0; si < e.sets.length; si++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 56, child: Text('Série ${si + 1}', style: TextStyle(fontSize: 13, color: c.muted, fontWeight: FontWeight.w600))),
              if (!seul) ...[
                Expanded(
                  child: TextFormField(
                    key: ValueKey('${widget.seanceId}-${widget.index}-$si-kg'),
                    initialValue: e.sets[si].kg == null ? '' : fmtKg(e.sets[si].kg!).replaceAll(' ', ''),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(hintText: 'kg', suffixText: def.inverse ? 'kg aide' : 'kg'),
                    onChanged: (v) {
                      e.sets[si].kg = parseNum(v);
                      st.sauverSansNotifier();
                    },
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('×')),
              ],
              Expanded(
                child: TextFormField(
                  key: ValueKey('${widget.seanceId}-${widget.index}-$si-reps'),
                  initialValue: e.sets[si].reps?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(hintText: e.unit == 's' ? 'sec.' : 'reps', suffixText: e.unit == 's' ? 's' : null),
                  onChanged: (v) {
                    e.sets[si].reps = parseNum(v)?.round();
                    st.sauverSansNotifier();
                  },
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'Série faite',
                isSelected: e.sets[si].fait,
                selectedIcon: const Icon(Icons.check),
                icon: const Icon(Icons.check_box_outline_blank),
                style: e.sets[si].fait ? IconButton.styleFrom(backgroundColor: c.good, foregroundColor: Colors.white) : null,
                onPressed: () {
                  final s = e.sets[si];
                  if (!s.fait && (s.reps ?? 0) <= 0) {
                    message(context, e.unit == 's' ? 'Indique la durée tenue.' : 'Indique le nombre de répétitions.');
                    return;
                  }
                  setState(() => s.fait = !s.fait);
                  st.sauverSansNotifier();
                  if (s.fait) widget.onRepos(e.rest);
                },
              ),
            ]),
          ),
        Row(children: [
          TextButton(
            onPressed: () {
              final last = e.sets.isNotEmpty ? e.sets.last : null;
              e.sets.add(SetDraft(kg: last?.kg));
              st.brouillonModifie();
            },
            child: const Text('+ Série'),
          ),
          if (e.sets.length > 1)
            TextButton(
              onPressed: () {
                e.sets.removeLast();
                st.brouillonModifie();
              },
              child: const Text('− Série'),
            ),
          const Spacer(),
          TextButton(onPressed: widget.onRetirer, child: Text('Retirer', style: TextStyle(color: c.bad))),
        ]),
      ],
    );
  }
}

class _CarteCardio extends StatelessWidget {
  final CardioDraft cardio;
  final double kg;
  final VoidCallback onChange, onRetirer;
  const _CarteCardio({super.key, required this.cardio, required this.kg, required this.onChange, required this.onRetirer});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.read(context);
    final c = Couleurs.of(context);
    void maj() {
      onChange();
      st.sauverSansNotifier();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: cardio.machine,
              decoration: const InputDecoration(labelText: 'Machine'),
              items: [for (final m in machinesCardio) DropdownMenuItem(value: m.id, child: Text(m.nom))],
              onChanged: (v) {
                if (v == null) return;
                cardio.machine = v;
                maj();
              },
            ),
          ),
          IconButton(tooltip: 'Retirer', onPressed: onRetirer, icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextFormField(
              initialValue: '${cardio.minutes}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes'),
              onChanged: (v) {
                cardio.minutes = parseNum(v)?.round() ?? 0;
                maj();
              },
            ),
          ),
          if (cardio.machine == 'tapis') ...[
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: fmt(cardio.vitesse, 1),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'km/h'),
                onChanged: (v) {
                  cardio.vitesse = parseNum(v) ?? 0;
                  maj();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: fmt(cardio.pente, 0),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Pente %'),
                onChanged: (v) {
                  cardio.pente = parseNum(v) ?? 0;
                  maj();
                },
              ),
            ),
          ],
        ]),
        if (cardio.machine != 'tapis') ...[
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [for (var i = 0; i < intensites.length; i++) ButtonSegment(value: i, label: Text(intensites[i]))],
            selected: {cardio.intensite},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              cardio.intensite = s.first;
              maj();
            },
          ),
        ],
        const SizedBox(height: 6),
        Text('≈ ${fmt(cardio.kcal(kg))} kcal', style: TextStyle(fontWeight: FontWeight.w700, color: c.good)),
      ]),
    );
  }
}


/// Date, durée et échauffement de la séance (à remplir pendant ou après la salle).
class _Infos extends StatelessWidget {
  final SeanceDraft d;
  final VoidCallback onChange;
  const _Infos({required this.d, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.read(context);
    final c = Couleurs.of(context);
    final today = st.today;
    final hier = addDays(today, -1);
    void maj() {
      onChange();
      st.sauverSansNotifier();
    }

    return Section(titre: 'Ta séance', children: [
      Row(children: [
        const Text('Quand ?'),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedButton<String>(
            segments: [ButtonSegment(value: today, label: const Text('Aujourd\'hui')), ButtonSegment(value: hier, label: const Text('Hier'))],
            selected: {d.date == hier ? hier : today},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              d.date = s.first;
              maj();
            },
          ),
        ),
      ]),
      const SizedBox(height: 10),
      TextFormField(
        key: ValueKey('${d.id}-duree'),
        initialValue: d.dureeManuelle?.toString() ?? '',
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Durée totale à la salle (min)', hintText: 'ex. 75'),
        onChanged: (v) {
          final n = parseNum(v)?.round();
          d.dureeManuelle = n != null && n > 0 && n < 300 ? n : null;
          maj();
        },
      ),
      Text('Laisse vide si tu remplis pendant la séance : la durée est comptée depuis l\'ouverture.', style: TextStyle(fontSize: 12, color: c.muted)),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('J\'ai fait un échauffement'),
        value: d.echauffementMin > 0,
        onChanged: (v) {
          d.echauffementMin = v ? 10 : 0;
          maj();
        },
      ),
      if (d.echauffementMin > 0)
        Row(children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              key: ValueKey('${d.id}-echauf-${d.echauffementType}'),
              initialValue: d.echauffementType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Échauffement'),
              items: const [
                DropdownMenuItem(value: 'tapis', child: Text('Tapis')),
                DropdownMenuItem(value: 'velo', child: Text('Vélo')),
                DropdownMenuItem(value: 'elliptique', child: Text('Elliptique')),
                DropdownMenuItem(value: 'rameur', child: Text('Rameur')),
                DropdownMenuItem(value: 'mobilite', child: Text('Mobilité, étirements')),
              ],
              onChanged: (v) {
                d.echauffementType = v ?? 'tapis';
                maj();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('${d.id}-echauf-min'),
              initialValue: '${d.echauffementMin}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes'),
              onChanged: (v) {
                final n = parseNum(v)?.round() ?? 0;
                d.echauffementMin = n.clamp(1, 60).toInt();
                maj();
              },
            ),
          ),
        ]),
    ]);
  }
}
