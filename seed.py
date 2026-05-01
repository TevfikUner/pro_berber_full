# seed.py - Veritabani baslangic verileriyle doldurur (Pazaryeri Modeli + Sosyal Medya)
import sys
sys.stdout.reconfigure(encoding='utf-8')
from database import SessionLocal, engine
import models

# Tabloları oluştur (Yeni eklenen sütunlar dahil)
models.Base.metadata.create_all(bind=engine)
db = SessionLocal()

# Temizlik: Çakışma olmaması için mevcut verileri silelim
db.query(models.Berber).delete()
db.query(models.Hizmet).delete()
db.query(models.Salon).delete()
db.query(models.Dukkan).delete()
db.commit()

# ─────────────────────────────────────────────
# 1. SALON OLUŞTURMA
# ─────────────────────────────────────────────
yeni_salon = models.Salon(
    ad="Premium Berber Center",
    adres="Akademi Mahallesi, İsmetpaşa Sokak No:1, Karatay/Konya",
    telefon="0 552 250 92 30",
    foto_url="https://images.unsplash.com/photo-1585747860715-2ba37e788b70",
    instagram_url="https://instagram.com/tevfikuner0",
    acilis_saati="09:00",
    kapanis_saati="22:00",
    konum_lat=37.87628556377653,
    konum_long=32.48504675949902
)
db.add(yeni_salon)
db.commit()
db.refresh(yeni_salon)
print(f"[OK] Salon oluşturuldu: {yeni_salon.ad}")

# ─────────────────────────────────────────────
# 2. HİZMETLER
# ─────────────────────────────────────────────
hizmetler = [
    models.Hizmet(ad="Saç Kesimi", fiyat=300, sure=30, aciklama="Klasik veya modern saç kesimi."),
    models.Hizmet(ad="Sakal Tıraşı", fiyat=150, sure=15, aciklama="Makineli veya ustura ile şekillendirme."),
    models.Hizmet(ad="Saç & Sakal Kesimi", fiyat=450, sure=45, aciklama="Komple bakım paketi."),
    models.Hizmet(ad="Çocuk Tıraşı", fiyat=200, sure=20, aciklama="13 yaş altı çocuklar için."),
    models.Hizmet(ad="Damat Tıraşı (Full VIP)", fiyat=1500, sure=120, aciklama="Düğün öncesi full bakım.")
]

db.add_all(hizmetler)
db.commit()
print(f"[OK] {len(hizmetler)} hizmet eklendi.")

# ─────────────────────────────────────────────
# 3. BERBERLER (Yeni Sosyal Medya Alanlarıyla)
# ─────────────────────────────────────────────
# NOT: whatsapp_no formatı başında '+' olmadan ülke koduyla olmalı (Örn: 90552...)
berberler = [
    models.Berber(
        ad="Ali", 
        soyad="Uysal", 
        uzmanlik="Usta", 
        puan=4.9, 
        salon_id=yeni_salon.id,
        whatsapp_no="905522509230", 
        instagram_username="tevfikuner0"
    ),
    models.Berber(
        ad="Mehmet", 
        soyad="Kaya", 
        uzmanlik="Kalfa", 
        puan=4.7, 
        salon_id=yeni_salon.id,
        whatsapp_no="905522509230", 
        instagram_username="tevfikuner0"
    ),
    models.Berber(
        ad="Eren", 
        soyad="Altınsoy", 
        uzmanlik="Kalfa", 
        puan=4.2, 
        salon_id=yeni_salon.id,
        whatsapp_no="905522509230", 
        instagram_username="tevfikuner0"
    ),
    models.Berber(
        ad="Baran", 
        soyad="Demir", 
        uzmanlik="Çırak", 
        puan=4.5, 
        salon_id=yeni_salon.id,
        whatsapp_no="905522509230", 
        instagram_username="tevfikuner0"
    )
]
db.add_all(berberler)
db.commit()
print(f"[OK] Berberler sosyal medya bilgileriyle eklendi.")

# ─────────────────────────────────────────────
# 4. ESKİ DÜKKAN BİLGİSİ
# ─────────────────────────────────────────────
dukkan = models.Dukkan(
    ad="Premium Berber",
    adres="Akademi Mahallesi, İsmetpaşa Sokak No:1, Karatay/Konya",
    telefon="0 552 250 92 30",
    email="infotevfik@gmail.com",
    harita_konum="37.87628556377653, 32.48504675949902",
    instagram="tevfikuner0",
    haftaici_kapanis="22:00",
    pazar_kapanis="17:00",
)
db.add(dukkan)
db.commit()

db.close()
print("\n🚀 [TAMAM] Yeni sistem seed islemi basariyla tamamlandi!")