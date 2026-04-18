import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../widgets/altin_buton.dart';
import '../services/api_service.dart';
import '../config.dart';

/// Randevu saatinden 2 saat sonra müşteriye gösterilen berber puanlama ekranı.
/// FCM bildirimine tıklanınca veya uygulama açılınca navigate edilir.
class DegerlendirmeEkrani extends StatefulWidget {
  final int randevuId;
  final String berberAdi;
  final String? berberFotoUrl; // null olabilir

  const DegerlendirmeEkrani({
    super.key,
    required this.randevuId,
    required this.berberAdi,
    this.berberFotoUrl,
  });

  @override
  State<DegerlendirmeEkrani> createState() => _DegerlendirmeEkraniState();
}

class _DegerlendirmeEkraniState extends State<DegerlendirmeEkrani>
    with SingleTickerProviderStateMixin {
  int _seciliYildiz = 5; // Varsayılan 5 yıldız
  bool _loading = false;
  bool _tamamlandi = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _degerlendirmeGonder() async {
    setState(() => _loading = true);
    try {
      await ApiService.degerlendirmeEkle(
        randevuId: widget.randevuId,
        puan: _seciliYildiz,
      );
      if (!mounted) return;
      setState(() {
        _tamamlandi = true;
        _loading = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Atla',
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
        ],
      ),
      body: ScaleTransition(
        scale: _scaleAnim,
        child: _tamamlandi ? _basariEkrani() : _puanlamaEkrani(),
      ),
    );
  }

  Widget _puanlamaEkrani() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Berber Fotoğrafı ─────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                // Parlama efekti
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.25),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppTheme.surface,
                  child: _buildAvatar(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Berber Adı ───────────────────────────────────
            Text(
              widget.berberAdi,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Randevunu nasıl buldun?',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // ── Yıldız Seçici ─────────────────────────────────
            _YildizSecici(
              secili: _seciliYildiz,
              onSecim: (v) => setState(() => _seciliYildiz = v),
            ),
            const SizedBox(height: 12),
            Text(
              _yildizMetni(_seciliYildiz),
              style: GoogleFonts.inter(
                color: AppTheme.gold,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),

            // ── Gönder Butonu ─────────────────────────────────
            AltinButon(
              text: 'Değerlendir',
              onPressed: _degerlendirmeGonder,
              loading: _loading,
              icon: const Icon(Icons.star, color: AppTheme.black, size: 20),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Şimdi değil',
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _basariEkrani() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold.withOpacity(0.15),
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.gold, size: 50),
          ),
          const SizedBox(height: 24),
          Text('Teşekkürler! ⭐',
              style: GoogleFonts.playfairDisplay(
                  color: AppTheme.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Değerlendirmeniz kaydedildi.',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final fotoUrl = widget.berberFotoUrl;
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: fotoUrl.startsWith('http')
              ? fotoUrl
              : '${AppConfig.baseUrl}$fotoUrl',
          width: 104,
          height: 104,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              const Icon(Icons.person, color: AppTheme.gold, size: 48),
        ),
      );
    }
    return const Icon(Icons.person, color: AppTheme.gold, size: 48);
  }

  String _yildizMetni(int y) {
    switch (y) {
      case 1:
        return 'Berberi İstemiyorum 😤';
      case 2:
        return 'İdare Eder 😐';
      case 3:
        return 'Fena Değil 🙂';
      case 4:
        return 'İyiydi, Teşekkürler 😊';
      case 5:
        return 'Harikaydı! 🤩';
      default:
        return '';
    }
  }
}

// ── Yıldız Seçici Widget ─────────────────────────────────────
class _YildizSecici extends StatelessWidget {
  final int secili;
  final ValueChanged<int> onSecim;

  const _YildizSecici({required this.secili, required this.onSecim});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final yildizNo = i + 1;
        final aktif = yildizNo <= secili;
        return GestureDetector(
          onTap: () => onSecim(yildizNo),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Transform.scale(
              scale: aktif ? 1.15 : 1.0,
              child: Icon(
                aktif ? Icons.star_rounded : Icons.star_outline_rounded,
                color: aktif ? AppTheme.gold : AppTheme.textSecondary,
                size: 46,
              ),
            ),
          ),
        );
      }),
    );
  }
}
