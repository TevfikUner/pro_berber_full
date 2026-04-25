import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config.dart';
import '../randevu_al/randevu_flow.dart';

/// Salon detay sayfası — Keşfet sekmesinden tıklanınca açılır.
/// Dükkan adı, puan, çalışma saatleri, konum, sosyal medya, galeri, randevu al.
class SalonDetayScreen extends StatefulWidget {
  final int salonId;

  const SalonDetayScreen({super.key, required this.salonId});

  @override
  State<SalonDetayScreen> createState() => _SalonDetayScreenState();
}

class _SalonDetayScreenState extends State<SalonDetayScreen> {
  Map<String, dynamic>? _salon;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final data = await ApiService.getSalonDetay(widget.salonId);
      if (mounted) setState(() { _salon = data; _yukleniyor = false; });
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  // ── Haritada Gör ──────────────────────────────────────
  Future<void> _haritadaGor() async {
    final lat = _salon?['konum']?['lat'];
    final lng = _salon?['konum']?['lng'];
    if (lat == null || lng == null) return;

    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      await launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── Yol Tarifi ────────────────────────────────────────
  Future<void> _yolTarifi() async {
    final lat = _salon?['konum']?['lat'];
    final lng = _salon?['konum']?['lng'];
    if (lat == null || lng == null) return;

    final navUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(navUri)) {
      await launchUrl(navUri);
    } else {
      await launchUrl(
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── Telefon ───────────────────────────────────────────
  Future<void> _telefonAc() async {
    final tel = (_salon?['telefon'] ?? '').replaceAll(' ', '');
    if (tel.isEmpty) return;
    await launchUrl(Uri.parse('tel:$tel'));
  }

  // ── Instagram ─────────────────────────────────────────
  Future<void> _instagramAc() async {
    final insta = _salon?['instagram'];
    if (insta == null || insta.isEmpty) return;
    final appUri = Uri.parse('instagram://user?username=$insta');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(
        Uri.parse('https://instagram.com/$insta'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── WhatsApp ──────────────────────────────────────────
  Future<void> _whatsappAc() async {
    final wp = _salon?['whatsapp'];
    if (wp == null || wp.isEmpty) return;
    final tel = wp.replaceAll(' ', '').replaceAll('+', '');
    await launchUrl(
      Uri.parse('https://wa.me/$tel'),
      mode: LaunchMode.externalApplication,
    );
  }

  // ── Galeri Dialog ─────────────────────────────────────
  void _galeriGoster() {
    final fotograflar = _salon?['fotograflar'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library, color: AppTheme.gold, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Galeri',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${fotograflar.length} fotoğraf',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF2A2A2A)),
                Expanded(
                  child: fotograflar.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera_outlined,
                                  color: AppTheme.gold.withOpacity(0.2), size: 64),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz fotoğraf eklenmemiş',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: fotograflar.length,
                          itemBuilder: (_, i) {
                            final fotoUrl = fotograflar[i]['foto_url'] ?? '';
                            final fullUrl = fotoUrl.startsWith('http')
                                ? fotoUrl
                                : '${AppConfig.baseUrl}$fotoUrl';
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                fullUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.black,
                                  child: const Icon(Icons.broken_image,
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return Scaffold(
        backgroundColor: AppTheme.black,
        appBar: AppBar(
          backgroundColor: AppTheme.black,
          leading: const BackButton(color: AppTheme.gold),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.gold),
        ),
      );
    }

    if (_salon == null) {
      return Scaffold(
        backgroundColor: AppTheme.black,
        appBar: AppBar(
          backgroundColor: AppTheme.black,
          leading: const BackButton(color: AppTheme.gold),
        ),
        body: Center(
          child: Text(
            'Salon bilgileri yüklenemedi',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final puan = (_salon!['puan'] as num?)?.toDouble() ?? 0;
    final acilis = _salon!['acilis_saati'] ?? '';
    final kapanis = _salon!['kapanis_saati'] ?? '';
    final insta = _salon!['instagram'];
    final whatsapp = _salon!['whatsapp'];
    final berberler = _salon!['berberler'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.black,
            elevation: 0,
            pinned: true,
            leading: const BackButton(color: AppTheme.gold),
            title: Text(
              _salon!['ad'] ?? 'Salon',
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ── Salon Başlık Kartı ─────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gold.withOpacity(0.1),
                    AppTheme.gold.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  // Salon ikonu
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.gold.withOpacity(0.1),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.content_cut,
                        color: AppTheme.gold, size: 32),
                  ),
                  const SizedBox(height: 14),
                  // Ad
                  Text(
                    _salon!['ad'] ?? 'Salon',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Puan + Çalışma saati
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Puan
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: AppTheme.gold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              puan.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                color: AppTheme.gold,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Saat
                      if (acilis.isNotEmpty && kapanis.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: AppTheme.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$acilis - $kapanis',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Adres
                  if (_salon!['adres'] != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppTheme.textSecondary, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _salon!['adres'],
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Konum Butonları ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _AksiyonButon(
                      icon: Icons.map_outlined,
                      label: 'Haritada Gör',
                      onTap: _haritadaGor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AksiyonButon(
                      icon: Icons.navigation_outlined,
                      label: 'Yol Tarifi',
                      onTap: _yolTarifi,
                      filled: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── İletişim & Sosyal Medya ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'İletişim'),
                  const SizedBox(height: 12),
                  // Telefon
                  _IletisimSatir(
                    icon: Icons.phone_outlined,
                    label: _salon!['telefon'] ?? 'Telefon',
                    onTap: _telefonAc,
                  ),
                  const SizedBox(height: 8),
                  // Sosyal medya
                  Row(
                    children: [
                      if (insta != null && insta.isNotEmpty)
                        Expanded(
                          child: _SosyalButon(
                            icon: Icons.camera_alt_outlined,
                            label: 'Instagram',
                            onTap: _instagramAc,
                          ),
                        ),
                      if (insta != null &&
                          insta.isNotEmpty &&
                          whatsapp != null &&
                          whatsapp.isNotEmpty)
                        const SizedBox(width: 10),
                      if (whatsapp != null && whatsapp.isNotEmpty)
                        Expanded(
                          child: _SosyalButon(
                            icon: Icons.chat_outlined,
                            label: 'WhatsApp',
                            onTap: _whatsappAc,
                            color: const Color(0xFF25D366),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Galeri Butonu ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: GestureDetector(
                onTap: _galeriGoster,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.photo_library_outlined,
                            color: AppTheme.gold, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Galeri',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Dükkan fotoğraflarını incele',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: AppTheme.gold.withOpacity(0.5), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Berberler Listesi ──────────────────────────
          if (berberler.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Ekibimiz'),
                    const SizedBox(height: 12),
                    ...berberler.map((b) => _BerberKart(berber: b)),
                  ],
                ),
              ),
            ),

          // ── Randevu Al Butonu ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RandevuFlow()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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
                          color: AppTheme.black, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Buradan Randevu Al',
                        style: GoogleFonts.inter(
                          color: AppTheme.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
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
// YARDIMCI WİDGET'LAR
// ═══════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _AksiyonButon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _AksiyonButon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: filled ? AppTheme.goldGradient : null,
          color: filled ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: filled
              ? null
              : Border.all(color: AppTheme.gold.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: filled ? AppTheme.black : AppTheme.gold, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: filled ? AppTheme.black : AppTheme.gold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IletisimSatir extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IletisimSatir({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosyalButon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SosyalButon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.gold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: c,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BerberKart extends StatelessWidget {
  final Map<String, dynamic> berber;
  const _BerberKart({required this.berber});

  @override
  Widget build(BuildContext context) {
    final puan = (berber['puan'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.gold.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppTheme.gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${berber['ad'] ?? ''} ${berber['soyad'] ?? ''}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  berber['uzmanlik'] ?? '',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: AppTheme.gold, size: 14),
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
        ],
      ),
    );
  }
}
