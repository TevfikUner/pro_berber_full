import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'providers/randevu_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/degerlendirme_ekrani.dart';

/// Global navigator key — FCM background handler'dan navigate için.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// FCM background/terminated handler (top-level, isolate-safe olmalı)
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background'da sadece OS bildirimini gösterir; navigate açılışta yapılır.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr_TR', null); // Türkçe takvim locale

  // FCM arka plan handler'ı kaydet
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  runApp(const BerberApp());
}

class BerberApp extends StatefulWidget {
  const BerberApp({super.key});

  @override
  State<BerberApp> createState() => _BerberAppState();
}

class _BerberAppState extends State<BerberApp> {
  @override
  void initState() {
    super.initState();
    _fcmAyarla();
  }

  void _fcmAyarla() {
    // --- İzin iste (iOS + Android 13+) ---
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // --- Foreground bildirimi geldiğinde ---
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      if (msg.data['type'] == 'degerlendirme') {
        _degerlendirmeEkraniniAc(msg.data);
      }
    });

    // --- Bildirime tıklanarak uygulama açıldığında (background → foreground) ---
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      if (msg.data['type'] == 'degerlendirme') {
        _degerlendirmeEkraniniAc(msg.data);
      }
    });

    // --- Uygulama tamamen kapalıyken bildirime tıklanarak açıldığında ---
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null && msg.data['type'] == 'degerlendirme') {
        // Splash bitmeden navigate etme — 2sn bekle
        Future.delayed(const Duration(seconds: 2), () {
          _degerlendirmeEkraniniAc(msg.data);
        });
      }
    });
  }

  void _degerlendirmeEkraniniAc(Map<String, dynamic> data) {
    final randevuId = int.tryParse(data['randevu_id']?.toString() ?? '');
    if (randevuId == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => DegerlendirmeEkrani(
          randevuId: randevuId,
          berberAdi: data['berber_adi']?.toString() ?? 'Berber',
          berberFotoUrl: data['berber_foto_url']?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RandevuProvider()),
      ],
      child: MaterialApp(
        title: 'Pro Berber',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
      ),
    );
  }
}