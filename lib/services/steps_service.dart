// Lecture automatique des pas : Health Connect (Android) ou Santé / HealthKit (iPhone).
import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../calc.dart';

class StepsResult {
  final Map<String, int> pas;
  final String? erreur;
  const StepsResult(this.pas, [this.erreur]);
}

class StepsService {
  final Health _health = Health();
  bool _configure = false;

  Future<void> _init() async {
    if (_configure) return;
    await _health.configure();
    _configure = true;
  }

  /// null si tout va bien, sinon un message à afficher.
  Future<String?> verifierDisponibilite() async {
    try {
      await _init();
      if (Platform.isAndroid) {
        final st = await _health.getHealthConnectSdkStatus();
        if (st != HealthConnectSdkStatus.sdkAvailable) {
          return 'Health Connect est absent ou doit être mis à jour sur ce téléphone.';
        }
      }
      return null;
    } catch (e) {
      return 'Lecture des pas indisponible : $e';
    }
  }

  Future<void> installerHealthConnect() async {
    await _init();
    await _health.installHealthConnect();
  }

  Future<bool> autoriser() async {
    await _init();
    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
    }
    final types = [HealthDataType.STEPS];
    final perms = [HealthDataAccess.READ];
    final deja = await _health.hasPermissions(types, permissions: perms);
    if (deja == true) return true;
    return _health.requestAuthorization(types, permissions: perms);
  }

  /// Total des pas pour chacun des [jours] derniers jours (aujourd'hui inclus).
  Future<StepsResult> lirePas({int jours = 7}) async {
    try {
      await _init();
      final now = DateTime.now();
      final out = <String, int>{};
      for (var i = 0; i < jours; i++) {
        final debut = DateTime(now.year, now.month, now.day - i);
        final fin = i == 0 ? now : DateTime(now.year, now.month, now.day - i + 1);
        final v = await _health.getTotalStepsInInterval(debut, fin);
        if (v != null) out[ymd(debut)] = v;
      }
      return StepsResult(out);
    } catch (e) {
      return StepsResult(const {}, 'Erreur de lecture des pas : $e');
    }
  }
}
