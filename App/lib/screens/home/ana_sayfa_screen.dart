import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/berber_desen.dart';
import '../../services/api_service.dart';
import '../randevu_al/randevu_flow.dart';

/// Yeni Ana Sayfa — Selamlama, Favori Berber, Hızlı İşlemler, İstatistikler
class AnaSayfaScreen extends StatefulWidget {
  const AnaSayfaScreen({super.key});

  @override
  State<AnaSayfaScreen> createState() => _AnaSayfaScreenState();
}

class _AnaSayfaScreenState extends State<AnaSayfaScreen> {
  Map<String, dynamic>? _profil;
  Map<String, dynamic>? _istatistik;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    // Her API çağrısını ayrı try-catch'e alarak
    // birinin hata vermesi diğerini engellemesin
    Map<String, dynamic>? profil;
    Map<String, dynamic>? istatistik;

    try {
      profil = await ApiService.profilGetir();
    } catch (e) {
      debugPrint('Profil yükleme hatası: $e');
    }

    try {
      istatistik = await ApiService.getIstatistik();
    } catch (e) {
      debugPrint('İstatistik yükleme hatası: $e');
    }

    if (mounted) {
      setState(() {
        _profil = profil;
        _istatistik = istatistik;
        _yukleniyor = false;
      });
    }
  }

  String get _musteriAdi {
    if (_profil == null) return '';
    final ad = _profil!['ad'] ?? '';
    return ad.toString().isNotEmpty ? ad.toString() : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          const BerberDesenWidget(),
          RefreshIndicator(
            color: AppTheme.gold,
            onRefresh: _yukle,
            child: CustomScrollView(
              slivers: [
                // ── AppBar ──────────────────────────────────
                SliverAppBar(
                  backgroundColor: AppTheme.black,
                  elevation: 0,
                  pinned: true,
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'PRO BERBER',
                    style: GoogleFonts.playfairDisplay(
                      color: AppTheme.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                // ── Selamlama Mesajı ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selamlama
                        if (_musteriAdi.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text('✂️', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sıhhatler Olsun, $_musteriAdi!',
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bugün kendine güzel bir randevu al',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Hoş Geldin! ✂️',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Favori Berberim Kartı ────────────────────
                SliverToBoxAdapter(
                  child: _FavoriBerberKart(
                    profil: _profil,
                    yukleniyor: _yukleniyor,
                  ),
                ),

                // ── Hızlı İşlem Butonları ───────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Hızlı İşlemler',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Randevu Al (büyük buton)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RandevuFlow()),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.gold.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: AppTheme.black, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Randevu Al',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // İstatistik kartları
                        Row(
                          children: [
                            Expanded(
                              child: _IstatistikKart(
                                icon: Icons.people_alt_outlined,
                                label: 'Bugünkü\nRandevu',
                                value: _yukleniyor
                                    ? '...'
                                    : '${_istatistik?["bugunku_randevu"] ?? 0}',
                                valueColor: AppTheme.gold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BosKontenjanKart(
                                value: _yukleniyor
                                    ? '...'
                                    : '${_istatistik?["musait_slot_sayisi"] ?? 0}',
                                sifirMi: !_yukleniyor &&
                                    (_istatistik?['musait_slot_sayisi'] ?? 1) ==
                                        0,
                                onRandevuAl: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RandevuFlow()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Alt boşluk ──────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FAVORİ BERBER KARTI
// ═══════════════════════════════════════════════
class _FavoriBerberKart extends StatelessWidget {
  final Map<String, dynamic>? profil;
  final bool yukleniyor;

  const _FavoriBerberKart({required this.profil, required this.yukleniyor});

  @override
  Widget build(BuildContext context) {
    final favoriBerberId = profil?['favori_berber_id'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.gold.withOpacity(0.1),
              AppTheme.gold.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded,
                    color: AppTheme.gold.withOpacity(0.7), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Favori Berberim',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (yukleniyor)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                      color: AppTheme.gold, strokeWidth: 2),
                ),
              )
            else if (favoriBerberId == null)
              // Favori seçilmemiş
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.gold.withOpacity(0.1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.gold.withOpacity(0.08),
                      ),
                      child: Icon(Icons.person_add_outlined,
                          color: AppTheme.gold.withOpacity(0.5), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Henüz favori berber seçmediniz',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Randevu aldıktan sonra favori seçebilirsiniz',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // Favori berber var → bilgisi gösterilir
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.gold.withOpacity(0.1),
                        border: Border.all(
                          color: AppTheme.gold.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(Icons.person,
                          color: AppTheme.gold, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favori Berberiniz',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Hızlıca randevu alabilirsiniz',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RandevuFlow()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Randevu',
                          style: GoogleFonts.inter(
                            color: AppTheme.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// İSTATİSTİK KARTI
// ═══════════════════════════════════════════════
class _IstatistikKart extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _IstatistikKart({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = AppTheme.gold,
  });

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
                Text(
                  value,
                  style: GoogleFonts.playfairDisplay(
                    color: valueColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// BOŞ KONTENJAN KARTI
// ═══════════════════════════════════════════════
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
                    Text(
                      value,
                      style: GoogleFonts.playfairDisplay(
                        color: sifirMi ? AppTheme.error : AppTheme.success,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bugünkü Boş\nKontenjan',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
