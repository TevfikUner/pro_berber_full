import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../data/turkiye_lokasyon.dart';
import 'salon_detay_screen.dart';

/// Keşfet sekmesi — Şehirdeki tüm salonların listesi.
/// 81 il/ilçe filtreleme + konuma yakın berber desteği.
class KesfetScreen extends StatefulWidget {
  const KesfetScreen({super.key});

  @override
  State<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends State<KesfetScreen> {
  List<Map<String, dynamic>> _salonlar = [];
  bool _yukleniyor = true;
  bool _konumYukleniyor = false;

  String? _seciliSehir;
  String? _seciliIlce;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final data = await ApiService.getSalonlar(sehir: _seciliSehir, ilce: _seciliIlce);
      if (mounted) setState(() { _salonlar = data; _yukleniyor = false; });
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _konumaGoreBul() async {
    setState(() => _konumYukleniyor = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni gerekli'), backgroundColor: AppTheme.error),
          );
        }
        setState(() => _konumYukleniyor = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        String? sehir = place.administrativeArea;
        String? ilce = place.subAdministrativeArea ?? place.locality;

        // Türkiye lokasyonlarında eşleşme ara
        if (sehir != null) {
          final eslesen = TurkiyeLokasyon.sehirler.firstWhere(
            (s) => s.toLowerCase() == sehir!.toLowerCase() || sehir!.toLowerCase().contains(s.toLowerCase()),
            orElse: () => '',
          );
          if (eslesen.isNotEmpty) sehir = eslesen;
        }

        setState(() {
          _seciliSehir = sehir;
          _seciliIlce = ilce;
        });
        _yukle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum alınamadı: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _konumYukleniyor = false);
  }

  void _sehirSec() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _SehirSecimSheet(
        onSecim: (sehir) {
          Navigator.pop(ctx);
          setState(() { _seciliSehir = sehir; _seciliIlce = null; });
          _yukle();
        },
      ),
    );
  }

  void _ilceSec() {
    if (_seciliSehir == null) return;
    final ilceler = TurkiyeLokasyon.ilcelerGetir(_seciliSehir!);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _IlceSecimSheet(
        ilceler: ilceler,
        onSecim: (ilce) {
          Navigator.pop(ctx);
          setState(() => _seciliIlce = ilce);
          _yukle();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Keşfet', style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ── Filtre Alanı ──────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.gold.withOpacity(0.1))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _sehirSec,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.black,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_city, color: AppTheme.gold, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_seciliSehir ?? 'Şehir Seçin',
                                  style: GoogleFonts.inter(color: _seciliSehir != null ? Colors.white : AppTheme.textSecondary, fontSize: 13))),
                              const Icon(Icons.keyboard_arrow_down, color: AppTheme.gold, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _seciliSehir != null ? _ilceSec : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.black,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _seciliSehir != null ? AppTheme.gold.withOpacity(0.2) : AppTheme.textSecondary.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.map_outlined, color: _seciliSehir != null ? AppTheme.gold : AppTheme.textSecondary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_seciliIlce ?? 'İlçe Seçin',
                                  style: GoogleFonts.inter(color: _seciliIlce != null ? Colors.white : AppTheme.textSecondary, fontSize: 13))),
                              Icon(Icons.keyboard_arrow_down, color: _seciliSehir != null ? AppTheme.gold : AppTheme.textSecondary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_seciliSehir != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() { _seciliSehir = null; _seciliIlce = null; });
                          _yukle();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.clear, color: AppTheme.error, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Konumuma Yakın buton
                GestureDetector(
                  onTap: _konumYukleniyor ? null : _konumaGoreBul,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_konumYukleniyor)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold))
                        else
                          const Icon(Icons.my_location, color: AppTheme.gold, size: 18),
                        const SizedBox(width: 8),
                        Text('Konumuma Yakın Berberleri Gör',
                            style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Salon Listesi ─────────────────────
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _salonlar.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store_outlined, color: AppTheme.gold.withOpacity(0.3), size: 72),
                            const SizedBox(height: 16),
                            Text('Salon bulunamadı', style: GoogleFonts.playfairDisplay(color: AppTheme.textSecondary, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Filtrelerinizi değiştirmeyi deneyin', style: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 13)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.gold,
                        onRefresh: _yukle,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _salonlar.length,
                          itemBuilder: (_, i) => _SalonKart(
                            salon: _salonlar[i],
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SalonDetayScreen(salonId: _salonlar[i]['id']),
                            )),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ŞEHİR SEÇİM BOTTOM SHEET
// ═══════════════════════════════════════════════
class _SehirSecimSheet extends StatefulWidget {
  final ValueChanged<String> onSecim;
  const _SehirSecimSheet({required this.onSecim});
  @override
  State<_SehirSecimSheet> createState() => _SehirSecimSheetState();
}

class _SehirSecimSheetState extends State<_SehirSecimSheet> {
  String _arama = '';
  @override
  Widget build(BuildContext context) {
    final sehirler = TurkiyeLokasyon.sehirler.where((s) => s.toLowerCase().contains(_arama.toLowerCase())).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _arama = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Şehir ara...', hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                filled: true, fillColor: AppTheme.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: sehirler.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(sehirler[i], style: GoogleFonts.inter(color: Colors.white)),
                leading: const Icon(Icons.location_city, color: AppTheme.gold, size: 20),
                onTap: () => widget.onSecim(sehirler[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// İLÇE SEÇİM BOTTOM SHEET
// ═══════════════════════════════════════════════
class _IlceSecimSheet extends StatelessWidget {
  final List<String> ilceler;
  final ValueChanged<String> onSecim;
  const _IlceSecimSheet({required this.ilceler, required this.onSecim});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('İlçe Seçin', style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: ilceler.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(ilceler[i], style: GoogleFonts.inter(color: Colors.white)),
                leading: const Icon(Icons.map_outlined, color: AppTheme.gold, size: 20),
                onTap: () => onSecim(ilceler[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SALON KARTI
// ═══════════════════════════════════════════════
class _SalonKart extends StatelessWidget {
  final Map<String, dynamic> salon;
  final VoidCallback onTap;
  const _SalonKart({required this.salon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final puan = (salon['puan'] as num?)?.toDouble() ?? 0;
    final sehir = salon['sehir'] ?? '';
    final ilce = salon['ilce'] ?? '';
    final konum = [sehir, ilce].where((s) => s.isNotEmpty).join(', ');
    final acilis = salon['acilis_saati'] ?? '';
    final kapanis = salon['kapanis_saati'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.gold.withOpacity(0.12)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
              ),
              child: const Icon(Icons.content_cut, color: AppTheme.gold, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(salon['ad'] ?? 'Salon', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (konum.isNotEmpty)
                    Row(children: [
                      Icon(Icons.location_on_outlined, color: AppTheme.textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text(konum, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star, color: AppTheme.gold, size: 13),
                        const SizedBox(width: 3),
                        Text(puan.toStringAsFixed(1), style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    if (acilis.isNotEmpty && kapanis.isNotEmpty)
                      Row(children: [
                        Icon(Icons.access_time, color: AppTheme.textSecondary.withOpacity(0.5), size: 13),
                        const SizedBox(width: 3),
                        Text('$acilis - $kapanis', style: GoogleFonts.inter(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 11)),
                      ]),
                  ]),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.gold.withOpacity(0.4), size: 16),
          ],
        ),
      ),
    );
  }
}
