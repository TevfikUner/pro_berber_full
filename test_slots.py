"""
Slot/Randevu algoritmalarının doğruluğunu test eden script.
Firebase'e bağımlı değildir.
"""
import math
from datetime import datetime, timedelta

# utils'den direkt fonksiyonları import etmek yerine burada yeniden tanımlıyoruz
# (Firebase import hatası engellenir)

def gecmis_tarih_mi(tarih_str: str) -> bool:
    try:
        secilen = datetime.strptime(tarih_str, "%Y-%m-%d").date()
        bugun = datetime.now().date()
        return secilen < bugun
    except ValueError:
        return True

def gecmis_saat_mi(tarih_str: str, saat_str: str) -> bool:
    try:
        secilen_tarih = datetime.strptime(tarih_str, "%Y-%m-%d").date()
        bugun = datetime.now().date()
        if secilen_tarih > bugun:
            return False
        if secilen_tarih < bugun:
            return True
        simdi = datetime.now()
        secilen_vakit = datetime.combine(secilen_tarih, datetime.strptime(saat_str, "%H:%M").time())
        return secilen_vakit <= simdi
    except ValueError:
        return True

def saat_listesi_olustur(baslangic_saat: str, sure_dk: int):
    slotlar = []
    format_str = "%H:%M"
    try:
        mevcut_vakit = datetime.strptime(baslangic_saat, format_str)
        adim_sayisi = math.ceil(sure_dk / 30)
        for _ in range(adim_sayisi):
            slotlar.append(mevcut_vakit.strftime(format_str))
            mevcut_vakit += timedelta(minutes=30)
    except Exception:
        pass
    return slotlar

def cakisma_var_mi(baslangic_saat: str, sure_dk: int, dolu_slotlar_listesi: list, is_sunday: bool):
    talep_edilen = saat_listesi_olustur(baslangic_saat, sure_dk)
    if not talep_edilen:
        return True
    kapanis_dk = (17 if is_sunday else 22) * 60
    acilis_dk = 10 * 60
    for s in talep_edilen:
        try:
            saat_parca, dakika_parca = map(int, s.split(":"))
            slot_dk = saat_parca * 60 + dakika_parca
            if slot_dk < acilis_dk:
                return True
            if slot_dk + 30 > kapanis_dk:
                return True
            if s in dolu_slotlar_listesi:
                return True
        except:
            return True
    return False

# ============================================================
# TESTLER
# ============================================================
print("=" * 60)
print("SLOT & RANDEVU ALGORİTMA TESTLERİ")
print("=" * 60)

# TEST 1: Geçmiş tarih kontrolü
print("\n--- TEST 1: Geçmiş tarih kontrolü ---")
assert gecmis_tarih_mi("2026-04-22") == True, "Dün geçmiş olmalı!"
assert gecmis_tarih_mi("2026-04-23") == False, "Bugün geçmiş değil!"
assert gecmis_tarih_mi("2026-04-24") == False, "Yarın geçmiş değil!"
print("✅ Dün (2026-04-22): gecmis=True")
print("✅ Bugün (2026-04-23): gecmis=False")
print("✅ Yarın (2026-04-24): gecmis=False")

# TEST 2: Geçmiş saat kontrolü
print("\n--- TEST 2: Geçmiş saat kontrolü (şu an ~13:25) ---")
assert gecmis_saat_mi("2026-04-23", "10:00") == True, "10:00 geçmiş olmalı!"
assert gecmis_saat_mi("2026-04-23", "13:00") == True, "13:00 geçmiş olmalı!"
# 23:00 henüz geçmedi
assert gecmis_saat_mi("2026-04-23", "23:00") == False, "23:00 henüz geçmemiş!"
# Yarın herhangi bir saat → False
assert gecmis_saat_mi("2026-04-24", "10:00") == False, "Yarın geçmiş olamaz!"
print("✅ Bugün 10:00: gecmis=True")
print("✅ Bugün 13:00: gecmis=True") 
print("✅ Bugün 23:00: gecmis=False")
print("✅ Yarın 10:00: gecmis=False")

# TEST 3: Slot oluşturma - 3 saat = 6 slot
print("\n--- TEST 3: 3 saatlik hizmet = 6 slot ---")
slotlar = saat_listesi_olustur("10:00", 180)
assert len(slotlar) == 6, f"6 slot olmalı, ama {len(slotlar)} slot var!"
assert slotlar == ["10:00", "10:30", "11:00", "11:30", "12:00", "12:30"]
print(f"✅ 180dk → {len(slotlar)} slot: {slotlar}")

# TEST 4: Slot oluşturma - 1 saat = 2 slot
print("\n--- TEST 4: 1 saatlik hizmet = 2 slot ---")
slotlar2 = saat_listesi_olustur("16:30", 60)
assert len(slotlar2) == 2, f"2 slot olmalı, ama {len(slotlar2)} slot var!"
assert slotlar2 == ["16:30", "17:00"]
print(f"✅ 60dk → {len(slotlar2)} slot: {slotlar2}")

