import 'package:flutter/material.dart';
import '../models/hizmet.dart';
import '../models/berber.dart';

class RandevuProvider extends ChangeNotifier {
  // ── Adım 1: Hizmetler ─────────────────────────────────────
  final List<Hizmet> seciliHizmetler = [];

  void hizmetToggle(Hizmet h) {
    if (seciliHizmetler.contains(h)) {
      seciliHizmetler.remove(h);
    } else {
      seciliHizmetler.add(h);
    }
    notifyListeners();
  }

  bool isHizmetSecili(Hizmet h) => seciliHizmetler.contains(h);

  int get toplamSureDk => seciliHizmetler.fold(0, (s, h) => s + h.sure);
  double get toplamFiyat => seciliHizmetler.fold(0.0, (s, h) => s + h.fiyat);

  // ── Adım 2: Berber ────────────────────────────────────────
  Berber? seciliBerber;

  void berberSec(Berber b) {
    seciliBerber = b;
    notifyListeners();
  }

  // ── Adım 3: Tarih ─────────────────────────────────────────
  DateTime? seciliTarih;

  void tarihSec(DateTime t) {
    seciliTarih = t;
    seciliSaat = null; // Tarih değişince saat sıfırla
    notifyListeners();
  }

  // ── Adım 4: Saat ──────────────────────────────────────────
  String? seciliSaat;

  void saatSec(String s) {
    seciliSaat = s;
    notifyListeners();
  }

  // ── Son onaydan sonra sıfırla ─────────────────────────────
  void reset() {
    seciliHizmetler.clear();
    seciliBerber = null;
    seciliTarih = null;
    seciliSaat = null;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────
  bool get adim1Tamam => seciliHizmetler.isNotEmpty;
  bool get adim2Tamam => seciliBerber != null;
  bool get adim3Tamam => seciliTarih != null;
  bool get adim4Tamam => seciliSaat != null;
}
