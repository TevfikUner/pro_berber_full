import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 30 dakikalık saat slotu — yeşil=müsait, kırmızı=dolu, gri=kapsam dışı
class SaatSlotWidget extends StatelessWidget {
  final String saat;
  final SlotDurumu durum;
  final bool secili;
  final VoidCallback? onTap;

  const SaatSlotWidget({
    super.key,
    required this.saat,
    required this.durum,
    this.secili = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final Color borderColor;

    if (secili) {
      bgColor = AppTheme.gold;
      textColor = AppTheme.black;
      borderColor = AppTheme.gold;
    } else {
      switch (durum) {
        case SlotDurumu.musait:
          bgColor = AppTheme.slotGreen.withOpacity(0.18);
          textColor = AppTheme.success;
          borderColor = AppTheme.slotGreen;
          break;
        case SlotDurumu.dolu:
          bgColor = AppTheme.slotRed.withOpacity(0.18);
          textColor = AppTheme.error;
          borderColor = AppTheme.slotRed;
          break;
        case SlotDurumu.kapsamDisi:
          bgColor = AppTheme.surface;
          textColor = AppTheme.textSecondary;
          borderColor = Colors.transparent;
          break;
      }
    }

    return GestureDetector(
      onTap: durum == SlotDurumu.musait ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: secili ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            saat,
            style: TextStyle(
              color: textColor,
              fontWeight: secili ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

enum SlotDurumu { musait, dolu, kapsamDisi }
