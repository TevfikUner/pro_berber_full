import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/altin_buton.dart';
import '../../widgets/berber_desen.dart';
import '../../services/auth_service.dart';

/// İşletme sahibi kayıt ekranı.
/// Kayıt sonrası "Başvurunuz alındı, onay bekleniyor" ekranına yönlendirir.
class IsletmeRegisterScreen extends StatefulWidget {
  const IsletmeRegisterScreen({super.key});

  @override
  State<IsletmeRegisterScreen> createState() => _IsletmeRegisterScreenState();
}

class _IsletmeRegisterScreenState extends State<IsletmeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _isletmeAdiCtrl = TextEditingController();
  bool _loading = false;
  bool _sifreGizli = true;
  bool _kayitTamam = false;

  Future<void> _kayitOl() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.isletmeKayitOl(
        email: _emailCtrl.text.trim(),
        sifre: _sifreCtrl.text,
        ad: _adCtrl.text.trim(),
        soyad: _soyadCtrl.text.trim(),
        telefon: '0${_telefonCtrl.text.trim()}',
        isletmeAdi: _isletmeAdiCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _kayitTamam = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kayıt başarısız: ${e.toString()}'),
        backgroundColor: AppTheme.error,
      ));
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _adCtrl, _soyadCtrl, _telefonCtrl,
      _emailCtrl, _sifreCtrl, _isletmeAdiCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A90D9)),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_kayitTamam) return _basariEkrani();

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          const BerberDesenWidget(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Geri butonu
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Color(0xFF4A90D9)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 8),

                    // Başlık
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90D9).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.store_outlined,
                              color: Color(0xFF4A90D9), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'İşletme Kaydı',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFF4A90D9),
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Salonunuzu kaydedin',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // İşletme Adı (öne çıkan alan)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4A90D9).withOpacity(0.08),
                            const Color(0xFF4A90D9).withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4A90D9).withOpacity(0.2),
                        ),
                      ),
                      child: _field(
                        _isletmeAdiCtrl,
                        'İşletme / Salon Adı',
                        Icons.business_outlined,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'İşletme adı zorunlu' : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Ad — Soyad
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _adCtrl,
                            'Ad',
                            Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Zorunlu' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _soyadCtrl,
                            'Soyad',
                            Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Zorunlu' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Telefon
                    TextFormField(
                      controller: _telefonCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası',
                        prefixIcon: Icon(Icons.phone_outlined,
                            color: Color(0xFF4A90D9)),
                        prefixText: '0  ',
                        prefixStyle: TextStyle(
                            color: Color(0xFF4A90D9),
                            fontWeight: FontWeight.bold),
                        counterText: '',
                        hintText: '5XX XXX XX XX',
                        hintStyle: TextStyle(color: Colors.white30),
                      ),
                      validator: (v) {
                        final digits = v?.trim() ?? '';
                        if (digits.length != 10) {
                          return 'Hatalı telefon numarası (10 rakam giriniz)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // E-posta
                    _field(
                      _emailCtrl,
                      'E-posta (Gmail)',
                      Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Geçerli e-posta girin'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Şifre
                    _field(
                      _sifreCtrl,
                      'Şifre',
                      Icons.lock_outline,
                      obscure: _sifreGizli,
                      suffix: IconButton(
                        icon: Icon(
                          _sifreGizli
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _sifreGizli = !_sifreGizli),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                    ),
                    const SizedBox(height: 32),

                    // Kayıt Ol butonu
                    AltinButon(
                      text: 'Başvuru Yap',
                      onPressed: _kayitOl,
                      loading: _loading,
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

  /// Kayıt başarılı → Onay bekleme ekranı
  Widget _basariEkrani() {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          const BerberDesenWidget(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Onay ikonu
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4A90D9).withOpacity(0.12),
                        border: Border.all(
                          color: const Color(0xFF4A90D9).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: Color(0xFF4A90D9),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Başvurunuz Alındı!',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFF4A90D9),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'İşletme kaydınız başarıyla oluşturuldu.\n'
                      'Başvurunuz incelendikten sonra\nhesabınız aktifleştirilecektir.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // İşletme adı rozeti
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF4A90D9).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store,
                              color: Color(0xFF4A90D9), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isletmeAdiCtrl.text,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Geri dön butonu
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A90D9),
                          side: const BorderSide(color: Color(0xFF4A90D9)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        child: Text(
                          'Ana Sayfaya Dön',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
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
