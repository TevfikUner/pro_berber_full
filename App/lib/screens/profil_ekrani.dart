import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'auth/role_selection_screen.dart';

class ProfilEkrani extends StatefulWidget {
  const ProfilEkrani({super.key});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  final TextEditingController adKontrolcusu = TextEditingController();
  final TextEditingController soyadKontrolcusu = TextEditingController();
  final TextEditingController telefonKontrolcusu = TextEditingController();
  bool yukleniyor = false;
  bool _duzenlemeModu = false;

  @override
  void initState() {
    super.initState();
    _bilgileriGetir();
  }

  // Tarayıcıda link açan yardımcı fonksiyon
  Future<void> _linkeGit(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print('Link açılamadı: $url');
    }
  }

  Future<void> _bilgileriGetir() async {
    setState(() => yukleniyor = true);
    try {
      final veriler = await ApiService.profilGetir();
      if (veriler != null) {
        adKontrolcusu.text = veriler['ad'] ?? '';
        soyadKontrolcusu.text = veriler['soyad'] ?? '';
        String tel = veriler['telefon'] ?? '';
        if (tel.startsWith('0')) tel = tel.substring(1);
        telefonKontrolcusu.text = tel;
      }
    } catch (e) {
      print("Bilgi getirme hatası: $e");
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  Future<void> _bilgileriKaydet() async {
    setState(() => yukleniyor = true);
    try {
      String gidenTel = telefonKontrolcusu.text.trim();
      if (gidenTel.isNotEmpty) gidenTel = '0$gidenTel';

      await ApiService.profilGuncelle(
        ad: adKontrolcusu.text.trim(),
        soyad: soyadKontrolcusu.text.trim(),
        telefon: gidenTel,
      );

      if (mounted) {
        setState(() => _duzenlemeModu = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilgileriniz başarıyla kaydedildi!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  Future<void> _cikisYap() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Çıkış Yap',
            style: GoogleFonts.playfairDisplay(
                color: AppTheme.gold, fontWeight: FontWeight.bold)),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Çıkış Yap',
                style: GoogleFonts.inter(
                    color: AppTheme.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (onay == true) {
      await AuthService.cikisYap();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _hesapSilmeOnayi() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hesabı Sil',
            style: GoogleFonts.playfairDisplay(color: AppTheme.error)),
        content: const Text(
          'Hesabınızı ve tüm randevu geçmişinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kalıcı Olarak Sil',
                style: TextStyle(
                    color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (onay == true) {
      // Hesap silme işlemi buraya gelecek
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
        title: Text('Profil',
            style: GoogleFonts.playfairDisplay(
                color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          children: [
            // ── Profil Avatarı ──────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border:
                    Border.all(color: AppTheme.gold.withOpacity(0.3), width: 2),
              ),
              child:
                  const Icon(Icons.person, color: AppTheme.gold, size: 56),
            ),
            const SizedBox(height: 8),
            if (adKontrolcusu.text.isNotEmpty || soyadKontrolcusu.text.isNotEmpty)
              Text(
                '${adKontrolcusu.text} ${soyadKontrolcusu.text}',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 24),

            // ── Kişisel Bilgiler ────────────────────────
            _SectionCard(
              title: 'Kişisel Bilgiler',
              icon: Icons.person_outline,
              trailing: TextButton(
                onPressed: () {
                  if (_duzenlemeModu) {
                    _bilgileriKaydet();
                  } else {
                    setState(() => _duzenlemeModu = true);
                  }
                },
                child: Text(
                  _duzenlemeModu ? 'Kaydet' : 'Düzenle',
                  style: GoogleFonts.inter(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _ProfilGirdisi(
                    baslik: 'Adınız',
                    kontrolcu: adKontrolcusu,
                    ikon: Icons.badge_outlined,
                    enabled: _duzenlemeModu,
                  ),
                  const SizedBox(height: 12),
                  _ProfilGirdisi(
                    baslik: 'Soyadınız',
                    kontrolcu: soyadKontrolcusu,
                    ikon: Icons.badge_outlined,
                    enabled: _duzenlemeModu,
                  ),
                  const SizedBox(height: 12),
                  _ProfilGirdisi(
                    baslik: 'Telefon',
                    kontrolcu: telefonKontrolcusu,
                    ikon: Icons.phone_outlined,
                    klavyeTipi: TextInputType.phone,
                    enabled: _duzenlemeModu,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Yasal & Gizlilik ────────────────────────
            _SectionCard(
              title: 'Yasal & Gizlilik',
              icon: Icons.shield_outlined,
              child: Column(
                children: [
                  _MenuSatir(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Gizlilik Politikası',
                    onTap: () => _linkeGit(
                        'https://docs.google.com/document/d/1J7rxdVU_4laHvegjVdZd-4XNQrlLm8InNt-f70BhhiY/edit?usp=sharing'),
                  ),
                  _MenuDivider(),
                  _MenuSatir(
                    icon: Icons.article_outlined,
                    label: 'KVKK Aydınlatma Metni',
                    onTap: () => _linkeGit(
                        'https://docs.google.com/document/d/1J7rxdVU_4laHvegjVdZd-4XNQrlLm8InNt-f70BhhiY/edit?usp=sharing'),
                  ),
                  _MenuDivider(),
                  _MenuSatir(
                    icon: Icons.description_outlined,
                    label: 'Kullanım Koşulları',
                    onTap: () => _linkeGit(
                        'https://docs.google.com/document/d/1J7rxdVU_4laHvegjVdZd-4XNQrlLm8InNt-f70BhhiY/edit?usp=sharing'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Hesap İşlemleri ─────────────────────────
            _SectionCard(
              title: 'Hesap',
              icon: Icons.settings_outlined,
              child: Column(
                children: [
                  // Çıkış Yap
                  _MenuSatir(
                    icon: Icons.logout,
                    label: 'Çıkış Yap',
                    iconColor: AppTheme.gold,
                    labelColor: AppTheme.gold,
                    onTap: _cikisYap,
                  ),
                  _MenuDivider(),
                  // Hesap Sil
                  _MenuSatir(
                    icon: Icons.delete_forever,
                    label: 'Hesabımı Sil',
                    iconColor: AppTheme.error,
                    labelColor: AppTheme.error,
                    onTap: _hesapSilmeOnayi,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// YARDIMCI WİDGET'LAR
// ═══════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.gold.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MenuSatir extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _MenuSatir({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: labelColor ?? Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppTheme.textSecondary.withOpacity(0.4), size: 14),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppTheme.gold.withOpacity(0.06),
      height: 1,
    );
  }
}

class _ProfilGirdisi extends StatelessWidget {
  final String baslik;
  final TextEditingController kontrolcu;
  final IconData ikon;
  final TextInputType klavyeTipi;
  final bool enabled;

  const _ProfilGirdisi({
    required this.baslik,
    required this.kontrolcu,
    required this.ikon,
    this.klavyeTipi = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: kontrolcu,
      keyboardType: klavyeTipi,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? Colors.white : AppTheme.textSecondary,
      ),
      decoration: InputDecoration(
        labelText: baslik,
        labelStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
        prefixIcon: Icon(ikon, color: AppTheme.gold.withOpacity(0.7)),
        filled: true,
        fillColor: enabled ? AppTheme.black : AppTheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.gold.withOpacity(0.15)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.gold.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.gold),
        ),
      ),
    );
  }
}