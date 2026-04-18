from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter(prefix="/kurumsal", tags=["Dükkan Bilgileri"])

@router.get("/bilgiler")
def dukkan_bilgilerini_getir(db: Session = Depends(get_db)):
    bilgi = db.query(models.Dukkan).first()
    if not bilgi:
        raise HTTPException(status_code=404, detail="Dükkan bilgisi henüz eklenmemiş.")
    return bilgi