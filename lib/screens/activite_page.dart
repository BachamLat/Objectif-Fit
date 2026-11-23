// Ajout d'une activité hors programme : estimation par MET, ou par Claude à partir d'une description.
import 'package:flutter/material.dart';

import '../calc.dart';
import '../models.dart';
import '../services/claude_service.dart';
import '../store.dart';
import '../widgets/common.dart';

class ActivitePage extends StatefulWidget {
  const ActivitePage({super.key});
  @override
  State<ActivitePage> createState() => _ActivitePageState();
}

class _ActivitePageState extends State<ActivitePage> {
  bool _hier = false;
  int _act = 0;
  int _intensite = 1;
  int _minutes = 45;
  final _desc = TextEditingController();
  bool _enCours = false;
  EstimationActivite? _estimation;
  String? _erreur;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _demanderClaude(AppState st) async {
    if (_desc.text.trim().length < 4) {
      message(context, 'Décris l\'activité, avec sa durée.');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
      _estimation = null;
    });
    try {
      final e = await ClaudeService().estimerActivite(cle: st.cleApi, modele: st.modele, description: _desc.text.trim(), poids: st.poidsActuel);
      if (!mounted) return;
      setState(() => _estimation = e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = Couleurs.of(context);
    final kg = st.poidsActuel;
    final a = autresActivites[_act];
    final met = a.met[_intensite];
    final kcal = kcalMet(met, kg, _minutes).round();
    final date = _hier ? addDays(st.today, -1) : st.today;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une activité')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, label: Text('Aujourd\'hui')), ButtonSegment(value: true, label: Text('Hier'))],
            selected: {_hier},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _hier = s.first),
          ),
          const SizedBox(height: 14),
          Section(titre: 'Choisir dans la liste', children: [
            DropdownButtonFormField<int>(
              initialValue: _act,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Activité'),
              items: [for (var i = 0; i < autresActivites.length; i++) DropdownMenuItem(value: i, child: Text(autresActivites[i].nom))],
              onChanged: (v) => setState(() => _act = v ?? 0),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: [for (var i = 0; i < intensites.length; i++) ButtonSegment(value: i, label: Text(intensites[i]))],
              selected: {_intensite},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _intensite = s.first),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Durée'),
              Expanded(
                child: Slider(
                  value: _minutes.toDouble(),
                  min: 5,
                  max: 180,
                  divisions: 35,
                  label: '$_minutes min',
                  onChanged: (v) => setState(() => _minutes = v.round()),
                ),
              ),
              SizedBox(width: 64, child: Text('$_minutes min', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 6),
            Text('≈ ${fmt(kcal)} kcal', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.good, fontFeatures: tabular)),
            Text('MET ${fmt(met, 1)} × ${fmt(kg, 1)} kg × ${fmt(_minutes / 60, 2)} h', style: TextStyle(fontSize: 12.5, color: c.muted)),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                st.ajouterActivite(date, ActiviteLog(id: nouvelId(), nom: '${a.nom} (${intensites[_intensite].toLowerCase()})', minutes: _minutes, kcal: kcal, source: 'met'));
                Navigator.of(context).pop();
                message(context, 'Activité enregistrée : ≈ ${fmt(kcal)} kcal.');
              },
              child: const Text('Enregistrer'),
            ),
          ]),
          const SizedBox(height: 14),
          Section(titre: 'Ou décris-la à Claude', children: [
            if (st.cleApi.isEmpty)
              Text('Ajoute ta clé API Claude dans le profil pour décrire librement une activité.', style: TextStyle(color: c.muted))
            else ...[
              TextField(
                controller: _desc,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'ex. 1 h de foot à 5 en salle, beaucoup de sprints'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(onPressed: _enCours ? null : () => _demanderClaude(st), child: Text(_enCours ? 'Claude calcule…' : 'Estimer avec Claude')),
              if (_erreur != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_erreur!, style: TextStyle(color: c.bad))),
              if (_estimation != null) ...[
                const SizedBox(height: 10),
                Text('${_estimation!.nom} · ${_estimation!.minutes} min', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('≈ ${fmt(_estimation!.kcal)} kcal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.good)),
                if (_estimation!.detail.isNotEmpty) Text(_estimation!.detail, style: TextStyle(fontSize: 12.5, color: c.muted)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    final e = _estimation!;
                    st.ajouterActivite(date, ActiviteLog(id: nouvelId(), nom: e.nom, minutes: e.minutes, kcal: e.kcal, source: 'claude', detail: e.detail));
                    Navigator.of(context).pop();
                    message(context, 'Activité enregistrée : ≈ ${fmt(e.kcal)} kcal.');
                  },
                  child: const Text('Enregistrer cette estimation'),
                ),
              ],
            ],
          ]),
        ],
      ),
    );
  }
}
