import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/altin_buton.dart';
import '../../widgets/berber_desen.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  bool _loading = false;
  bool _sifreGizli = true;

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.girisYap(_emailCtrl.text.trim(), _sifreCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Giriş başarısız: ${e.toString()}'),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sifremiUnuttum() async {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());

    await showDialog(
      context: context,
      builder: (ctx) {
        bool sending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
              ),
              title: Text(
                'Şifremi Unuttum',
                style: GoogleFonts.playfairDisplay(
                    color: AppTheme.gold, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'E-posta adresinizi girin, şifre sıfırlama bağlantısını göndereceğiz.',
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon:
                          Icon(Icons.email_outlined, color: AppTheme.gold),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('İptal',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: sending
                      ? null
                      : () async {
                          final email = resetEmailCtrl.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Geçerli bir e-posta girin')),
                            );
                            return;
                          }
                          setDialogState(() => sending = true);
                          try {
                            await AuthService.sifreSifirla(email);
                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Şifre sıfırlama e-postası $email adresine gönderildi.'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => sending = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: ${e.toString()}'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.black))
                      : Text('Gönder',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Geri butonu
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: AppTheme.gold),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logo
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC9A84C).withOpacity(0.35),
                              blurRadius: 40,
                              spreadRadius: 8,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Hoş Geldin',
                        style: GoogleFonts.playfairDisplay(
                            color: AppTheme.gold,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Randevun seni bekliyor',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 40),
                    // E-posta
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon:
                            Icon(Icons.email_outlined, color: AppTheme.gold),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@'))
                              ? 'Geçerli e-posta girin'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    // Şifre
                    TextFormField(
                      controller: _sifreCtrl,
                      obscureText: _sifreGizli,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: AppTheme.gold),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _sifreGizli
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.textSecondary),
                          onPressed: () =>
                              setState(() => _sifreGizli = !_sifreGizli),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                    ),
                    // Şifremi Unuttum linki
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _sifremiUnuttum,
                        child: Text(
                          'Şifremi Unuttum',
                          style: GoogleFonts.inter(
                            color: AppTheme.gold.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AltinButon(
                        text: 'Giriş Yap',
                        onPressed: _girisYap,
                        loading: _loading),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: RichText(
                          text: TextSpan(
                            text: 'Hesabın yok mu? ',
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
                            children: [
                              TextSpan(
                                  text: 'Kayıt Ol',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold)),
                            ],
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
