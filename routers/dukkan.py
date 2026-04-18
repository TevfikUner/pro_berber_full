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