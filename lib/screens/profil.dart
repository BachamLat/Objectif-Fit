// Onglet Profil : réglages, cibles calculées, pas automatiques, clé Claude, import/export.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../calc.dart';
import '../models.dart';
import '../services/claude_service.dart';
import '../store.dart';
import '../widgets/common.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late TextEditingController _age, _taille, _poids, _debut, _objectif, _cle;
  String _sexe = 'H';
  double _activite = 1.375;
  int _deficit = 500;
  bool _tapisSeul = true;
  String _modele = 'claude-sonnet-5-5';
  bool _init = false;
  bool _voirCle = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _age = TextEditingController();
    _taille = TextEditingController();
    _poids = TextEditingController();
    _debut = TextEditingController();
    _objectif = TextEditingController();
    _cle = TextEditingController();
    _remplir(AppScope.read(context));
    _init = true;
  }

  void _remplir(AppState st) {
    final p = st.profil;
    _age.text = '${p.age}';
    _taille.text = fmt(p.taille, 0);
    _poids.text = fmt(p.poidsDepart, 1);
    _debut.text = p.debut;
    _objectif.text = fmt(st.cible, 1);
    _cle.text = st.cleApi;
    _sexe = p.sexe;
    _activite = activites.any((a) => a.f == p.activite) ? p.activite : 1.375;
    _deficit = [300, 500, 700].contains(p.deficit) ? p.deficit : 500;
    _tapisSeul = p.tapisSeul;
    _modele = modelesClaude.containsKey(st.modele) ? st.modele : 'claude-sonnet-5-5';
  }

  @override
  void dispose() {
    for (final c in [_age, _taille, _poids, _debut, _objectif, _cle]) {
      c.dispose();
    }
    super.dispose();
  }

  void _enregistrer(AppState st) {
    final age = parseNum(_age.text)?.round();
    final taille = parseNum(_taille.text);
    final poids = parseNum(_poids.text);
    final objectif = parseNum(_objectif.text);
    final debut = _debut.text.trim();
    if (age == null || age < 14 || age > 90) return message(context, 'Âge entre 14 et 90 ans.');
    if (taille == null || taille < 140 || taille > 220) return message(context, 'Taille entre 140 et 220 cm.');
    if (poids == null || poids < 40 || poids > 250) return message(context, 'Poids de départ entre 40 et 250 kg.');
    if (objectif == null || objectif < 30 || objectif > 200) return message(context, 'Poids objectif entre 30 et 200 kg.');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(debut)) return message(context, 'Date de début au format AAAA-MM-JJ.');
    st.enregistrerProfil(Profil(
      sexe: _sexe,
      age: age,
      taille: taille,
      poidsDepart: poids,
      debut: debut,
      activite: _activite,
      deficit: _deficit,
      imcCible: st.profil.imcCible,
      poidsObjectif: objectif,
      tapisSeul: _tapisSeul,
      confirme: true,
    ));
    FocusScope.of(context).unfocus();
    message(context, 'Profil enregistré.');
  }

  Future<void> _importer(AppState st) async {
    final ctl = TextEditingController();
    final texte = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Importer des données'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Colle ici le texte copié avec « Copier mes données (JSON) » dans l\'appli web ou dans cette appli.'),
          const SizedBox(height: 10),
          TextField(controller: ctl, minLines: 4, maxLines: 8, decoration: const InputDecoration(hintText: '{ "profil": … }')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('Importer')),
        ],
      ),
    );
    ctl.dispose();
    if (texte == null || texte.trim().isEmpty || !mounted) return;
    try {
      final n = st.importer(texte);
      setState(() => _remplir(st));
      message(context, '$n jours importés.');
    } catch (e) {
      message(context, 'Import impossible : texte non reconnu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final t = Theme.of(context);
    final c = Couleurs.of(context);
    final cib = st.cibles;
    Widget ligne(String a, String b, {bool gras = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(child: Text(a, style: TextStyle(fontWeight: gras ? FontWeight.w800 : FontWeight.w400))),
            Text(b, style: TextStyle(fontWeight: gras ? FontWeight.w800 : FontWeight.w600, fontFeatures: tabular)),
          ]),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const Etiquette('Réglages'),
        const SizedBox(height: 4),
        Text('Profil', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Section(children: [
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('sexe-$_sexe'),
                initialValue: _sexe,
                decoration: const InputDecoration(labelText: 'Sexe'),
                items: const [DropdownMenuItem(value: 'H', child: Text('Homme')), DropdownMenuItem(value: 'F', child: Text('Femme'))],
                onChanged: (v) => setState(() => _sexe = v ?? 'H'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Âge'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _taille, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Taille (cm)'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(controller: _poids, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Poids de départ (kg)'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _debut, decoration: const InputDecoration(labelText: 'Début (AAAA-MM-JJ)'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _objectif, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Poids objectif (kg)'))),
          ]),
          const SizedBox(height: 4),
          Text('Repère : à ta taille, un IMC sous 25 correspond à ${fmt(st.cibleImc, 1)} kg.', style: TextStyle(fontSize: 12.5, color: c.muted)),
          const SizedBox(height: 10),
          DropdownButtonFormField<double>(
            key: ValueKey('act-$_activite'),
            initialValue: _activite,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Activité habituelle'),
            items: [for (final a in activites) DropdownMenuItem(value: a.f, child: Text(a.label, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _activite = v ?? 1.375),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            key: ValueKey('def-$_deficit'),
            initialValue: _deficit,
            decoration: const InputDecoration(labelText: 'Rythme de perte'),
            items: const [
              DropdownMenuItem(value: 300, child: Text('Doux (−300 kcal/jour)')),
              DropdownMenuItem(value: 500, child: Text('Standard (−500 kcal/jour)')),
              DropdownMenuItem(value: 700, child: Text('Soutenu (−700 kcal/jour)')),
            ],
            onChanged: (v) => setState(() => _deficit = v ?? 500),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _tapisSeul,
            onChanged: (v) => setState(() => _tapisSeul = v),
            title: const Text('Ajouter une séance « tapis seul » chaque semaine'),
          ),
          FilledButton(onPressed: () => _enregistrer(st), child: const Text('Enregistrer le profil')),
        ]),
        const SizedBox(height: 14),
        Section(titre: 'Tes cibles', children: [
          ligne('Poids objectif', '${fmt(st.cible, 1)} kg'),
          ligne('Métabolisme de base', '${fmt(cib.bmr)} kcal'),
          ligne('Dépense estimée (maintien)', '${fmt(cib.tdee)} kcal'),
          ligne('Calories par jour', '${fmt(cib.kcal)} kcal', gras: true),
          ligne('Protéines · glucides · lipides', '${cib.prot} · ${cib.gluc} · ${cib.lip} g'),
          ligne('Perte attendue', '≈ ${fmt(cib.perteSem, 2)} kg/semaine'),
          const SizedBox(height: 6),
          Text(
              'Formule de Mifflin-St Jeor, recalculée avec ton dernier poids. Protéines : 1,8 g par kg de poids visé pour garder tes muscles. Si tu ne perds rien en 3 semaines en notant tout, baisse de 150 kcal ; si tu perds plus de 1 kg par semaine, remonte un peu.',
              style: TextStyle(fontSize: 12.5, color: c.muted)),
        ]),
        const SizedBox(height: 14),
        Section(titre: 'Pas automatiques', children: [
          Text(
            st.pasAutoActif
                ? 'Activé : les pas sont lus depuis Health Connect (Android) ou Santé (iPhone) à chaque ouverture de l\'appli.'
                : 'Sur ton Samsung : ouvre Samsung Health > Paramètres > Health Connect et autorise le partage des pas. Puis active la lecture ici.',
          ),
          const SizedBox(height: 8),
          if (!st.pasAutoActif) FilledButton.tonal(onPressed: st.activerPasAuto, child: const Text('Activer la lecture des pas')),
          if (st.pasAutoActif) OutlinedButton(onPressed: st.synchroniserPas, child: Text(st.pasEnCours ? 'Lecture…' : 'Relire les 7 derniers jours')),
          if (st.pasMessage != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(st.pasMessage!, style: TextStyle(color: c.warn))),
        ]),
        const SizedBox(height: 14),
        Section(titre: 'Claude (photos des repas)', children: [
          const Text(
              'L\'analyse des photos et des activités décrites passe par l\'API Claude, avec ta propre clé (compte sur console.anthropic.com, facturé à l\'usage, séparé de l\'abonnement Claude). La clé reste sur ton téléphone.'),
          const SizedBox(height: 10),
          TextField(
            controller: _cle,
            obscureText: !_voirCle,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Clé API (sk-ant-…)',
              suffixIcon: IconButton(icon: Icon(_voirCle ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _voirCle = !_voirCle)),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('mod-$_modele'),
            initialValue: _modele,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Modèle'),
            items: [for (final e in modelesClaude.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _modele = v ?? 'claude-sonnet-5-5'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: () {
              st.setClaude(_cle.text, _modele);
              FocusScope.of(context).unfocus();
              message(context, _cle.text.trim().isEmpty ? 'Clé retirée.' : 'Clé enregistrée.');
            },
            child: const Text('Enregistrer'),
          ),
        ]),
        const SizedBox(height: 14),
        Section(titre: 'Données', children: [
          Text('Tout est enregistré sur ce téléphone uniquement.', style: TextStyle(color: c.muted)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: st.exporter()));
              if (context.mounted) message(context, 'Données copiées (sans ta clé API).');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier mes données (sauvegarde)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => _importer(st), icon: const Icon(Icons.download), label: const Text('Importer (depuis l\'appli web ou une sauvegarde)')),
        ]),
      ],
    );
  }
}
