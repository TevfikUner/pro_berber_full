/// Salon veri modeli — Keşfet listesi ve detay sayfası için kullanılır.
class SalonModel {
  final int id;
  final String ad;
  final String? adres;
  final String? telefon;
  final String? fotoUrl;
  final String? sehir;
  final String? ilce;
  final double puan;
  final String? acilisSaati;
  final String? kapanisSaati;

  const SalonModel({
    required this.id,
    required this.ad,
    this.adres,
    this.telefon,
    this.fotoUrl,
    this.sehir,
    this.ilce,
    this.puan = 5.0,
    this.acilisSaati,
    this.kapanisSaati,
  });

  factory SalonModel.fromJson(Map<String, dynamic> j) => SalonModel(
        id: j['id'],
        ad: j['ad'] ?? '',
        adres: j['adres'],
        telefon: j['telefon'],
        fotoUrl: j['foto_url'],
        sehir: j['sehir'],
        ilce: j['ilce'],
        puan: (j['puan'] as num?)?.toDouble() ?? 5.0,
        acilisSaati: j['acilis_saati'],
        kapanisSaati: j['kapanis_saati'],
      );
}
