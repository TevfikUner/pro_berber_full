import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/berber.dart';
import '../../services/api_service.dart';
import '../../providers/randevu_provider.dart';
import '../../config.dart';

class Adim2Personel extends StatefulWidget {
  const Adim2Personel({super.key});

  @override
  State<Adim2Personel> createState() => _Adim2PersonelState();
}

class _Adim2PersonelState extends State<Adim2Personel> {
  List<Berber>? _berberler;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final data = await ApiService.getBerberler();
      if (mounted) setState(() { _berberler = data; _yukleniyor = false; });
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RandevuProvider>();

    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _berberler?.length ?? 0,
      itemBuilder: (_, i) {
        final b = _berberler![i];
        final secili = provider.seciliBerber?.id == b.id;
        // İsim ve soyismi burada birleştiriyoruz
        final tamAd = "${b.ad} ${b.soyad}";

        return GestureDetector(
          onTap: () => provider.berberSec(b),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secili ? AppTheme.gold.withOpacity(0.1) : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: secili ? AppTheme.gold : AppTheme.gold.withOpacity(0.15),
                width: secili ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.card,
                      child: b.fotoUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: b.fotoUrl!.startsWith('http') ? b.fotoUrl! : '${AppConfig.baseUrl}${b.fotoUrl}',
                                width: 60, height: 60, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppTheme.gold, size: 32),
                              ),
                            )
                          : const Icon(Icons.person, color: AppTheme.gold, size: 32),
                    ),
                    if (secili)
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: AppTheme.black, size: 13),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tamAd,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(b.uzmanlik,
                            style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                Column(children: [
                  const Icon(Icons.star, color: AppTheme.gold, size: 18),
                  Text(b.puan.toStringAsFixed(1),
                      style: GoogleFonts.inter(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}