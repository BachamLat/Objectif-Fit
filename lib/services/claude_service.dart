// Appels à l'API Claude : estimation d'un repas en photo et d'une activité décrite librement.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ClaudeException implements Exception {
  final String message;
  const ClaudeException(this.message);
  @override
  String toString() => message;
}

class AlimentEstime {
  String nom, quantite;
  int kcal, p, g, l;
  AlimentEstime({required this.nom, this.quantite = '', required this.kcal, this.p = 0, this.g = 0, this.l = 0});
  Map<String, dynamic> toJson() => {'nom': nom, 'quantite': quantite, 'kcal': kcal, 'proteines': p, 'glucides': g, 'lipides': l};
}

class AnalyseRepas {
  String plat, confiance, remarque;
  int kcal, p, g, l;
  final List<AlimentEstime> aliments;
  AnalyseRepas({required this.plat, required this.kcal, required this.p, required this.g, required this.l, required this.aliments, this.confiance = '', this.remarque = ''});

  /// Recalcule les totaux à partir des aliments (après en avoir retiré un, par exemple).
  void recalculer() {
    if (aliments.isEmpty) return;
    kcal = aliments.fold(0, (t, a) => t + a.kcal);
    p = aliments.fold(0, (t, a) => t + a.p);
    g = aliments.fold(0, (t, a) => t + a.g);
    l = aliments.fold(0, (t, a) => t + a.l);
  }

  Map<String, dynamic> toJson() => {
        'plat': plat,
        'aliments': aliments.map((a) => a.toJson()).toList(),
        'kcal': kcal,
        'proteines': p,
        'glucides': g,
        'lipides': l,
      };
}

class EstimationActivite {
  final String nom;
  final int minutes, kcal;
  final String detail;
  const EstimationActivite(this.nom, this.minutes, this.kcal, this.detail);
}

const modelesClaude = {
  'claude-sonnet-5-5': 'Sonnet 5.5 (meilleure précision)',
  'claude-haiku-5-5': 'Haiku 5.5 (plus rapide, moins cher)',
};

class ClaudeService {
  static const _url = 'https://api.anthropic.com/v1/messages';

