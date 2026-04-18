import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/berber_desen.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../randevu_al/randevu_flow.dart';
import 'randevularim_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dukkan;
  Map<String, dynamic>? _istatistik;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final results = await Future.wait([
        ApiService.getDukkanBilgisi(),
        ApiService.getIstatistik(),
      ]);
      if (mounted) {
        setState(() {
          _dukkan = results[0];
          _istatistik = results[1];
          _yukleniyor = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  // ── Telefon: dialer açar, numara otomatik dolu gelir ─────
  Future<void> _arama() async {
    final tel = (_dukkan?['iletisim']?['tel'] ?? '').replaceAll(' ', '');
    final uri = Uri.parse('tel:$tel');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  // ── Haritada Gör: Google Maps'te koordinatı göster ────────
  Future<void> _haritadaGor() async {
    final lat = _dukkan?['koordinatlar']?['lat'] ?? '0';
    final lng = _dukkan?['koordinatlar']?['lng'] ?? '0';
    // Önce native geo: URI (Google Maps apk varsa açar)
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(Pro+Berber)');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      // Fallback: web
      await launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── Yol Tarifi Al: Navigation mod, kullanıcı konumundan ────
  Future<void> _yolTarifi() async {
    final lat = _dukkan?['koordinatlar']?['lat'] ?? '0';
    final lng = _dukkan?['koordinatlar']?['lng'] ?? '0';
    // Google Navigation URI (uygulama açıksa konum izni ister)
    final navUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(navUri)) {
      await launchUrl(navUri);
    } else {
      // Fallback: Google Maps Dir URL
      await launchUrl(
        Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── E-posta: Gmail'de alıcı alanı dolu gelir ─────────────
  Future<void> _mailAc() async {
    final email = _dukkan?['iletisim']?['email'] ?? 'info@proberber.com';
    final uri = Uri.parse('mailto:$email');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          const BerberDesenWidget(),
          CustomScrollView(
            slivers: [
              // ── App Bar ─────────────────────────────────
              SliverAppBar(
                backgroundColor: AppTheme.black,
                elevation: 0,
                pinned: true,
                title: Text('PRO BERBER',
                    style: GoogleFonts.playfairDisplay(
                        color: AppTheme.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: AppTheme.gold),
                    tooltip: 'Randevularım',
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RandevularimScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
                    onPressed: () async {
                      await AuthService.cikisYap();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                  ),
                ],
              ),

              // ── Hero Bölümü ─────────────────────────────
              SliverToBoxAdapter(child: _HeroSection(
                istatistik: _istatistik,
                yukleniyor: _yukleniyor,
                onRandevuAl: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RandevuFlow())),
              )),

              // ── Bize Ulaşın ─────────────────────────────
              SliverToBoxAdapter(child: _BizeUlasinSection(
                dukkan: _dukkan,
                onArama: _arama,
                onHaritadaGor: _haritadaGor,
                onYolTarifi: _yolTarifi,
                onMail: _mailAc,
              )),

              // ── Çalışma Saatleri ────────────────────────
              SliverToBoxAdapter(child: _CalismaSection(dukkan: _dukkan)),

              // ── SSS ─────────────────────────────────────
              const SliverToBoxAdapter(child: _SSSSection()),

              // ── Footer ──────────────────────────────────
              SliverToBoxAdapter(child: _FooterSection(
                  dukkanAd: _dukkan?['isletme'] ?? 'Pro Berber')),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// HERO SECTION
// ════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final Map<String, dynamic>? istatistik;
  final bool yukleniyor;
  final VoidCallback onRandevuAl;

  const _HeroSection(
      {required this.istatistik, required this.yukleniyor, required this.onRandevuAl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        children: [
          // Dekoratif çizgi
          Row(children: [
            Expanded(child: Divider(color: AppTheme.gold.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.content_cut, color: AppTheme.gold.withOpacity(0.5), size: 18),
            ),
            Expanded(child: Divider(color: AppTheme.gold.withOpacity(0.3))),
          ]),
          const SizedBox(height: 28),
          Text('Stilinizi\nBize Bırakın',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2)),
          const SizedBox(height: 12),
          Text('Profesyonel berber deneyimi için\nhemen randevu alın',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
          const SizedBox(height: 36),
          // Randevu Al butonu
          GestureDetector(
            onTap: onRandevuAl,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.black, size: 20),
                  const SizedBox(width: 10),
                  Text('Randevu Al',
                      style: GoogleFonts.inter(
                          color: AppTheme.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          // İstatistik kartları
          Row(children: [
            Expanded(child: _StatKart(
              label: 'Bugünkü\nRandevu',
              value: yukleniyor ? '...' : '${istatistik?["bugunku_randevu"] ?? 0}',
              icon: Icons.people_alt_outlined,
            )),
            const SizedBox(width: 12),
            Expanded(child: _BosKontenjanKart(
              value: yukleniyor ? '...' : '${istatistik?["musait_slot_sayisi"] ?? 0}',
              sifirMi: !yukleniyor && (istatistik?['musait_slot_sayisi'] ?? 1) == 0,
              onRandevuAl: onRandevuAl,
            )),
          ]),
        ],
      ),
    );
  }
}

class _StatKart extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _StatKart(
      {required this.label,
      required this.value,
      required this.icon,
      this.valueColor = AppTheme.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.playfairDisplay(
                        color: valueColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Bugünkü boş kontenjan kartı — 0 olunca alternatif gün butonu gösterir
class _BosKontenjanKart extends StatelessWidget {
  final String value;
  final bool sifirMi;
  final VoidCallback onRandevuAl;

  const _BosKontenjanKart({
    required this.value,
    required this.sifirMi,
    required this.onRandevuAl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sifirMi
              ? AppTheme.error.withOpacity(0.4)
              : AppTheme.gold.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available,
                  color: sifirMi ? AppTheme.error : AppTheme.success, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: GoogleFonts.playfairDisplay(
                            color: sifirMi ? AppTheme.error : AppTheme.success,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    Text('Bugünkü Boş\nKontenjan',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          // Kontenjan doluysa alternatif gün butonu
          if (sifirMi) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRandevuAl,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Başka Bir Güne\nRandevu Oluştur',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppTheme.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// BİZE ULAŞIN
// ════════════════════════════════════════════════
class _BizeUlasinSection extends StatelessWidget {
  final Map<String, dynamic>? dukkan;
  final VoidCallback onArama;
  final VoidCallback onHaritadaGor; // Haritada göster
  final VoidCallback onYolTarifi;   // Navigasyon balaştır
  final VoidCallback onMail;

  const _BizeUlasinSection({
    required this.dukkan,
    required this.onArama,
    required this.onHaritadaGor,
    required this.onYolTarifi,
    required this.onMail,
  });

  @override
  Widget build(BuildContext context) {
    final instagram = dukkan?['iletisim']?['instagram'];
    return _SectionWrapper(
      title: 'Bize Ulaşın',
      child: Column(
        children: [
          // ── Konum kartı (adres gösterimi) ─────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppTheme.gold.withOpacity(0.1),
                  AppTheme.gold.withOpacity(0.04),
                ],
              ),
              border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.location_on, color: AppTheme.gold, size: 32),
                const SizedBox(height: 8),
                Text(
                  dukkan?['adres'] ?? 'Adres yükleniyor...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 14),
                // İki harita butonu yan yana
                Row(children: [
                  Expanded(
                    child: _HaritaButon(
                      icon: Icons.map_outlined,
                      label: 'Haritada Gör',
                      onTap: onHaritadaGor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HaritaButon(
                      icon: Icons.navigation_outlined,
                      label: 'Yol Tarifi Al',
                      onTap: onYolTarifi,
                      filled: true,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Telefon ve E-posta ────────────────────────────
          Row(children: [
            Expanded(
              child: _IletisimButon(
                icon: Icons.phone,
                label: dukkan?['iletisim']?['tel'] ?? 'Telefon',
                onTap: onArama,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _IletisimButon(
                icon: Icons.email_outlined,
                label: dukkan?['iletisim']?['email'] ?? 'E-posta',
                onTap: onMail,
              ),
            ),
          ]),

          // ── Instagram ────────────────────────────────────
          if (instagram != null) ...[
            const SizedBox(height: 12),
            _IletisimButon(
              icon: Icons.camera_alt_outlined,
              label: '@$instagram',
              onTap: () async {
                // Önce Instagram uygulamasını dene
                final appUri =
                    Uri.parse('instagram://user?username=$instagram');
                if (await canLaunchUrl(appUri)) {
                  await launchUrl(appUri);
                } else {
                  // Fallback: tarayıcıda aç
                  await launchUrl(
                    Uri.parse('https://instagram.com/$instagram'),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

// Harita kartı içindeki küçük buton
class _HaritaButon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _HaritaButon(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: filled ? AppTheme.goldGradient : null,
          color: filled ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(color: AppTheme.gold.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: filled ? AppTheme.black : AppTheme.gold, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    color: filled ? AppTheme.black : AppTheme.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _IletisimButon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IletisimButon(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.gold, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// ÇALIŞMA SAATLERİ
// ════════════════════════════════════════════════
class _CalismaSection extends StatelessWidget {
  final Map<String, dynamic>? dukkan;
  const _CalismaSection({required this.dukkan});

  @override
  Widget build(BuildContext context) {
    final saatler = dukkan?['mesai_saatleri'];
    return _SectionWrapper(
      title: 'Çalışma Saatleri',
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            _SaatSatir(
              gun: 'Pazartesi – Cumartesi',
              saat: saatler?['pazartesi_cumartesi'] ?? '10:00 – 22:00',
              isFirst: true,
            ),
            Divider(color: AppTheme.gold.withOpacity(0.1), height: 1),
            _SaatSatir(
              gun: 'Pazar',
              saat: saatler?['pazar'] ?? '10:00 – 17:00',
            ),
          ],
        ),
      ),
    );
  }
}

class _SaatSatir extends StatelessWidget {
  final String gun;
  final String saat;
  final bool isFirst;

  const _SaatSatir({required this.gun, required this.saat, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.access_time, color: AppTheme.gold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(gun,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
          ),
          Text(saat,
              style: GoogleFonts.inter(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// SSS
// ════════════════════════════════════════════════
class _SSSSection extends StatelessWidget {
  const _SSSSection();

  static const _sorular = [
    {
      'soru': 'Aynı anda birden fazla hizmet (Örn: Saç ve Sakal) için randevu alabilir miyim?',
      'cevap':
          'Kesinlikle! Uygulamamız üzerinden randevu oluştururken dilediğin kadar hizmeti (Saç Kesimi, Sakal, Cilt Bakımı vb.) aynı anda seçebilirsin. Akıllı sistemimiz, seçtiğin işlemlerin toplam süresini otomatik hesaplayarak sana sadece tam olarak uygun olan boş saatleri gösterir.',
    },
    {
      'soru': 'Aldığım randevuyu sonradan iptal edebilir miyim?',
      'cevap':
          'Tabii ki, "Randevularım" sekmesinden tek tıkla randevunu silebilirsin. Ancak sistemimizde adil bir randevu yönetimi için son 30 dakika kuralı bulunmaktadır. Randevu saatine 30 dakikadan az bir süre kaldıysa iptal işlemi yapılamaz. İptal ettiğinde telefonuna anında bildirim gelecektir.',
    },
    {
      'soru': 'Randevumu aylar öncesinden aldım, fiyatlar değişirse hangi tutarı ödeyeceğim?',
      'cevap':
          'Hiç merak etme, sistemimizde "Fiyat Mühürleme" özelliği bulunur. Sen randevuyu onayladığın an ekranda gördüğün toplam fiyat sistemimize kilitlenir. Sonradan fiyat listesi güncellense bile, sen randevu aldığın günkü fiyattan ödeme yaparsın.',
    },
    {
      'soru': 'Randevu onayı nasıl gelir, onaylandığını nasıl anlarım?',
      'cevap':
          'Randevunu oluşturduğunda seni hiç bekletmeyiz! İşlemin tamamlandığı an, sistemimiz telefonuna doğrudan bir bildirim (Push Notification) göndererek "Randevun onaylandı" mesajını iletir. Ayrıca alt menüdeki "Randevularım" sekmesine girerek yaklaşan tüm randevularının durumunu (onaylandı, tamamlandı vb.) canlı olarak takip edebilirsin.',
    },
    {
      'soru': 'Tıraş olmak istediğim belirli bir berberi kendim seçebilir miyim?',
      'cevap':
          'Kesinlikle! Bizde "Sıradaki gelsin" mantığı yok. Randevu alma adımına geçtiğinde, salonumuzdaki tüm ustalarımızı ve uzmanlık alanlarını görebilirsin. Kendi favori berberini seçtiğinde, sistem sana sadece o berberin müsait olduğu saatleri gösterir. Böylece her zaman alıştığın ellerde tıraş olabilirsin!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Sık Sorulan Sorular',
      child: Column(
        children: _sorular.map((s) => _SSSItem(
          soru: s['soru']!,
          cevap: s['cevap']!,
        )).toList(),
      ),
    );
  }
}

class _SSSItem extends StatelessWidget {
  final String soru;
  final String cevap;
  const _SSSItem({required this.soru, required this.cevap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.gold,
          collapsedIconColor: AppTheme.textSecondary,
          title: Text(soru,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(cevap,
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// FOOTER
// ════════════════════════════════════════════════
class _FooterSection extends StatelessWidget {
  final String dukkanAd;
  const _FooterSection({required this.dukkanAd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: const Color(0xFF080808),
      child: Column(
        children: [
          Divider(color: AppTheme.gold.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Icon(Icons.content_cut, color: AppTheme.gold, size: 28),
          const SizedBox(height: 12),
          Text(dukkanAd.toUpperCase(),
              style: GoogleFonts.playfairDisplay(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3)),
          const SizedBox(height: 8),
          Text('© ${DateTime.now().year} Tüm hakları saklıdır.',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// ORTAK BÖLÜM SARMALAYICI
// ════════════════════════════════════════════════
class _SectionWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 4, height: 20,
                decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
