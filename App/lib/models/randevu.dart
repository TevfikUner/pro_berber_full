class Randevu {
  final int id;
  final int berberId;
  final String berber;
  final String salonAd;
  final List<String> hizmetler;
  final String tarih;
  final String saat;
  final String durum;
  final double toplamFiyat;
  final int? puan;
  final String? yorum;

  const Randevu({
    required this.id,
    required this.berberId,
    required this.berber,
    required this.salonAd,
    required this.hizmetler,
    required this.tarih,
    required this.saat,
    required this.durum,
    required this.toplamFiyat,
    this.puan,
    this.yorum,
  });

  factory Randevu.fromJson(Map<String, dynamic> j) => Randevu(
    id: j['id'],
    berberId: j['berber_id'] ?? 0,
    berber: j['berber'] ?? '',
    salonAd: j['salon_ad'] ?? '',
    hizmetler: List<String>.from(j['hizmetler'] ?? []),
    tarih: j['tarih'] ?? '',
    saat: j['saat'] ?? '',
    durum: j['durum'] ?? '',
    toplamFiyat: (j['toplam_fiyat'] as num).toDouble(),
    puan: j['puan'],
    yorum: j['yorum'],
  );
}