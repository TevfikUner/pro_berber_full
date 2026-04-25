from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter(prefix="/isletmeler", tags=["İşletme Yönetimi"])


@router.post("/kayit")
def isletme_kayit(
    ad: str,
    soyad: str,
    telefon: str,
    email: str,
    isletme_adi: str,
    firebase_uid: str,
    db: Session = Depends(get_db),
):
    """İşletme sahibi kayıt olur. Durum varsayılan olarak 'beklemede' olur."""
    # Aynı UID ile kayıt var mı kontrol et
    var_mi = db.query(models.Isletme).filter(
        models.Isletme.firebase_uid == firebase_uid
    ).first()
    if var_mi:
        raise HTTPException(status_code=400, detail="Bu hesap zaten kayıtlı!")

    yeni = models.Isletme(
        firebase_uid=firebase_uid,
        ad=ad,
        soyad=soyad,
        telefon=telefon,
        email=email,
        isletme_adi=isletme_adi,
        durum="beklemede",
    )
    db.add(yeni)
    db.commit()
    db.refresh(yeni)
    return {
        "mesaj": "İşletme başvurunuz alındı! Onay bekleniyor.",
        "id": yeni.id,
        "durum": yeni.durum,
    }


@router.get("/")
def isletmeleri_listele(db: Session = Depends(get_db)):
    """Tüm onaylı işletmeleri listeler."""
    isletmeler = db.query(models.Isletme).filter(
        models.Isletme.durum == "onaylandi"
    ).all()
    return [
        {
            "id": i.id,
            "isletme_adi": i.isletme_adi,
            "ad": i.ad,
            "soyad": i.soyad,
            "telefon": i.telefon,
            "email": i.email,
        }
        for i in isletmeler
    ]


@router.get("/durum")
def isletme_durum(
    firebase_uid: str,
    db: Session = Depends(get_db),
):
    """İşletme sahibi kendi başvuru durumunu sorgular."""
    isletme = db.query(models.Isletme).filter(
        models.Isletme.firebase_uid == firebase_uid
    ).first()
    if not isletme:
        raise HTTPException(status_code=404, detail="İşletme başvurusu bulunamadı.")
    return {
        "id": isletme.id,
        "isletme_adi": isletme.isletme_adi,
        "durum": isletme.durum,
    }
