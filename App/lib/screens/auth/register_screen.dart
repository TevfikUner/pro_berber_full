import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/altin_buton.dart';
import '../../widgets/berber_desen.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  bool _loading = false;
  bool _sifreGizli = true;

  Future<void> _kayitOl() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.kayitOl(
        email: _emailCtrl.text.trim(),
        sifre: _sifreCtrl.text,
        ad: _adCtrl.text.trim(),
        soyad: _soyadCtrl.text.trim(),
        telefon: '0${_telefonCtrl.text.trim()}',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kayıt başarısız: ${e.toString()}'),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_adCtrl, _soyadCtrl, _telefonCtrl, _emailCtrl, _sifreCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard,
      bool obscure = false,
      Widget? suffix,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.gold),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gold),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 8),
                    Text('Hesap Oluştur',
                        style: GoogleFonts.playfairDisplay(
                            color: AppTheme.gold,
                            fontSize: 30,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Birkaç adımda randevu almaya başla',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 30),
                    Row(children: [
                      Expanded(
                        child: _field(_adCtrl, 'Ad', Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Zorunlu' : null),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(_soyadCtrl, 'Soyad', Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Zorunlu' : null),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    // Telefon alanı: başında sabit "0" prefix gösterilir
                    TextFormField(
                      controller: _telefonCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.gold),
                        prefixText: '0  ',
                        prefixStyle: TextStyle(
                            color: AppTheme.gold, fontWeight: FontWeight.bold),
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
                    _field(_emailCtrl, 'E-posta', Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Geçerli e-posta girin' : null),
                    const SizedBox(height: 14),
                    _field(_sifreCtrl, 'Şifre', Icons.lock_outline,
                        obscure: _sifreGizli,
                        suffix: IconButton(
                          icon: Icon(
                              _sifreGizli ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textSecondary),
                          onPressed: () =>
                              setState(() => _sifreGizli = !_sifreGizli),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'En az 6 karakter' : null),
                    const SizedBox(height: 30),
                    AltinButon(
                        text: 'Kayıt Ol', onPressed: _kayitOl, loading: _loading),
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
