from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker

# ARTIK YERELDEYİZ KANKİ!
# format: postgresql://kullanıcı:şifre@localhost:port/veritabanı_adı
SQLALCHEMY_DATABASE_URL = "sqlite:///./berber_yeni.db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()