  Future<Map<String, dynamic>> _demander(String cle, String modele, List<Map<String, dynamic>> contenu, {int maxTokens = 1500}) async {
    if (cle.trim().isEmpty) throw const ClaudeException('Ajoute ta clé API Claude dans le profil.');
    http.Response r;
    try {
      r = await http
          .post(
            Uri.parse(_url),
            headers: {
              'x-api-key': cle.trim(),
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': modele,
              'max_tokens': maxTokens,
              'messages': [
                {'role': 'user', 'content': contenu}
              ],
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw const ClaudeException('Claude met trop de temps à répondre. Réessaie.');
    } catch (_) {
      throw const ClaudeException('Pas de connexion Internet ?');
    }
    final corps = utf8.decode(r.bodyBytes);
    if (r.statusCode != 200) {
      String detail = '';
      try {
        final e = jsonDecode(corps);
        if (e is Map && e['error'] is Map) detail = (e['error'] as Map)['message']?.toString() ?? '';
      } catch (_) {}
      switch (r.statusCode) {
        case 401:
          throw const ClaudeException('Clé API refusée : vérifie-la dans le profil.');
        case 402:
        case 403:
          throw ClaudeException('Accès refusé ou crédit épuisé. $detail');
        case 429:
          throw const ClaudeException('Trop de demandes : réessaie dans une minute.');
        case 529:
          throw const ClaudeException('Claude est surchargé : réessaie dans un instant.');
        default:
          throw ClaudeException('Erreur ${r.statusCode}. $detail');
      }
    }
    final data = jsonDecode(corps);
    final blocs = data is Map && data['content'] is List ? data['content'] as List : const [];
    final texte = blocs.whereType<Map>().where((b) => b['type'] == 'text').map((b) => b['text']?.toString() ?? '').join('\n');
    return extraireJson(texte);
  }

  static Map<String, dynamic> extraireJson(String t) {
    final a = t.indexOf('{'), b = t.lastIndexOf('}');
    if (a < 0 || b <= a) throw const ClaudeException('Réponse illisible, réessaie.');
    try {
      final v = jsonDecode(t.substring(a, b + 1));
      if (v is Map) return Map<String, dynamic>.from(v);
    } catch (_) {}
    throw const ClaudeException('Réponse illisible, réessaie.');
  }

  static String typeImage(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length > 12 && b[0] == 0x52 && b[1] == 0x49 && b[8] == 0x57 && b[9] == 0x45) return 'image/webp';
    if (b.length > 3 && b[0] == 0x47 && b[1] == 0x49) return 'image/gif';
    return 'image/jpeg';
  }

  static int _n(dynamic v) => v is num ? v.round() : (int.tryParse(v?.toString() ?? '') ?? 0);

  /// Estime un repas en photo. Avec [correction] et [precedent], refait l'estimation en tenant compte
  /// de ce que l'utilisateur précise (ex. « c'est un cordon bleu végétarien »).
  Future<AnalyseRepas> analyserRepas({
    required String cle,
    required String modele,
    required Uint8List image,
    String precisions = '',
    String correction = '',
    AnalyseRepas? precedent,
  }) async {
    final q = (String x) => x.replaceAll('"', "'");
    final buf = StringBuffer()
      ..writeln('Tu es nutritionniste. Estime les apports du repas visible sur la photo, pour le journal alimentaire d\'une personne qui veut perdre du poids.')
      ..writeln('Précisions de l\'utilisateur (peuvent être vides) : "${q(precisions)}"');
    if (precedent != null && correction.trim().isNotEmpty) {
      buf
        ..writeln('Ta première estimation était : ${jsonEncode(precedent.toJson())}')
        ..writeln('L\'utilisateur corrige : "${q(correction)}"')
        ..writeln('Refais l\'estimation complète en appliquant cette correction : elle prime sur ce que tu crois voir (aliment différent, version végétarienne, quantité, aliment non mangé…).');
    }
    buf
      ..writeln('Règles : portions réalistes et visibles (assiette standard d\'environ 26 cm), compte l\'huile de cuisson et les sauces probables, n\'invente pas d\'aliments invisibles sauf s\'ils sont cités. '
          'Chaque aliment a ses propres calories et macros ; les totaux sont la somme des aliments. Si la photo ne montre pas de nourriture, mets kcal à 0 et explique-le dans remarque.')
      ..writeln('Réponds uniquement avec un objet JSON en français, de cette forme :')
      ..write('{"plat":"nom court","aliments":[{"nom":"riz blanc cuit","quantite":"~180 g","kcal":230,"proteines":5,"glucides":50,"lipides":1}],'
          '"kcal":650,"proteines":35,"glucides":70,"lipides":22,"confiance":"faible|moyenne|élevée","remarque":"un conseil utile pour perdre du poids avec ce repas"}');
    final j = await _demander(cle, modele, [
      {
        'type': 'image',
        'source': {'type': 'base64', 'media_type': typeImage(image), 'data': base64Encode(image)},
      },
      {'type': 'text', 'text': buf.toString()},
    ], maxTokens: 2000);
    final alims = <AlimentEstime>[];
    if (j['aliments'] is List) {
      for (final a in (j['aliments'] as List).whereType<Map>().take(15)) {
        alims.add(AlimentEstime(
          nom: a['nom']?.toString() ?? '',
          quantite: a['quantite']?.toString() ?? '',
          kcal: _n(a['kcal']),
          p: _n(a['proteines']),
          g: _n(a['glucides']),
          l: _n(a['lipides']),
        ));
      }
    }
    final r = AnalyseRepas(
      plat: (j['plat'] ?? 'Repas').toString(),
      kcal: _n(j['kcal']),
      p: _n(j['proteines']),
      g: _n(j['glucides']),
      l: _n(j['lipides']),
      aliments: alims,
      confiance: (j['confiance'] ?? '').toString(),
      remarque: (j['remarque'] ?? '').toString(),
    );
    r.recalculer();
    return r;
  }

  Future<EstimationActivite> estimerActivite({required String cle, required String modele, required String description, required double poids}) async {
    final prompt = 'Estime la dépense énergétique brute (kcal) de cette activité physique pour une personne de ${poids.toStringAsFixed(0)} kg, '
        'en te basant sur les valeurs MET du Compendium des activités physiques.\n'
        'Activité décrite : "${description.replaceAll('"', "'")}"\n'
        'Si la durée n\'est pas donnée, suppose 30 minutes et dis-le dans detail.\n'
        'Réponds uniquement avec un objet JSON : {"nom":"nom court de l\'activité","minutes":45,"kcal":420,"detail":"MET retenu et hypothèse en une phrase"}';
    final j = await _demander(cle, modele, [
      {'type': 'text', 'text': prompt}
    ], maxTokens: 600);
    return EstimationActivite((j['nom'] ?? 'Activité').toString(), _n(j['minutes']), _n(j['kcal']), (j['detail'] ?? '').toString());
  }
}
