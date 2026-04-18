import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/randevu.dart';

class RandevularimScreen extends StatefulWidget {
  const RandevularimScreen({super.key});

  @override
  State<RandevularimScreen> createState() => _RandevularimScreenState();
}

class _RandevularimScreenState extends State<RandevularimScreen> {
  List<Randevu>? _randevular;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
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
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('Randevularım'),
        leading: const BackButton(color: AppTheme.gold),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _randevular == null || _randevular!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: AppTheme.gold.withOpacity(0.3), size: 72),
                      const SizedBox(height: 16),
                      Text('Henüz randevunuz yok',
                          style: GoogleFonts.playfairDisplay(
                              color: AppTheme.textSecondary, fontSize: 18)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.gold,
                  onRefresh: _yukle,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _randevular!.length,
                    itemBuilder: (_, i) {
                      final r = _randevular![i];
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
                              // Durum badge
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
                              // Tarih & Saat
                              Row(children: [
                                const Icon(Icons.calendar_today, color: AppTheme.gold, size: 16),
                                const SizedBox(width: 8),
                                Text('${r.tarih}  •  ${r.saat}',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 6),
                              // Berber
                              Row(children: [
                                const Icon(Icons.person, color: AppTheme.textSecondary, size: 16),
                                const SizedBox(width: 8),
                                Text(r.berber,
                                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                              ]),
                              const SizedBox(height: 6),
                              // Hizmetler
                              Row(children: [
                                const Icon(Icons.content_cut, color: AppTheme.textSecondary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(r.hizmetler.join(', '),
                                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                                ),
                              ]),
                              // İptal butonu (sadece onaylı olanlara)
                              if (r.durum == 'onaylandi') ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.error,
                                      side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _sil(r),
                                    child: Text('Randevuyu İptal Et',
                                        style: GoogleFonts.inter(fontSize: 13)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
