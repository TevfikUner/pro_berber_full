import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../models/hizmet.dart';
import '../models/berber.dart';
import '../models/randevu.dart';

class ApiService {
  static final String _base = AppConfig.baseUrl;

  // ── Yardımcı ─────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return {'Content-Type': 'application/json', 'x-firebase-uid': uid};
  }

  static String _buildQuery(String path, Map<String, dynamic> params) {
    final parts = params.entries.expand((e) {
      if (e.value is List) {
        return (e.value as List)
            .map((v) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(v.toString())}');
      }
      if (e.value != null) {
        return ['${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}'];
      }
      return <String>[];
    });
    final q = parts.join('&');
    return q.isEmpty ? '$_base$path' : '$_base$path?$q';
  }

  // ── Dükkan ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDukkanBilgisi() async {
    final res = await http.get(Uri.parse('$_base/dukkan/')).timeout(AppConfig.timeout);
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    throw Exception('Dükkan bilgisi yüklenemedi');
  }

  // ── İstatistik (ana sayfa / salon bazlı) ───────────────────
  static Future<Map<String, dynamic>> getIstatistik({int? salonId}) async {
    String url = '$_base/randevular/istatistik';
    if (salonId != null) url += '?salon_id=$salonId';
    final res = await http.get(Uri.parse(url)).timeout(AppConfig.timeout);
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    return {'bugunki_randevu': 0, 'musait_slot_sayisi': 0};
  }

  // ── Hizmetler ────────────────────────────────────────────
  static Future<List<Hizmet>> getHizmetler() async {
    final res = await http.get(Uri.parse('$_base/hizmetler/')).timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      final List data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Hizmet.fromJson(e)).toList();
    }
    throw Exception('Hizmetler yüklenemedi');
  }

  // ── Berberler ────────────────────────────────────────────
  static Future<List<Berber>> getBerberler() async {
    final res = await http.get(Uri.parse('$_base/berberler/')).timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      final List data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Berber.fromJson(e)).toList();
    }
    throw Exception('Berberler yüklenemedi');
  }

  // ── Takvim ───────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMusaitTakvim({int? berberId}) async {
    final url = berberId != null
        ? '$_base/randevular/musait-takvim?berber_id=$berberId'
        : '$_base/randevular/musait-takvim';
    final res = await http.get(Uri.parse(url)).timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      final List data = json.decode(utf8.decode(res.bodyBytes));
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Takvim yüklenemedi');
  }

  // ── Dolu Saatler ─────────────────────────────────────────
  static Future<List<String>> getDoluSaatler(int berberId, String tarih) async {
    final res = await http
        .get(Uri.parse('$_base/randevular/dolu-saatler/$berberId?tarih=$tarih'))
        .timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      final List data = json.decode(utf8.decode(res.bodyBytes));
      return data.cast<String>();
    }
    return [];
  }

  // ── Randevu Oluştur ──────────────────────────────────────
  static Future<Map<String, dynamic>> randevuOlustur({
    required int berberId,
    required String saat,
    required String tarih,
    required List<int> hizmetIds,
    required String ad,
    required String soyad,
    required String telefon,
  }) async {
    final headers = await _authHeaders();
    final url = _buildQuery('/randevular/olustur', {
      'berber_id': berberId,
      'saat': saat,
      'tarih': tarih,
      'hizmet_ids': hizmetIds,
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
    });

    final http.Response res;
    try {
      res = await http.post(Uri.parse(url), headers: headers).timeout(AppConfig.timeout);
    } on Exception catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }

    final rawBody = utf8.decode(res.bodyBytes);

    // JSON parse güvenli — HTML 500/502 sayfaları için koruma
    Map<String, dynamic> body;
    try {
      final decoded = json.decode(rawBody);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      } else {
        throw Exception('Sunucu beklenmeyen yanıt döndürdü: $rawBody');
      }
    } catch (_) {
      // JSON değilse raw body'yi göster (HTML hata sayfası vs)
      throw Exception('Sunucu hatası (${res.statusCode}): $rawBody');
    }

    if (res.statusCode == 200) return body;
    throw Exception(body['detail']?.toString() ?? 'Randevu oluşturulamadı (${res.statusCode})');
  }


  // ── Randevularım ─────────────────────────────────────────
  static Future<List<Randevu>> getRandevularim() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$_base/randevular/benim-randevularim'), headers: headers)
        .timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      final List data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Randevu.fromJson(e)).toList();
    }
    throw Exception('Randevularınız yüklenemedi');
  }

  // ── Randevu Sil ──────────────────────────────────────────
  static Future<void> randevuSil(int randevuId) async {
    final headers = await _authHeaders();
    final res = await http
        .delete(Uri.parse('$_base/randevular/sil/$randevuId'), headers: headers)
        .timeout(AppConfig.timeout);
    if (res.statusCode != 200) {
      final body = json.decode(utf8.decode(res.bodyBytes));
      throw Exception(body['detail']?.toString() ?? 'Silinemedi');
    }
  }

  // ── Müşteri Kayıt ────────────────────────────────────────
  static Future<void> musteriEkle({
    required String ad,
    required String soyad,
    required String telefon,
    required String firebaseUid,
  }) async {
    final url = _buildQuery('/musteriler/ekle', {
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'firebase_uid': firebaseUid,
    });
    await http.post(Uri.parse(url)).timeout(AppConfig.timeout);
  }

  // ── Değerlendirme Ekle ───────────────────────────────────
  static Future<Map<String, dynamic>> degerlendirmeEkle({
    required int randevuId,
    required int puan,
    String? yorum,
  }) async {
    final headers = await _authHeaders();
    final url = _buildQuery('/degerlendirmeler/ekle', {
      'randevu_id': randevuId,
      'puan': puan,
      if (yorum != null && yorum.isNotEmpty) 'yorum': yorum,
    });
    final res = await http
        .post(Uri.parse(url), headers: headers)
        .timeout(AppConfig.timeout);
    final body = json.decode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200) return body as Map<String, dynamic>;
    throw Exception((body as Map)['detail']?.toString() ?? 'Değerlendirme gönderilemedi');
  }
  // ... senin önceki kodların (örneğin degerlendirme vs.)

  // --- KULLANICI PROFİLİNİ GETİR (Bunu içeri aldık!) ---
  static Future<Map<String, dynamic>?> profilGetir() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final response = await http.get(
        Uri.parse('$_base/randevular/profil'),
        headers: {
          'Content-Type': 'application/json',
          'x-firebase-uid': uid,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print("Profil getirme hatası: $e");
      return null;
    }
  }
  // --- KULLANICI PROFİLİNİ GÜNCELLE ---
  static Future<void> profilGuncelle({
    required String ad,
    required String soyad,
    required String telefon,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Kullanıcı girişi bulunamadı.");

    final response = await http.post(
      Uri.parse('$_base/randevular/profil/guncelle'),
      headers: {
        'Content-Type': 'application/json',
        'x-firebase-uid': uid,
      },
      body: json.encode({
        'ad': ad,
        'soyad': soyad,
        'telefon': telefon,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Profil güncellenirken bir hata oluştu.");
    }
  }

  // ── İşletme Kayıt ────────────────────────────────────────
  static Future<void> isletmeKayit({
    required String ad,
    required String soyad,
    required String telefon,
    required String email,
    required String isletmeAdi,
    required String firebaseUid,
  }) async {
    final url = _buildQuery('/isletmeler/kayit', {
      'ad': ad,
      'soyad': soyad,
      'telefon': telefon,
      'email': email,
      'isletme_adi': isletmeAdi,
      'firebase_uid': firebaseUid,
    });
    final res = await http.post(Uri.parse(url)).timeout(AppConfig.timeout);
    if (res.statusCode != 200) {
      final body = json.decode(utf8.decode(res.bodyBytes));
      throw Exception(body['detail']?.toString() ?? 'İşletme kaydı başarısız');
    }
  }

  // ── Keşfet: Salon Listesi ────────────────────────────────
  static Future<List<Map<String, dynamic>>> getSalonlar({
    String? sehir,
    String? ilce,
  }) async {
    final params = <String, dynamic>{};
    if (sehir != null) params['sehir'] = sehir;
    if (ilce != null) params['ilce'] = ilce;
    final url = _buildQuery('/dukkan/salonlar', params);
    final res = await http.get(Uri.parse(url)).timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      final List data = json.decode(utf8.decode(res.bodyBytes));
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Keşfet: Salon Detay ──────────────────────────────────
  static Future<Map<String, dynamic>> getSalonDetay(int salonId) async {
    final res = await http
        .get(Uri.parse('$_base/dukkan/salon/$salonId'))
        .timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Salon bilgileri yüklenemedi');
  }

  // ── Keşfet: Filtre Seçenekleri ───────────────────────────
  static Future<Map<String, dynamic>> getFiltreler() async {
    final res = await http
        .get(Uri.parse('$_base/dukkan/filtreler'))
        .timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    return {'sehirler': [], 'ilceler': {}};
  }

  // ── Favori Berber Toggle (Çoklu Favori) ────────────────────
  static Future<Map<String, dynamic>> favoriToggle(int berberId) async {
    final headers = await _authHeaders();
    final url = _buildQuery('/randevular/profil/favori-toggle', {'berber_id': berberId});
    final res = await http.post(Uri.parse(url), headers: headers).timeout(AppConfig.timeout);
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    throw Exception('Favori güncellenemedi');
  }

  // ── Favori Berber Listesi ─────────────────────────────────
  static Future<List<Map<String, dynamic>>> favorileriGetir() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_base/randevular/profil/favoriler'),
      headers: headers,
    ).timeout(AppConfig.timeout);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(utf8.decode(res.bodyBytes)));
    }
    return [];
  }
}
