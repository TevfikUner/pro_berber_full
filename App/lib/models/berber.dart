class Berber {
  final int id;
  final String ad;
  final String soyad;
  final String uzmanlik;
  final String? fotoUrl;
  final double puan;
  // 1. BURASI KRİTİK: Değişkenleri burada tanımlıyoruz
  final String? whatsappNo;
  final String? instagramUsername;

  const Berber({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.uzmanlik,
    this.fotoUrl,
    required this.puan,
    // 2. BURASI: Constructor içinde değişkenleri bağlıyoruz
    this.whatsappNo,
    this.instagramUsername,
  });

  factory Berber.fromJson(Map<String, dynamic> j) => Berber(
        id: j['id'],
        ad: j['ad'],
        soyad: j['soyad'],
        uzmanlik: j['uzmanlik'],
        fotoUrl: j['foto_url'],
        puan: (j['puan'] as num).toDouble(),
        // 3. BURASI: JSON'dan gelen veriyi modele aktarıyoruz
        whatsappNo: j['whatsapp_no'],
        instagramUsername: j['instagram_username'],
      );
}