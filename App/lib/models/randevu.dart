class Randevu {
  final int id;
  final String berber;
  final List<String> hizmetler;
  final String tarih;
  final String saat;
  final String durum;
  final double toplamFiyat;
  // --- YENİ ALANLAR ---
  final int? puan;   // Puan 1-5 arası olabilir veya henüz verilmemişse null gelir
  final String? yorum;

  const Randevu({
    required this.id,
    required this.berber,
    required this.hizmetler,
    required this.tarih,
    required this.saat,
    required this.durum,
    required this.toplamFiyat,
    this.puan,   // Bu alanlar opsiyonel olduğu için süslü parantez içinde
    this.yorum,
  });

  factory Randevu.fromJson(Map<String, dynamic> j) => Randevu(
    id: j['id'],
    berber: j['berber'] ?? '',
    hizmetler: List<String>.from(j['hizmetler'] ?? []),
    tarih: j['tarih'] ?? '',
    saat: j['saat'] ?? '',
    durum: j['durum'] ?? '',
    toplamFiyat: (j['toplam_fiyat'] as num).toDouble(),
    // Backend'den gelen yeni kolonları modele mühürlüyoruz
    puan: j['puan'],
    yorum: j['yorum'],
  );
}