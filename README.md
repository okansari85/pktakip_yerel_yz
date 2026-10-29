# PKTakip yerel yapay zeka

PKTakip'in internetsiz rapor okuması için üç servis, tek komutla:

| Servis | Port | Ne yapar |
|---|---|---|
| `model` | 8090 | NuExtract3 (küçük ajanların modeli) |
| `okuyucu` | 8091 | Qwen3.5-4B (sayfa sayfa bölüm haritası) |
| `docling` | 8092 | PDF → yapısı korunmuş metin + tablo konumları |

Uygulamanın kendisi (backend, önyüz) bu depoda değil.

## Gerekenler

- NVIDIA ekran kartı, en az 12 GB bellek (16 GB rahat), güncel sürücü. İki model birlikte ~8 GB tutar.
- Docker:
  - **Linux:** Docker Engine + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
  - **Windows:** Docker Desktop (WSL 2). Ekran kartı WSL'de kendiliğinden görünür.
- İlk kurulumda internet. Kurulumdan sonra internet gerekmez.
- Disk: ~25 GB (imajlar + modeller).

Kart görünüyor mu:

```
docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu24.04 nvidia-smi
```

## Kurulum

```
git clone https://github.com/okansari85/pktakip_yerel_yz.git
cd pktakip_yerel_yz
docker compose up -d
```

İlk açılış uzun sürer:
- llama.cpp kaynağından derlenir (~20-40 dk).
- Modeller iner (~5,5 GB, `models/` klasörüne).
- Docling imajı kurulur (~10 dk).

Sonraki açılışlar saniyeler sürer. Makine yeniden başlayınca servisler kendiliğinden açılır.

Hazır mı:

```
docker compose ps
curl http://127.0.0.1:8090/health
curl http://127.0.0.1:8091/health
curl http://127.0.0.1:8092/
```

Docling'in `curl` cevabı `{"error": ...}` olabilir; bu normal, servisin açık olduğunu gösterir.

## PKTakip'i bağlama

Backend `.env`:

```
PKTAKIP_LOCAL_MODEL=nuextract3
PKTAKIP_LOCAL_TIMEOUT=900
PKTAKIP_LOCAL_READER_URL=http://127.0.0.1:8091/v1
PKTAKIP_LOCAL_READER_MODEL=qwen3.5-4b
PKTAKIP_DOCLING_URL=http://127.0.0.1:8092/
```

Sonra PKTakip'te **Ayarlar → Yapay zeka** sayfasında:
- Sağlayıcı: **Yerel sunucu**
- Okuma yöntemi: **Çok ajanlı (Docling)**
- Sunucu adresi: `http://127.0.0.1:8090/v1`

Geri dönmek için aynı sayfada eski sağlayıcıyı seçmek yeter.

**Uygulama başka makinede ya da Docker içindeyse:**
- Bu klasörde `.env` dosyası açıp `BIND=0.0.0.0` yazın, sonra `docker compose up -d`.
- Adreslerde `127.0.0.1` yerine bu makinenin adresini yazın.
- Uygulama aynı makinede Docker içindeyse, uygulamanın servisine `extra_hosts: ["host.docker.internal:host-gateway"]` ekleyip adres olarak `host.docker.internal` kullanın.
- Portları (8090-8092) yalnız uygulamanın makinesine açın. Servislerde parola yok.

## Günlük işler

```
docker compose logs -f model     # model günlüğü
docker compose restart           # yeniden başlat
docker compose down              # durdur (modeller silinmez)
git pull && docker compose up -d --build   # güncelle
```

## Sürümler

- Değerler 29 Ekim 2026 testleriyle aynı: llama.cpp b11840, Docling 2.142.1, NuExtract3 ve Qwen3.5-4B (Q4_K_M), aynı bağlam boyutları ve başlatma ayarları.
- `docling/pk_docling.py`, backend deposundaki `scripts/pk_docling.py` dosyasının kopyasıdır. Orada değişirse buraya kopyalanır.
