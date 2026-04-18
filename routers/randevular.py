from fastapi import APIRouter, Depends, HTTPException, Header, Query
from auth import admin_dogrula
from sqlalchemy.orm import Session
from database import get_db
import models, utils
from datetime import datetime, timedelta

router = APIRouter(prefix="/randevular", tags=["Randevu İşlemleri"])

# --- 1. MÜSAİT TAKVİM ---
@router.get("/musait-takvim")
def musait_takvim_getir(
    berber_id: int = None,  # Verilirse o berberin izin günleri de filtrelenir
    db: Session = Depends(get_db)
):
    """Flutter takvimi için önümüzdeki 14 günlük çalışma saatlerini döner.
    Tatil günleri ve (berber_id verilmişse) berber izin günleri hariç tutulur.
    """
    gunler = utils.musait_gunleri_listele(14)

    # Tatil günlerini DB'den al
    tatil_tarihleri = {
        t.tarih for t in db.query(models.TatilGunu).all()
    }

    # Berber izin günlerini DB'den al (eğer berber_id verilmişse)
    berber_izin_tarihleri = set()
    if berber_id:
        berber_izin_tarihleri = {
            i.tarih for i in db.query(models.BerberIzin).filter(
                models.BerberIzin.berber_id == berber_id
            ).all()
        }

    # Kapalı günleri filtrele
    kapali = tatil_tarihleri | berber_izin_tarihleri
    return [
        {**g, "tatil": g["tarih"] in tatil_tarihleri, "berber_izin": g["tarih"] in berber_izin_tarihleri}
        for g in gunler
        if g["tarih"] not in kapali
    ]

# --- 1b. ANA SAYFA İSTATİSTİK ---
@router.get("/istatistik")
def istatistik_getir(db: Session = Depends(get_db)):
    import math
    import datetime as _dt

    # 1. Bugünün tarihi
    simdi = _dt.datetime.now()
    bugun_str = simdi.strftime("%Y-%m-%d")

    # 2. Dinamik berber sayısı
    berber_sayisi = db.query(models.Berber).count()
    if berber_sayisi == 0:
        return {"bugunku_randevu": 0, "musait_slot_sayisi": 0, "toplam_slot": 0, "aktif_berber": 0}

    # 3. Bugün tatil mi? (tatil_gunleri tablosundan kontrol)
    bugun_tatil = db.query(models.TatilGunu).filter(
        models.TatilGunu.tarih == bugun_str
    ).first()
    if bugun_tatil:
        return {"bugunku_randevu": 0, "musait_slot_sayisi": 0, "toplam_slot": 0, "aktif_berber": berber_sayisi}

    # 4. Toplam kapasite — 30dk slotlar (dolu_slot ile aynı birim!)
    # Hafta içi (0-5): 10:00–22:00 = 12 saat = 24 slot/berber
    # Pazar    (6)   : 10:00–17:00 =  7 saat = 14 slot/berber
    gun_index = simdi.weekday()
    mesai_saati = 7 if gun_index == 6 else 12
    slot_per_berber = mesai_saati * 2          # ✅ 30dk birim: 12 saat → 24 slot
    toplam_slot = berber_sayisi * slot_per_berber

    # 5. Bugünkü onaylı randevuları çek
    bugunki_randevular = db.query(models.Randevu).filter(
        models.Randevu.tarih == bugun_str,
        models.Randevu.durum == "onaylandi"
    ).all()

    # 6. Dolu slot sayısını hesapla (30dk birim — toplam_slot ile eşleşiyor)
    dolu_slot_sayisi = 0
    for r in bugunki_randevular:
        sure = sum(h.sure for h in r.hizmetler) if r.hizmetler else 30
        if sure == 0:
            sure = 30
        dolu_slot_sayisi += math.ceil(sure / 30)  # ✅ 30dk birim

    # 7. Sonuçları dön
    return {
        "bugunku_randevu": len(bugunki_randevular),                          # Gerçek randevu adedi
        "musait_slot_sayisi": max(0, toplam_slot - dolu_slot_sayisi),        # Boş 30dk slotlar
        "toplam_slot": toplam_slot,                                          # Toplam 30dk slotlar
        "aktif_berber": berber_sayisi
    }


