from sqlalchemy import Column, Integer, String, Float, ForeignKey, Table, Boolean
from sqlalchemy.orm import relationship
from database import Base

# Köprü Tablo
randevu_hizmetleri = Table(
    "randevu_hizmetleri",
    Base.metadata,
    Column("randevu_id", Integer, ForeignKey("randevular.id"), primary_key=True),
    Column("hizmet_id", Integer, ForeignKey("hizmetler.id"), primary_key=True)
)

class Berber(Base):
    __tablename__ = "berberler"
    id = Column(Integer, primary_key=True, index=True)
    ad = Column(String); soyad = Column(String)
    uzmanlik = Column(String); foto_url = Column(String, nullable=True); puan = Column(Float, default=5.0)

class Musteri(Base):
    __tablename__ = "musteriler"
    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String, unique=True, index=True)
    ad = Column(String); soyad = Column(String); telefon = Column(String)
    fcm_token = Column(String, nullable=True)

class Hizmet(Base):
    __tablename__ = "hizmetler"
    id = Column(Integer, primary_key=True, index=True)
    ad = Column(String); fiyat = Column(Float); sure = Column(Integer); aciklama = Column(String, nullable=True)

class Dukkan(Base):
    __tablename__ = "dukkan_bilgileri"
    id = Column(Integer, primary_key=True, index=True)
    ad = Column(String); adres = Column(String); telefon = Column(String)
    email = Column(String, nullable=True)
    instagram = Column(String, nullable=True); harita_konum = Column(String)
    haftaici_kapanis = Column(String, default="22:00"); pazar_kapanis = Column(String, default="17:00")

class Randevu(Base):
    __tablename__ = "randevular"
    id = Column(Integer, primary_key=True, index=True)
    musteri_id = Column(Integer, ForeignKey("musteriler.id"))
    berber_id = Column(Integer, ForeignKey("berberler.id"))
    saat = Column(String); tarih = Column(String); durum = Column(String, default="onaylandi")
    toplam_fiyat = Column(Float)
    hatirlatma_gonderildi = Column(Boolean, default=False)          # 1 saat öncesi hatırlatma
    degerlendirme_bildirimi_gonderildi = Column(Boolean, default=False)  # Randevu+2saat sonrası puanlama bildirimi

    musteri = relationship("Musteri"); berber = relationship("Berber")
    hizmetler = relationship("Hizmet", secondary=randevu_hizmetleri)


# --- YENİ MODELLER ---

class Degerlendirme(Base):
    """Her tamamlanan randevu için bir kez puan verilebilir."""
    __tablename__ = "degerlendirmeler"
    id = Column(Integer, primary_key=True, index=True)
    musteri_id = Column(Integer, ForeignKey("musteriler.id"))
    berber_id = Column(Integer, ForeignKey("berberler.id"))
    randevu_id = Column(Integer, ForeignKey("randevular.id"), unique=True)  # Tekrar değerlendirme engeli
    puan = Column(Integer)  # 1-5 arası
    yorum = Column(String, nullable=True)
    tarih = Column(String)  # YYYY-MM-DD

    musteri = relationship("Musteri")
    berber = relationship("Berber")


class TatilGunu(Base):
    """Admin tarafından kapalı ilan edilen günler (bayram, tatil vs.)"""
    __tablename__ = "tatil_gunleri"
    id = Column(Integer, primary_key=True, index=True)
    tarih = Column(String, unique=True, index=True)  # YYYY-MM-DD, unique: aynı gün iki kez eklenemez
    aciklama = Column(String, nullable=True)  # "Kurban Bayramı" vs.


class BerberIzin(Base):
    """Her berberin kendi tatil/izin günleri."""
    __tablename__ = "berber_izinler"
    id = Column(Integer, primary_key=True, index=True)
    berber_id = Column(Integer, ForeignKey("berberler.id"))
    tarih = Column(String)  # YYYY-MM-DD
    aciklama = Column(String, nullable=True)  # "Hastalık izni" vs.

    berber = relationship("Berber")