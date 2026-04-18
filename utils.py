import os
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, messaging

def gun_bilgisi_getir(tarih_str: str):
    """ Verilen tarihin (YYYY-MM-DD) kapanış saatini ve tatil durumunu döner """
    tarih_obj = datetime.strptime(tarih_str, "%Y-%m-%d")
    is_sunday = tarih_obj.weekday() == 6 # 6 = Pazar
    
    return {
        "kapanis": "17:00" if is_sunday else "22:00",
        "is_open": True # Şu an her gün açığız
    }

def musait_gunleri_listele(gun_sayisi: int = 14):
    """ Bugünden itibaren belirtilen gün kadar ileriye dönük açık günleri listeler """
    musait_gunler = []
    simdi = datetime.now()
    
    for i in range(gun_sayisi):
        hedef_gun = simdi + timedelta(days=i)
        gun_str = hedef_gun.strftime("%Y-%m-%d")
        
        # Geçmiş saat kontrolü (Eğer bugünse ve saat 22:00'yi geçtiyse ekleme)
        bilgi = gun_bilgisi_getir(gun_str)
        kapanis_vakti = datetime.combine(hedef_gun.date(), datetime.strptime(bilgi["kapanis"], "%H:%M").time())
        
        if datetime.now() < kapanis_vakti:
            musait_gunler.append({
                "tarih": gun_str,
                "kapanis": bilgi["kapanis"],
                "gun_adi": hedef_gun.strftime("%A") # Flutter'da göstermek için
            })
            
    return musait_gunler

# --- 1. FIREBASE BAŞLATMA ---
# serviceAccountKey.json dosyasını proje klasörüne koyunca otomatik yüklenir.
# Firebase Console > Proje Ayarları > Hizmet Hesapları > JSON İndir
_KEY_PATH = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")
try:
    if os.path.exists(_KEY_PATH):
        cred = credentials.Certificate(_KEY_PATH)
        firebase_admin.initialize_app(cred)
    else:
        # Anahtar dosyası yoksa Firebase devre dışı (bildirimler çalışmaz)
        print("[UYARI] serviceAccountKey.json bulunamadı. Push bildirimler devre dışı.")
except ValueError:
    # Uygulama zaten başlatılmışsa (hot-reload durumu) sessizce devam et
    pass

# --- 2. BİLDİRİM MOTORU ---
def bildirim_gonder(token: str, baslik: str, mesaj: str):
    """Telefona push notification gönderen ana fonksiyon"""
    if not token:
        return # Token yoksa (cihaz kayıtlı değilse) işlem yapma
        
    message = messaging.Message(
        notification=messaging.Notification(
            title=baslik,
            body=mesaj,
        ),
        token=token,
    )
    
    try:
        response = messaging.send(message)
        print("Bildirim başarıyla gönderildi:", response)
    except Exception as e:
        print("Bildirim gönderilirken hata oluştu (Şu an JSON dosyası eksik olabilir):", e)

# --- 3. RANDEVU VE SLOT MANTIKLARI ---
def saat_listesi_olustur(baslangic_saat: str, sure_dk: int):
    """ 
    Verilen başlangıç saatinden itibaren hizmet süresi boyunca 
    oluşacak tüm 15 dakikalık slotları liste olarak döner.
    Ceiling division kullanır: 40dk → 3 slot (45dk bloke), 40//15=2 değil!
    """
    import math
    slotlar = []
    format_str = "%H:%M"
    try:
        mevcut_vakit = datetime.strptime(baslangic_saat, format_str)
        # Ceiling: 40dk → ceil(40/15)=3 slot, 30dk → 2 slot, 45dk → 3 slot
        adim_sayisi = math.ceil(sure_dk / 15)
        for _ in range(adim_sayisi):
            slotlar.append(mevcut_vakit.strftime(format_str))
            mevcut_vakit += timedelta(minutes=15)
    except Exception:
        pass
    return slotlar

def cakisma_var_mi(baslangic_saat: str, sure_dk: int, dolu_slotlar_listesi: list, is_sunday: bool):
    """ 
    Belirli bir saat ve sürenin mevcut doluluklarla ve mesaiyle 
    çakışıp çakışmadığını denetler. (Dakika hassasiyetli)
    """
    talep_edilen = saat_listesi_olustur(baslangic_saat, sure_dk)
    
    # Kapanış sınırını tam dakika olarak hesaplayalım
    kapanis_saati = 17 if is_sunday else 22
    
    for s in talep_edilen:
        try:
            # "16:45" -> saat: 16, dakika: 45
            saat_parca, dakika_parca = map(int, s.split(":"))
            
            # 1. Mesai Dışı Kontrolü (10:00 altı veya kapanış üstü)
            # Eğer saat kapanış saatine eşitse ama dakika 00'dan büyükse (örn 17:15), yasak!
            if saat_parca < 10:
                return True
            if saat_parca > kapanis_saati or (saat_parca == kapanis_saati and dakika_parca > 0):
                return True
                
            # 2. Doluluk Kontrolü
            if s in dolu_slotlar_listesi:
                return True
        except:
            return True
            
    return False
