// Adapte les dossiers android/ et ios/ générés par `flutter create`.
// Usage, à la racine du projet :  dart setup/patch.dart
import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln("Dossier android/ introuvable. Lance d'abord :\n"
        '  flutter create --org com.objectiffit --project-name objectif_fit --platforms android,ios .');
    exit(1);
  }

  // 1. Manifeste Android : Internet, Health Connect (pas), liens externes.
  manifest.writeAsStringSync(File('setup/android/AndroidManifest.xml').readAsStringSync());
  stdout.writeln('✓ AndroidManifest.xml');

  // 2. MainActivity doit hériter de FlutterFragmentActivity (Health Connect).
  final activites = Directory('android/app/src/main')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('MainActivity.kt') || f.path.endsWith('MainActivity.java'));
  for (final f in activites) {
    final txt = f.readAsStringSync();
    final pkg = RegExp(r'^package\s+([\w.]+)', multiLine: true).firstMatch(txt)?.group(1) ?? 'com.objectiffit.objectif_fit';
    if (f.path.endsWith('.kt')) {
      f.writeAsStringSync('package $pkg\n\nimport io.flutter.embedding.android.FlutterFragmentActivity\n\nclass MainActivity : FlutterFragmentActivity()\n');
    } else {
      f.writeAsStringSync('package $pkg;\n\nimport io.flutter.embedding.android.FlutterFragmentActivity;\n\npublic class MainActivity extends FlutterFragmentActivity {}\n');
    }
    stdout.writeln('✓ ${f.path}');
  }

  // 3. minSdk 26 (minimum de Health Connect).
  for (final nom in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final f = File(nom);
    if (!f.existsSync()) continue;
    final kts = nom.endsWith('.kts');
    var s = f.readAsStringSync();
    s = s.replaceAll(RegExp(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion'), kts ? 'minSdk = 26' : 'minSdkVersion 26');
    s = s.replaceAllMapped(RegExp(r'(minSdk(?:Version)?\s*=?\s*)(\d+)'), (m) => int.parse(m[2]!) < 26 ? '${m[1]}26' : m[0]!);
    f.writeAsStringSync(s);
    stdout.writeln('✓ $nom (minSdk 26)');
  }

  // 4. iOS : textes d'autorisation (Santé, appareil photo, photos).
  final plist = File('ios/Runner/Info.plist');
  if (plist.existsSync()) {
    var s = plist.readAsStringSync();
    const ajouts = {
      'NSHealthShareUsageDescription': 'Objectif Fit lit ton nombre de pas pour suivre ton objectif quotidien.',
      'NSHealthUpdateUsageDescription': 'Objectif Fit n\'écrit pas de données dans Santé.',
      'NSCameraUsageDescription': 'Prendre en photo tes repas pour estimer les calories.',
      'NSPhotoLibraryUsageDescription': 'Choisir une photo de repas pour estimer les calories.',
    };
    final buf = StringBuffer();
    ajouts.forEach((k, v) {
      if (!s.contains('<key>$k</key>')) buf.write('\t<key>$k</key>\n\t<string>$v</string>\n');
    });
    final i = s.lastIndexOf('</dict>');
    if (i > 0 && buf.isNotEmpty) {
      s = s.substring(0, i) + buf.toString() + s.substring(i);
      plist.writeAsStringSync(s);
    }
    stdout.writeln('✓ ios/Runner/Info.plist');
  }

  // 5. iOS 15 minimum (exigé par le plugin health).
  final pbx = File('ios/Runner.xcodeproj/project.pbxproj');
  if (pbx.existsSync()) {
    pbx.writeAsStringSync(pbx.readAsStringSync().replaceAll(RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = \d+(\.\d+)?;'), 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;'));
    stdout.writeln('✓ iOS 15.0 minimum');
  }
  final pod = File('ios/Podfile');
  if (pod.existsSync()) {
    pod.writeAsStringSync(pod.readAsStringSync().replaceAll(RegExp(r"#?\s*platform :ios, '[\d.]+'"), "platform :ios, '15.0'"));
    stdout.writeln('✓ ios/Podfile');
  }

  stdout.writeln('\nTerminé. Lance maintenant : flutter run --release  (téléphone branché)\n'
      'ou : flutter build apk --release');
}
