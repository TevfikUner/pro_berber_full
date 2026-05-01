import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/berber_desen.dart';
import '../../services/api_service.dart';
import '../../models/berber.dart';
import '../../models/randevu.dart';
import '../randevu_al/randevu_flow.dart';
import 'favori_berberler_screen.dart';

/// Ana Sayfa — Selamlama, Favori Berberler, Yaklaşan Randevu, Hızlı İşlemler
class AnaSayfaScreen extends StatefulWidget {
  final VoidCallback? onKesfeteGit;
  const AnaSayfaScreen({super.key, this.onKesfeteGit});

  @override
  State<AnaSayfaScreen> createState() => _AnaSayfaScreenState();
}

class _AnaSayfaScreenState extends State<AnaSayfaScreen> {
  Map<String, dynamic>? _profil;
  List<Map<String, dynamic>> _favoriler = [];
  List<Randevu> _yaklasanlar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final results = await Future.wait([
        ApiService.profilGetir(),
        ApiService.favorileriGetir(),
        ApiService.getRandevularim(),
      ]);

      if (mounted) {
        final randevular = results[2] as List<Randevu>;
        // Yaklaşan randevuları filtrele (onaylandi durumunda olanlar)
        final yaklasan = randevular
            .where((r) => r.durum == 'onaylandi')
            .toList()
          ..sort((a, b) => '${a.tarih} ${a.saat}'.compareTo('${b.tarih} ${b.saat}'));

        setState(() {
          _profil = results[0] as Map<String, dynamic>?;
          _favoriler = results[1] as List<Map<String, dynamic>>;
          _yaklasanlar = yaklasan.take(3).toList();
          _yukleniyor = false;
        });
      }
    } catch (e) {
      debugPrint('Yükleme hatası: $e');
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  String get _musteriAdi {
    if (_profil == null) return '';
    final ad = _profil!['ad'] ?? '';
    return ad.toString().isNotEmpty ? ad.toString() : '';
  }

  /// Akıllı Randevu Al
  void _randevuAlTiklandi(BuildContext ctx) async {
    if (_favoriler.isEmpty) {
      widget.onKesfeteGit?.call();
      return;
    }

    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bsCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Randevu Al',
                  style: GoogleFonts.playfairDisplay(
                      color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Nasıl devam etmek istersiniz?',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              // Favori berberlerden seç
              ..._favoriler.take(3).map((fav) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FavoriSecimTile(
                  fav: fav,
                  onTap: () {
                    Navigator.pop(bsCtx);
                    final berber = Berber(
                      id: fav['berber_id'],
                      ad: fav['berber_ad'].toString().split(' ').first,
                      soyad: fav['berber_ad'].toString().split(' ').skip(1).join(' '),
                      uzmanlik: fav['uzmanlik'] ?? '',
                      puan: (fav['puan'] ?? 0).toDouble(),
                      fotoUrl: fav['foto_url'],
                    );
                    Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => RandevuFlow(
                        salonId: fav['salon_id'],
                        favoriBerber: berber,
                      ),
                    ));
                  },
                ),
              )),
              const SizedBox(height: 4),
              // Yeni salon keşfet
              _BottomSheetTile(
                icon: Icons.explore,
                title: 'Yeni Bir Salon Keşfet',
                subtitle: 'Farklı salonları keşfet',
                onTap: () {
                  Navigator.pop(bsCtx);
                  widget.onKesfeteGit?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
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
                    'PREMIUM BERBER',
                    style: GoogleFonts.playfairDisplay(
                      color: AppTheme.gold, fontSize: 22,
                      fontWeight: FontWeight.bold, letterSpacing: 2,
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
                        if (_musteriAdi.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text('✂️', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sıhhatler Olsun, $_musteriAdi!',
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Bugün kendine güzel bir randevu al',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                        ] else ...[
                          Text('Hoş Geldin! ✂️',
                              style: GoogleFonts.playfairDisplay(
                                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Randevu Al Butonu ───────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GestureDetector(
                      onTap: () => _randevuAlTiklandi(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withOpacity(0.35),
                              blurRadius: 20, offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.black, size: 24),
                            const SizedBox(width: 12),
                            Text('Randevu Al',
                                style: GoogleFonts.inter(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Yaklaşan Randevular ─────────────────────
                if (_yaklasanlar.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _baslikWidget('Yaklaşan Randevularınız', Icons.calendar_today)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _yaklasanlar.length,
                        itemBuilder: (_, i) => _YaklasanRandevuKart(randevu: _yaklasanlar[i]),
                      ),
                    ),
                  ),
                ],

                // ── Favori Berberlerim ──────────────────────
                SliverToBoxAdapter(child: _baslikWidget('Favori Berberlerim', Icons.star_rounded, trailing: _favoriler.isNotEmpty ? GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriBerberlerScreen()));
                    _yukle(); // Geri dönünce yenile
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Düzenle', style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ) : null)),
                SliverToBoxAdapter(
                  child: _favoriler.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GestureDetector(
                            onTap: () => widget.onKesfeteGit?.call(),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.gold.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46, height: 46,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gold.withOpacity(0.08)),
                                    child: Icon(Icons.explore_outlined, color: AppTheme.gold.withOpacity(0.5), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Henüz favori berberiniz yok', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      Text('Salon keşfedin ve randevu alın', style: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 11)),
                                    ]),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: AppTheme.gold, size: 16),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _favoriler.length,
                            itemBuilder: (_, i) {
                              final fav = _favoriler[i];
                              return _FavoriBerberChip(
                                ad: fav['berber_ad'] ?? '',
                                salon: fav['salon_ad'] ?? '',
                                puan: (fav['puan'] ?? 0).toDouble(),
                                onTap: () {
                                  final berber = Berber(
                                    id: fav['berber_id'],
                                    ad: fav['berber_ad'].toString().split(' ').first,
                                    soyad: fav['berber_ad'].toString().split(' ').skip(1).join(' '),
                                    uzmanlik: fav['uzmanlik'] ?? '',
                                    puan: (fav['puan'] ?? 0).toDouble(),
                                    fotoUrl: fav['foto_url'],
                                  );
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => RandevuFlow(salonId: fav['salon_id'], favoriBerber: berber),
                                  ));
                                },
                              );
                            },
                          ),
                        ),
                ),

                // ── Hızlı İşlemler ─────────────────────────
                SliverToBoxAdapter(child: _baslikWidget('Hızlı İşlemler', Icons.flash_on)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: _HizliIslemKart(
                          icon: Icons.explore, label: 'Salon Keşfet',
                          onTap: () => widget.onKesfeteGit?.call(),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _HizliIslemKart(
                          icon: Icons.star_outline, label: 'Favorilerim',
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriBerberlerScreen()));
                            _yukle();
                          },
                        )),
                      ],
                    ),
                  ),
                ),

                // ── Bilgi Kartı ─────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.gold.withOpacity(0.08), AppTheme.gold.withOpacity(0.02)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.gold.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.info_outline, color: AppTheme.gold, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Randevu İpucu 💡', style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Favori berberinizi seçerek hızlıca randevu alabilirsiniz. Personel seçimi adımı otomatik atlanır!',
                                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                          ]),
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

  Widget _baslikWidget(String title, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: AppTheme.gold, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// YAKLAŞAN RANDEVU KARTI (Horizontal scroll)
// ═══════════════════════════════════════════════
class _YaklasanRandevuKart extends StatelessWidget {
  final Randevu randevu;
  const _YaklasanRandevuKart({required this.randevu});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(randevu.saat, style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(randevu.tarih, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12))),
          ]),
          const SizedBox(height: 10),
          Text(randevu.berber, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (randevu.salonAd.isNotEmpty)
            Text(randevu.salonAd, style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 11)),
          const Spacer(),
          Text(randevu.hizmetler.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FAVORİ BERBER ÇİP (Horizontal scroll)
// ═══════════════════════════════════════════════
class _FavoriBerberChip extends StatelessWidget {
  final String ad;
  final String salon;
  final double puan;
  final VoidCallback onTap;

  const _FavoriBerberChip({required this.ad, required this.salon, required this.puan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.gold.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppTheme.gold, size: 22),
            ),
            const SizedBox(height: 8),
            Text(ad, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(salon, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: AppTheme.gold, size: 12),
              const SizedBox(width: 2),
              Text(puan.toStringAsFixed(1), style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// HIZLI İŞLEM KARTI
// ═══════════════════════════════════════════════
class _HizliIslemKart extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HizliIslemKart({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.gold, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// BOTTOM SHEET TİLE
// ═══════════════════════════════════════════════
class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BottomSheetTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gold.withOpacity(0.08)),
          child: Icon(icon, color: AppTheme.gold, size: 22),
        ),
        title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.gold, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FAVORİ SEÇİM TİLE (BottomSheet'te)
// ═══════════════════════════════════════════════
class _FavoriSecimTile extends StatelessWidget {
  final Map<String, dynamic> fav;
  final VoidCallback onTap;

  const _FavoriSecimTile({required this.fav, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.gold.withOpacity(0.15),
          child: const Icon(Icons.person, color: AppTheme.gold, size: 20),
        ),
        title: Text(fav['berber_ad'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(fav['salon_ad'] ?? '', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(8)),
          child: Text('Randevu', style: GoogleFonts.inter(color: AppTheme.black, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        onTap: onTap,
      ),
    );
  }
}
