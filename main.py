from apscheduler.schedulers.background import BackgroundScheduler
from utils import degerlendirme_gorevi
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from apscheduler.schedulers.background import BackgroundScheduler
import models, utils
from database import engine
from routers import dukkan, randevular, berberler, musteriler, hizmetler, kurumsal
from routers import degerlendirmeler, tatil, raporlar

models.Base.metadata.create_all(bind=engine)
app = FastAPI(title="Premium Berber")

# Zamanlayıcıyı kuruyoruz
scheduler = BackgroundScheduler()
# degerlendirme_gorevi fonksiyonunu her 15 dakikada bir çalışacak şekilde ayarla
scheduler.add_job(degerlendirme_gorevi, 'interval', minutes=15)
scheduler.start()


# --- 6. CORS MIDDLEWARE ---
# Flutter Web veya harici istemciler için gerekli.
# Prodüksiyonda allow_origins'i kendi domain'inle değiştir.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Prodüksiyonda: ["https://senin-domain.com"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- STATİK DOSYA SUNUMU (Fotoğraf upload için) ---
import os
os.makedirs("uploads/berberler", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# --- 3. APScheduler — HATIRLATMA + DEĞERLENDİRME BİLDİRİMLERİ ---
scheduler = BackgroundScheduler()
scheduler.add_job(
    utils.hatirlatma_gorevi,
    trigger="interval",
    minutes=15,
    id="hatirlatma_gorevi"
)
scheduler.add_job(
    utils.degerlendirme_gorevi,
    trigger="interval",
    minutes=15,
    id="degerlendirme_gorevi"
)

@app.on_event("startup")
def uygulama_baslangic():
    scheduler.start()
    print("[APScheduler] Hatırlatma zamanlayıcısı başlatıldı.")

@app.on_event("shutdown")
def uygulama_kapanis():
    scheduler.shutdown()
    print("[APScheduler] Zamanlayıcı durduruldu.")

# --- ROUTER'LAR ---
app.include_router(dukkan.router)
app.include_router(randevular.router)
app.include_router(berberler.router)
app.include_router(musteriler.router)
app.include_router(hizmetler.router)
app.include_router(kurumsal.router)
app.include_router(degerlendirmeler.router)  # ✅ Yeni: Değerlendirme & Puan
app.include_router(tatil.router)             # ✅ Yeni: Tatil Günleri
app.include_router(raporlar.router)          # ✅ Yeni: Admin Raporlar

@app.get("/")
def home():
    return {"durum": "Sistem tıkır tıkır çalışıyor kanki!"}