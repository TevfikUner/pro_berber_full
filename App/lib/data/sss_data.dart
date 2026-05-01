/// Sıkça Sorulan Sorular verileri
class SSS {
  final String soru;
  final String cevap;
  const SSS({required this.soru, required this.cevap});

  static const List<SSS> sorular = [
    SSS(
      soru: 'Nasıl randevu alabilirim?',
      cevap: 'Ana sayfadaki "Randevu Al" butonuna tıklayarak hizmet, personel, tarih ve saat seçerek kolayca randevu alabilirsiniz.',
    ),
    SSS(
      soru: 'Randevumu nasıl iptal edebilirim?',
      cevap: 'Randevularım sekmesinden ilgili randevuyu bulup "Randevuyu İptal Et" butonuna basarak iptal edebilirsiniz.',
    ),
    SSS(
      soru: 'Favori berber nasıl seçilir?',
      cevap: 'Randevu geçmişinizden daha önce hizmet aldığınız bir berberi favori olarak seçebilirsiniz. Ana sayfadaki "Favori Berberim" kartından değiştirebilirsiniz.',
    ),
    SSS(
      soru: 'Profil bilgilerimi nasıl güncellerim?',
      cevap: 'Profil sekmesinde "Kişisel Bilgiler" bölümündeki "Düzenle" butonuna basarak ad, soyad ve telefon bilgilerinizi güncelleyebilirsiniz.',
    ),
    SSS(
      soru: 'Şifremi unuttum ne yapmalıyım?',
      cevap: 'Giriş ekranındaki "Şifremi Unuttum" bağlantısına tıklayın. E-posta adresinize şifre sıfırlama linki gönderilecektir.',
    ),
    SSS(
      soru: 'Uygulama hangi şehirlerde aktif?',
      cevap: 'Premium Berber, Türkiye genelinde tüm 81 ilde aktiftir. Keşfet sekmesinden şehir ve ilçe filtreleyerek bölgenizdeki berberleri bulabilirsiniz.',
    ),
    SSS(
      soru: 'İşletme sahibi olarak nasıl kayıt olabilirim?',
      cevap: 'Giriş ekranında "İşletme Sahibi" seçeneğini tıklayarak başvuru formunu doldurun. Başvurunuz incelendikten sonra hesabınız aktifleştirilecektir.',
    ),
    SSS(
      soru: 'Değerlendirme nasıl yapılır?',
      cevap: 'Tamamlanan randevularınızdan "Hizmeti Değerlendir" butonuna basarak puan ve yorum bırakabilirsiniz.',
    ),
  ];
}
