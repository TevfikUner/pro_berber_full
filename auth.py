import os
from fastapi import Header, HTTPException

# Admin şifresini environment variable'dan okur.
# Sunucuyu başlatmadan önce terminalde şunu çalıştır:
#   Windows: $env:ADMIN_SECRET = "guvenli_bir_sifre_yaz"
#   Linux:   export ADMIN_SECRET="guvenli_bir_sifre_yaz"
# Eğer set etmezsen varsayılan olarak aşağıdaki şifre kullanılır.
ADMIN_SECRET = os.getenv("ADMIN_SECRET", "tevfik1687")

def admin_dogrula(x_admin_secret: str = Header(...)):
    """
    Admin endpoint'lerini koruyan dependency.
    İsteklerde 'X-Admin-Secret' header'ı gönderilmesi zorunludur.
    """
    if x_admin_secret != ADMIN_SECRET:
        raise HTTPException(
            status_code=403, 
            detail="Yetkisiz erişim! Admin şifresi hatalı."
        )
