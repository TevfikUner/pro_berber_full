from sqlalchemy import Column, Integer, String, Float, ForeignKey, Table, Boolean, Text
from sqlalchemy.orm import relationship
from database import Base

# Köprü Tablolar
randevu_hizmetleri = Table(
    "randevu_hizmetleri",
    Base.metadata,
    Column("randevu_id", Integer, ForeignKey("randevular.id"), primary_key=True),
    Column("hizmet_id", Integer, ForeignKey("hizmetler.id"), primary_key=True)
)

favori_berberler = Table(
    "favori_berberler",
    Base.metadata,
    Column("musteri_id", Integer, ForeignKey("musteriler.id"), primary_key=True),
    Column("berber_id", Integer, ForeignKey("berberler.id"), primary_key=True)
)

class Salon(Base):
    __tablename__ = "salonlar"

    id = Column(Integer, primary_key=True, index=True)
    ad = Column(String)
    adres = Column(String)
    telefon = Column(String)
    foto_url = Column(String, nullable=True) 
    instagram_url = Column(String, nullable=True)
    whatsapp = Column(String, nullable=True)
    konum_lat = Column(Float, nullable=True) 
    konum_long = Column(Float, nullable=True)
    sehir = Column(String, nullable=True)
    ilce = Column(String, nullable=True)
    acilis_saati = Column(String, default="09:00")
    kapanis_saati = Column(String, default="20:00")
    puan = Column(Float, default=5.0)

    # İlişkiler
    berberler = relationship("Berber", back_populates="salon")
    randevular = relationship("Randevu", back_populates="salon")
    fotograflar = relationship("SalonFotograf", back_populates="salon")

class Berber(Base):
    __tablename__ = "berberler"
    id = Column(Integer, primary_key=True, index=True)
    ad = Column(String)
    soyad = Column(String)
    uzmanlik = Column(String)
    foto_url = Column(String, nullable=True)
    puan = Column(Float, default=5.0)

    salon_id = Column(Integer, ForeignKey("salonlar.id"))
    salon = relationship("Salon", back_populates="berberler")

    whatsapp_no = Column(String, nullable=True)
    instagram_username = Column(String, nullable=True)

class Musteri(Base):
    __tablename__ = "musteriler"
    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String, unique=True, index=True)
    ad = Column(String)
    soyad = Column(String)
    telefon = Column(String)
    fcm_token = Column(String, nullable=True)
    favori_berber_id = Column(Integer, ForeignKey("berberler.id"), nullable=True)

    favori_berberler = relationship("Berber", secondary=favori_berberler)

class Hizmet(Base):
    __tablename__ = "hizmetler"
    id = Column(Integer, primary_key=True, index=True)
    ad = Column(String)
    fiyat = Column(Float)
    sure = Column(Integer)
    aciklama = Column(String, nullable=True)

class Dukkan(Base):
    __tablename__ = "dukkan_bilgileri"
    id = Column(Integer, primary_key=True, index=True)
    ad = Column(String)
    adres = Column(String)
    telefon = Column(String)
    email = Column(String, nullable=True)
    instagram = Column(String, nullable=True)
    harita_konum = Column(String)
    haftaici_kapanis = Column(String, default="22:00")
    pazar_kapanis = Column(String, default="17:00")

class Randevu(Base):
    __tablename__ = "randevular"
    id = Column(Integer, primary_key=True, index=True)
    musteri_id = Column(Integer, ForeignKey("musteriler.id"))
    berber_id = Column(Integer, ForeignKey("berberler.id"))
    salon_id = Column(Integer, ForeignKey("salonlar.id")) # Salon bağlantısı
    saat = Column(String)
    tarih = Column(String)
    durum = Column(String, default="onaylandi")
    toplam_fiyat = Column(Float)
    hatirlatma_gonderildi = Column(Boolean, default=False)
    degerlendirme_bildirimi_gonderildi = Column(Boolean, default=False)
    puan = Column(Integer, nullable=True) 
    yorum = Column(Text, nullable=True)
    
    musteri = relationship("Musteri")
    berber = relationship("Berber")
    salon = relationship("Salon", back_populates="randevular")
    hizmetler = relationship("Hizmet", secondary=randevu_hizmetleri)

class Degerlendirme(Base):
    __tablename__ = "degerlendirmeler"
    id = Column(Integer, primary_key=True, index=True)
    musteri_id = Column(Integer, ForeignKey("musteriler.id"))
    berber_id = Column(Integer, ForeignKey("berberler.id"))
    randevu_id = Column(Integer, ForeignKey("randevular.id"), unique=True)
    puan = Column(Integer)
    yorum = Column(String, nullable=True)
    tarih = Column(String)

    musteri = relationship("Musteri")
    berber = relationship("Berber")

class TatilGunu(Base):
    __tablename__ = "tatil_gunleri"
    id = Column(Integer, primary_key=True, index=True)
    tarih = Column(String, unique=True, index=True)
    aciklama = Column(String, nullable=True)

class BerberIzin(Base):
    __tablename__ = "berber_izinler"
    id = Column(Integer, primary_key=True, index=True)
    berber_id = Column(Integer, ForeignKey("berberler.id"))
    tarih = Column(String)
    aciklama = Column(String, nullable=True)

    berber = relationship("Berber")


class Isletme(Base):
    """İşletme sahibi kayıt tablosu. Kayıt sonrası onay bekler."""
    __tablename__ = "isletmeler"
    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String, unique=True, index=True)
    ad = Column(String)
    soyad = Column(String)
    telefon = Column(String)
    email = Column(String)
    isletme_adi = Column(String)
    durum = Column(String, default="beklemede")  # beklemede / onaylandi / reddedildi


class SalonFotograf(Base):
    """Salon galeri fotoğrafları tablosu."""
    __tablename__ = "salon_fotograflari"
    id = Column(Integer, primary_key=True, index=True)
    salon_id = Column(Integer, ForeignKey("salonlar.id"))
    foto_url = Column(String)
    sira = Column(Integer, default=0)

    salon = relationship("Salon", back_populates="fotograflar")