# --- 2. RANDEVU OLUŞTURMA (ÇOKLU HİZMET & FİYAT MÜHÜRLEME) ---
@router.post("/olustur")
def randevu_olustur(
    berber_id: int,
    saat: str,
    tarih: str,
    x_firebase_uid: str = Header(...),
    hizmet_ids: list[int] = Query(...),
    # Flutter adım 5'ten gelen form alanları (opsiyonel — ilk kez gelenler için)
    ad: str = Query(default=""),
    soyad: str = Query(default=""),
    telefon: str = Query(default=""),
    db: Session = Depends(get_db)
):
    # Müşteri ara — yoksa form bilgileriyle otomatik oluştur
    musteri = db.query(models.Musteri).filter(
        models.Musteri.firebase_uid == x_firebase_uid
    ).first()

    if not musteri:
        # Firebase kimlik doğrulaması zaten yapıldı.
        # Form bilgileri varsa DB'ye kaydet, yoksa geçici isim kullan.
        musteri = models.Musteri(
            firebase_uid=x_firebase_uid,
            ad=ad or "Misafir",
            soyad=soyad or "",
            telefon=telefon or "",
        )
        db.add(musteri)
        db.commit()
        db.refresh(musteri)

    # Seçilen tüm hizmetleri bul
    hizmetler = db.query(models.Hizmet).filter(models.Hizmet.id.in_(hizmet_ids)).all()
    if not hizmetler:
        raise HTTPException(status_code=404, detail="Hizmetler bulunamadı.")

    
    # Süre ve O Anki Toplam Fiyatı Hesapla
    toplam_sure = sum(h.sure for h in hizmetler)
    anlik_toplam_fiyat = sum(h.fiyat for h in hizmetler)

    # Doluluk Kontrolü (Seçilen tarihe göre)
    secilen_tarih_obj = datetime.strptime(tarih, "%Y-%m-%d")
    is_sunday = secilen_tarih_obj.weekday() == 6
    
    mevcut_randevular = db.query(models.Randevu).filter(
        models.Randevu.berber_id == berber_id,
        models.Randevu.tarih == tarih,
        models.Randevu.durum == "onaylandi"
    ).all()
    
    dolu_slotlar = []
    for r in mevcut_randevular:
        r_toplam_sure = sum(h.sure for h in r.hizmetler)
        dolu_slotlar.extend(utils.saat_listesi_olustur(r.saat, r_toplam_sure))

    # Yeni randevunun toplam süresi için çakışma kontrolü
    if not utils.cakisma_var_mi(saat, toplam_sure, dolu_slotlar, is_sunday):
        yeni = models.Randevu(
            musteri_id=musteri.id,
            berber_id=berber_id,
            saat=saat,
            tarih=tarih,
            durum="onaylandi",
            hizmetler=hizmetler,
            toplam_fiyat=anlik_toplam_fiyat # Fiyatı buraya mühürledik!
        )
        db.add(yeni)
        db.commit()
        db.refresh(yeni)  # 🔧 Düzeltme: ID ve diğer DB alanlarını güncelle

        # --- BİLDİRİM ---
        if musteri.fcm_token:
            utils.bildirim_gonder(
                token=musteri.fcm_token,
                baslik="Randevu Onayı 💈",
                mesaj=f"Kanki {tarih} günü {saat} saati için randevun alındı. Toplam: {anlik_toplam_fiyat} TL"
            )

        return {
            "mesaj": "Randevu başarıyla alındı!",
            "randevu_id": yeni.id,  # 🔧 Düzeltme: Artık ID dönebiliyoruz
            "detay": f"Toplam {len(hizmetler)} hizmet, {toplam_sure} dakika, {anlik_toplam_fiyat} TL"
        }
    
    # Doluysa Öneri Mantığı
    oneriler = []
    tara = datetime.strptime("10:00", "%H:%M")
    kapanis = "17:00" if is_sunday else "22:00"
    while tara < datetime.strptime(kapanis, "%H:%M"):
        aday = tara.strftime("%H:%M")
        if not utils.cakisma_var_mi(aday, toplam_sure, dolu_slotlar, is_sunday):
            oneriler.append(aday)
        tara += timedelta(minutes=30)

    raise HTTPException(
        status_code=400, 
        detail={"hata": f"Toplam {toplam_sure} dakikalık boşluk bulunamadı.", "öneriler": oneriler[:5]}
    )

