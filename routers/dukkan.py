from fastapi import APIRouter, Depends, HTTPException
from auth import admin_dogrula
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter(prefix="/dukkan", tags=["Dükkan Bilgileri"])

@router.get("/")
def dukkan_bilgisi(db: Session = Depends(get_db)):
    """
    Dükkan bilgilerini veritabanından çeker. 
    Eğer veritabanında dükkan kaydı yoksa hata döndürür.
    """
    # Veritabanındaki ilk (ve tek) dükkan kaydını getir
    bilgi = db.query(models.Dukkan).first()
    
    if not bilgi:
        raise HTTPException(status_code=404, detail="Dükkan bilgileri veritabanında bulunamadı. Lütfen önce ekleyin!")

    # Koordinatları parçalayalım (Veritabanında "37.876, 32.485" olarak tuttuğunu varsayıyorum)
    try:
        lat, lng = bilgi.harita_konum.split(",")
    except:
        lat, lng = "0", "0"

    yol_tarifi = f"https://www.google.com/maps/search/?api=1&query={lat.strip()},{lng.strip()}"
    
    return {
        "isletme": bilgi.ad,
        "adres": bilgi.adres,
        "iletisim": {
            "tel": bilgi.telefon,
            "email": bilgi.email or "",
            "instagram": bilgi.instagram
        },
        "koordinatlar": {"lat": lat.strip(), "lng": lng.strip()},
        "yol_tarifi": yol_tarifi,
        "mesai_saatleri": {
            "pazartesi_cumartesi": f"10:00 - {bilgi.haftaici_kapanis}",
            "pazar": f"10:00 - {bilgi.pazar_kapanis}"
        }
    }

# --- YENİ: Dükkan Bilgisi Ekleme/Güncelleme Kapısı ---
@router.post("/guncelle")
def dukkan_guncelle(
    ad: str,
    adres: str,
    telefon: str,
    konum: str,  # "37.876, 32.485" formatında
    instagram: str = None,
    h_ici_kapanis: str = "22:00",
    pazar_kapanis: str = "17:00",
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔒 Sadece admin güncelleyebilir
):
    # Eski kayıt var mı bak
    mevcut = db.query(models.Dukkan).first()
    
    if mevcut:
        # Varsa güncelle
        mevcut.ad = ad
        mevcut.adres = adres
        mevcut.telefon = telefon
        mevcut.harita_konum = konum
        mevcut.instagram = instagram
        mevcut.haftaici_kapanis = h_ici_kapanis
        mevcut.pazar_kapanis = pazar_kapanis
    else:
        # Yoksa yeni oluştur
        yeni = models.Dukkan(
            ad=ad, adres=adres, telefon=telefon, 
            harita_konum=konum, instagram=instagram,
            haftaici_kapanis=h_ici_kapanis, pazar_kapanis=pazar_kapanis
        )
        db.add(yeni)
    
    db.commit()
    return {"mesaj": "Dükkan bilgileri başarıyla güncellendi!"}


# --- Keşfet Sekmesi: Salon Listeleme ---
@router.get("/salonlar")
def salonlari_listele(
    sehir: str = None,
    ilce: str = None,
    db: Session = Depends(get_db),
):
    """
    Tüm salonları listeler. İsteğe bağlı şehir ve ilçe filtreleri.
    Keşfet sekmesi bu endpoint'i kullanır.
    """
    sorgu = db.query(models.Salon)
    if sehir:
        sorgu = sorgu.filter(models.Salon.sehir == sehir)
    if ilce:
        sorgu = sorgu.filter(models.Salon.ilce == ilce)

    salonlar = sorgu.all()
    return [
        {
            "id": s.id,
            "ad": s.ad,
            "adres": s.adres,
            "telefon": s.telefon,
            "foto_url": s.foto_url,
            "sehir": s.sehir,
            "ilce": s.ilce,
            "puan": s.puan,
            "acilis_saati": s.acilis_saati,
            "kapanis_saati": s.kapanis_saati,
        }
        for s in salonlar
    ]


@router.get("/salon/{salon_id}")
def salon_detay(salon_id: int, db: Session = Depends(get_db)):
    """
    Tek bir salonun detay bilgilerini getirir.
    Fotoğraflar, berberler, iletişim ve konum bilgileri dahil.
    """
    salon = db.query(models.Salon).filter(models.Salon.id == salon_id).first()
    if not salon:
        raise HTTPException(status_code=404, detail="Salon bulunamadı.")

    # Salon fotoğraflarını getir
    fotograflar = (
        db.query(models.SalonFotograf)
        .filter(models.SalonFotograf.salon_id == salon_id)
        .order_by(models.SalonFotograf.sira)
        .all()
    )

    # Salonun berberlerini getir
    berberler = (
        db.query(models.Berber)
        .filter(models.Berber.salon_id == salon_id)
        .all()
    )

    return {
        "id": salon.id,
        "ad": salon.ad,
        "adres": salon.adres,
        "telefon": salon.telefon,
        "foto_url": salon.foto_url,
        "instagram": salon.instagram_url,
        "whatsapp": salon.whatsapp,
        "sehir": salon.sehir,
        "ilce": salon.ilce,
        "puan": salon.puan,
        "acilis_saati": salon.acilis_saati,
        "kapanis_saati": salon.kapanis_saati,
        "konum": {
            "lat": salon.konum_lat,
            "lng": salon.konum_long,
        },
        "fotograflar": [
            {"id": f.id, "foto_url": f.foto_url, "sira": f.sira}
            for f in fotograflar
        ],
        "berberler": [
            {
                "id": b.id,
                "ad": b.ad,
                "soyad": b.soyad,
                "uzmanlik": b.uzmanlik,
                "puan": b.puan,
                "foto_url": b.foto_url,
            }
            for b in berberler
        ],
    }


# --- Keşfet: Mevcut şehir ve ilçe listesi ---
@router.get("/filtreler")
def filtre_secenekleri(db: Session = Depends(get_db)):
    """Keşfet sekmesindeki filtre dropdown'ları için mevcut şehir/ilçe listesini döner."""
    salonlar = db.query(models.Salon).all()
    sehirler = sorted(set(s.sehir for s in salonlar if s.sehir))
    ilceler = {}
    for s in salonlar:
        if s.sehir and s.ilce:
            ilceler.setdefault(s.sehir, set()).add(s.ilce)
    return {
        "sehirler": sehirler,
        "ilceler": {k: sorted(v) for k, v in ilceler.items()},
    }