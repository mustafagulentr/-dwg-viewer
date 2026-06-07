"""FastAPI DWG -> DXF convert servisi.

Telefon DWG'yi yükler, backend LibreDWG ile DXF'e çevirip döner.
Dosya gizliliği: yüklenen DWG ve üretilen DXF geçici klasörde tutulur ve
istek biter bitmez silinir; disk/log'da kalmaz.
"""
from __future__ import annotations

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse

from converter import ConvertError, dwg_to_dxf

# Yükleme boyut limiti (byte) — 50 MB. Büyük dosya = bellek/CPU koruması
MAX_UPLOAD = 50 * 1024 * 1024

app = FastAPI(title="DWG Viewer Convert", version="1.0")

# Mobil uygulamadan çağrı; origin sabit değil → tümüne izin (sadece convert endpoint)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/convert", response_class=PlainTextResponse)
async def convert(file: UploadFile = File(...)) -> str:
    """DWG yükle, DXF metni dön (text/plain)."""
    name = (file.filename or "").lower()
    if not name.endswith(".dwg"):
        raise HTTPException(400, "Sadece .dwg kabul edilir")

    data = await file.read()
    if len(data) > MAX_UPLOAD:
        raise HTTPException(413, f"Dosya çok büyük (max {MAX_UPLOAD // (1024*1024)} MB)")

    try:
        return dwg_to_dxf(data)
    except ConvertError as e:
        raise HTTPException(422, str(e)) from e
