# DWG Viewer Backend

DWG → DXF convert servisi. FastAPI + LibreDWG (`dwg2dxf`, ayrı process).

## Endpoint

- `GET /health` → `{"status":"ok"}`
- `POST /convert` (multipart `file=*.dwg`) → DXF metni (`text/plain`)

## Lokal çalıştırma (dev)

LibreDWG `dwg2dxf` PATH'te olmalı. Yoksa convert `422` döner.

```bash
cd backend
python -m venv .venv && . .venv/Scripts/activate   # Windows
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Test:
```bash
curl -F "file=@cizim.dwg" http://localhost:8000/convert -o out.dxf
```

## Docker (LibreDWG dahil, deploy için)

```bash
docker build -t dwg-convert .
docker run -p 8000:8000 dwg-convert
```

İmaj LibreDWG'yi kaynaktan statik derler → `dwg2dxf` hazır gelir, ayrıca kurulum gerekmez.

## Oracle Cloud Always-Free VM deploy

1. VM'e Docker kur (`sudo apt install docker.io`).
2. Repoyu çek, `docker build -t dwg-convert backend/`.
3. `docker run -d --restart=always -p 8000:8000 dwg-convert`.
4. VM güvenlik listesi + iptables'ta 8000 (veya reverse proxy ile 443) aç.
5. App'te `EXPO_PUBLIC_CONVERT_URL` = `http://<VM_IP>:8000`.

> Üretimde HTTPS şart (mobil store + gizlilik). Caddy/Nginx reverse proxy + Let's Encrypt önerilir.

## Gizlilik

Yüklenen DWG ve üretilen DXF geçici klasörde tutulur, istek biter bitmez silinir.
Disk veya log'da kullanıcı dosyası kalmaz. Bkz. `LICENSE-NOTICE.md` (GPL uyumu).
