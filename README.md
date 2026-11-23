# Objectif Fit — appli Android / iPhone

Suivi de perte de poids : poids et objectif en kg, repas en photo (calories estimées par Claude, corrigeables), pas lus automatiquement, séances de salle notées exercice par exercice en choisissant les machines en image, échauffement et cardio, dépense en kcal de chaque activité et historique.

Tout est enregistré sur le téléphone : chaque personne qui installe l'appli a ses propres données.

---

## Obtenir l'APK

À chaque modification envoyée sur ce dépôt, GitHub compile l'appli automatiquement (onglet **Actions**, traitement « Construire l'APK Android », 8 à 15 min).

1. Ouvre le dernier traitement terminé (coche verte), puis en bas **Artifacts > objectif-fit-apk**. Tu télécharges un `.zip` qui contient `app-release.apk`.
2. Sur le téléphone Android : ouvre le zip dans **Mes fichiers**, extrais-le, touche `app-release.apk`. Autorise l'installation depuis cette source si le téléphone le demande. Si Play Protect affiche un avertissement, choisis **Installer quand même** (l'appli n'est simplement pas publiée sur le Play Store).
3. Pour la partager (à ta sœur par exemple), envoie-lui simplement le fichier `app-release.apk`.

## Compiler sur un PC (facultatif)

1. Installe Flutter (<https://docs.flutter.dev/get-started/install>) et Android Studio. Vérifie avec `flutter doctor`.
2. Dans un terminal ouvert dans le dossier du projet :

   ```bash
   flutter create --org com.objectiffit --project-name objectif_fit --platforms android,ios .
   dart setup/patch.dart
   flutter pub get
   flutter build apk --release
   ```

   `setup/patch.dart` ajoute ce qu'il faut pour Health Connect (autorisations, `minSdk 26`, `FlutterFragmentActivity`) et Internet.

## iPhone

Il faut un Mac avec Xcode : fais la compilation sur PC ci-dessus sur le Mac, puis ouvre `ios/Runner.xcworkspace`, **Runner > Signing & Capabilities > + Capability > HealthKit**, choisis ton identifiant Apple dans **Team** et lance sur l'iPhone branché.

---

## Premier lancement

1. **Profil** : vérifie l'âge, la taille, le poids de départ, ton **poids objectif** et l'activité, puis **Enregistrer**. Les cibles (calories, protéines) se recalculent avec ton dernier poids.
2. **Pas automatiques** (Samsung) : dans **Samsung Health**, ouvre les paramètres puis **Health Connect** et autorise le partage des pas. Dans l'appli, **Lire mes pas automatiquement** : Health Connect te demande l'autorisation. Les pas des 7 derniers jours sont relus à chaque ouverture.
3. **Photos des repas** : l'analyse passe par l'API Claude avec ta propre clé.
   - Crée une clé sur <https://console.anthropic.com> (**API Keys**) et ajoute un peu de crédit (facturation à l'usage, séparée de l'abonnement Claude).
   - Colle-la dans **Profil > Claude**. Elle reste sur le téléphone et n'est jamais incluse dans l'export.
   - Ordre de grandeur : moins d'un centime par photo avec Sonnet 5.5, encore moins avec Haiku 5.5.
   - Sans clé, tu peux toujours saisir les repas à la main.
4. **Reprendre tes données de l'appli web** : dans l'appli web (Cap IMC 25), onglet Profil, **Copier mes données (JSON)**, puis ici **Profil > Importer** et colle le texte.

## Comment sont estimées les calories dépensées

- **Musculation** : MET × poids × durée hors cardio (MET 3,5 bras, 3,8 dos, 5 jambes ; Compendium des activités physiques).
- **Tapis** : équation de l'ACSM à partir de la vitesse et de la pente (la plus précise pour la marche inclinée).
- **Vélo, elliptique, rameur, escalier, autres activités** : MET selon l'intensité choisie.
- **Description libre** (« 1 h de foot à 5 ») : estimation par Claude si une clé est enregistrée.

Ce sont des dépenses brutes estimées, à ±20 %. Elles servent à suivre ton activité. Elles ne s'ajoutent pas à ta cible de calories, qui tient déjà compte de ton niveau d'activité.

## Organisation du code

| Fichier | Rôle |
|---|---|
| `lib/calc.dart` | IMC, cibles caloriques, tendance du poids, kcal des activités, formats français |
| `lib/programme.dart` | Bibliothèque de machines, phases, split, charges suggérées |
| `lib/models.dart`, `lib/store.dart` | Données, sauvegarde JSON locale, import/export |
| `lib/services/` | Pas (Health Connect / HealthKit) et API Claude |
| `lib/widgets/anim_solver.dart`, `exercise_anim.dart`, `anim_data.dart` | Schémas animés des machines |
| `lib/screens/` | Écrans Accueil, Repas, Salle, Séance, Programme, Profil |
| `outils/anim/` | Définition des animations (`anim.json`) et prévisualisation (`preview.py`) |

Pour modifier une animation : édite `outils/anim/anim.json`, vérifie le rendu avec `python3 outils/anim/preview.py outils/anim/anim.json apercu.png`, puis régénère `lib/widgets/anim_data.dart` avec `python3 outils/anim/generer_dart.py`.
