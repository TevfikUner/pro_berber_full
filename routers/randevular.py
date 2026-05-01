from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, Header, Query
from auth import admin_dogrula
from sqlalchemy.orm import Session
from database import get_db
import models, utils
from datetime import datetime, timedelta
import math

router = APIRouter(prefix="/randevular", tags=["Randevu İşlemleri"])

# --- 1. MÜSAİT TAKVİM ---
@router.get("/musait-takvim")
def musait_takvim_getir(
    berber_id: int = None,  # Verilirse o berberin izin günleri de filtrelenir
    db: Session = Depends(get_db)
):
    """Flutter takvimi için önümüzdeki 14 günlük çalışma saatlerini döner.
    Tatil günleri ve (berber_id verilmişse) berber izin günleri hariç tutulur.
    Geçmiş günler otomatik olarak hariç tutulur.
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
def istatistik_getir(salon_id: int = None, db: Session = Depends(get_db)):
    import datetime as _dt

    # 1. Bugünün tarihi
    simdi = _dt.datetime.now()
    bugun_str = simdi.strftime("%Y-%m-%d")

    # 2. Dinamik berber sayısı (salon bazlı veya genel)
    berber_sorgu = db.query(models.Berber)
    if salon_id:
        berber_sorgu = berber_sorgu.filter(models.Berber.salon_id == salon_id)
    berber_sayisi = berber_sorgu.count()
    berber_idleri = [b.id for b in berber_sorgu.all()]
    
    if berber_sayisi == 0:
        return {"bugunku_randevu": 0, "musait_slot_sayisi": 0, "toplam_slot": 0, "aktif_berber": 0}

    # 3. Bugün tatil mi? (tatil_gunleri tablosundan kontrol)
    bugun_tatil = db.query(models.TatilGunu).filter(
        models.TatilGunu.tarih == bugun_str
    ).first()
    if bugun_tatil:
        return {"bugunku_randevu": 0, "musait_slot_sayisi": 0, "toplam_slot": 0, "aktif_berber": berber_sayisi}

    # 4. Toplam kapasite — 30dk slotlar
    gun_index = simdi.weekday()
    
    # Salon bazlı açılış/kapanış saatleri
    if salon_id:
        salon = db.query(models.Salon).filter(models.Salon.id == salon_id).first()
        if salon and salon.acilis_saati and salon.kapanis_saati:
            try:
                acilis = int(salon.acilis_saati.split(":")[0])
                kapanis = int(salon.kapanis_saati.split(":")[0])
                mesai_saati = max(0, kapanis - acilis)
                if gun_index == 6:  # Pazar
                    mesai_saati = 0  # Kapalı
            except:
                mesai_saati = 7 if gun_index == 6 else 12
        else:
            mesai_saati = 7 if gun_index == 6 else 12
    else:
        mesai_saati = 7 if gun_index == 6 else 12
    
    slot_per_berber = mesai_saati * 2
    toplam_slot = berber_sayisi * slot_per_berber

    # 5. Bugünkü onaylı randevuları çek (salon bazlı filtreleme)
    randevu_sorgu = db.query(models.Randevu).filter(
        models.Randevu.tarih == bugun_str,
        models.Randevu.durum == "onaylandi"
    )
    if salon_id and berber_idleri:
        randevu_sorgu = randevu_sorgu.filter(models.Randevu.berber_id.in_(berber_idleri))
    
    bugunki_randevular = randevu_sorgu.all()

    # 6. Dolu slot sayısını hesapla
    dolu_slot_sayisi = 0
    for r in bugunki_randevular:
        sure = sum(h.sure for h in r.hizmetler) if r.hizmetler else 30
        if sure == 0:
            sure = 30
        dolu_slot_sayisi += math.ceil(sure / 30)

    # 7. Sonuçları dön
    return {
        "bugunku_randevu": len(bugunki_randevular),
        "musait_slot_sayisi": max(0, toplam_slot - dolu_slot_sayisi),
        "toplam_slot": toplam_slot,
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
    # ============================================================
    # DOĞRULAMA 1: Geçmiş tarih kontrolü
    # ============================================================
    if utils.gecmis_tarih_mi(tarih):
        raise HTTPException(
            status_code=400,
            detail="Geçmiş bir tarihe randevu alınamaz."
        )

    # ============================================================
    # DOĞRULAMA 2: Bugünse geçmiş saat kontrolü
    # ============================================================
    if utils.gecmis_saat_mi(tarih, saat):
        raise HTTPException(
            status_code=400,
            detail="Geçmiş bir saate randevu alınamaz."
        )

    # ============================================================
    # DOĞRULAMA 3: Saat formatı kontrolü (sadece 30dk slotlar: XX:00 veya XX:30)
    # ============================================================
    try:
        saat_obj = datetime.strptime(saat, "%H:%M")
        if saat_obj.minute not in (0, 30):
            raise HTTPException(
                status_code=400,
                detail="Randevu saati sadece tam veya yarım saat olabilir (örn: 10:00, 10:30)."
            )
    except ValueError:
        raise HTTPException(status_code=400, detail="Geçersiz saat formatı. Örnek: 14:30")

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

    # Gerekli slot sayısını hesapla (bilgi amaçlı)
    gerekli_slot = math.ceil(toplam_sure / 30)

    # ============================================================
    # DOĞRULAMA 4: Mesai saatleri kontrolü
    # ============================================================
    secilen_tarih_obj = datetime.strptime(tarih, "%Y-%m-%d")
    is_sunday = secilen_tarih_obj.weekday() == 6
    kapanis_dk = (17 if is_sunday else 22) * 60
    
    saat_parca, dakika_parca = map(int, saat.split(":"))
    baslangic_dk = saat_parca * 60 + dakika_parca
    bitis_dk = baslangic_dk + toplam_sure
    
    if baslangic_dk < 10 * 60:
        raise HTTPException(status_code=400, detail="Dükkan 10:00'dan önce açık değil.")
    if bitis_dk > kapanis_dk:
        kapanis_str = "17:00" if is_sunday else "22:00"
        raise HTTPException(
            status_code=400,
            detail=f"Hizmet süresi ({toplam_sure} dk) mesai bitimine ({kapanis_str}) sığmıyor."
        )

    # ============================================================
    # DOĞRULAMA 5: Doluluk & çakışma kontrolü
    # ============================================================
    mevcut_randevular = db.query(models.Randevu).filter(
        models.Randevu.berber_id == berber_id,
        models.Randevu.tarih == tarih,
        models.Randevu.durum == "onaylandi"
    ).all()
    
    dolu_slotlar = []
    for r in mevcut_randevular:
        r_toplam_sure = sum(h.sure for h in r.hizmetler)
        if r_toplam_sure == 0:
            r_toplam_sure = 30
        dolu_slotlar.extend(utils.saat_listesi_olustur(r.saat, r_toplam_sure))

    # Yeni randevunun talep ettiği slotları hesapla
    talep_edilen_slotlar = utils.saat_listesi_olustur(saat, toplam_sure)
    
    # Her bir talep edilen slot dolu mu kontrol et
    cakisan_slotlar = [s for s in talep_edilen_slotlar if s in dolu_slotlar]
    
    if cakisan_slotlar:
        # Doluysa Öneri Mantığı — müsait saatleri bul
        oneriler = utils.musait_saatler_hesapla(tarih, berber_id, toplam_sure, dolu_slotlar)
        raise HTTPException(
            status_code=400,
            detail={
                "hata": f"Seçtiğiniz saat ({saat}) dolu. Hizmet {toplam_sure} dk ({gerekli_slot} slot) gerektiriyor.",
                "cakisan_slotlar": cakisan_slotlar,
                "öneriler": oneriler[:5]
            }
        )

    # ============================================================
    # DOĞRULAMA 6: Yeterli ardışık boş slot kontrolü
    # ============================================================
    # cakisma_var_mi fonksiyonu hem doluluk hem mesai dışı kontrolü yapar
    if utils.cakisma_var_mi(saat, toplam_sure, dolu_slotlar, is_sunday):
        oneriler = utils.musait_saatler_hesapla(tarih, berber_id, toplam_sure, dolu_slotlar)
        raise HTTPException(
            status_code=400,
            detail={
                "hata": f"Toplam {toplam_sure} dakikalık ({gerekli_slot} slot) boşluk bulunamadı.",
                "öneriler": oneriler[:5]
            }
        )

    # ============================================================
    # RANDEVU OLUŞTURMA — Tüm kontroller geçildi
    # ============================================================
    yeni = models.Randevu(
        musteri_id=musteri.id,
        berber_id=berber_id,
        saat=saat,                    # ← Tam olarak müşterinin seçtiği saat, KAYMA YOK
        tarih=tarih,
        durum="onaylandi",
        hizmetler=hizmetler,
        toplam_fiyat=anlik_toplam_fiyat # Fiyatı buraya mühürledik!
    )
    db.add(yeni)
    db.commit()
    db.refresh(yeni)  # ID ve diğer DB alanlarını güncelle

    # --- BİLDİRİM ---
    if musteri.fcm_token:
        utils.bildirim_gonder(
            token=musteri.fcm_token,
            baslik="Randevu Onayı 💈",
            mesaj=f"Kanki {tarih} günü {saat} saati için randevun alındı. Toplam: {anlik_toplam_fiyat} TL"
        )

    return {
        "mesaj": "Randevu başarıyla alındı!",
        "randevu_id": yeni.id,
        "saat": saat,
        "tarih": tarih,
        "kaplanan_slotlar": talep_edilen_slotlar,
        "slot_sayisi": gerekli_slot,
        "detay": f"Toplam {len(hizmetler)} hizmet, {toplam_sure} dakika ({gerekli_slot} slot), {anlik_toplam_fiyat} TL"
    }


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
    from datetime import datetime, timedelta
    musteri = db.query(models.Musteri).filter(models.Musteri.firebase_uid == x_firebase_uid).first()
    if not musteri: raise HTTPException(404, "Müşteri bulunamadı.")
    
    randevular = db.query(models.Randevu).filter(models.Randevu.musteri_id == musteri.id).all()
    
    # Geçmiş tarihli "onaylandi" randevuları otomatik "tamamlandi" yap
    simdi = datetime.now()
    degisen = False
    for r in randevular:
        if r.durum == "onaylandi":
            try:
                randevu_zamani = datetime.strptime(f"{r.tarih} {r.saat}", "%Y-%m-%d %H:%M")
                toplam_sure = sum(h.sure for h in r.hizmetler) if r.hizmetler else 30
                randevu_bitis = randevu_zamani + timedelta(minutes=toplam_sure)
                if randevu_bitis < simdi:
                    r.durum = "tamamlandi"
                    degisen = True
            except:
                pass
    if degisen:
        db.commit()
    
    return [{
        "id": r.id,
        "berber_id": r.berber_id,
        "berber": f"{r.berber.ad} {r.berber.soyad}",
        "salon_ad": r.salon.ad if r.salon else "Bilinmiyor",
        "hizmetler": [h.ad for h in r.hizmetler],
        "tarih": r.tarih,
        "saat": r.saat,
        "durum": r.durum,
        "toplam_fiyat": r.toplam_fiyat,
        "puan": r.puan,
        "yorum": r.yorum,
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
    from datetime import datetime
    randevular = db.query(models.Randevu).filter(
        models.Randevu.berber_id == berber_id,
        models.Randevu.tarih == tarih,
        models.Randevu.durum == "onaylandi"
    ).all()
    
    dolu_slotlar = []
    for r in randevular:
        r_toplam_sure = sum(h.sure for h in r.hizmetler) if r.hizmetler else 30
        dolu_slotlar.extend(utils.saat_listesi_olustur(r.saat, r_toplam_sure))

    # --- YENİ: Geçmiş saatleri "DOLU" gibi göster (Gri renk için) ---
    simdi = datetime.now()
    bugun_str = simdi.strftime("%Y-%m-%d")

    if tarih == bugun_str:
        su_an_saat = simdi.hour
        su_an_dakika = simdi.minute
        
        # 10:00 ile 24:00 arası tüm slotları kontrol et
        for saat_degeri in range(10, 24):
            for dakika_degeri in (0, 30):
                # Eğer slot şu anki saatten küçükse veya eşitse (geçmişse)
                if saat_degeri < su_an_saat or (saat_degeri == su_an_saat and dakika_degeri <= su_an_dakika):
                    gecmis_saat_str = f"{saat_degeri:02d}:{dakika_degeri:02d}"
                    dolu_slotlar.append(gecmis_saat_str)
    # ----------------------------------------------------------------

    return list(set(dolu_slotlar))


# --- 6b. MÜSAİT SAATLERİ LİSTELEME (YENİ - KAYMA KORUMALI) ---
@router.get("/musait-saatler/{berber_id}")
def musait_saatleri_getir(
    berber_id: int,
    tarih: str,
    hizmet_ids: list[int] = Query(...),
    db: Session = Depends(get_db)
):
    import math
    from datetime import datetime
    
    # Geçmiş tarih kontrolü
    if utils.gecmis_tarih_mi(tarih):
        raise HTTPException(status_code=400, detail="Geçmiş bir tarih için saat sorgulanamaz.")
    
    # Hizmetleri bul ve toplam süreyi hesapla
    hizmetler = db.query(models.Hizmet).filter(models.Hizmet.id.in_(hizmet_ids)).all()
    if not hizmetler:
        raise HTTPException(status_code=404, detail="Hizmetler bulunamadı.")
    
    toplam_sure = sum(h.sure for h in hizmetler)
    gerekli_slot = math.ceil(toplam_sure / 30)
    
    # Mevcut dolu slotları DB'den çek
    randevular = db.query(models.Randevu).filter(
        models.Randevu.berber_id == berber_id,
        models.Randevu.tarih == tarih,
        models.Randevu.durum == "onaylandi"
    ).all()
    
    dolu_slotlar = []
    for r in randevular:
        r_toplam_sure = sum(h.sure for h in r.hizmetler) if r.hizmetler else 30
        dolu_slotlar.extend(utils.saat_listesi_olustur(r.saat, r_toplam_sure))
    
    # Müsait saatleri hesapla
    musait = utils.musait_saatler_hesapla(tarih, berber_id, toplam_sure, dolu_slotlar)
    
    # =========================================================================
    # HAYAT KURTARAN DÜZELTME: Grid (Ekran) Kaymasını Önleme Algoritması
    # =========================================================================
    # Tüm mesai saatlerini tara. Eğer bir saat 'musait' listesine giremediyse 
    # (geçmiş saat olduğu için VEYA araya sığmadığı için), onu ZORLA 'dolu_slotlar' 
    # listesine ekle! Böylece Flutter hiçbir butonu silmez, sadece griye boyar.
    
    secilen_tarih_obj = datetime.strptime(tarih, "%Y-%m-%d")
    is_sunday = secilen_tarih_obj.weekday() == 6
    kapanis_saati = 17 if is_sunday else 22
    
    for saat_degeri in range(10, kapanis_saati):
        for dakika_degeri in (0, 30):
            slot_str = f"{saat_degeri:02d}:{dakika_degeri:02d}"
            
            # Eğer saat müsait değilse ve halihazırda dolu listesinde de yoksa, doldur!
            if slot_str not in musait and slot_str not in dolu_slotlar:
                dolu_slotlar.append(slot_str)
    # =========================================================================
    
    return {
        "tarih": tarih,
        "berber_id": berber_id,
        "toplam_sure_dk": toplam_sure,
        "gerekli_slot": gerekli_slot,
        "musait_saatler": musait,
        "dolu_slotlar": list(set(dolu_slotlar))
    }

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
# --- 8. PROFİL BİLGİLERİNİ GETİR ---
@router.get("/profil")
def profil_getir(x_firebase_uid: str = Header(...), db: Session = Depends(get_db)):
    musteri = db.query(models.Musteri).filter(models.Musteri.firebase_uid == x_firebase_uid).first()
    
    if not musteri:
        return {"ad": "", "soyad": "", "telefon": "", "favori_berber_id": None}
        
    return {
        "ad": musteri.ad or "",
        "soyad": musteri.soyad or "",
        "telefon": musteri.telefon or "",
        "favori_berber_id": musteri.favori_berber_id,
    }
# --- Veri Modeli ---
class ProfilGuncellemeVerisi(BaseModel):
    ad: str
    soyad: str
    telefon: str

# --- 9. PROFİL GÜNCELLEME ---
@router.post("/profil/guncelle")
def profil_guncelle(
    veriler: ProfilGuncellemeVerisi,
    x_firebase_uid: str = Header(...),
    db: Session = Depends(get_db)
):
    musteri = db.query(models.Musteri).filter(models.Musteri.firebase_uid == x_firebase_uid).first()
    
    if not musteri:
        # Adamın hesabı yoksa yeni müşteri olarak kaydet
        yeni_musteri = models.Musteri(
            firebase_uid=x_firebase_uid,
            ad=veriler.ad,
            soyad=veriler.soyad,
            telefon=veriler.telefon
        )
        db.add(yeni_musteri)
        db.commit()
        return {"mesaj": "Profil başarıyla oluşturuldu"}
        
    # Varsa mevcut bilgileri güncelle
    musteri.ad = veriler.ad
    musteri.soyad = veriler.soyad
    musteri.telefon = veriler.telefon
    
    db.commit()
    return {"mesaj": "Profil başarıyla güncellendi"}

# --- 10. FAVORİ BERBER TOGGLE (Çoklu Favori) ---
@router.post("/profil/favori-toggle")
def favori_toggle(
    berber_id: int,
    x_firebase_uid: str = Header(...),
    db: Session = Depends(get_db)
):
    musteri = db.query(models.Musteri).filter(
        models.Musteri.firebase_uid == x_firebase_uid
    ).first()
    if not musteri:
        raise HTTPException(status_code=404, detail="Müşteri bulunamadı.")
    
    berber = db.query(models.Berber).filter(models.Berber.id == berber_id).first()
    if not berber:
        raise HTTPException(status_code=404, detail="Berber bulunamadı.")
    
    if berber in musteri.favori_berberler:
        musteri.favori_berberler.remove(berber)
        db.commit()
        return {"mesaj": f"{berber.ad} {berber.soyad} favorilerden çıkarıldı.", "favori": False}
    else:
        musteri.favori_berberler.append(berber)
        db.commit()
        return {"mesaj": f"{berber.ad} {berber.soyad} favorilere eklendi!", "favori": True}

# --- 11. FAVORİ BERBER LİSTESİ ---
@router.get("/profil/favoriler")
def favori_listele(
    x_firebase_uid: str = Header(...),
    db: Session = Depends(get_db)
):
    musteri = db.query(models.Musteri).filter(
        models.Musteri.firebase_uid == x_firebase_uid
    ).first()
    if not musteri:
        raise HTTPException(status_code=404, detail="Müşteri bulunamadı.")
    
    return [{
        "berber_id": b.id,
        "berber_ad": f"{b.ad} {b.soyad}",
        "salon_id": b.salon_id,
        "salon_ad": b.salon.ad if b.salon else "Bilinmiyor",
        "uzmanlik": b.uzmanlik,
        "puan": b.puan,
        "foto_url": b.foto_url,
    } for b in musteri.favori_berberler]