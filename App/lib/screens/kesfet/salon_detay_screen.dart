import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../randevu_al/randevu_flow.dart';

class SalonDetayScreen extends StatefulWidget {
  final int salonId;
  const SalonDetayScreen({super.key, required this.salonId});

  @override
  State<SalonDetayScreen> createState() => _SalonDetayScreenState();
}

class _SalonDetayScreenState extends State<SalonDetayScreen> {
  Map<String, dynamic>? _salon;
  Map<String, dynamic>? _istatistik;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final results = await Future.wait([
        ApiService.getSalonDetay(widget.salonId),
        ApiService.getIstatistik(salonId: widget.salonId),
      ]);
      if (mounted) setState(() {
        _salon = results[0] as Map<String, dynamic>;
        _istatistik = results[1] as Map<String, dynamic>;
        _yukleniyor = false;
      });
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

  Future<void> _telefonAra() async {
    final tel = _salon?['telefon'];
    if (tel == null) return;
    Clipboard.setData(ClipboardData(text: tel));
    final uri = Uri.parse('tel:$tel');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsappAc() async {
    final wp = _salon?['whatsapp'];
    if (wp == null) return;
    final uri = Uri.parse('https://wa.me/$wp');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _instagramAc() async {
    final ig = _salon?['instagram'];
    if (ig == null) return;
    await launchUrl(Uri.parse(ig), mode: LaunchMode.externalApplication);
  }

  // Günlük çalışma saatleri oluştur
  List<Map<String, String>> get _calismaSaatleri {
    final acilis = _salon?['acilis_saati'] ?? '09:00';
    final kapanis = _salon?['kapanis_saati'] ?? '20:00';
    return [
      {'gun': 'Pazartesi', 'saat': '$acilis - $kapanis'},
      {'gun': 'Salı', 'saat': '$acilis - $kapanis'},
      {'gun': 'Çarşamba', 'saat': '$acilis - $kapanis'},
      {'gun': 'Perşembe', 'saat': '$acilis - $kapanis'},
      {'gun': 'Cuma', 'saat': '$acilis - $kapanis'},
      {'gun': 'Cumartesi', 'saat': '$acilis - $kapanis'},
      {'gun': 'Pazar', 'saat': 'Kapalı'},
    ];
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
    final bugunkuRandevu = _istatistik?['bugunku_randevu'] ?? 0;
    final musaitSlot = _istatistik?['musait_slot_sayisi'] ?? 0;
    final toplamSlot = _istatistik?['toplam_slot'] ?? 0;
    final aktifBerber = _istatistik?['aktif_berber'] ?? 0;

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
                // ── 1. Salon Bilgi Kartı ──────────────────
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

                // ── 2. İletişim Butonları ─────────────────
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

                // Harita & Yol Tarifi
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
                const SizedBox(height: 10),

                // Telefon Numarası
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _telefonAra,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, color: AppTheme.gold, size: 20),
                          const SizedBox(width: 10),
                          Text(_salon!['telefon'] ?? 'Telefon yok',
                              style: GoogleFonts.inter(color: AppTheme.gold, fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(width: 8),
                          Icon(Icons.copy, color: AppTheme.gold.withOpacity(0.5), size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 3. Ekibimiz ───────────────────────────
                if (berberler.isNotEmpty) ...[
                  _baslikWidget('Ekibimiz', Icons.people_alt_outlined),
                  ...berberler.map((b) => _BerberKart(berber: b)),
                ],

                // ── 4. Bugünkü Kontenjan (Salon Bazlı) ───
                _baslikWidget('Bugünkü Durum', Icons.event_available),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Bugünkü Randevu
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.people_alt_outlined, color: AppTheme.gold, size: 28),
                                  const SizedBox(height: 8),
                                  Text('$bugunkuRandevu',
                                      style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 28, fontWeight: FontWeight.bold)),
                                  Text('Bugünkü\nRandevu', textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, height: 1.4)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Boş Kontenjan
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: musaitSlot == 0
                                    ? AppTheme.error.withOpacity(0.06)
                                    : AppTheme.success.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: musaitSlot == 0
                                    ? Border.all(color: AppTheme.error.withOpacity(0.2))
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.event_available,
                                      color: musaitSlot == 0 ? AppTheme.error : AppTheme.success, size: 28),
                                  const SizedBox(height: 8),
                                  Text('$musaitSlot',
                                      style: GoogleFonts.playfairDisplay(
                                          color: musaitSlot == 0 ? AppTheme.error : AppTheme.success,
                                          fontSize: 28, fontWeight: FontWeight.bold)),
                                  Text('Boş\nKontenjan', textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, height: 1.4)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Doluluk çubuğu
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Doluluk Oranı', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                                Text(toplamSlot > 0
                                    ? '${(((toplamSlot - musaitSlot) / toplamSlot) * 100).toStringAsFixed(0)}%'
                                    : '0%',
                                    style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: toplamSlot > 0 ? (toplamSlot - musaitSlot) / toplamSlot : 0,
                                backgroundColor: AppTheme.gold.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  musaitSlot == 0 ? AppTheme.error : AppTheme.gold,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$aktifBerber berber aktif', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                                Text('$toplamSlot toplam slot', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (musaitSlot == 0) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RandevuFlow(salonId: widget.salonId))),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Başka Güne Randevu Al', textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── 5. Çalışma Saatleri ───────────────────
                _baslikWidget('Çalışma Saatleri', Icons.schedule),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: _calismaSaatleri.asMap().entries.map((e) {
                      final i = e.key;
                      final gun = e.value;
                      final bugun = DateTime.now().weekday == i + 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: bugun ? AppTheme.gold.withOpacity(0.08) : Colors.transparent,
                          border: i < 6 ? Border(bottom: BorderSide(color: AppTheme.gold.withOpacity(0.06))) : null,
                        ),
                        child: Row(
                          children: [
                            if (bugun) const Icon(Icons.circle, color: AppTheme.gold, size: 8) else const SizedBox(width: 8),
                            const SizedBox(width: 10),
                            Expanded(child: Text(gun['gun']!, style: GoogleFonts.inter(
                              color: bugun ? AppTheme.gold : Colors.white,
                              fontWeight: bugun ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ))),
                            Text(gun['saat']!, style: GoogleFonts.inter(
                              color: gun['saat'] == 'Kapalı' ? AppTheme.error : (bugun ? AppTheme.gold : AppTheme.textSecondary),
                              fontWeight: bugun ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

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
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RandevuFlow(salonId: widget.salonId))),
          child: Text("RANDEVU AL", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _baslikWidget(String title, IconData icon) {
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
          Text(title, style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Yardımcı Widget'lar ──────────────────────────
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