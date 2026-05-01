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
# 1. SALONLAR OLUŞTURMA (Çoklu Salon - Farklı Şehirler)
# ─────────────────────────────────────────────
salonlar_data = [
    {
        "ad": "Premium Berber Center",
        "adres": "Akademi Mahallesi, İsmetpaşa Sokak No:1, Karatay/Konya",
        "telefon": "0 552 250 92 30",
        "foto_url": "https://images.unsplash.com/photo-1585747860715-2ba37e788b70",
        "instagram_url": "https://instagram.com/tevfikuner0",
        "whatsapp": "905522509230",
        "sehir": "Konya",
        "ilce": "Karatay",
        "acilis_saati": "09:00",
        "kapanis_saati": "22:00",
        "konum_lat": 37.87628556377653,
        "konum_long": 32.48504675949902,
        "puan": 5.0,
    },
    {
        "ad": "Elit Kuaför Salonu",
        "adres": "Mevlana Mah. Ankara Cad. No:45, Selçuklu/Konya",
        "telefon": "0 332 555 12 34",
        "foto_url": "https://images.unsplash.com/photo-1503951914875-452162b0f3f1",
        "instagram_url": "https://instagram.com/elitkuafor",
        "whatsapp": "903325551234",
        "sehir": "Konya",
        "ilce": "Selçuklu",
        "acilis_saati": "09:00",
        "kapanis_saati": "21:00",
        "konum_lat": 37.8746,
        "konum_long": 32.4932,
        "puan": 4.7,
    },
    {
        "ad": "İstanbul Style Barber",
        "adres": "Bağdat Caddesi No:120, Kadıköy/İstanbul",
        "telefon": "0 216 555 67 89",
        "foto_url": "https://images.unsplash.com/photo-1621605815971-fbc98d665033",
        "instagram_url": "https://instagram.com/istanbulstyle",
        "whatsapp": "902165556789",
        "sehir": "İstanbul",
        "ilce": "Kadıköy",
        "acilis_saati": "10:00",
        "kapanis_saati": "22:00",
        "konum_lat": 40.9906,
        "konum_long": 29.0230,
        "puan": 4.8,
    },
    {
        "ad": "Ankara Premium Erkek Kuaförü",
        "adres": "Kızılay Mah. Atatürk Blv. No:78, Çankaya/Ankara",
        "telefon": "0 312 555 11 22",
        "foto_url": "https://images.unsplash.com/photo-1599351431202-1e0f0137899a",
        "instagram_url": "https://instagram.com/ankarapremium",
        "whatsapp": "903125551122",
        "sehir": "Ankara",
        "ilce": "Çankaya",
        "acilis_saati": "09:00",
        "kapanis_saati": "21:00",
        "konum_lat": 39.9208,
        "konum_long": 32.8541,
        "puan": 4.6,
    },
    {
        "ad": "Ege Barber Shop",
        "adres": "Alsancak Mah. Kordon Boyu No:55, Konak/İzmir",
        "telefon": "0 232 555 33 44",
        "foto_url": "https://images.unsplash.com/photo-1622286342621-4bd786c2447c",
        "instagram_url": "https://instagram.com/egebarber",
        "whatsapp": "902325553344",
        "sehir": "İzmir",
        "ilce": "Konak",
        "acilis_saati": "10:00",
        "kapanis_saati": "22:00",
        "konum_lat": 38.4192,
        "konum_long": 27.1287,
        "puan": 4.9,
    },
    {
        "ad": "Antalya Beach Barber",
        "adres": "Lara Mah. Güllük Cad. No:12, Muratpaşa/Antalya",
        "telefon": "0 242 555 77 88",
        "foto_url": "https://images.unsplash.com/photo-1605497788044-5a32c7078486",
        "instagram_url": "https://instagram.com/antalyabeach",
        "whatsapp": "902425557788",
        "sehir": "Antalya",
        "ilce": "Muratpaşa",
        "acilis_saati": "09:00",
        "kapanis_saati": "23:00",
        "konum_lat": 36.8869,
        "konum_long": 30.7025,
        "puan": 4.5,
    },
]

salon_objeleri = []
for s_data in salonlar_data:
    salon = models.Salon(**s_data)
    db.add(salon)
    db.commit()
    db.refresh(salon)
    salon_objeleri.append(salon)
    print(f"[OK] Salon oluşturuldu: {salon.ad} ({salon.sehir}/{salon.ilce})")

