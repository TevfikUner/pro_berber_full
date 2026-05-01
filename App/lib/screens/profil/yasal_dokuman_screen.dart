import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Yasal dokümanları uygulama içinden gösteren ekran
class YasalDokumanScreen extends StatelessWidget {
  final String baslik;
  final String icerik;

  const YasalDokumanScreen({super.key, required this.baslik, required this.icerik});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: const BackButton(color: AppTheme.gold),
        title: Text(baslik,
            style: GoogleFonts.playfairDisplay(
                color: AppTheme.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          icerik,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.85),
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ),
    );
  }

  // ─── Gizlilik Politikası ───────────────────
  static const String gizlilikPolitikasi = '''
GİZLİLİK POLİTİKASI

Son Güncelleme: 01.05.2026

Premium Berber uygulaması olarak, kullanıcılarımızın gizliliğine büyük önem veriyoruz. Bu gizlilik politikası, kişisel verilerinizin nasıl toplandığını, kullanıldığını ve korunduğunu açıklamaktadır.

1. TOPLANAN BİLGİLER

1.1 Kişisel Bilgiler
• Ad ve soyad
• Telefon numarası
• E-posta adresi
• Profil fotoğrafı (isteğe bağlı)

1.2 Kullanım Verileri
• Randevu geçmişi
• Favori berber seçimleri
• Değerlendirme ve yorumlar

1.3 Konum Verileri
• Yakındaki berberleri bulmak amacıyla cihazınızın konumu (yalnızca izin verdiğinizde)

2. VERİLERİN KULLANIM AMACI

Toplanan veriler aşağıdaki amaçlarla kullanılmaktadır:
• Randevu oluşturma ve yönetme
• Kullanıcı hesabı oluşturma ve doğrulama
• Hizmet kalitesinin artırılması
• Bildirim gönderme (randevu hatırlatma vb.)
• Konum bazlı berber önerme

3. VERİ GÜVENLİĞİ

Kişisel verileriniz, endüstri standardı güvenlik önlemleriyle korunmaktadır:
• SSL/TLS şifreleme
• Firebase Authentication ile güvenli kimlik doğrulama
• Düzenli güvenlik denetimleri

4. VERİ PAYLAŞIMI

Kişisel verileriniz üçüncü taraflarla paylaşılmaz. Yalnızca:
• Yasal zorunluluk durumlarında yetkili makamlarla
• Hizmet sağlayıcılarımızla (Firebase, sunucu hizmetleri) teknik gereksinimler doğrultusunda paylaşılır.

5. KULLANICI HAKLARI

Kullanıcılar aşağıdaki haklara sahiptir:
• Verilerine erişim talep etme
• Verilerinin düzeltilmesini isteme
• Verilerinin silinmesini talep etme
• Veri işlenmesine itiraz etme

6. İLETİŞİM

Gizlilik politikamız hakkında sorularınız için:
E-posta: premiumbarber@gmail.com
''';

  // ─── KVKK Aydınlatma Metni ─────────────────
  static const String kvkkMetni = '''
KİŞİSEL VERİLERİN KORUNMASI KANUNU (KVKK) AYDINLATMA METNİ

Son Güncelleme: 01.05.2026

6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") kapsamında, Premium Berber olarak kişisel verilerinizin korunmasına büyük önem vermekteyiz.

1. VERİ SORUMLUSU

Premium Berber uygulaması olarak, kişisel verilerinizin işlenmesinde veri sorumlusu sıfatıyla hareket etmekteyiz.

2. KİŞİSEL VERİLERİN İŞLENME AMACI

Kişisel verileriniz aşağıdaki amaçlarla işlenmektedir:
• Üyelik kaydı oluşturulması ve yönetimi
• Randevu hizmetlerinin sunulması
• Müşteri memnuniyetinin ölçülmesi (değerlendirme sistemi)
• İletişim faaliyetlerinin yürütülmesi
• Bilgi güvenliği süreçlerinin yönetimi
• Hukuki yükümlülüklerin yerine getirilmesi

3. KİŞİSEL VERİLERİN AKTARILMASI

Toplanan kişisel verileriniz, KVKK'nın 8. ve 9. maddesinde belirtilen şartlara uygun olarak:
• İlgili kamu kurum ve kuruluşlarına
• İş ortaklarımıza (bulut hizmet sağlayıcıları)
aktarılabilmektedir.

4. KİŞİSEL VERİLERİN TOPLANMA YÖNTEMİ VE HUKUKİ SEBEBİ

Kişisel verileriniz;
• Mobil uygulama üzerinden elektronik ortamda
• Açık rıza
• Sözleşmenin ifası
• Meşru menfaat
hukuki sebeplerine dayanılarak toplanmaktadır.

5. KVKK KAPSAMINDA HAKLARINIZ

KVKK'nın 11. maddesi uyarınca aşağıdaki haklara sahipsiniz:
a) Kişisel verilerinizin işlenip işlenmediğini öğrenme
b) İşlenmişse buna ilişkin bilgi talep etme
c) İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme
d) Aktarıldığı üçüncü kişileri bilme
e) Eksik veya yanlış işlenmiş olması hâlinde düzeltilmesini isteme
f) KVKK'nın 7. maddesinde öngörülen şartlar çerçevesinde silinmesini isteme
g) Aktarıldığı üçüncü kişilere bildirilmesini isteme
h) İşlenen verilerin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme
ı) Kanuna aykırı olarak işlenmesi sebebiyle zarara uğramanız hâlinde zararın giderilmesini talep etme

6. BAŞVURU

Haklarınıza ilişkin taleplerinizi premiumbarber@gmail.com adresine iletebilirsiniz.
''';

  // ─── Kullanım Koşulları ────────────────────
  static const String kullanimKosullari = '''
KULLANIM KOŞULLARI

Son Güncelleme: 01.05.2026

Premium Berber uygulamasını kullanarak aşağıdaki koşulları kabul etmiş sayılırsınız.

1. HİZMET TANIMI

Premium Berber, kullanıcıların berber salonlarından online randevu almasını sağlayan bir mobil uygulamadır. Uygulama aşağıdaki hizmetleri sunar:
• Berber salonu keşfetme ve filtreleme
• Online randevu oluşturma
• Randevu yönetimi (görüntüleme, iptal)
• Berber değerlendirme ve puanlama

2. HESAP OLUŞTURMA

• Uygulamayı kullanmak için geçerli bir e-posta adresi ile hesap oluşturmanız gerekmektedir.
• Hesap bilgilerinizin doğruluğundan siz sorumlusunuz.
• Hesabınızın güvenliğinden siz sorumlusunuz.

3. RANDEVU KURALLARI

• Randevular en az 30 dakika öncesinden iptal edilmelidir.
• Randevuya gelmeme durumunda salon tarafından değerlendirme yapılabilir.
• Randevu saatleri salonun çalışma saatleriyle sınırlıdır.

4. DEĞERLENDİRME SİSTEMİ

• Tamamlanan randevular için değerlendirme yapabilirsiniz.
• Değerlendirmeler 1-5 yıldız arasında puanlama ve isteğe bağlı yorum içerir.
• Hakaret, küfür veya uygunsuz içerik barındıran yorumlar kaldırılabilir.

5. YASAK DAVRANIŞLAR

Aşağıdaki davranışlar kesinlikle yasaktır:
• Sahte hesap oluşturma
• Sistemi manipüle etme girişimleri
• Sahte randevu oluşturma
• Diğer kullanıcılara karşı uygunsuz davranış

6. FİKRİ MÜLKİYET

• Uygulama içeriği, tasarım ve kod Premium Berber'e aittir.
• İzinsiz kopyalama, dağıtım veya değiştirme yasaktır.

7. SORUMLULUK SINIRLANDIRMASI

• Premium Berber, salon hizmetlerinin kalitesinden doğrudan sorumlu değildir.
• Teknik arızalardan kaynaklanan geçici hizmet kesintilerinden dolayı sorumluluk kabul edilmez.

8. DEĞİŞİKLİKLER

Bu kullanım koşulları önceden bildirimde bulunmaksızın güncellenebilir. Güncel koşullar uygulama üzerinden erişilebilir.

9. İLETİŞİM

Sorularınız için: premiumbarber@gmail.com
''';
}
