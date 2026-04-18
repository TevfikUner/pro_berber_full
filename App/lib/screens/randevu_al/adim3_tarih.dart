import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/randevu_provider.dart';

class Adim3Tarih extends StatefulWidget {
  const Adim3Tarih({super.key});

  @override
  State<Adim3Tarih> createState() => _Adim3TarihState();
}

class _Adim3TarihState extends State<Adim3Tarih> {
  Set<String> _musaitTarihler = {};
  bool _yukleniyor = true;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final provider = context.read<RandevuProvider>();
    final berberId = provider.seciliBerber?.id;
    try {
      final data = await ApiService.getMusaitTakvim(berberId: berberId);
      if (mounted) {
        setState(() {
          _musaitTarihler = data.map((e) => e['tarih'] as String).toSet();
          _yukleniyor = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  bool _isDayEnabled(DateTime day) {
    // Geçmiş günler kapalı
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    final str =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _musaitTarihler.contains(str);
  }

  String _tarihFormatla(DateTime t) {
    const aylar = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const gunler = [
      '', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
      'Cuma', 'Cumartesi', 'Pazar'
    ];
    return '${gunler[t.weekday]}, ${t.day} ${aylar[t.month]} ${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RandevuProvider>();
    final now = DateTime.now();
    // İçinde bulunulan ayın 1'i
    final ayBaslangic = DateTime(now.year, now.month, 1);
    // 2 ay sonra
    final ayBitis = DateTime(now.year, now.month + 2, 0);

    if (_yukleniyor) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.gold));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // ── Takvim ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withOpacity(0.15)),
            ),
            child: TableCalendar(
              locale: 'tr_TR',
              firstDay: ayBaslangic,
              lastDay: ayBitis,
              focusedDay: _focusedDay,
              // Ayı değiştirince lockedDay sıfırlanmasın
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) =>
                  isSameDay(provider.seciliTarih, day),
              enabledDayPredicate: _isDayEnabled,
              onDaySelected: (selected, focused) {
                if (!_isDayEnabled(selected)) return;
                provider.tarihSec(selected);
                setState(() => _focusedDay = focused);
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Ay',
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                outsideTextStyle: TextStyle(
                    color: Colors.white.withOpacity(0.2), fontSize: 13),
                // Bugün
                todayDecoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.25),
                    shape: BoxShape.circle),
                todayTextStyle:
                    const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                // Seçili gün
                selectedDecoration: const BoxDecoration(
                    color: AppTheme.gold, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(
                    color: AppTheme.black, fontWeight: FontWeight.bold),
                // Normal açık günler
                defaultTextStyle:
                    const TextStyle(color: Colors.white, fontSize: 13),
                weekendTextStyle:
                    const TextStyle(color: Colors.white, fontSize: 13),
                // Kapalı günler (soluk)
                disabledTextStyle: TextStyle(
                    color: Colors.white.withOpacity(0.18), fontSize: 13),
                disabledDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03)),
                // Müsait günlere altın nokta
                markerDecoration: const BoxDecoration(
                    color: AppTheme.gold, shape: BoxShape.circle),
                markersMaxCount: 1,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: AppTheme.gold, size: 28),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: AppTheme.gold, size: 28),
                headerPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                weekendStyle: GoogleFonts.inter(
                    color: AppTheme.gold.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              // Müsait günleri işaretle
              eventLoader: (day) {
                final str =
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                return _musaitTarihler.contains(str) ? ['musait'] : [];
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Seçilen gün gösterimi ─────────────────────────
          if (provider.seciliTarih != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.gold.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppTheme.gold, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _tarihFormatla(provider.seciliTarih!),
                    style: GoogleFonts.inter(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // ── Lejant ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LejantItem(renk: AppTheme.gold, label: 'Müsait gün'),
              const SizedBox(width: 20),
              _LejantItem(
                  renk: Colors.white.withOpacity(0.18), label: 'Kapalı gün'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tatil ve personel izin günleri otomatik olarak kapalıdır.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LejantItem extends StatelessWidget {
  final Color renk;
  final String label;
  const _LejantItem({required this.renk, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: renk, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.inter(
              color: AppTheme.textSecondary, fontSize: 11)),
    ]);
  }
}
