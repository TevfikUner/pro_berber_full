import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/randevu.dart';

class RandevularimScreen extends StatefulWidget {
  const RandevularimScreen({super.key});

  @override
  State<RandevularimScreen> createState() => _RandevularimScreenState();
}

class _RandevularimScreenState extends State<RandevularimScreen> with SingleTickerProviderStateMixin {
  List<Randevu>? _randevular;
  bool _yukleniyor = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _yukle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    try {
      final data = await ApiService.getRandevularim();
      if (mounted) setState(() { _randevular = data; _yukleniyor = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _yukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Yüklenemedi: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  void _degerlendirmeDialogGoster(Randevu r) {
    double secilenPuan = 5;
    final TextEditingController yorumCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Sıhhatler Olsun! ⭐",
            style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${r.berber} ustadan aldığın hizmeti puanla:",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 20),

              RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(Icons.star, color: AppTheme.gold),
                onRatingUpdate: (rating) => secilenPuan = rating,
              ),

              const SizedBox(height: 20),

              TextField(
                controller: yorumCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Yorumun (isteğe bağlı)...",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: AppTheme.black,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.gold.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.gold),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                await ApiService.degerlendirmeEkle(
                  randevuId: r.id,
                  puan: secilenPuan.toInt(),
                  yorum: yorumCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _yukle();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Yorumun için teşekkürler kanki!"), backgroundColor: AppTheme.success)
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Hata: $e"), backgroundColor: AppTheme.error)
                  );
                }
              }
            },
            child: const Text("Gönder", style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _sil(Randevu r) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Randevu İptal', style: GoogleFonts.playfairDisplay(color: AppTheme.gold)),
        content: Text('${r.tarih} - ${r.saat} randevunuzu iptal etmek istiyor musunuz?',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('İptal Et', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await ApiService.randevuSil(r.id);
      _yukle();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error));
    }
  }

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'onaylandi': return AppTheme.success;
      case 'iptal': return AppTheme.error;
      case 'tamamlandi': return AppTheme.textSecondary;
      default: return AppTheme.gold;
    }
  }

  String _durumMetin(String durum) {
    switch (durum) {
      case 'onaylandi': return '✓ Onaylandı';
      case 'iptal': return '✗ İptal';
      case 'tamamlandi': return '✔ Tamamlandı';
      default: return durum;
    }
  }

  @override
  Widget build(BuildContext context) {
    final yaklasanlar = _randevular?.where((r) => r.durum == 'onaylandi').toList() ?? [];
    final gecmis = _randevular?.where((r) => r.durum == 'tamamlandi' || r.durum == 'iptal').toList() ?? [];

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('Randevularım'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'YAKLAŞANLAR', icon: Icon(Icons.calendar_today, size: 20)),
            Tab(text: 'GEÇMİŞ', icon: Icon(Icons.history, size: 20)),
          ],
        ),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildRandevuListesi(yaklasanlar, 'Henüz aktif randevunuz yok', false),
          _buildRandevuListesi(gecmis, 'Geçmiş randevu bulunamadı', true),
        ],
      ),
    );
  }

  Widget _buildRandevuListesi(List<Randevu> liste, String bosMesaj, bool gecmisMi) {
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, color: AppTheme.gold.withOpacity(0.3), size: 72),
            const SizedBox(height: 16),
            Text(bosMesaj,
                style: GoogleFonts.playfairDisplay(color: AppTheme.textSecondary, fontSize: 18)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: _yukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: liste.length,
        itemBuilder: (_, i) {
          final r = liste[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _durumRenk(r.durum).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _durumRenk(r.durum).withOpacity(0.4)),
                        ),
                        child: Text(_durumMetin(r.durum),
                            style: GoogleFonts.inter(
                                color: _durumRenk(r.durum),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text('${r.toplamFiyat.toStringAsFixed(0)} ₺',
                          style: GoogleFonts.playfairDisplay(
                              color: AppTheme.gold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.calendar_today, color: AppTheme.gold, size: 16),
                    const SizedBox(width: 8),
                    Text('${r.tarih}  •  ${r.saat}',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.person, color: AppTheme.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Text(r.berber,
                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.content_cut, color: AppTheme.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(r.hizmetler.join(', '),
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  ]),

                  // ─── AKILLI BUTONLAR ───
                  if (r.durum == 'onaylandi') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _sil(r),
                        child: Text('Randevuyu İptal Et', style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    ),
                  ]
                  else if (gecmisMi && r.durum == 'tamamlandi') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: r.puan != null // Zaten değerlendirilmişse
                          ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
                            const SizedBox(width: 8),
                            Text('Değerlendirildi (${r.puan} ⭐)',
                                style: GoogleFonts.inter(color: AppTheme.success, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                          : ElevatedButton.icon( // Henüz değerlendirilmemişse
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _degerlendirmeDialogGoster(r),
                        icon: const Icon(Icons.star_border, color: AppTheme.black),
                        label: const Text('Hizmeti Değerlendir',
                            style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}