# seed.py - Veritabani baslangi verileriyle doldurur.
# Sadece 1 kez calistirilir:
#   .venv/Scripts/python seed.py
import sys
sys.stdout.reconfigure(encoding='utf-8')
from database import SessionLocal, engine
import models

models.Base.metadata.create_all(bind=engine)
db = SessionLocal()

# ─────────────────────────────────────────────
# 1. HİZMETLER
# ─────────────────────────────────────────────
# Mevcut hizmetleri temizle (tekrar çalıştırma güvenliği)
db.query(models.Hizmet).delete()
db.commit()

hizmetler = [
    # ── Temel Kesimler ──────────────────────────────────────
    models.Hizmet(
        ad="Saç Kesimi",
        fiyat=300,
        sure=30,
        aciklama="Klasik veya modern saç kesimi. Yıkama dahil değil."
    ),
    models.Hizmet(
        ad="Sakal Tıraşı (Makineli / Usturalı)",
        fiyat=150,
        sure=15,
        aciklama="Makineli veya ustura ile hassas sakal şekillendirme."
    ),
    models.Hizmet(
        ad="Saç & Sakal Kesimi (Yıkama Dahil)",
        fiyat=450,
        sure=45,
        aciklama="Saç kesimi + sakal düzeltme + saç yıkama. Tek seferde tam bakim."
    ),
    models.Hizmet(
        ad="Çocuk Tıraşı (13 Yaş Altı)",
        fiyat=200,
        sure=20,
        aciklama="13 yaş altı çocuklar için özel fiyatlı tıraş hizmeti."
    ),
    models.Hizmet(
        ad="Sadece yıkama ve şekillendirme (Fon)",
        fiyat=100,
        sure=15,
        aciklama="Saç yıkama + fon + şekillendirme. Kesim yapılmaz."
    ),

    # ── Bakim & Ekstra ──────────────────────────────────────
    models.Hizmet(
        ad="Detayli Cilt Bakimi (Siyah Maske + Peeling)",
        fiyat=200,
        sure=20,
        aciklama="Gözenek temizleyici siyah maske ve peeling uygulaması."
    ),
    models.Hizmet(
        ad="Ağda İşlemleri (Kulak / Yanak / Burun)",
        fiyat=100,
        sure=15,
        aciklama="Kulak, yanak ve burun bölgesi ağda uygulaması."
    ),
    models.Hizmet(
        ad="Keratin Bakimi (Saç Düzlestirme ve Besleme)",
        fiyat=500,
        sure=60,
        aciklama="Saçı besleyen ve düzleştiren profesyonel keratin uygulaması."
    ),
    models.Hizmet(
        ad="Saç Boyama / Beyaz Kapatma",
        fiyat=500,
        sure=60,
        aciklama="Beyaz kapatma veya tam saç boyama hizmeti."
    ),
    models.Hizmet(
        ad="Kaş Tasarımı / Düzeltme",
        fiyat=100,
        sure=15,
        aciklama="Kaşları sekillendirme ve düzeltme."
    ),

    # ── VIP Paket ───────────────────────────────────────────
    models.Hizmet(
        ad="Damat Tıraşı (Full VIP Paket)",
        fiyat=1500,
        sure=120,
        aciklama=(
            "Saç + Sakal + Detayli Cilt Bakimi + Ağda + Keratin + "
            "Maske + Fon ve Özel şekillendirme. Özel günler için özel bakim."
        )
    ),
]


db.add_all(hizmetler)
db.commit()
print(f"[OK] {len(hizmetler)} hizmet eklendi.")

# ─────────────────────────────────────────────
# 2. DÜKKAN BİLGİSİ (eğer yoksa ekle)
# ─────────────────────────────────────────────
if not db.query(models.Dukkan).first():
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
    print("[OK] Dukkan bilgisi eklendi.")
else:
    print("[--] Dukkan bilgisi zaten mevcut, atlandi.")

# ─────────────────────────────────────────────
# 3. ÖRNEK BERBER (eğer hiç berber yoksa)
# ─────────────────────────────────────────────
if not db.query(models.Berber).first():
    berberler = [
        models.Berber(ad="Ali", soyad="Uysal", uzmanlik="Usta", puan=4.9),
        models.Berber(ad="Mehmet", soyad="Kaya", uzmanlik="Kalfa", puan=4.7),
        models.Berber(ad="Eren", soyad="Altınsoy", uzmanlik="Kalfa", puan=4.2),
        models.Berber(ad="Baran", soyad="Demir", uzmanlik="Çırak", puan=4.5),
        
    ]
    db.add_all(berberler)
    db.commit()
    print(f"[OK] {len(berberler)} berber eklendi.")
else:
    print("[--] Berberler zaten mevcut, atlandi.")

db.close()
print("\n[TAMAM] Seed islemi tamamlandi!")
