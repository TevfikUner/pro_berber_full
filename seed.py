# seed.py - Veritabani baslangic verileriyle doldurur (Pazaryeri Modeli)
import sys
sys.stdout.reconfigure(encoding='utf-8')
from database import SessionLocal, engine
import models

# Tabloları oluştur (Özellikle yeni eklenen salonlar tablosu için)
models.Base.metadata.create_all(bind=engine)
db = SessionLocal()

# Temizlik: Çakışma olmaması için mevcut verileri silelim
db.query(models.Berber).delete()
db.query(models.Hizmet).delete()
db.query(models.Salon).delete()
db.query(models.Dukkan).delete()
db.commit()

# ─────────────────────────────────────────────
# 1. SALON OLUŞTURMA (Yeni Sistemin Temeli)
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
print(f"[OK] Salon oluşturuldu: {yeni_salon.ad} (ID: {yeni_salon.id})")

# ─────────────────────────────────────────────
# 2. HİZMETLER (Senin listen)
# ─────────────────────────────────────────────
hizmetler = [
    models.Hizmet(ad="Saç Kesimi", fiyat=300, sure=30, aciklama="Klasik veya modern saç kesimi. Yıkama dahil değil."),
    models.Hizmet(ad="Sakal Tıraşı (Makineli / Usturalı)", fiyat=150, sure=15, aciklama="Makineli veya ustura ile hassas sakal şekillendirme."),
    models.Hizmet(ad="Saç & Sakal Kesimi (Yıkama Dahil)", fiyat=450, sure=45, aciklama="Saç kesimi + sakal düzeltme + saç yıkama. Tek seferde tam bakim."),
    models.Hizmet(ad="Çocuk Tıraşı (13 Yaş Altı)", fiyat=200, sure=20, aciklama="13 yaş altı çocuklar için özel fiyatlı tıraş hizmeti."),
    models.Hizmet(ad="Sadece yıkama ve şekillendirme (Fon)", fiyat=100, sure=15, aciklama="Saç yıkama + fon + şekillendirme. Kesim yapılmaz."),
    models.Hizmet(ad="Detayli Cilt Bakimi (Siyah Maske + Peeling)", fiyat=200, sure=20, aciklama="Gözenek temizleyici siyah maske ve peeling uygulaması."),
    models.Hizmet(ad="Ağda İşlemleri (Kulak / Yanak / Burun)", fiyat=100, sure=15, aciklama="Kulak, yanak ve burun bölgesi ağda uygulaması."),
    models.Hizmet(ad="Keratin Bakimi (Saç Düzlestirme ve Besleme)", fiyat=500, sure=60, aciklama="Saçı besleyen ve düzleştiren profesyonel keratin uygulaması."),
    models.Hizmet(ad="Saç Boyama / Beyaz Kapatma", fiyat=500, sure=60, aciklama="Beyaz kapatma veya tam saç boyama hizmeti."),
    models.Hizmet(ad="Kaş Tasarımı / Düzeltme", fiyat=100, sure=15, aciklama="Kaşları sekillendirme ve düzeltme."),
    models.Hizmet(ad="Damat Tıraşı (Full VIP Paket)", fiyat=1500, sure=120, aciklama="Saç + Sakal + Detayli Cilt Bakimi + Ağda + Keratin + Maske + Fon ve Özel şekillendirme.")
]

db.add_all(hizmetler)
db.commit()
print(f"[OK] {len(hizmetler)} hizmet eklendi.")

# ─────────────────────────────────────────────
# 3. BERBERLER (Salon ID'sine bağlandılar)
# ─────────────────────────────────────────────
berberler = [
    models.Berber(ad="Ali", soyad="Uysal", uzmanlik="Usta", puan=4.9, salon_id=yeni_salon.id),
    models.Berber(ad="Mehmet", soyad="Kaya", uzmanlik="Kalfa", puan=4.7, salon_id=yeni_salon.id),
    models.Berber(ad="Eren", soyad="Altınsoy", uzmanlik="Kalfa", puan=4.2, salon_id=yeni_salon.id),
    models.Berber(ad="Baran", soyad="Demir", uzmanlik="Çırak", puan=4.5, salon_id=yeni_salon.id)
]
db.add_all(berberler)
db.commit()
print(f"[OK] {len(berberler)} berber '{yeni_salon.ad}' salonuna eklendi.")

# ─────────────────────────────────────────────
# 4. ESKİ DÜKKAN BİLGİSİ (Geriye dönük uyumluluk için)
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