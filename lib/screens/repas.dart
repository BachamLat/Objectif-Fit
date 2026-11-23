// Onglet Repas : photo analysée par Claude, ajout manuel, journal du jour.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../calc.dart';
import '../models.dart';
import '../services/claude_service.dart';
import '../store.dart';
import '../widgets/common.dart';

class RepasPage extends StatefulWidget {
  const RepasPage({super.key});
  @override
  State<RepasPage> createState() => _RepasPageState();
}

class _RepasPageState extends State<RepasPage> {
  String? _date;
  Uint8List? _image;
  final _precisions = TextEditingController();
  final _correction = TextEditingController();
  bool _analyse = false;
  String? _erreur;
  AnalyseRepas? _res;
  final _plat = TextEditingController(), _kcal = TextEditingController(), _p = TextEditingController(), _g = TextEditingController(), _l = TextEditingController();
  final _mNom = TextEditingController(), _mKcal = TextEditingController(), _mP = TextEditingController(), _mG = TextEditingController(), _mL = TextEditingController();

  @override
  void dispose() {
    for (final c in [_precisions, _correction, _plat, _kcal, _p, _g, _l, _mNom, _mKcal, _mP, _mG, _mL]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _choisir(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1280, maxHeight: 1280, imageQuality: 82);
      if (x == null) return;
      final b = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _image = b;
        _res = null;
        _erreur = null;
        _precisions.clear();
        _correction.clear();
      });
    } catch (e) {
      if (mounted) message(context, 'Impossible d\'ouvrir la photo : $e');
    }
  }

  void _majChamps(AnalyseRepas r) {
    _plat.text = r.plat;
    _kcal.text = '${r.kcal}';
    _p.text = '${r.p}';
    _g.text = '${r.g}';
    _l.text = '${r.l}';
  }

  /// Première estimation, ou nouvelle estimation avec la correction tapée par l'utilisateur.
  Future<void> _analyser(AppState st, {bool corriger = false}) async {
    final img = _image;
    if (img == null) return;
    if (corriger && _correction.text.trim().isEmpty) {
      message(context, 'Écris ta précision, par exemple « c\'est un cordon bleu végétarien ».');
      return;
    }
    setState(() {
      _analyse = true;
      _erreur = null;
    });
    try {
      final r = await ClaudeService().analyserRepas(
        cle: st.cleApi,
        modele: st.modele,
        image: img,
        precisions: _precisions.text,
        correction: corriger ? _correction.text : '',
        precedent: corriger ? _res : null,
      );
      if (!mounted) return;
      _majChamps(r);
      if (corriger) _correction.clear();
      setState(() => _res = r);
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _analyse = false);
    }
  }

  Future<void> _ajouterAnalyse(AppState st, String date) async {
    final r = _res;
    if (r == null) return;
    final id = nouvelId();
    String? chemin;
    final dir = st.dossierPhotos;
    final img = _image;
    if (dir != null && img != null) {
      final ext = ClaudeService.typeImage(img) == 'image/png' ? 'png' : 'jpg';
      try {
        final f = File('${dir.path}/$id.$ext');
        await f.writeAsBytes(img);
        chemin = f.path;
      } catch (_) {}
    }
    st.ajouterRepas(
      date,
      Repas(
        id: id,
        heure: date == st.today ? heureMinute(DateTime.now()) : '',
        nom: _plat.text.trim().isEmpty ? 'Repas' : _plat.text.trim(),
        kcal: parseNum(_kcal.text)?.round() ?? r.kcal,
        p: parseNum(_p.text)?.round() ?? r.p,
        g: parseNum(_g.text)?.round() ?? r.g,
        l: parseNum(_l.text)?.round() ?? r.l,
        source: 'photo',
        detail: r.aliments.map((a) => '${a.nom} ${a.quantite}'.trim()).join(', '),
        photo: chemin,
      ),
    );
    if (!mounted) return;
    setState(() {
      _image = null;
      _res = null;
    });
    message(context, 'Repas ajouté.');
  }

  void _ajouterManuel(AppState st, String date) {
    final kcal = parseNum(_mKcal.text);
    if (_mNom.text.trim().isEmpty || kcal == null || kcal < 0) {
      message(context, 'Indique au moins le nom et les calories.');
      return;
    }
    int n(TextEditingController c) => (parseNum(c.text) ?? 0).round();
    st.ajouterRepas(
      date,
      Repas(id: nouvelId(), heure: date == st.today ? heureMinute(DateTime.now()) : '', nom: _mNom.text.trim(), kcal: kcal.round(), p: n(_mP), g: n(_mG), l: n(_mL)),
    );
    for (final c in [_mNom, _mKcal, _mP, _mG, _mL]) {
      c.clear();
    }
    FocusScope.of(context).unfocus();
    message(context, 'Repas ajouté.');
  }

  Widget _champ(TextEditingController c, String label, {bool nombre = true}) => TextField(
        controller: c,
        keyboardType: nombre ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      );

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final t = Theme.of(context);
    final c = Couleurs.of(context);
    final date = _date ?? st.today;
    final j = st.jourSiExiste(date);
    final cib = st.cibles;
    final repas = [...(j?.repas ?? const <Repas>[])]..sort((a, b) => a.heure.compareTo(b.heure));
    final estAujourdhui = date == st.today;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const Etiquette('Journal alimentaire'),
        const SizedBox(height: 4),
        Text('Repas', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Section(children: [
          Row(children: [
            IconButton.outlined(tooltip: 'Jour précédent', onPressed: () => setState(() => _date = addDays(date, -1)), icon: const Icon(Icons.chevron_left)),
            Expanded(child: Text(estAujourdhui ? 'Aujourd\'hui' : dateLongue(date), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            IconButton.outlined(tooltip: 'Jour suivant', onPressed: estAujourdhui ? null : () => setState(() => _date = addDays(date, 1)), icon: const Icon(Icons.chevron_right)),
          ]),
          const SizedBox(height: 10),
          Jauge(label: 'Calories', valeur: j?.kcalMangees ?? 0, max: cib.kcal, unite: 'kcal', alerteSiDepasse: true),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Macro('Protéines', j?.proteines ?? 0, cib.prot)),
            Expanded(child: _Macro('Glucides', j?.glucides ?? 0, cib.gluc)),
            Expanded(child: _Macro('Lipides', j?.lipides ?? 0, cib.lip)),
          ]),
        ]),
        const SizedBox(height: 14),
        Section(titre: 'Analyser une photo', children: [
          if (st.cleApi.isEmpty)
            Text('Pour estimer les calories d\'une photo, ajoute ta clé API Claude dans l\'onglet Profil. En attendant, ajoute tes repas à la main ci-dessous.', style: TextStyle(color: c.muted))
          else if (_image == null) ...[
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: () => _choisir(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: const Text('Photo'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: () => _choisir(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galerie'))),
            ]),
            const SizedBox(height: 6),
            Text('Photo prise du dessus, toute l\'assiette visible.', style: TextStyle(fontSize: 12.5, color: c.muted)),
          ] else ...[
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_image!, height: 220, fit: BoxFit.cover)),
            const SizedBox(height: 10),
            if (_res == null) ...[
              TextField(
                controller: _precisions,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Précisions (facultatif)', hintText: 'ex. 200 g de riz, 1 c. à soupe d\'huile, Coca zéro'),
              ),
              const SizedBox(height: 10),
              if (_analyse) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 6),
                Text('Claude analyse ton assiette… (10 à 40 s)', style: TextStyle(color: c.muted)),
              ] else
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _image = null), child: const Text('Annuler'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(onPressed: () => _analyser(st), child: const Text('Estimer'))),
                ]),
              if (_erreur != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_erreur!, style: TextStyle(color: c.bad))),
            ] else ...[
              _champ(_plat, 'Plat', nombre: false),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _champ(_kcal, 'kcal')),
                const SizedBox(width: 8),
                Expanded(child: _champ(_p, 'Prot. (g)')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _champ(_g, 'Gluc. (g)')),
                const SizedBox(width: 8),
                Expanded(child: _champ(_l, 'Lip. (g)')),
              ]),
              if (_res!.aliments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Etiquette('Aliments détectés'),
                Text('Touche ✕ pour retirer ce que tu n\'as pas mangé : les totaux se mettent à jour.', style: TextStyle(fontSize: 12.5, color: c.muted)),
                for (final a in _res!.aliments)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${a.nom}${a.quantite.isNotEmpty ? '  ${a.quantite}' : ''}'),
                          Text('P ${a.p} g · G ${a.g} g · L ${a.l} g', style: TextStyle(fontSize: 12, color: c.muted)),
                        ]),
                      ),
                      Text('${a.kcal} kcal', style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular)),
                      IconButton(
                        tooltip: 'Retirer ${a.nom}',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _analyse
                            ? null
                            : () => setState(() {
                                  _res!.aliments.remove(a);
                                  _res!.recalculer();
                                  if (_res!.aliments.isEmpty) {
                                    _res!.kcal = 0;
                                    _res!.p = 0;
                                    _res!.g = 0;
                                    _res!.l = 0;
                                  }
                                  _majChamps(_res!);
                                }),
                      ),
                    ]),
                  ),
              ],
              const SizedBox(height: 12),
              const Etiquette('Une erreur ? Précise et je recalcule'),
              const SizedBox(height: 6),
              TextField(
                controller: _correction,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'ex. c\'est un cordon bleu végétarien, je n\'ai pas mangé le pain, 2 cuillères de mayo'),
              ),
              const SizedBox(height: 8),
              if (_analyse) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 6),
                Text('Claude recalcule…', style: TextStyle(color: c.muted)),
              ] else
                OutlinedButton.icon(onPressed: () => _analyser(st, corriger: true), icon: const Icon(Icons.refresh), label: const Text('Recalculer avec cette précision')),
              if (_erreur != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_erreur!, style: TextStyle(color: c.bad))),
              const SizedBox(height: 6),
              Text('Estimation${_res!.confiance.isNotEmpty ? ' (confiance ${_res!.confiance})' : ''} : corrige les chiffres si tu connais les quantités.', style: TextStyle(fontSize: 12.5, color: c.muted)),
              if (_res!.remarque.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: t.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                  child: Text(_res!.remarque),
                ),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() {
                      _image = null;
                      _res = null;
                    }), child: const Text('Annuler'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: () => _ajouterAnalyse(st, date), child: const Text('Ajouter'))),
              ]),
            ],
          ],
        ]),
        const SizedBox(height: 14),
        Section(titre: 'Ajouter à la main', children: [
          _champ(_mNom, 'Repas (ex. sandwich poulet + pomme)', nombre: false),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _champ(_mKcal, 'kcal')),
            const SizedBox(width: 8),
            Expanded(child: _champ(_mP, 'Prot. (g)')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _champ(_mG, 'Gluc. (g)')),
            const SizedBox(width: 8),
            Expanded(child: _champ(_mL, 'Lip. (g)')),
          ]),
          const SizedBox(height: 10),
          FilledButton.tonal(onPressed: () => _ajouterManuel(st, date), child: const Text('Ajouter')),
        ]),
        const SizedBox(height: 14),
        Section(
          titre: estAujourdhui ? 'Mangé aujourd\'hui' : 'Mangé ce jour-là',
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: repas.isEmpty
              ? [Text('Aucun repas noté.', style: TextStyle(color: c.muted))]
              : [
                  for (final r in repas)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: r.photo != null && File(r.photo!).existsSync()
                              ? Image.file(File(r.photo!), fit: BoxFit.cover, cacheWidth: 150)
                              : Container(color: t.colorScheme.surfaceContainerHighest, child: const Icon(Icons.restaurant)),
                        ),
                      ),
                      title: Text(r.nom),
                      subtitle: Text('${r.heure.isNotEmpty ? '${r.heure} · ' : ''}P ${r.p} g · G ${r.g} g · L ${r.l} g'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${fmt(r.kcal)} kcal', style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: tabular)),
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dc) => AlertDialog(
                                title: Text('Supprimer « ${r.nom} » ?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Annuler')),
                                  FilledButton(onPressed: () => Navigator.pop(dc, true), child: const Text('Supprimer')),
                                ],
                              ),
                            );
                            if (ok == true) st.supprimerRepas(date, r.id);
                          },
                        ),
                      ]),
                    ),
                ],
        ),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  final String label;
  final int val, cible;
  const _Macro(this.label, this.val, this.cible);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Etiquette(label),
        Text.rich(TextSpan(children: [
          TextSpan(text: '$val', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFeatures: tabular)),
          TextSpan(text: ' / $cible g', style: TextStyle(color: Couleurs.of(context).muted)),
        ])),
      ]);
}
