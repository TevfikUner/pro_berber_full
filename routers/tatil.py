from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from auth import admin_dogrula
import models

router = APIRouter(prefix="/tatil", tags=["Tatil & Kapalı Günler"])


@router.post("/ekle")
def tatil_ekle(
    tarih: str,
    aciklama: str = None,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔒 Sadece admin
):
    """
    Admin belirli bir günü kapalı ilan eder.
    tarih formatı: YYYY-MM-DD (örn: 2025-04-23)
    """
    # Format kontrolü
    try:
        from datetime import datetime
        datetime.strptime(tarih, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Tarih formatı hatalı. Doğru format: YYYY-MM-DD")

    # Zaten var mı?
    var_mi = db.query(models.TatilGunu).filter(models.TatilGunu.tarih == tarih).first()
    if var_mi:
        raise HTTPException(status_code=400, detail=f"{tarih} zaten tatil olarak işaretli.")

    yeni = models.TatilGunu(tarih=tarih, aciklama=aciklama)
    db.add(yeni)
    db.commit()
    return {"mesaj": f"{tarih} tatil günü olarak eklendi.", "aciklama": aciklama}


@router.delete("/sil/{tarih}")
def tatil_sil(
    tarih: str,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔒 Sadece admin
):
    """Belirtilen tarihi tatil listesinden kaldırır."""
    tatil = db.query(models.TatilGunu).filter(models.TatilGunu.tarih == tarih).first()
    if not tatil:
        raise HTTPException(status_code=404, detail="Bu tarih tatil listesinde yok.")

    db.delete(tatil)
    db.commit()
    return {"mesaj": f"{tarih} tatil listesinden kaldırıldı."}


@router.get("/liste")
def tatil_listesi(db: Session = Depends(get_db)):
    """Tüm tatil ve kapalı günleri listeler."""
    tatiller = db.query(models.TatilGunu).order_by(models.TatilGunu.tarih).all()
    return [{"tarih": t.tarih, "aciklama": t.aciklama} for t in tatiller]