# --- 3. DURUM GÜNCELLEME (🔒 Sadece Admin) ---
@router.patch("/durum-guncelle/{randevu_id}")
def durum_guncelle(
    randevu_id: int,
    yeni_durum: str,
    db: Session = Depends(get_db),
    _: None = Depends(admin_dogrula)  # 🔧 Düzeltme: Artık sadece admin güncelleyebilir
):
    GECERLI_DURUMLAR = {"onaylandi", "iptal", "tamamlandi", "beklemede"}
    if yeni_durum not in GECERLI_DURUMLAR:
        raise HTTPException(status_code=400, detail=f"Geçersiz durum. Seçenekler: {GECERLI_DURUMLAR}")

    r = db.query(models.Randevu).filter(models.Randevu.id == randevu_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Randevu bulunamadı.")

    r.durum = yeni_durum
    db.commit()

    if r.musteri.fcm_token:
        utils.bildirim_gonder(
            token=r.musteri.fcm_token,
            baslik="Randevu Güncellendi 🛎️",
            mesaj=f"Randevun şu an: {yeni_durum}. Bilgin olsun kanki!"
        )

    return {"mesaj": f"Durum '{yeni_durum}' olarak güncellendi."}

# --- 4. MÜŞTERİ PANELİ ---
@router.get("/benim-randevularim")
def benim_randevularim(x_firebase_uid: str = Header(...), db: Session = Depends(get_db)):
    musteri = db.query(models.Musteri).filter(models.Musteri.firebase_uid == x_firebase_uid).first()
    if not musteri: raise HTTPException(404, "Müşteri bulunamadı.")
    
    randevular = db.query(models.Randevu).filter(models.Randevu.musteri_id == musteri.id).all()
    return [{
        "id": r.id,
        "berber": f"{r.berber.ad} {r.berber.soyad}",
        "hizmetler": [h.ad for h in r.hizmetler],
        "tarih": r.tarih,
        "saat": r.saat,
        "durum": r.durum,
        "toplam_fiyat": r.toplam_fiyat # Mühürlü fiyatı dönüyoruz
    } for r in randevular]

# --- 5. BERBER PANELİ ---
@router.get("/berber-plani/{berber_id}")
def berber_plani(berber_id: int, db: Session = Depends(get_db)):
    randevular = db.query(models.Randevu).filter(
        models.Randevu.berber_id == berber_id,
        models.Randevu.durum != "iptal"
    ).all()
    return [{
        "id": r.id,
        "musteri": f"{r.musteri.ad} {r.musteri.soyad}",
        "tarih": r.tarih,
        "saat": r.saat,
        "hizmetler": [h.ad for h in r.hizmetler],
        "toplam_fiyat": r.toplam_fiyat
    } for r in randevular]

# --- 6. DOLU SAATLERİ LİSTELEME ---
@router.get("/dolu-saatler/{berber_id}")
def dolu_saatleri_getir(berber_id: int, tarih: str, db: Session = Depends(get_db)):
    randevular = db.query(models.Randevu).filter(
        models.Randevu.berber_id == berber_id,
        models.Randevu.tarih == tarih,
        models.Randevu.durum == "onaylandi"
    ).all()
    
    dolu_slotlar = []
    for r in randevular:
        r_toplam_sure = sum(h.sure for h in r.hizmetler)
        dolu_slotlar.extend(utils.saat_listesi_olustur(r.saat, r_toplam_sure))
    return list(set(dolu_slotlar))

# --- 7. RANDEVU SİLME ---
@router.delete("/sil/{randevu_id}")
def randevu_sil(randevu_id: int, x_firebase_uid: str = Header(...), db: Session = Depends(get_db)):
    r = db.query(models.Randevu).filter(models.Randevu.id == randevu_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Randevu bulunamadı.")

    # 🔧 Düzeltme: Sadece randevunun sahibi silebilir
    if r.musteri.firebase_uid != x_firebase_uid:
        raise HTTPException(status_code=403, detail="Bu randevu sana ait değil kanki!")

    if 0 < utils.dakika_farki_hesapla(r.saat, r.tarih) < 30:  # ✅ Tarih de geçiriliyor artık
        raise HTTPException(status_code=400, detail="Son 30 dakika iptal edilemez kanki!")

    if r.musteri.fcm_token:
        utils.bildirim_gonder(
            token=r.musteri.fcm_token,
            baslik="Randevu İptal Edildi ❌",
            mesaj=f"{r.saat} saatindeki randevun silindi."
        )

    db.delete(r)
    db.commit()
    return {"mesaj": "Randevu başarıyla silindi."}