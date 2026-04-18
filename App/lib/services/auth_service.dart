import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Giriş yap
  static Future<UserCredential> girisYap(String email, String sifre) async {
    return _auth.signInWithEmailAndPassword(email: email, password: sifre);
  }

  /// Kayıt ol + backend'e müşteri ekle
  static Future<void> kayitOl({
    required String email,
    required String sifre,
    required String ad,
    required String soyad,
    required String telefon,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: sifre);
    final uid = cred.user!.uid;
    await ApiService.musteriEkle(
      ad: ad,
      soyad: soyad,
      telefon: telefon,
      firebaseUid: uid,
    );
  }

  /// Şifre sıfırlama e-postası gönder
  static Future<void> sifreSifirla(String email) async {
    // YENİ EKLENEN KISIM: Maili göndermeden hemen önce dili Türkçe yapıyoruz
    await _auth.setLanguageCode("tr");

    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Çıkış yap
  static Future<void> cikisYap() => _auth.signOut();
}