# ─────────────────────────────────────────────
# 2. HİZMETLER (Tüm Salonlar İçin Ortak)
# ─────────────────────────────────────────────
hizmetler = [
    models.Hizmet(ad="Saç Kesimi", fiyat=300, sure=30, aciklama="Klasik veya modern saç kesimi. Yıkama dahil değil."),
    models.Hizmet(ad="Sakal Tıraşı (Makineli / Usturalı)", fiyat=150, sure=15, aciklama="Makineli veya ustura ile hassas sakal şekillendirme."),
    models.Hizmet(ad="Saç & Sakal Kesimi (Yıkama Dahil)", fiyat=450, sure=45, aciklama="Saç kesimi + sakal düzeltme + saç yıkama."),
    models.Hizmet(ad="Çocuk Tıraşı (13 Yaş Altı)", fiyat=200, sure=20, aciklama="13 yaş altı çocuklar için özel fiyatlı tıraş hizmeti."),
    models.Hizmet(ad="Sadece yıkama ve şekillendirme (Fon)", fiyat=100, sure=15, aciklama="Saç yıkama + fon + şekillendirme."),
    models.Hizmet(ad="Detayli Cilt Bakimi (Siyah Maske + Peeling)", fiyat=200, sure=20, aciklama="Gözenek temizleyici siyah maske ve peeling."),
    models.Hizmet(ad="Ağda İşlemleri (Kulak / Yanak / Burun)", fiyat=100, sure=15, aciklama="Kulak, yanak ve burun bölgesi ağda."),
    models.Hizmet(ad="Keratin Bakimi (Saç Düzlestirme ve Besleme)", fiyat=500, sure=60, aciklama="Profesyonel keratin uygulaması."),
    models.Hizmet(ad="Saç Boyama / Beyaz Kapatma", fiyat=500, sure=60, aciklama="Beyaz kapatma veya tam saç boyama."),
    models.Hizmet(ad="Kaş Tasarımı / Düzeltme", fiyat=100, sure=15, aciklama="Kaşları şekillendirme ve düzeltme."),
    models.Hizmet(ad="Damat Tıraşı (Full VIP Paket)", fiyat=1500, sure=120, aciklama="Saç + Sakal + Cilt Bakımı + Ağda + Keratin + Maske + Fon."),
]

db.add_all(hizmetler)
db.commit()
print(f"[OK] {len(hizmetler)} hizmet eklendi.")

# ─────────────────────────────────────────────
# 3. BERBERLER (Her Salona 2-4 Berber)
# ─────────────────────────────────────────────
berber_adlari = [
    ("Ali", "Uysal", "Usta", 4.9),
    ("Mehmet", "Kaya", "Kalfa", 4.7),
    ("Eren", "Altınsoy", "Kalfa", 4.2),
    ("Baran", "Demir", "Çırak", 4.5),
    ("Hasan", "Yılmaz", "Usta", 4.8),
    ("Emre", "Çelik", "Kalfa", 4.6),
    ("Can", "Özdemir", "Usta", 4.9),
    ("Burak", "Arslan", "Kalfa", 4.3),
    ("Oğuz", "Koç", "Usta", 4.7),
    ("Serkan", "Aydın", "Kalfa", 4.4),
    ("Murat", "Şahin", "Usta", 4.8),
    ("Kemal", "Tuncer", "Çırak", 4.1),
]

berber_idx = 0
for salon in salon_objeleri:
    # Her salona 2 berber ata
    for _ in range(2):
        if berber_idx >= len(berber_adlari):
            break
        ad, soyad, uzmanlik, puan = berber_adlari[berber_idx]
        berber = models.Berber(
            ad=ad, soyad=soyad, uzmanlik=uzmanlik, puan=puan,
            salon_id=salon.id,
            whatsapp_no="905522509230",
            instagram_username="tevfikuner0"
        )
        db.add(berber)
        berber_idx += 1
    db.commit()
    print(f"[OK] {salon.ad} salonuna berberler eklendi.")

# ─────────────────────────────────────────────
# 4. ESKİ DÜKKAN BİLGİSİ (Ana Dükkan)
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
print("\n🚀 [TAMAM] 6 salon, 12 berber ve 11 hizmet başarıyla eklendi!")