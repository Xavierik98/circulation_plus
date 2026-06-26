import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/sync_service.dart';

/// Handler des messages Firebase reçus en arrière-plan.
/// Doit être une fonction top-level (pas une méthode de classe).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé par le plugin — pas besoin de ré-appeler initializeApp().
  // Les données de la notification sont dans message.data et message.notification.
  debugPrint('[FCM] Message reçu en arrière-plan : ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  // Initialisation non-bloquante : l'app fonctionne même si Firebase n'est
  // pas encore configuré (google-services.json placeholder).
  // Firebase désactivé sur web (config mobile uniquement)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('[FCM] Firebase non initialisé : $e');
    }
  }

  // ── Sync hors-ligne ────────────────────────────────────────────────────────
  // Démarre le service de synchronisation : les PV créés sans internet
  // seront envoyés automatiquement dès le retour du réseau.
  SyncService.instance.init();

  // ── Orientation & style système ───────────────────────────────────────────
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF060B18),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: CirculationPlusApp()));
}
