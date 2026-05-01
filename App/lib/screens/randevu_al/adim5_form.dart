import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/altin_buton.dart';
import '../../services/api_service.dart';
import '../../providers/randevu_provider.dart';
import 'onay_sayfasi.dart';

class Adim5Form extends StatefulWidget {
  const Adim5Form({super.key});

  @override
  State<Adim5Form> createState() => _Adim5FormState();
}

class _Adim5FormState extends State<Adim5Form> {
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  
  bool _loading = false;
  bool _profilYukleniyor = true;

  @override
  void initState() {
    super.initState();
    _profilBilgileriniCek();
  }

  Future<void> _profilBilgileriniCek() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null) {
        final parts = user!.displayName!.split(' ');
        if (parts.isNotEmpty) _adCtrl.text = parts.first;
        if (parts.length > 1) _soyadCtrl.text = parts.sublist(1).join(' ');
      }

      final profil = await ApiService.profilGetir();
      if (profil != null) {
        if (profil['ad']?.toString().isNotEmpty ?? false) _adCtrl.text = profil['ad'];
        if (profil['soyad']?.toString().isNotEmpty ?? false) _soyadCtrl.text = profil['soyad'];
        if (profil['telefon']?.toString().isNotEmpty ?? false) {
          String tel = profil['telefon'].toString();
          if (tel.startsWith('0')) tel = tel.substring(1);
          _telefonCtrl.text = tel;
        }
      }
    } catch (e) {
      debugPrint("Profil çekme hatası: $e");
    } finally {
      if (mounted) setState(() => _profilYukleniyor = false);
    }
  }

  Future<void> _randevuOlustur() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final provider = context.read<RandevuProvider>();

    try {
      final berber = provider.seciliBerber;
      final tarih = provider.seciliTarih;
      final saat = provider.seciliSaat;
      if (berber == null || tarih == null || saat == null) {
        throw Exception('Lütfen tüm adımları tamamlayın.');
      }

      final tarihStr = '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}';

      final sonuc = await ApiService.randevuOlustur(
        berberId: berber.id,
        saat: saat,
        tarih: tarihStr,
        hizmetIds: provider.seciliHizmetler.map((h) => h.id).toList(),
        ad: _adCtrl.text.trim(),
        soyad: _soyadCtrl.text.trim(),
        telefon: '0${_telefonCtrl.text.trim()}',
      );

      final List<String> hizmetAdlari = provider.seciliHizmetler.map((h) => h.ad).toList();
      final double toplamFiyat = provider.toplamFiyat;
      final String berberTamAd = "${berber.ad} ${berber.soyad}";

      provider.reset(); 

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OnaySayfasi(
            tarih: tarihStr,
            saat: saat,
            berber: berberTamAd,
            hizmetler: hizmetAdlari,
            toplamFiyat: toplamFiyat,
            randevuId: sonuc['randevu_id']?.toString() ?? '',
          ),
        ),
        (route) => route.isFirst,
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _telefonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RandevuProvider>();
    final berberTamAd = provider.seciliBerber != null 
        ? "${provider.seciliBerber!.ad} ${provider.seciliBerber!.soyad}" 
        : "-";

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _OzetSatir(Icons.person, 'Personel', berberTamAd),
                  _OzetSatir(Icons.calendar_today, 'Tarih', provider.seciliTarih == null ? '-' : '${provider.seciliTarih!.day}.${provider.seciliTarih!.month}.${provider.seciliTarih!.year}'),
                  _OzetSatir(Icons.access_time, 'Saat', provider.seciliSaat ?? '-'),
                  _OzetSatir(Icons.content_cut, 'Hizmetler', provider.seciliHizmetler.map((h) => h.ad).join(', ')),
                  Divider(color: AppTheme.gold.withOpacity(0.15)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Toplam', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                      Text('${provider.toplamFiyat.toStringAsFixed(0)} ₺',
                          style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('İletişim Bilgileriniz', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_profilYukleniyor) 
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: AppTheme.gold)))
            else
              Column(
                children: [
                  Row(children: [
                    Expanded(child: TextFormField(controller: _adCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person_outline, color: AppTheme.gold)), validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _soyadCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Soyad'), validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null)),
                  ]),
                  const SizedBox(height: 14),
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
                      prefixStyle: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                      counterText: '',
                      hintText: '5XX XXX XX XX',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                    validator: (v) => (v?.trim().length != 10) ? '10 rakam giriniz' : null,
                  ),
                ],
              ),
            const SizedBox(height: 32),
            AltinButon(text: 'Randevumu Onayla', onPressed: _randevuOlustur, loading: _loading, icon: const Icon(Icons.check_circle_outline, color: AppTheme.black, size: 20)),
          ],
        ),
      ),
    );
  }
}

class _OzetSatir extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _OzetSatir(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: AppTheme.gold, size: 16),
        const SizedBox(width: 10),
        Text('$label: ', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}