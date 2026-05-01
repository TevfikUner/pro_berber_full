import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/randevu.dart';

/// Favori berberler yönetim sayfası
/// Geçmiş randevulardan berberler listelenir
/// Favoriler üste çıkar, yıldız ile toggle yapılır
class FavoriBerberlerScreen extends StatefulWidget {
  const FavoriBerberlerScreen({super.key});

  @override
  State<FavoriBerberlerScreen> createState() => _FavoriBerberlerScreenState();
}

class _FavoriBerberlerScreenState extends State<FavoriBerberlerScreen> {
  List<_BerberItem> _berberler = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final results = await Future.wait([
        ApiService.getRandevularim(),
        ApiService.favorileriGetir(),
      ]);

      final randevular = results[0] as List<Randevu>;
      final favoriler = results[1] as List<Map<String, dynamic>>;
      final favoriIdler = favoriler.map((f) => f['berber_id'] as int).toSet();

      // Geçmiş randevulardan benzersiz berberleri çıkar
      final berberMap = <int, _BerberItem>{};
      for (final r in randevular) {
        if (!berberMap.containsKey(r.berberId)) {
          berberMap[r.berberId] = _BerberItem(
            berberId: r.berberId,
            berberAd: r.berber,
            salonAd: r.salonAd,
            favoriMi: favoriIdler.contains(r.berberId),
          );
        }
      }

      // Favoriler önce gelsin
      final liste = berberMap.values.toList()
        ..sort((a, b) {
          if (a.favoriMi && !b.favoriMi) return -1;
          if (!a.favoriMi && b.favoriMi) return 1;
          return a.berberAd.compareTo(b.berberAd);
        });

      if (mounted) setState(() { _berberler = liste; _yukleniyor = false; });
    } catch (e) {
      debugPrint('Favori yükleme hatası: $e');
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _favoriToggle(_BerberItem item) async {
    try {
      await ApiService.favoriToggle(item.berberId);
      setState(() {
        item.favoriMi = !item.favoriMi;
        // Sıralamayı güncelle
        _berberler.sort((a, b) {
          if (a.favoriMi && !b.favoriMi) return -1;
          if (!a.favoriMi && b.favoriMi) return 1;
          return a.berberAd.compareTo(b.berberAd);
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item.favoriMi
                ? '${item.berberAd} favorilere eklendi ⭐'
                : '${item.berberAd} favorilerden çıkarıldı'),
            backgroundColor: item.favoriMi ? AppTheme.gold : AppTheme.surface,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: const BackButton(color: AppTheme.gold),
        title: Text('Favori Berberlerim',
            style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _berberler.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_border, color: AppTheme.gold.withOpacity(0.3), size: 64),
                      const SizedBox(height: 16),
                      Text('Henüz randevu geçmişiniz yok', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('Randevu aldıktan sonra berberleriniz\nburada görünecektir',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.gold,
                  onRefresh: _yukle,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _berberler.length,
                    itemBuilder: (_, i) {
                      final item = _berberler[i];

                      // Favori / favori olmayan ayırıcısı
                      final oncekiFavoriMi = i > 0 ? _berberler[i - 1].favoriMi : null;
                      final ayiriciGoster = i == 0 || (oncekiFavoriMi != null && oncekiFavoriMi != item.favoriMi);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ayiriciGoster && item.favoriMi)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 4),
                              child: Row(children: [
                                const Icon(Icons.star, color: AppTheme.gold, size: 16),
                                const SizedBox(width: 8),
                                Text('Favorileriniz', style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Expanded(child: Divider(color: AppTheme.gold.withOpacity(0.2))),
                              ]),
                            ),
                          if (ayiriciGoster && !item.favoriMi)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 16),
                              child: Row(children: [
                                const Icon(Icons.people_outline, color: AppTheme.textSecondary, size: 16),
                                const SizedBox(width: 8),
                                Text('Diğer Berberler', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Expanded(child: Divider(color: AppTheme.textSecondary.withOpacity(0.2))),
                              ]),
                            ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.favoriMi ? AppTheme.gold.withOpacity(0.06) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.favoriMi ? AppTheme.gold.withOpacity(0.3) : AppTheme.gold.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.gold.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: AppTheme.gold, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.berberAd,
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        Icon(Icons.store_outlined, color: AppTheme.textSecondary, size: 13),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(item.salonAd,
                                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                // Yıldız toggle butonu
                                GestureDetector(
                                  onTap: () => _favoriToggle(item),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: item.favoriMi ? AppTheme.gold.withOpacity(0.2) : AppTheme.surface,
                                    ),
                                    child: Icon(
                                      item.favoriMi ? Icons.star : Icons.star_border,
                                      color: AppTheme.gold,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}

class _BerberItem {
  final int berberId;
  final String berberAd;
  final String salonAd;
  bool favoriMi;

  _BerberItem({
    required this.berberId,
    required this.berberAd,
    required this.salonAd,
    required this.favoriMi,
  });
}
