import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/saat_slot_widget.dart';
import '../../services/api_service.dart';
import '../../providers/randevu_provider.dart';

class Adim4Saat extends StatefulWidget {
  const Adim4Saat({super.key});

  @override
  State<Adim4Saat> createState() => _Adim4SaatState();
}

class _Adim4SaatState extends State<Adim4Saat> {
  List<String> _doluSlotlar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final provider = context.read<RandevuProvider>();
    final berber = provider.seciliBerber;
    final tarih = provider.seciliTarih;
    // Null guard — adım 2 veya 3 atlandıysa yükleme yapma
    if (berber == null || tarih == null) {
      if (mounted) setState(() => _yukleniyor = false);
      return;
    }
    try {
      final data = await ApiService.getDoluSaatler(berber.id, _tarihStr(tarih));
      if (mounted) setState(() { _doluSlotlar = data; _yukleniyor = false; });
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  String _tarihStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Slot Algoritması ─────────────────────────────────────
  // 30-dk blok listesi oluştur (backend ile aynı birim)
  List<String> _generate30MinBlocks(String startTime, int durationMin) {
    final blocks = <String>[];
    final parts = startTime.split(':');
    int totalMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    // Ceiling: 40dk → 2 blok (2×30=60dk bloke), 90dk → 3 blok
    final steps = (durationMin + 29) ~/ 30;
    for (int i = 0; i < steps; i++) {
      final h = (totalMin + i * 30) ~/ 60;
      final m = (totalMin + i * 30) % 60;
      blocks.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
    }
    return blocks;
  }

  SlotDurumu _slotDurumu(String saat, int toplamSureDk, bool isPazar) {
    final blocks = _generate30MinBlocks(saat, toplamSureDk);
    if (blocks.isEmpty) return SlotDurumu.kapsamDisi;

    // Kapanış kontrolü: son bloğun sonu (+ 30dk) kapanışı geçmemeli
    final kapanis = isPazar ? 17 * 60 : 22 * 60;
    final lastMin = () {
      final p = blocks.last.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]) + 30; // son bloğun sonu
    }();
    if (lastMin > kapanis) return SlotDurumu.kapsamDisi;

    // Açılış kontrolü
    final parts = saat.split(':');
    final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    if (startMin < 10 * 60) return SlotDurumu.kapsamDisi;

    // Doluluk kontrolü — backend 30dk slotlar yolluyor, blocks da 30dk
    for (final b in blocks) {
      if (_doluSlotlar.contains(b)) return SlotDurumu.dolu;
    }
    return SlotDurumu.musait;
  }

  List<String> _tumSlotlar(bool isPazar) {
    final kapanis = isPazar ? 17 : 22;
    final slots = <String>[];
    for (int h = 10; h < kapanis; h++) {
      slots.add('${h.toString().padLeft(2, '0')}:00');
      slots.add('${h.toString().padLeft(2, '0')}:30');
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RandevuProvider>();
    final tarih = provider.seciliTarih;
    // Tarih seçilmediyse boş ekran göster
    if (tarih == null) {
      return const Center(
          child: Text('Lütfen önce bir tarih seçin.',
              style: TextStyle(color: Colors.white60)));
    }
    final isPazar = tarih.weekday == DateTime.sunday;
    final sureDk = provider.toplamSureDk;
    final slots = _tumSlotlar(isPazar);

    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${tarih.day}.${tarih.month}.${tarih.year} — ${isPazar ? 'Pazar' : 'Hafta içi'}',
                style: GoogleFonts.inter(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(),
            // Lejant
            _Lejant(color: AppTheme.success, label: 'Müsait'),
            const SizedBox(width: 10),
            _Lejant(color: AppTheme.error, label: 'Dolu'),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Toplam süre: $sureDk dk — seçili saat bu süre boyunca müsait olmalı',
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: slots.length,
            itemBuilder: (_, i) {
              final saat = slots[i];
              final durum = _slotDurumu(saat, sureDk, isPazar);
              final secili = provider.seciliSaat == saat;
              return SaatSlotWidget(
                saat: saat,
                durum: durum,
                secili: secili,
                onTap: () => provider.saatSec(saat),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Lejant extends StatelessWidget {
  final Color color;
  final String label;
  const _Lejant({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
    ]);
  }
}
