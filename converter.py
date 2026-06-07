"""DWG -> DXF dönüşümü: LibreDWG `dwg2dxf` binary'sini AYRI process olarak çağırır.

GPL uyumu kritik: LibreDWG buraya statik linklenmez, sadece subprocess olarak
çalıştırılır. Bu sayede GPL lisansı uygulamaya bulaşmaz (bkz. LICENSE-NOTICE.md).
"""
from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

# dwg2dxf binary adı (PATH'te olmalı; Docker imajında libredwg ile gelir)
DWG2DXF = shutil.which("dwg2dxf") or "dwg2dxf"

# Dönüşüm zaman aşımı (saniye) — kötü/dev dosyada takılmayı önler
TIMEOUT_S = 60


class ConvertError(Exception):
    """Dönüşüm başarısız (binary yok, bozuk DWG, timeout vs.)."""


def dwg_to_dxf(dwg_bytes: bytes) -> str:
    """DWG byte'larını DXF metnine çevir. Geçici dosyalar iş bitince silinir.

    Raises ConvertError dönüşüm başarısızsa.
    """
    if not dwg_bytes:
        raise ConvertError("Boş dosya")

    # Geçici izole klasör — istek bitince tamamen silinir (gizlilik: dosya tutulmaz)
    with tempfile.TemporaryDirectory(prefix="dwg2dxf_") as tmp:
        tmpdir = Path(tmp)
        in_path = tmpdir / "input.dwg"
        out_path = tmpdir / "output.dxf"
        in_path.write_bytes(dwg_bytes)

        try:
            proc = subprocess.run(
                [DWG2DXF, "-y", "-o", str(out_path), str(in_path)],
                capture_output=True,
                timeout=TIMEOUT_S,
            )
        except FileNotFoundError as e:
            raise ConvertError(
                f"dwg2dxf binary bulunamadı ({DWG2DXF}). LibreDWG kurulu mu?"
            ) from e
        except subprocess.TimeoutExpired as e:
            raise ConvertError("Dönüşüm zaman aşımına uğradı") from e

        stderr = proc.stderr.decode("utf-8", "replace").strip()

        if not out_path.exists() or out_path.stat().st_size == 0:
            # LibreDWG bazen kısmi başarıda 0 döner ama dosya yazmaz
            raise ConvertError(
                f"DXF üretilemedi (kod {proc.returncode}). {stderr[:500]}"
            )

        # LibreDWG ASCII DXF üretir; dxf-parser bunu okur
        return out_path.read_text(encoding="utf-8", errors="replace")
