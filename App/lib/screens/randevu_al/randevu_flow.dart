import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/altin_buton.dart';
import '../../providers/randevu_provider.dart';
import '../../models/berber.dart';
import 'adim1_hizmet.dart';
import 'adim2_personel.dart';
import 'adim3_tarih.dart';
import 'adim4_saat.dart';
import 'adim5_form.dart';

class RandevuFlow extends StatefulWidget {
  final int? salonId;
  /// Favori berber ile hızlı randevu alırken berber bilgisi geçirilir
  /// Personel seçimi adımı atlanır
  final Berber? favoriBerber;

  const RandevuFlow({super.key, this.salonId, this.favoriBerber});

  @override
  State<RandevuFlow> createState() => _RandevuFlowState();
}

class _RandevuFlowState extends State<RandevuFlow> {
  late final PageController _pageCtrl;
  late int _currentStep;
  late final bool _berberAtla;
  late final List<String> _stepBasliklari;
  late final List<Widget> _sayfalar;

  @override
  void initState() {
    super.initState();
    _berberAtla = widget.favoriBerber != null;

    if (_berberAtla) {
      // Favori berberle geldi → adım 2 atla
      _stepBasliklari = ['Hizmet Seçin', 'Tarih Seçin', 'Saat Seçin', 'Bilgileriniz'];
      _sayfalar = const [Adim1Hizmet(), Adim3Tarih(), Adim4Saat(), Adim5Form()];
    } else {
      _stepBasliklari = ['Hizmet Seçin', 'Personel Seçin', 'Tarih Seçin', 'Saat Seçin', 'Bilgileriniz'];
      _sayfalar = const [Adim1Hizmet(), Adim2Personel(), Adim3Tarih(), Adim4Saat(), Adim5Form()];
    }

    _currentStep = 0;
    _pageCtrl = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RandevuProvider>();
      // Salon ID'yi provider'a set et
      if (widget.salonId != null) {
        provider.salonSec(widget.salonId!);
      }
      // Favori berber varsa otomatik seç
      if (widget.favoriBerber != null) {
        provider.berberSec(widget.favoriBerber!);
      }
    });
  }

  int get _totalSteps => _stepBasliklari.length;

  void _ileri() {
    final provider = context.read<RandevuProvider>();

    if (_berberAtla) {
      // 4 adımlı akış: Hizmet → Tarih → Saat → Form
      if (_currentStep == 0 && !provider.adim1Tamam) {
        _snack('Lütfen en az bir hizmet seçin'); return;
      }
      if (_currentStep == 1 && !provider.adim3Tamam) {
        _snack('Lütfen bir tarih seçin'); return;
      }
      if (_currentStep == 2 && !provider.adim4Tamam) {
        _snack('Lütfen bir saat seçin'); return;
      }
    } else {
      // 5 adımlı akış: Hizmet → Personel → Tarih → Saat → Form
      if (_currentStep == 0 && !provider.adim1Tamam) {
        _snack('Lütfen en az bir hizmet seçin'); return;
      }
      if (_currentStep == 1 && !provider.adim2Tamam) {
        _snack('Lütfen bir personel seçin'); return;
      }
      if (_currentStep == 2 && !provider.adim3Tamam) {
        _snack('Lütfen bir tarih seçin'); return;
      }
      if (_currentStep == 3 && !provider.adim4Tamam) {
        _snack('Lütfen bir saat seçin'); return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _geri() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gold),
          onPressed: _geri,
        ),
        title: Column(
          children: [
            Text(_stepBasliklari[_currentStep],
                style: GoogleFonts.playfairDisplay(
                    color: AppTheme.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('Adım ${_currentStep + 1} / $_totalSteps',
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: StepIndicator(
                currentStep: _currentStep, totalSteps: _totalSteps),
          ),
          // Sayfa içeriği
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: _sayfalar,
            ),
          ),
          // Alt bar — son adımda Adim5 kendi butonunu yönetir
          if (_currentStep < _totalSteps - 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: AltinButon(text: 'İleri →', onPressed: _ileri),
            ),
        ],
      ),
    );
  }
}
