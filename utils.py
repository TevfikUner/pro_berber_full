import os
from datetime import datetime, timedelta
import math
import firebase_admin
from firebase_admin import credentials, messaging

def gun_bilgisi_getir(tarih_str: str):
    """ Verilen tarihin (YYYY-MM-DD) kapanış saatini ve tatil durumunu döner """
    tarih_obj = datetime.strptime(tarih_str, "%Y-%m-%d")
    is_sunday = tarih_obj.weekday() == 6 # 6 = Pazar
    
    return {
        "kapanis": "17:00" if is_sunday else "22:00",
        "acilis": "10:00",
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

def gecmis_tarih_mi(tarih_str: str) -> bool:
    """
    Verilen tarih bugünden önceyse True döner.
    Bugün veya gelecek ise False döner.
    """
    try:
        secilen = datetime.strptime(tarih_str, "%Y-%m-%d").date()
        bugun = datetime.now().date()
        return secilen < bugun
    except ValueError:
        return True  # Geçersiz tarih formatı → reddet


def gecmis_saat_mi(tarih_str: str, saat_str: str) -> bool:
    """
    Seçilen tarih bugünse ve seçilen saat şu anki saatten önceyse True döner.
    Gelecek bir tarih ise False döner.
    """
    try:
        secilen_tarih = datetime.strptime(tarih_str, "%Y-%m-%d").date()
        bugun = datetime.now().date()
        
        # Gelecek bir günse saat kontrolü gereksiz
        if secilen_tarih > bugun:
            return False
        
        # Geçmiş günse zaten gecmis_tarih_mi tarafından yakalanır
        if secilen_tarih < bugun:
            return True
        
        # Bugünse → saat kontrolü yap
        simdi = datetime.now()
        secilen_vakit = datetime.combine(secilen_tarih, datetime.strptime(saat_str, "%H:%M").time())
        return secilen_vakit <= simdi
    except ValueError:
        return True  # Geçersiz format → reddet


def saat_listesi_olustur(baslangic_saat: str, sure_dk: int):
    """ 
    Verilen başlangıç saatinden itibaren hizmet süresi boyunca 
    oluşacak tüm 30 DAKIKALIK slotları liste olarak döner.
    Ceiling division kullanır: 40dk → 2 slot (60dk bloke), 90dk → 3 slot.
    30 dakikalık birim istatistik sistemiyle tutarlıdır.
    Örnek: 3 saatlik hizmet → 6 slot (3*60/30=6) kapar.
    
    Önemli: Başlangıç saati DAHİLDİR. Yani "10:00" başlangıçlı 90dk hizmet:
    → ["10:00", "10:30", "11:00"] (3 slot) döner.
    """
    slotlar = []
    format_str = "%H:%M"
    try:
        mevcut_vakit = datetime.strptime(baslangic_saat, format_str)
        # Ceiling: 40dk → ceil(40/30)=2 slot, 30dk → 1 slot, 90dk → 3 slot
        adim_sayisi = math.ceil(sure_dk / 30)
        for _ in range(adim_sayisi):
            slotlar.append(mevcut_vakit.strftime(format_str))
            mevcut_vakit += timedelta(minutes=30)
    except Exception:
        pass
    return slotlar


def cakisma_var_mi(baslangic_saat: str, sure_dk: int, dolu_slotlar_listesi: list, is_sunday: bool):
    """ 
    Belirli bir saat ve sürenin mevcut doluluklarla ve mesaiyle 
    çakışıp çakışmadığını denetler. (30 dakikalık slot bazında)
    
    True = çakışma VAR (randevu alınamaz)
    False = çakışma YOK (randevu alınabilir)
    """
    talep_edilen = saat_listesi_olustur(baslangic_saat, sure_dk)
    
    # Eğer hiç slot oluşmadıysa (geçersiz saat vs.) → çakışma var say
    if not talep_edilen:
        return True
    
    # Kapanış dakika cinsinden
    kapanis_dk = (17 if is_sunday else 22) * 60
    acilis_dk = 10 * 60  # 10:00
    
    for s in talep_edilen:
        try:
            saat_parca, dakika_parca = map(int, s.split(":"))
            slot_dk = saat_parca * 60 + dakika_parca
            
            # 1. Mesai Dışı Kontrolü — açılış: 10:00
            if slot_dk < acilis_dk:
                return True
            # Bu slot'un sonu (slot_dk + 30) kapanışı geçiyorsa yasak
            if slot_dk + 30 > kapanis_dk:
                return True
                
            # 2. Doluluk Kontrolü
            if s in dolu_slotlar_listesi:
                return True
        except:
            return True
            
    return False


def musait_saatler_hesapla(tarih_str: str, berber_id: int, toplam_sure_dk: int, dolu_slotlar: list):
    """
    Verilen tarih, berber ve hizmet süresi için müsait olan saatleri döner.
    
    Kurallar:
    1. Geçmiş tarihlere izin verilmez
    2. Bugünse, geçmiş saatler döndürülmez
    3. Hizmetin tüm süresi mesai saatleri içinde olmalı
    4. Hizmetin hiçbir slotu dolu slotlarla çakışmamalı
    5. Hizmet için yeterli ardışık boş slot yoksa o saat gösterilmez
    
    Returns: 
        list of str — müsait saat listesi ["10:00", "10:30", ...]
    """
    secilen_tarih_obj = datetime.strptime(tarih_str, "%Y-%m-%d")
    is_sunday = secilen_tarih_obj.weekday() == 6
    
    kapanis = "17:00" if is_sunday else "22:00"
    kapanis_dk = int(kapanis.split(":")[0]) * 60
    
    # Gerekli slot sayısı
    gerekli_slot = math.ceil(toplam_sure_dk / 30)
    
    musait = []
    tara = datetime.strptime("10:00", "%H:%M")
    kapanis_vakit = datetime.strptime(kapanis, "%H:%M")
    
    while tara < kapanis_vakit:
        aday_saat = tara.strftime("%H:%M")
        
        # Bugünse geçmiş saati atla
        if gecmis_saat_mi(tarih_str, aday_saat):
            tara += timedelta(minutes=30)
            continue
        
        # Bu saatten başlayarak hizmet süresince tüm slotlar müsait mi kontrol et
        if not cakisma_var_mi(aday_saat, toplam_sure_dk, dolu_slotlar, is_sunday):
            musait.append(aday_saat)
        
        tara += timedelta(minutes=30)
    
    return musait


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


import models as _models
from database import SessionLocal
from datetime import datetime, timedelta, date as _date
from firebase_admin import messaging

# --- 5. APScheduler DEĞERLENDİRME GÖREVİ ---
def degerlendirme_gorevi():
    """
    Her 15 dakikada bir çalışır.
    Randevu saatinden 2 saat sonra müşteriye 'Bizi Puanla' bildirimi gönderir.
    """
    db = SessionLocal()
    try:
        bugun_str = _date.today().strftime("%Y-%m-%d")
        simdi = datetime.now()

        # Bugünkü, onaylanmış, bildirim gitmemiş ve puanlanmamış randevuları bul
        randevular = db.query(_models.Randevu).filter(
            _models.Randevu.tarih == bugun_str,
            _models.Randevu.durum == "onaylandi",
            _models.Randevu.degerlendirme_bildirimi_gonderildi == False,
            _models.Randevu.puan == None # Zaten puanladıysa tekrar sorma
        ).all()

        for r in randevular:
            try:
                # Randevu saatini datetime objesine çevir
                randevu_vakti = datetime.combine(
                    simdi.date(),
                    datetime.strptime(r.saat, "%H:%M").time()
                )

                # Randevu saatinden 2 saat geçtiyse tetiğe bas
                if simdi >= randevu_vakti + timedelta(hours=2):
                    if r.musteri and r.musteri.fcm_token:
                        berber_adi = f"{r.berber.ad} {r.berber.soyad}" if r.berber else "Berber"
                        
                        # FCM Mesajını Oluştur
                        message = messaging.Message(
                            data={
                                "type": "degerlendirme",
                                "randevu_id": str(r.id),
                                "berber_adi": berber_adi,
                                "baslik": "Randevunu Nasıl Buldun? ⭐",
                                "mesaj": f"{berber_adi}'i puanlamak ister misin?"
                            },
                            notification=messaging.Notification(
                                title="Sıhhatler Olsun! 💈",
                                body=f"{berber_adi} ile olan tıraşını puanlamak ister misin?"
                            ),
                            token=r.musteri.fcm_token,
                        )
                        
                        try:
                            messaging.send(message)
                            print(f"[Değerlendirme] Randevu {r.id} için bildirim gönderildi.")
                        except Exception as e:
                            print(f"[Değerlendirme] Bildirim hatası: {e}")

                    # Bildirim gitse de gitmese de (token yoksa) bu randevuyu işaretle ki döngüye girmesin
                    r.degerlendirme_bildirimi_gonderildi = True
            
            except Exception as e:
                print(f"[Değerlendirme] Randevu {r.id} döngü hatası: {e}")

        db.commit() # Tüm değişiklikleri DB'ye mühürle
    except Exception as e:
        print(f"[APScheduler] Genel görev hatası: {e}")
    finally:
        db.close()