# Docling servisi (PKTAKIP_DOCLING_URL): sürümler laptoptaki test ortamıyla aynı (pk-docling, Python 3.13, CPU torch).
FROM python:3.13-slim

RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cpu \
        torch==2.14.1+cpu torchvision==0.29.1+cpu docling==2.142.1

# Docling modelleri imaja: kurulumdan sonra internet gerekmez.
ENV DOCLING_ARTIFACTS_PATH=/opt/docling-models
RUN docling-tools models download -o /opt/docling-models

# Betik backend deposundan (main): kopya tutulmaz; backend'de değişince `kur.bat` imajı yeniden derler.
ADD https://raw.githubusercontent.com/okansari85/taseron_managment/main/scripts/pk_docling.py /app/pk_docling.py
EXPOSE 8092
CMD ["python", "/app/pk_docling.py", "--serve", "8092", "0.0.0.0"]