def dakika_farki_hesapla(randevu_saati_str: str, randevu_tarih_str: str = None):
    """
    Randevuya ne kadar dakika kaldığını hesaplar.
    Tarih parametresi verilmezse bugünü kullanır — ama yarınki randevular
    için MUTLAKA tarih gönderilmelidir, aksi halde hatalı sonuç döner!
    """
    try:
        simdi = datetime.now()
        if randevu_tarih_str:
            randevu_tarihi = datetime.strptime(randevu_tarih_str, "%Y-%m-%d").date()
        else:
            randevu_tarihi = simdi.date()  # Geriye dönük uyumluluk
        randevu_vakti = datetime.combine(
            randevu_tarihi,
            datetime.strptime(randevu_saati_str, "%H:%M").time()
        )
        fark = randevu_vakti - simdi
        return fark.total_seconds() / 60
    except ValueError:
        return 9999


# --- 4. APScheduler HATIRLATMA GÖREVİ ---
def hatirlatma_gorevi():
    """
    Her 15 dakikada bir çalışır.
    Yaklaşık 1 saat sonraya (55-70 dk arası) randevusu olan müşterilere
    hatırlatma bildirimi gönderir. Aynı randevuya iki kez bildirim gitmez.
    """
    from database import SessionLocal
    import models as _models

    db = SessionLocal()
    try:
        simdi_str = __import__("datetime").date.today().strftime("%Y-%m-%d")

        randevular = db.query(_models.Randevu).filter(
            _models.Randevu.tarih == simdi_str,
            _models.Randevu.durum == "onaylandi",
            _models.Randevu.hatirlatma_gonderildi == False
        ).all()

        for r in randevular:
            fark = dakika_farki_hesapla(r.saat, r.tarih)
            if 55 <= fark <= 70:  # ~1 saat penceresi
                if r.musteri.fcm_token:
                    bildirim_gonder(
                        token=r.musteri.fcm_token,
                        baslik="Randevu Hatırlatması ⏰",
                        mesaj=f"1 saate kalmadı! Saat {r.saat}'daki randevunu unutma kanki."
                    )
                r.hatirlatma_gonderildi = True

        db.commit()
    except Exception as e:
        print(f"[APScheduler] Hatırlatma görevi hata verdi: {e}")
    finally:
        db.close()


# --- 5. APScheduler DEĞERLENDİRME GÖREVİ ---
def degerlendirme_gorevi():
    """
    Her 15 dakikada bir çalışır.
    Randevu saatinden 2 saat sonra müşteriye 'Bizi Puanla' FCM data bildirimi gönderir.
    Aynı randevuya ikinci kez bildirim gitmez.
    """
    from database import SessionLocal
    import models as _models
    from datetime import date as _date

    db = SessionLocal()
    try:
        bugun_str = _date.today().strftime("%Y-%m-%d")

        # Bugünkü, onaylanmış, henüz değerlendirme bildirimi gönderilmemiş randevular
        randevular = db.query(_models.Randevu).filter(
            _models.Randevu.tarih == bugun_str,
            _models.Randevu.durum == "onaylandi",
            _models.Randevu.degerlendirme_bildirimi_gonderildi == False
        ).all()

        simdi = datetime.now()

        for r in randevular:
            try:
                randevu_vakti = datetime.combine(
                    simdi.date(),
                    datetime.strptime(r.saat, "%H:%M").time()
                )
                # Randevu saatinden 2 saat sonra geçtiyse bildirim gönder
                if simdi >= randevu_vakti + timedelta(hours=2):
                    if r.musteri and r.musteri.fcm_token:
                        berber_adi = f"{r.berber.ad} {r.berber.soyad}" if r.berber else "Berber"
                        berber_foto = r.berber.foto_url or "" if r.berber else ""

                        # Data-only payload → uygulama foreground/background/killed durumda çalışır
                        message = messaging.Message(
                            data={
                                "type": "degerlendirme",
                                "randevu_id": str(r.id),
                                "berber_adi": berber_adi,
                                "berber_foto_url": berber_foto,
                                "baslik": "Randevunu Nasıl Buldun? ⭐",
                                "mesaj": f"{berber_adi}'i puanlamak ister misin?"
                            },
                            notification=messaging.Notification(
                                title="Randevunu Nasıl Buldun? ⭐",
                                body=f"{berber_adi}'i puanlamak ister misin?"
                            ),
                            token=r.musteri.fcm_token,
                        )
                        try:
                            messaging.send(message)
                            print(f"[Değerlendirme] Randevu {r.id} için bildirim gönderildi.")
                        except Exception as e:
                            print(f"[Değerlendirme] Bildirim gönderilemedi: {e}")

                    # Token yoksa da flag'i true yap (bir daha deneme)
                    r.degerlendirme_bildirimi_gonderildi = True
            except Exception as e:
                print(f"[Değerlendirme] Randevu {r.id} işlenirken hata: {e}")

        db.commit()
    except Exception as e:
        print(f"[APScheduler] Değerlendirme görevi hata verdi: {e}")
    finally:
        db.close()