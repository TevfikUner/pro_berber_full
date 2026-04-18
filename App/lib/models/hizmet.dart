class Hizmet {
  final int id;
  final String ad;
  final double fiyat;
  final int sure; // dakika
  final String? aciklama;

  const Hizmet({
    required this.id,
    required this.ad,
    required this.fiyat,
    required this.sure,
    this.aciklama,
  });

  factory Hizmet.fromJson(Map<String, dynamic> j) => Hizmet(
    id: j['id'],
    ad: j['ad'],
    fiyat: (j['fiyat'] as num).toDouble(),
    sure: j['sure'],
    aciklama: j['aciklama'],
  );

  @override
  bool operator ==(Object other) => other is Hizmet && other.id == id;
  @override
  int get hashCode => id.hashCode;
}
