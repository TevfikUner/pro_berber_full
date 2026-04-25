import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/berber_desen.dart';
import 'login_screen.dart';
import 'isletme_register_screen.dart';

/// İlk giriş ekranı: "Müşteri misiniz?" veya "İşletme Sahibi misiniz?"
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim1;
  late Animation<Offset> _slideAnim2;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim1 = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    ));
    _slideAnim2 = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── Logo ───────────────────────────────────
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC9A84C).withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Başlık ──────────────────────────────────
                    Text(
                      'Hoş Geldiniz',
                      style: GoogleFonts.playfairDisplay(
                        color: AppTheme.gold,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Devam etmek için rolünüzü seçin',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ── Müşteri Kartı ───────────────────────────
                    SlideTransition(
                      position: _slideAnim1,
                      child: _RolKarti(
                        icon: Icons.person_outline,
                        baslik: 'Müşteri',
                        aciklama: 'Randevu al, berber bul\nve hizmetlerden yararlan',
                        gradientColors: const [
                          Color(0xFF2A1F0E),
                          Color(0xFF1A1510),
                        ],
                        borderColor: AppTheme.gold.withOpacity(0.4),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── İşletme Sahibi Kartı ────────────────────
                    SlideTransition(
                      position: _slideAnim2,
                      child: _RolKarti(
                        icon: Icons.store_outlined,
                        baslik: 'İşletme Sahibi',
                        aciklama: 'Salonunuzu kaydedin\nve müşterilerinizi yönetin',
                        gradientColors: const [
                          Color(0xFF0E1F2A),
                          Color(0xFF101518),
                        ],
                        borderColor: const Color(0xFF4A90D9).withOpacity(0.4),
                        iconColor: const Color(0xFF4A90D9),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IsletmeRegisterScreen(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Alt dekoratif çizgi ─────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.gold.withOpacity(0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.content_cut,
                            color: AppTheme.gold.withOpacity(0.3),
                            size: 16,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.gold.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Premium Berber Hizmetleri',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
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
// ROL SEÇİM KARTI
// ═══════════════════════════════════════════════
class _RolKarti extends StatefulWidget {
  final IconData icon;
  final String baslik;
  final String aciklama;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _RolKarti({
    required this.icon,
    required this.baslik,
    required this.aciklama,
    required this.gradientColors,
    required this.borderColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_RolKarti> createState() => _RolKartiState();
}

class _RolKartiState extends State<_RolKarti> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? AppTheme.gold;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // İkon dairesi
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(widget.icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              // Metin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.baslik,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.aciklama,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Ok ikonu
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
