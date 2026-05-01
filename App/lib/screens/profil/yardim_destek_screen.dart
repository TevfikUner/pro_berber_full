import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../data/sss_data.dart';

/// Yardım & Destek ekranı — SSS + Bize Ulaşın
class YardimDestekScreen extends StatelessWidget {
  const YardimDestekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.black,
        appBar: AppBar(
          backgroundColor: AppTheme.black,
          leading: const BackButton(color: AppTheme.gold),
          title: Text('Yardım & Destek',
              style: GoogleFonts.playfairDisplay(
                  color: AppTheme.gold, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: AppTheme.gold,
            labelColor: AppTheme.gold,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'SSS', icon: Icon(Icons.help_outline, size: 20)),
              Tab(text: 'Bize Ulaşın', icon: Icon(Icons.mail_outline, size: 20)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SSSTab(),
            _BizeUlasinTab(),
          ],
        ),
      ),
    );
  }
}

// ── SSS Sekmesi ──────────────────────────────────
class _SSSTab extends StatelessWidget {
  const _SSSTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: SSS.sorular.length,
      itemBuilder: (_, i) {
        final sss = SSS.sorular[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gold.withOpacity(0.1)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              iconColor: AppTheme.gold,
              collapsedIconColor: AppTheme.textSecondary,
              title: Text(sss.soru,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              children: [
                Text(sss.cevap,
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Bize Ulaşın Sekmesi ──────────────────────────
class _BizeUlasinTab extends StatefulWidget {
  const _BizeUlasinTab();

  @override
  State<_BizeUlasinTab> createState() => _BizeUlasinTabState();
}

class _BizeUlasinTabState extends State<_BizeUlasinTab> {
  String? _seciliKonu;
  final _mesajCtrl = TextEditingController();
  final List<File> _ekliDosyalar = [];

  final List<String> _konular = [
    'Randevu Sorunu',
    'Ödeme / Fiyat',
    'Hesap Problemi',
    'Uygulama Hatası',
    'Öneri / İstek',
    'Diğer',
  ];

  Future<void> _dosyaEkle() async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dosya Ekle', style: GoogleFonts.playfairDisplay(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt, color: AppTheme.gold)),
                title: Text('Fotoğraf Çek', style: GoogleFonts.inter(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library, color: AppTheme.gold)),
                title: Text('Galeriden Seç', style: GoogleFonts.inter(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.attach_file, color: AppTheme.gold)),
                title: Text('Dosya Seç', style: GoogleFonts.inter(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        ),
      ),
    );

    if (secim == null) return;

    if (secim == 'camera' || secim == 'gallery') {
      final picker = ImagePicker();
      final img = await picker.pickImage(
        source: secim == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024, imageQuality: 85,
      );
      if (img != null) setState(() => _ekliDosyalar.add(File(img.path)));
    } else {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        setState(() => _ekliDosyalar.add(File(result.files.first.path!)));
      }
    }
  }

  Future<void> _mailGonder() async {
    if (_seciliKonu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir konu seçin'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_mesajCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen mesajınızı yazın'), backgroundColor: AppTheme.error),
      );
      return;
    }

    String dosyaBilgisi = '';
    if (_ekliDosyalar.isNotEmpty) {
      dosyaBilgisi = '\n\n[${_ekliDosyalar.length} dosya eklendi - dosyalar e-postaya eklenecek]';
    }

    final subject = Uri.encodeComponent('Premium Berber - $_seciliKonu');
    final body = Uri.encodeComponent('${_mesajCtrl.text.trim()}$dosyaBilgisi');
    final uri = Uri.parse('mailto:premiumbarber@gmail.com?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-posta uygulaması açılamadı'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _mesajCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Açıklama
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.gold, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sorunlarınızı bize bildirin, en kısa sürede dönüş yapalım.',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Konu Seçimi
          Text('Konu Seçin',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text('Konu seçiniz...', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                value: _seciliKonu,
                dropdownColor: AppTheme.surface,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.gold),
                items: _konular.map((k) => DropdownMenuItem(
                  value: k,
                  child: Text(k, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                )).toList(),
                onChanged: (v) => setState(() => _seciliKonu = v),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mesaj Alanı
          Text('Mesajınız',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _mesajCtrl,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Sorununuzu veya isteğinizi detaylı açıklayın...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: AppTheme.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.gold.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.gold),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dosya / Görsel Ekleme
          Text('Dosya veya Görsel Ekle',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _dosyaEkle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppTheme.gold.withOpacity(0.5), size: 32),
                  const SizedBox(height: 8),
                  Text('Fotoğraf, ekran görüntüsü veya dosya ekleyin',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
          // Eklenen dosyalar listesi
          if (_ekliDosyalar.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._ekliDosyalar.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: AppTheme.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    e.value.path.split('/').last,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  )),
                  GestureDetector(
                    onTap: () => setState(() => _ekliDosyalar.removeAt(e.key)),
                    child: const Icon(Icons.close, color: AppTheme.error, size: 18),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 20),

          // Gönder Butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _mailGonder,
              icon: const Icon(Icons.send, color: AppTheme.black),
              label: Text('E-posta Gönder',
                  style: GoogleFonts.inter(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
