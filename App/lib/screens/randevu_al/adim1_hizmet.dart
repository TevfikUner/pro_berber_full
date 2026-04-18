import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/hizmet.dart';
import '../../services/api_service.dart';
import '../../providers/randevu_provider.dart';

class Adim1Hizmet extends StatefulWidget {
  const Adim1Hizmet({super.key});

  @override
  State<Adim1Hizmet> createState() => _Adim1HizmetState();
}

class _Adim1HizmetState extends State<Adim1Hizmet> {
  List<Hizmet>? _hizmetler;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final data = await ApiService.getHizmetler();
      if (mounted) setState(() { _hizmetler = data; _yukleniyor = false; });
    } catch (e) {
      if (mounted) setState(() { _yukleniyor = false; _hata = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RandevuProvider>();

    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    if (_hata != null || _hizmetler == null || _hizmetler!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Hizmetler yüklenemedi',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              if (_hata != null) ...[
                const SizedBox(height: 8),
                Text(_hata!, textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _yukle,
                icon: const Icon(Icons.refresh),
                label: const Text('Yeniden Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _hizmetler!.length,
            itemBuilder: (_, i) {
              final h = _hizmetler![i];
              final secili = provider.isHizmetSecili(h);
              return GestureDetector(
                onTap: () => provider.hizmetToggle(h),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: secili
                        ? AppTheme.gold.withOpacity(0.12)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: secili ? AppTheme.gold : AppTheme.gold.withOpacity(0.15),
                      width: secili ? 1.5 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: secili ? AppTheme.gold : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: secili ? AppTheme.gold : AppTheme.textSecondary,
                                width: 1.5),
                          ),
                          child: secili
                              ? const Icon(Icons.check, color: AppTheme.black, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        // Bilgi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.ad,
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              if (h.aciklama != null && h.aciklama!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(h.aciklama!,
                                    style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.access_time,
                                    color: AppTheme.textSecondary, size: 12),
                                const SizedBox(width: 4),
                                Text('${h.sure} dk',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary, fontSize: 12)),
                              ]),
                            ],
                          ),
                        ),
                        // Fiyat
                        Text('${h.fiyat.toStringAsFixed(0)} ₺',
                            style: GoogleFonts.playfairDisplay(
                                color: AppTheme.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Alt özet bar
        if (provider.seciliHizmetler.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${provider.seciliHizmetler.length} hizmet seçildi',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('${provider.toplamSureDk} dakika',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                ]),
                Text('${provider.toplamFiyat.toStringAsFixed(0)} ₺',
                    style: GoogleFonts.playfairDisplay(
                        color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }
}
