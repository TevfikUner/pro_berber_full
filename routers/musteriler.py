from fastapi import APIRouter, Depends, HTTPException, Header # <-- Header buraya eklendi!
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter(prefix="/musteriler", tags=["Müşteri Yönetimi"])

@router.post("/ekle")
def musteri_ekle(
    ad: str, 
    soyad: str, 
    telefon: str, 
    firebase_uid: str, 
    db: Session = Depends(get_db)
):
    # Aynı UID ile başka kayıt var mı kontrolü
    var_mi = db.query(models.Musteri).filter(models.Musteri.firebase_uid == firebase_uid).first()
    if var_mi:
        raise HTTPException(status_code=400, detail="Bu UID zaten kayıtlı kanki!")

    yeni_musteri = models.Musteri(
        ad=ad, 
        soyad=soyad, 
        telefon=telefon, 
        firebase_uid=firebase_uid
    )
    db.add(yeni_musteri)
    db.commit()
    db.refresh(yeni_musteri)
    return {"mesaj": "Müşteri başarıyla eklendi", "id": yeni_musteri.id}

@router.patch("/fcm-token-guncelle")
def fcm_token_guncelle(
    fcm_token: str, 
    x_firebase_uid: str = Header(...), # Artık Header'ı tanıdığı için hata vermez
    db: Session = Depends(get_db)
):
    # Veritabanında müşteriyi bul
    musteri = db.query(models.Musteri).filter(models.Musteri.firebase_uid == x_firebase_uid).first()
    
    if not musteri:
        raise HTTPException(status_code=404, detail="Müşteri bulunamadı kanki!")
    
    # Token'ı güncelle
    musteri.fcm_token = fcm_token
    db.commit()
    
    return {"mesaj": "Cihaz bildirime başarıyla kaydedildi!", "uid": x_firebase_uid}

@router.put("/profil-guncelle")
def profil_guncelle(
    ad: str = None, 
    soyad: str = None, 
    telefon: str = None, 
    x_firebase_uid: str = Header(...), 
    db: Session = Depends(get_db)
):
    musteri = db.query(models.Musteri).filter(models.Musteri.firebase_uid == x_firebase_uid).first()
    if not musteri:
        raise HTTPException(status_code=404, detail="Müşteri bulunamadı kanki!")

    # Sadece dolu gelen bilgileri güncelle (Boş gelirse eskisi kalsın)
    if ad: musteri.ad = ad
    if soyad: musteri.soyad = soyad
    if telefon: musteri.telefon = telefon

    db.commit()
    return {"mesaj": "Profil bilgilerin mermi gibi güncellendi!", "yeni_bilgiler": {"ad": musteri.ad, "soyad": musteri.soyad}}


@router.put("/favori-berber")
def favori_berber_guncelle(
    berber_id: int = None,  # None gönderilirse favori kaldırılır
    x_firebase_uid: str = Header(...),
    db: Session = Depends(get_db),
):
    """Müşterinin favori berberini günceller veya kaldırır."""
    musteri = db.query(models.Musteri).filter(
        models.Musteri.firebase_uid == x_firebase_uid
    ).first()
    if not musteri:
        raise HTTPException(status_code=404, detail="Müşteri bulunamadı!")

    if berber_id is not None:
        # Berber var mı kontrol et
        berber = db.query(models.Berber).filter(models.Berber.id == berber_id).first()
        if not berber:
            raise HTTPException(status_code=404, detail="Berber bulunamadı!")

    musteri.favori_berber_id = berber_id
    db.commit()

    if berber_id:
        return {"mesaj": "Favori berberin güncellendi!", "favori_berber_id": berber_id}
    return {"mesaj": "Favori berber kaldırıldı."}