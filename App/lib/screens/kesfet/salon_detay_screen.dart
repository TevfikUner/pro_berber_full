import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config.dart';
import '../randevu_al/randevu_flow.dart';

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

  Future<void> _haritadaGor() async {
    final lat = _salon?['konum']?['lat'];
    final lng = _salon?['konum']?['lng'];
    if (lat == null || lng == null) return;
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _yolTarifi() async {
    final lat = _salon?['konum']?['lat'];
    final lng = _salon?['konum']?['lng'];
    if (lat == null || lng == null) return;
    final navUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(navUri)) {
      await launchUrl(navUri);
    } else {
      await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _telefonAc() async {
    final tel = (_salon?['telefon'] ?? '').replaceAll(' ', '');
    if (tel.isEmpty) return;
    await launchUrl(Uri.parse('tel:$tel'));
  }

  Future<void> _instagramAc() async {
    final insta = _salon?['instagram'];
    if (insta == null || insta.isEmpty) return;
    final appUri = Uri.parse('instagram://user?username=$insta');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(Uri.parse('https://instagram.com/$insta'), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _whatsappAc() async {
    final wp = _salon?['whatsapp'];
    if (wp == null || wp.isEmpty) return;
    final tel = wp.replaceAll(' ', '').replaceAll('+', '');
    await launchUrl(Uri.parse('https://wa.me/$tel'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return Scaffold(backgroundColor: AppTheme.black, body: const Center(child: CircularProgressIndicator(color: AppTheme.gold)));
    }

    if (_salon == null) {
      return Scaffold(backgroundColor: AppTheme.black, body: Center(child: Text('Salon yüklenemedi', style: GoogleFonts.inter(color: AppTheme.textSecondary))));
    }

    final berberler = _salon!['berberler'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.black,
            pinned: true,
            leading: const BackButton(color: AppTheme.gold),
            title: Text(_salon!['ad'] ?? 'Salon', style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Salon Bilgi Kartı
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.content_cut, color: AppTheme.gold, size: 40),
                      const SizedBox(height: 12),
                      Text(_salon!['ad'] ?? '', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_salon!['adres'] ?? '', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                // İletişim Butonları
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _SosyalButon(icon: Icons.chat_outlined, label: 'WhatsApp', color: Colors.green, onTap: _whatsappAc)),
                      const SizedBox(width: 10),
                      Expanded(child: _SosyalButon(icon: Icons.camera_alt_outlined, label: 'Instagram', color: Colors.purple, onTap: _instagramAc)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _AksiyonButon(icon: Icons.map_outlined, label: 'Harita', onTap: _haritadaGor)),
                      const SizedBox(width: 10),
                      Expanded(child: _AksiyonButon(icon: Icons.navigation_outlined, label: 'Yol Tarifi', onTap: _yolTarifi, filled: true)),
                    ],
                  ),
                ),
                // Berberler
                if (berberler.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Align(alignment: Alignment.centerLeft, child: Text("Ekibimiz", style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold))),
                  ),
                  ...berberler.map((b) => _BerberKart(berber: b)),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RandevuFlow())),
          child: Text("RANDEVU AL", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}

// Yardımcı Widget'lar (Buton tasarımları için)
class _SosyalButon extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _SosyalButon({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 13))]),
      ),
    );
  }
}

class _AksiyonButon extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool filled;
  const _AksiyonButon({required this.icon, required this.label, required this.onTap, this.filled = false});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: filled ? AppTheme.gold : AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.gold.withOpacity(0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: filled ? Colors.black : AppTheme.gold, size: 20), const SizedBox(width: 8), Text(label, style: GoogleFonts.inter(color: filled ? Colors.black : AppTheme.gold, fontWeight: FontWeight.w600, fontSize: 13))]),
      ),
    );
  }
}

class _BerberKart extends StatelessWidget {
  final Map<String, dynamic> berber;
  const _BerberKart({required this.berber});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.gold.withOpacity(0.1))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.1), child: const Icon(Icons.person, color: AppTheme.gold)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${berber['ad']} ${berber['soyad']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(berber['uzmanlik'] ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))])),
          Row(children: [const Icon(Icons.star, color: AppTheme.gold, size: 16), const SizedBox(width: 4), Text(berber['puan']?.toString() ?? '0.0', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
        ],
      ),
    );
  }
}