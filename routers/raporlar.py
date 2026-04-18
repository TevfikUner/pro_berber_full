from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
from auth import admin_dogrula
import models
from datetime import datetime, date

router = APIRouter(prefix="/raporlar", tags=["Admin İstatistik & Raporlar"])


@router.get("/gunluk")
def gunluk_rapor(
    tarih: str = Query(default=None, description="YYYY-MM-DD, boş bırakılırsa bugün"),
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)
):
    """Belirli bir günün ciro, randevu ve hizmet istatistiklerini döner."""
    hedef = tarih or date.today().strftime("%Y-%m-%d")

    randevular = db.query(models.Randevu).filter(
        models.Randevu.tarih == hedef,
        models.Randevu.durum == "tamamlandi"
    ).all()

    tum_randevular = db.query(models.Randevu).filter(
        models.Randevu.tarih == hedef
    ).all()

    toplam_ciro = sum(r.toplam_fiyat for r in randevular)
    hizmet_sayac = {}
    for r in randevular:
        for h in r.hizmetler:
            hizmet_sayac[h.ad] = hizmet_sayac.get(h.ad, 0) + 1

    return {
        "tarih": hedef,
        "toplam_randevu": len(tum_randevular),
        "tamamlanan": len(randevular),
        "iptal_edilen": sum(1 for r in tum_randevular if r.durum == "iptal"),
        "bekleyen": sum(1 for r in tum_randevular if r.durum in ("onaylandi", "beklemede")),
        "toplam_ciro_tl": round(toplam_ciro, 2),
        "en_cok_yapilan_hizmetler": sorted(hizmet_sayac.items(), key=lambda x: x[1], reverse=True)[:5]
    }


@router.get("/aylik")
def aylik_rapor(
    yil: int = Query(default=None),
    ay: int = Query(default=None, ge=1, le=12),
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)
):
    """Belirli bir ayın özet istatistiklerini döner. Boş bırakılırsa bu ay."""
    simdi = datetime.now()
    hedef_yil = yil or simdi.year
    hedef_ay = ay or simdi.month
    ay_prefix = f"{hedef_yil}-{hedef_ay:02d}"  # örn: "2025-04"

    randevular = db.query(models.Randevu).filter(
        models.Randevu.tarih.like(f"{ay_prefix}%")
    ).all()

    tamamlananlar = [r for r in randevular if r.durum == "tamamlandi"]
    toplam_ciro = sum(r.toplam_fiyat for r in tamamlananlar)

    # Berber bazlı ciro
    berber_ciro = {}
    for r in tamamlananlar:
        isim = f"{r.berber.ad} {r.berber.soyad}"
        berber_ciro[isim] = berber_ciro.get(isim, 0) + r.toplam_fiyat

    # Günlük dağılım
    gunluk = {}
    for r in tamamlananlar:
        gunluk[r.tarih] = gunluk.get(r.tarih, 0) + r.toplam_fiyat

    return {
        "donem": f"{hedef_yil}/{hedef_ay:02d}",
        "toplam_randevu": len(randevular),
        "tamamlanan": len(tamamlananlar),
        "iptal_edilen": sum(1 for r in randevular if r.durum == "iptal"),
        "toplam_ciro_tl": round(toplam_ciro, 2),
        "ortalama_gunluk_ciro_tl": round(toplam_ciro / max(len(gunluk), 1), 2),
        "berber_bazli_ciro": {k: round(v, 2) for k, v in sorted(berber_ciro.items(), key=lambda x: x[1], reverse=True)},
        "en_yogun_gunler": sorted(gunluk.items(), key=lambda x: x[1], reverse=True)[:5]
    }


@router.get("/populer-hizmetler")
def populer_hizmetler(
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)
):
    """Tüm zamanların en çok tercih edilen hizmetlerini döner."""
    randevular = db.query(models.Randevu).filter(
        models.Randevu.durum == "tamamlandi"
    ).all()

    sayac = {}
    ciro = {}
    for r in randevular:
        for h in r.hizmetler:
            sayac[h.ad] = sayac.get(h.ad, 0) + 1
            ciro[h.ad] = ciro.get(h.ad, 0) + h.fiyat

    siralama = sorted(sayac.items(), key=lambda x: x[1], reverse=True)
    return [
        {"hizmet": ad, "toplam_yapilma": adet, "toplam_ciro_tl": round(ciro.get(ad, 0), 2)}
        for ad, adet in siralama
    ]
