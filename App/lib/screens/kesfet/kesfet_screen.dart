import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'salon_detay_screen.dart';

/// Keşfet sekmesi — Şehirdeki tüm salonların listesi.
/// Şehir/ilçe filtreleme + arama desteği.
class KesfetScreen extends StatefulWidget {
  const KesfetScreen({super.key});

  @override
  State<KesfetScreen> createState() => _KesfetScreenState();
}

class _KesfetScreenState extends State<KesfetScreen> {
  List<Map<String, dynamic>> _salonlar = [];
  bool _yukleniyor = true;

  // Filtre state
  List<String> _sehirler = [];
  Map<String, List<String>> _ilceler = {};
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
      final results = await Future.wait([
        ApiService.getSalonlar(sehir: _seciliSehir, ilce: _seciliIlce),
        ApiService.getFiltreler(),
      ]);
      if (mounted) {
        final filtreler = results[1] as Map<String, dynamic>;
        setState(() {
          _salonlar = results[0] as List<Map<String, dynamic>>;
          _sehirler = List<String>.from(filtreler['sehirler'] ?? []);
          final rawIlceler = filtreler['ilceler'] as Map<String, dynamic>? ?? {};
          _ilceler = rawIlceler.map(
              (k, v) => MapEntry(k, List<String>.from(v as List)));
          _yukleniyor = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
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
        title: Text(
          'Keşfet',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filtre Alanı ──────────────────────────────
          _FiltreBolumu(
            sehirler: _sehirler,
            ilceler: _seciliSehir != null
                ? (_ilceler[_seciliSehir] ?? [])
                : [],
            seciliSehir: _seciliSehir,
            seciliIlce: _seciliIlce,
            onSehirSecim: (s) {
              setState(() {
                _seciliSehir = s;
                _seciliIlce = null;
              });
              _yukle();
            },
            onIlceSecim: (i) {
              setState(() => _seciliIlce = i);
              _yukle();
            },
            onTemizle: () {
              setState(() {
                _seciliSehir = null;
                _seciliIlce = null;
              });
              _yukle();
            },
          ),

          // ── Salon Listesi ─────────────────────────────
          Expanded(
            child: _yukleniyor
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold),
                  )
                : _salonlar.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store_outlined,
                                color: AppTheme.gold.withOpacity(0.3),
                                size: 72),
                            const SizedBox(height: 16),
                            Text(
                              'Salon bulunamadı',
                              style: GoogleFonts.playfairDisplay(
                                color: AppTheme.textSecondary,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Filtrelerinizi değiştirmeyi deneyin',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SalonDetayScreen(
                                  salonId: _salonlar[i]['id'],
                                ),
                              ),
                            ),
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
// FİLTRE BÖLÜMÜ
// ═══════════════════════════════════════════════
class _FiltreBolumu extends StatelessWidget {
  final List<String> sehirler;
  final List<String> ilceler;
  final String? seciliSehir;
  final String? seciliIlce;
  final ValueChanged<String?> onSehirSecim;
  final ValueChanged<String?> onIlceSecim;
  final VoidCallback onTemizle;

  const _FiltreBolumu({
    required this.sehirler,
    required this.ilceler,
    required this.seciliSehir,
    required this.seciliIlce,
    required this.onSehirSecim,
    required this.onIlceSecim,
    required this.onTemizle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.gold.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Şehir dropdown
          Expanded(
            child: _FiltreDropdown(
              label: 'Şehir',
              value: seciliSehir,
              items: sehirler,
              onChanged: onSehirSecim,
            ),
          ),
          const SizedBox(width: 10),
          // İlçe dropdown
          Expanded(
            child: _FiltreDropdown(
              label: 'İlçe',
              value: seciliIlce,
              items: ilceler,
              onChanged: onIlceSecim,
              enabled: seciliSehir != null,
            ),
          ),
          // Temizle butonu
          if (seciliSehir != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTemizle,
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
    );
  }
}

class _FiltreDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const _FiltreDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? AppTheme.gold.withOpacity(0.2)
              : AppTheme.textSecondary.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          value: value,
          dropdownColor: AppTheme.surface,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: enabled ? AppTheme.gold : AppTheme.textSecondary,
            size: 20,
          ),
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s,
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Salon ikonu
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
              ),
              child: const Icon(Icons.content_cut,
                  color: AppTheme.gold, size: 26),
            ),
            const SizedBox(width: 14),
            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salon['ad'] ?? 'Salon',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (konum.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: AppTheme.textSecondary, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            konum,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Puan
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: AppTheme.gold, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              puan.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                color: AppTheme.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Çalışma saati
                      if (acilis.isNotEmpty && kapanis.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                color: AppTheme.textSecondary.withOpacity(0.5),
                                size: 13),
                            const SizedBox(width: 3),
                            Text(
                              '$acilis - $kapanis',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Ok ikonu
            Icon(Icons.arrow_forward_ios,
                color: AppTheme.gold.withOpacity(0.4), size: 16),
          ],
        ),
      ),
    );
  }
}
