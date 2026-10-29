@echo off
rem PKTakip yerel yapay zeka kurulumu (Windows, Docker Desktop). Tekrar calistirmak guvenli: guncelleme de budur.
setlocal EnableDelayedExpansion
title PKTakip yerel yapay zeka kurulumu
cd /d "%~dp0"

echo [1/5] Docker kontrol ediliyor...
docker info >nul 2>&1
if errorlevel 1 (
    echo   Docker calismiyor. Docker Desktop'u kurun ^(https://www.docker.com/products/docker-desktop/^), acin ve bu dosyayi yeniden calistirin.
    goto son
)

echo [2/5] Ekran karti kontrol ediliyor...
docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu24.04 nvidia-smi -L
if errorlevel 1 (
    echo   Docker NVIDIA ekran kartini goremiyor. NVIDIA surucusunu guncelleyin, Docker Desktop'ta WSL 2 acik olsun.
    goto son
)

echo [3/5] Guncel surum aliniyor...
if exist .git (
    git pull --ff-only
) else (
    echo   git klasoru yok, mevcut dosyalarla devam ediliyor.
)

echo [4/5] Servisler kuruluyor. Ilk kurulum 30-60 dakika surer ^(llama.cpp derlenir, modeller iner^)...
docker compose up -d --build
if errorlevel 1 (
    echo   Kurulum hata verdi. Yukaridaki mesaja bakin.
    goto son
)

echo   Modeller yukleniyor...
set /a deneme=0
:bekle
set hazir=1
for %%p in (8090 8091) do (
    curl -sf http://127.0.0.1:%%p/health >nul 2>&1 || set hazir=0
)
rem Docling bos istege hata dondurur; cevap gelmesi acik oldugunu gosterir.
curl -s http://127.0.0.1:8092/ >nul 2>&1 || set hazir=0
if !hazir!==0 (
    set /a deneme+=1
    if !deneme! geq 90 (
        echo   15 dakikada acilmadi. Gunluk: docker compose logs model okuyucu docling
        goto son
    )
    timeout /t 10 /nobreak >nul
    goto bekle
)
echo   Servisler hazir: model 8090, okuyucu 8091, docling 8092.

echo [5/5] PKTakip baglantisi
if exist pktakip-backend.txt set /p backend=<pktakip-backend.txt
if not defined backend (
    echo   PKTakip backend klasorunu yazin ^(.env dosyasinin oldugu klasor, ornek C:\laragon\www\pktakip^).
    set /p backend=  Bos birakirsaniz .env'e yazilmaz:
)
if defined backend (
    if exist "!backend!\.env" (
        powershell -NoProfile -ExecutionPolicy Bypass -File env-yaz.ps1 "!backend!\.env"
        >pktakip-backend.txt echo !backend!
        echo   Kuyruk calisiyorsa yeniden baslatin ^(php artisan queue:restart^).
    ) else (
        echo   "!backend!\.env" bulunamadi, .env'e yazilmadi.
    )
)
rem Adres: varsayilan yalniz bu makine; .env'de BIND=0.0.0.0 ise agdaki adres (uygulama baska makinedeyse).
set host=127.0.0.1
if exist .env for /f "usebackq tokens=1,* delims==" %%a in (".env") do if /i "%%a"=="BIND" set host=%%b
if "!host!"=="0.0.0.0" for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^(127|169\.254)\.' -and $_.InterfaceAlias -notmatch 'vEthernet|WSL|Loopback' } | Select-Object -First 1).IPAddress"`) do set host=%%i
echo.
echo   ================= SUNUCU ADRESLERI =================
echo   Model    http://!host!:8090/v1   ^(Yapay zeka sayfasi: Sunucu adresi^)
echo   Okuyucu  http://!host!:8091/v1   ^(.env PKTAKIP_LOCAL_READER_URL^)
echo   Docling  http://!host!:8092/     ^(.env PKTAKIP_DOCLING_URL^)
echo   ====================================================
echo.
echo   PKTakip ^> Yapay zeka sayfasi: Saglayici "Yerel sunucu", Okuma yontemi "Cok ajanli (Docling)", Sunucu adresi yukaridaki Model.

:son
echo.
pause