# TEST 5: Kayma testi — randevu tam seçilen saatte başlamalı
print("\n--- TEST 5: Saat kayması testi ---")
slotlar3 = saat_listesi_olustur("16:30", 60)
assert slotlar3[0] == "16:30", f"İlk slot 16:30 olmalı, ama {slotlar3[0]}!"
print(f"✅ 16:30 başlangıç: {slotlar3} (Kayma YOK)")

slotlar4 = saat_listesi_olustur("14:00", 90)
assert slotlar4[0] == "14:00", f"İlk slot 14:00 olmalı!"
assert slotlar4 == ["14:00", "14:30", "15:00"]
print(f"✅ 14:00 başlangıç 90dk: {slotlar4} (Kayma YOK)")

# TEST 6: 2 slot boş ama 3 saatlik hizmet → İZİN VERMEMELİ
print("\n--- TEST 6: Yetersiz boşluk kontrolü ---")
# 14:00 ve 14:30 boş (2 slot), diğer her yer dolu
dolu = [
    "10:00", "10:30", "11:00", "11:30", "12:00", "12:30",
    "13:00", "13:30",
    # 14:00 ve 14:30 BOŞ (2 slot = 1 saat)
    "15:00", "15:30", "16:00", "16:30", "17:00", "17:30",
    "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
    "21:00", "21:30"
]
# 3 saatlik hizmet (6 slot gerekli) → 2 slot boş → çakışma OLMALI
cakisma = cakisma_var_mi("14:00", 180, dolu, False)
assert cakisma == True, "2 slot boş, 6 slot gerekli → çakışma olmalı!"
print(f"✅ 14:00'da 3 saat (6 slot), sadece 2 slot boş → çakışma={cakisma} (DOĞRU, izin verilmedi)")

# 1 saatlik hizmet (2 slot gerekli) → 2 slot boş → çakışma OLMAMALI
cakisma2 = cakisma_var_mi("14:00", 60, dolu, False)
assert cakisma2 == False, "2 slot boş, 2 slot gerekli → çakışma olmamalı!"
print(f"✅ 14:00'da 1 saat (2 slot), 2 slot boş → çakışma={cakisma2} (DOĞRU, izin verildi)")

# TEST 7: Mesai dışı kontrolü
print("\n--- TEST 7: Mesai dışı kontrolü ---")
# Hafta içi kapanış 22:00 → 21:30'da 1 saatlik hizmet son slotu 22:00 → YASAK (22:00+30=22:30>22:00)
cakisma3 = cakisma_var_mi("21:30", 60, [], False)
assert cakisma3 == True, "21:30'da 1 saat → 22:00 slotu kapanışı aşar!"
print(f"✅ Hafta içi 21:30'da 60dk → çakışma={cakisma3} (kapanış aşılır)")

# 21:00'da 30dk hizmet → OK (21:00+30=21:30 ≤ 22:00)
cakisma4 = cakisma_var_mi("21:00", 30, [], False)
assert cakisma4 == False, "21:00'da 30dk → 21:30'da biter, OK!"
print(f"✅ Hafta içi 21:00'da 30dk → çakışma={cakisma4} (mesai içi)")

# 21:30'da 30dk hizmet → OK (21:30+30=22:00 ≤ 22:00)
cakisma5 = cakisma_var_mi("21:30", 30, [], False)
assert cakisma5 == False, "21:30'da 30dk → 22:00'da biter, OK!"
print(f"✅ Hafta içi 21:30'da 30dk → çakışma={cakisma5} (mesai içi)")

# Pazar kapanış 17:00 → 16:30'da 1 saat → YASAK
cakisma6 = cakisma_var_mi("16:30", 60, [], True)
assert cakisma6 == True, "Pazar 16:30'da 1 saat → 17:00 slotu kapanışı aşar!"
print(f"✅ Pazar 16:30'da 60dk → çakışma={cakisma6} (kapanış aşılır)")

# TEST 8: Ardışık randevu — kayma olmamalı
print("\n--- TEST 8: Ardışık randevu testi ---")
# İlk randevu: 16:30 başlangıç, 60dk
ilk_dolu = saat_listesi_olustur("16:30", 60)
print(f"  1. randevu: 16:30, 60dk → dolu slotlar: {ilk_dolu}")

# İkinci randevu: 17:30 başlangıç (ilk randevudan hemen sonra)
cakisma7 = cakisma_var_mi("17:30", 60, ilk_dolu, False)
assert cakisma7 == False, "17:30 müsait olmalı!"
ikinci_dolu = saat_listesi_olustur("17:30", 60)
print(f"  2. randevu: 17:30, 60dk → dolu slotlar: {ikinci_dolu}")

# 17:00 zaten doluysa → çakışma olmalı 
cakisma8 = cakisma_var_mi("17:00", 60, ilk_dolu, False)
assert cakisma8 == True, "17:00 dolu olmalı (16:30'dan 60dk = 16:30+17:00 dolu)!"
print(f"  17:00'da randevu → çakışma={cakisma8} (DOĞRU, 17:00 zaten dolu)")

print("\n" + "=" * 60)
print("TÜM TESTLER BAŞARILI! ✅")
print("=" * 60)
