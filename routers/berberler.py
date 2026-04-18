import os, shutil
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from auth import admin_dogrula
from sqlalchemy.orm import Session
from database import get_db
import models

router = APIRouter(prefix="/berberler", tags=["Berber Yönetimi"])

@router.post("/ekle")
def berber_ekle(
    ad: str,
    soyad: str,
    uzmanlik: str,  # Buraya "Usta", "Kalfa" gibi değerler gireceğiz
    foto_url: str = None,
    puan: float = 5.0,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔒 Sadece admin ekleyebilir
):
    yeni_berber = models.Berber(
        ad=ad, 
        soyad=soyad, 
        uzmanlik=uzmanlik, 
        foto_url=foto_url, 
        puan=puan
    )
    db.add(yeni_berber)
    db.commit()
    db.refresh(yeni_berber)
    return {
        "mesaj": "Yeni personel kadroya başarıyla katıldı kanki!", 
        "berber": f"{yeni_berber.ad} ({yeni_berber.uzmanlik})"
    }
@router.get("/")
def berberleri_listele(db: Session = Depends(get_db)):
    return db.query(models.Berber).all()

@router.put("/guncelle/{berber_id}")
def berber_guncelle(
    berber_id: int,
    ad: str = None,
    soyad: str = None,
    uzmanlik: str = None,
    foto_url: str = None,
    puan: float = None,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔒 Sadece admin güncelleyebilir
):
    berber = db.query(models.Berber).filter(models.Berber.id == berber_id).first()
    if not berber:
        raise HTTPException(status_code=404, detail="Berber bulunamadı.")

    if ad: berber.ad = ad
    if soyad: berber.soyad = soyad
    if uzmanlik: berber.uzmanlik = uzmanlik
    if foto_url: berber.foto_url = foto_url
    if puan is not None: berber.puan = puan

    db.commit()
    db.refresh(berber)
    return {"mesaj": "Berber bilgileri güncellendi.", "berber": f"{berber.ad} {berber.soyad}"}

@router.delete("/sil/{berber_id}")
def berber_sil(
    berber_id: int,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)
):
    berber = db.query(models.Berber).filter(models.Berber.id == berber_id).first()
    if not berber:
        raise HTTPException(status_code=404, detail="Berber bulunamadı.")

    db.delete(berber)
    db.commit()
    return {"mesaj": f"{berber.ad} {berber.soyad} kadrodan çıkarıldı."}


# ============================================================
# BERBER İZİN YÖNETİMİ (7. Özellik)
# ============================================================

@router.post("/izin-ekle")
def berber_izin_ekle(
    berber_id: int,
    tarih: str,
    aciklama: str = None,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)
):
    """Belirli bir berbere belirli bir gün için izin tanımlar."""
    from datetime import datetime
    try:
        datetime.strptime(tarih, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Tarih formatı hatalı. Doğru format: YYYY-MM-DD")

    berber = db.query(models.Berber).filter(models.Berber.id == berber_id).first()
    if not berber:
        raise HTTPException(status_code=404, detail="Berber bulunamadı.")

    # Aynı gün zaten izinli mi?
    var_mi = db.query(models.BerberIzin).filter(
        models.BerberIzin.berber_id == berber_id,
        models.BerberIzin.tarih == tarih
    ).first()
    if var_mi:
        raise HTTPException(status_code=400, detail=f"{berber.ad} zaten o gün izinli.")

    yeni = models.BerberIzin(berber_id=berber_id, tarih=tarih, aciklama=aciklama)
    db.add(yeni)
    db.commit()
    return {"mesaj": f"{berber.ad} için {tarih} izin günü eklendi.", "aciklama": aciklama}


@router.delete("/izin-sil/{izin_id}")
def berber_izin_sil(
    izin_id: int,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)
):
    izin = db.query(models.BerberIzin).filter(models.BerberIzin.id == izin_id).first()
    if not izin:
        raise HTTPException(status_code=404, detail="İzin kaydı bulunamadı.")
    db.delete(izin)
    db.commit()
    return {"mesaj": "İzin günü kaldırıldı."}


@router.get("/izinler/{berber_id}")
def berber_izinleri(berber_id: int, db: Session = Depends(get_db)):
    """Bir berberin tüm izin günlerini listeler."""
    izinler = db.query(models.BerberIzin).filter(
        models.BerberIzin.berber_id == berber_id
    ).order_by(models.BerberIzin.tarih).all()
    return [{"id": i.id, "tarih": i.tarih, "aciklama": i.aciklama} for i in izinler]


# ============================================================
# FOTOĞRAF UPLOAD (8. Özellik)
# ============================================================

@router.post("/foto-yukle/{berber_id}")
async def berber_foto_yukle(
    berber_id: int,
    foto: UploadFile = File(...),
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)
):
    """Berber profil fotoğrafını yükler ve URL'yi veritabanına kaydeder."""
    berber = db.query(models.Berber).filter(models.Berber.id == berber_id).first()
    if not berber:
        raise HTTPException(status_code=404, detail="Berber bulunamadı.")

    # Sadece resim dosyaları kabul et
    izin_verilen = {"image/jpeg", "image/png", "image/webp"}
    if foto.content_type not in izin_verilen:
        raise HTTPException(status_code=400, detail="Sadece JPG, PNG ve WebP formatı kabul edilir.")

    # Klasörü oluştur ve dosyayı kaydet
    klasor = "uploads/berberler"
    os.makedirs(klasor, exist_ok=True)
    uzanti = foto.filename.rsplit(".", 1)[-1]
    dosya_adi = f"berber_{berber_id}.{uzanti}"
    dosya_yolu = os.path.join(klasor, dosya_adi)

    with open(dosya_yolu, "wb") as buffer:
        shutil.copyfileobj(foto.file, buffer)

    # Veritabanındaki URL'yi güncelle (/uploads/... şeklinde erişilebilir URL)
    berber.foto_url = f"/uploads/berberler/{dosya_adi}"
    db.commit()
    return {"mesaj": "Fotoğraf başarıyla yüklendi.", "foto_url": berber.foto_url}