import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'providers/randevu_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/degerlendirme_ekrani.dart';
import 'screens/main_screen.dart'; // Eklendi

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr_TR', null);
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
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((msg) {
      if (msg.data['type'] == 'degerlendirme') _degerlendirmeEkraniniAc(msg.data);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      if (msg.data['type'] == 'degerlendirme') _degerlendirmeEkraniniAc(msg.data);
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
        title: 'Premium Berber',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        navigatorKey: navigatorKey,
        home: const SplashScreen(), // Başlangıç her zaman Splash
      ),
    );
  }
}