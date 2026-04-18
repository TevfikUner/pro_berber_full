from fastapi import APIRouter, Depends, HTTPException
from auth import admin_dogrula
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter(prefix="/hizmetler", tags=["Hizmet Menüsü"])

@router.post("/ekle")
def hizmet_ekle(
    ad: str,
    fiyat: float,
    sure: int,
    aciklama: str = None,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔒 Sadece admin ekleyebilir
):
    yeni_hizmet = models.Hizmet(
        ad=ad, 
        fiyat=fiyat, 
        sure=sure, 
        aciklama=aciklama # Modeldeki yeni sütuna gönderiyoruz
    )
    db.add(yeni_hizmet)
    db.commit()
    db.refresh(yeni_hizmet)
    return {"mesaj": "Hizmet başarıyla menüye eklendi!", "id": yeni_hizmet.id}

@router.get("/")
def hizmetleri_listele(db: Session = Depends(get_db)):
    return db.query(models.Hizmet).all()

@router.put("/guncelle/{hizmet_id}")
def hizmet_guncelle(
    hizmet_id: int,
    ad: str = None,
    fiyat: float = None,
    sure: int = None,
    aciklama: str = None,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔒 Sadece admin güncelleyebilir
):
    hizmet = db.query(models.Hizmet).filter(models.Hizmet.id == hizmet_id).first()
    if not hizmet:
        raise HTTPException(status_code=404, detail="Hizmet bulunamadı.")

    if ad: hizmet.ad = ad
    if fiyat is not None: hizmet.fiyat = fiyat
    if sure is not None: hizmet.sure = sure
    if aciklama: hizmet.aciklama = aciklama

    db.commit()
    db.refresh(hizmet)
    return {"mesaj": "Hizmet güncellendi.", "hizmet": hizmet.ad, "yeni_fiyat": hizmet.fiyat}

@router.delete("/sil/{hizmet_id}")
def hizmet_sil(
    hizmet_id: int,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔒 Sadece admin silebilir
):
    hizmet = db.query(models.Hizmet).filter(models.Hizmet.id == hizmet_id).first()
    if not hizmet:
        raise HTTPException(status_code=404, detail="Hizmet bulunamadı.")

    db.delete(hizmet)
    db.commit()
    return {"mesaj": f"'{hizmet.ad}' hizmeti menüden kaldırıldı."}