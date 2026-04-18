from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
import models
from datetime import datetime

router = APIRouter(prefix="/degerlendirmeler", tags=["Değerlendirme & Puan"])


@router.post("/ekle")
def degerlendirme_ekle(
    randevu_id: int,
    puan: int,
    yorum: str = None,
    x_firebase_uid: str = Header(...),
    db: Session = Depends(get_db)
):
    """
    Müşteri tamamlanan randevusunu değerlendirir.
    - Puan 1-5 arasında olmalı
    - Aynı randevu için iki kez değerlendirme yapılamaz
    - Sadece 'tamamlandi' durumundaki randevular değerlendirilebilir
    """
    # Müşteri doğrulama
    musteri = db.query(models.Musteri).filter(models.Musteri.firebase_uid == x_firebase_uid).first()
    if not musteri:
        raise HTTPException(status_code=401, detail="Önce kayıt olmalısın!")

    # Puan aralığı kontrolü
    if not (1 <= puan <= 5):
        raise HTTPException(status_code=400, detail="Puan 1 ile 5 arasında olmalı.")

    # Randevu var mı ve bu müşteriye mi ait?
    randevu = db.query(models.Randevu).filter(models.Randevu.id == randevu_id).first()
    if not randevu:
        raise HTTPException(status_code=404, detail="Randevu bulunamadı.")
    if randevu.musteri_id != musteri.id:
        raise HTTPException(status_code=403, detail="Bu randevu sana ait değil kanki!")

    # Sadece tamamlanan randevular değerlendirilebilir
    if randevu.durum != "tamamlandi":
        raise HTTPException(
            status_code=400,
            detail="Sadece tamamlanan randevuları değerlendirebilirsin."
        )

    # Daha önce değerlendirilmiş mi?
    var_mi = db.query(models.Degerlendirme).filter(
        models.Degerlendirme.randevu_id == randevu_id
    ).first()
    if var_mi:
        raise HTTPException(status_code=400, detail="Bu randevuyu zaten değerlendirdin.")

    # Değerlendirmeyi oluştur ve session'a ekle
    yeni = models.Degerlendirme(
        musteri_id=musteri.id,
        berber_id=randevu.berber_id,
        randevu_id=randevu_id,
        puan=puan,
        yorum=yorum,
        tarih=datetime.now().strftime("%Y-%m-%d")
    )
    db.add(yeni)
    db.flush()  # ID atanır ama commit edilmez — avg hesabına yeni kayıt dahil olur

    # Berberin ortalama puanını yeniden hesapla (flush ile yeni kayıt dahil)
    ort_puan = db.query(func.avg(models.Degerlendirme.puan)).filter(
        models.Degerlendirme.berber_id == randevu.berber_id
    ).scalar() or puan
    berber = db.query(models.Berber).filter(models.Berber.id == randevu.berber_id).first()
    berber.puan = round(float(ort_puan), 2)

    db.commit()
    return {"mesaj": "Değerlendirme için teşekkürler!", "verilen_puan": puan, "berber_yeni_puan": berber.puan}


@router.get("/berber/{berber_id}")
def berber_degerlendirmeleri(berber_id: int, db: Session = Depends(get_db)):
    """Bir berberin tüm değerlendirmelerini ve ortalama puanını döner."""
    degerlendirmeler = db.query(models.Degerlendirme).filter(
        models.Degerlendirme.berber_id == berber_id
    ).all()

    if not degerlendirmeler:
        return {"ortalama_puan": None, "toplam": 0, "yorumlar": []}

    ort = round(sum(d.puan for d in degerlendirmeler) / len(degerlendirmeler), 2)

    return {
        "ortalama_puan": ort,
        "toplam": len(degerlendirmeler),
        "yorumlar": [
            {
                "puan": d.puan,
                "yorum": d.yorum,
                "tarih": d.tarih,
                "musteri": f"{d.musteri.ad} {d.musteri.soyad[0]}."  # Gizlilik için soyad baş harfi
            }
            for d in degerlendirmeler
        ]
    }
