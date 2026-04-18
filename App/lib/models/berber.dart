class Berber {
  final int id;
  final String ad;
  final String soyad;
  final String uzmanlik;
  final String? fotoUrl;
  final double puan;

  const Berber({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.uzmanlik,
    this.fotoUrl,
    required this.puan,
  });

  factory Berber.fromJson(Map<String, dynamic> j) => Berber(
    id: j['id'],
    ad: j['ad'],
    soyad: j['soyad'],
    uzmanlik: j['uzmanlik'],
    fotoUrl: j['foto_url'],
    puan: (j['puan'] as num).toDouble(),
  );

  String get adSoyad => '$ad $soyad';
}
