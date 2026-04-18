class Randevu {
  final int id;
  final String berber;
  final List<String> hizmetler;
  final String tarih;
  final String saat;
  final String durum;
  final double toplamFiyat;

  const Randevu({
    required this.id,
    required this.berber,
    required this.hizmetler,
    required this.tarih,
    required this.saat,
    required this.durum,
    required this.toplamFiyat,
  });

  factory Randevu.fromJson(Map<String, dynamic> j) => Randevu(
    id: j['id'],
    berber: j['berber'] ?? '',
    hizmetler: List<String>.from(j['hizmetler'] ?? []),
    tarih: j['tarih'] ?? '',
    saat: j['saat'] ?? '',
    durum: j['durum'] ?? '',
    toplamFiyat: (j['toplam_fiyat'] as num).toDouble(),
  );
}
