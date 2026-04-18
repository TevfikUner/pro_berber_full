import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/berber_desen.dart';
import '../home/home_screen.dart';

class OnaySayfasi extends StatefulWidget {
  final String tarih;
  final String saat;
  final String berber;
  final List<String> hizmetler;
  final double toplamFiyat;
  final String randevuId;

  const OnaySayfasi({
    super.key,
    required this.tarih,
    required this.saat,
    required this.berber,
    required this.hizmetler,
    required this.toplamFiyat,
    required this.randevuId,
  });

  @override
  State<OnaySayfasi> createState() => _OnaySayfasiState();
}

class _OnaySayfasiState extends State<OnaySayfasi>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          const BerberDesenWidget(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animasyonlu onay ikonu
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: AppTheme.black, size: 60),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text('Randevunuz Onaylandı!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                                color: AppTheme.gold,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Sizi bekliyoruz 💈',
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary, fontSize: 15)),
                        const SizedBox(height: 32),
                        // Detay kartı
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.gold.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              _DetaySatir(
                                  icon: Icons.calendar_today,
                                  label: 'Tarih',
                                  value: widget.tarih),
                              _DetaySatir(
                                  icon: Icons.access_time,
                                  label: 'Saat',
                                  value: widget.saat),
                              _DetaySatir(
                                  icon: Icons.person,
                                  label: 'Personel',
                                  value: widget.berber),
                              _DetaySatir(
                                  icon: Icons.content_cut,
                                  label: 'Hizmetler',
                                  value: widget.hizmetler.join(', ')),
                              Divider(
                                  color: AppTheme.gold.withOpacity(0.15),
                                  height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Toplam',
                                      style: GoogleFonts.inter(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14)),
                                  Text(
                                    '${widget.toplamFiyat.toStringAsFixed(0)} ₺',
                                    style: GoogleFonts.playfairDisplay(
                                        color: AppTheme.gold,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Ana sayfaya dön butonu
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const HomeScreen()),
                                  (_) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Ana Sayfaya Dön',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetaySatir extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetaySatir(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gold, size: 16),
          const SizedBox(width: 10),
          Text('$label: ',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
