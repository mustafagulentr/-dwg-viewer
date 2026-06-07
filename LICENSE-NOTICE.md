# LibreDWG GPL Uyum Bildirimi

Bu backend, DWG dosyalarını DXF'e çevirmek için **LibreDWG** projesini kullanır.

- **LibreDWG lisansı:** GNU General Public License v3.0 or later (GPL-3.0-or-later)
- **Kaynak kod:** https://github.com/LibreDWG/libredwg
- **Sürüm:** Dockerfile içindeki `LIBREDWG_VERSION` (varsayılan 0.13.3)

## Neden bu mimari?

LibreDWG GPL'dir. GPL, bir programa **statik/dinamik link** edilen kodu da GPL
kapsamına sokar. Bunu önlemek için LibreDWG bu projede **ayrı bir process** olarak
(`dwg2dxf` komut satırı binary'si, `subprocess` ile) çağrılır.

Ayrı process üzerinden çağrı, GPL'in "derived work" tanımına girmez (FSF'in kabul
ettiği sınır: bağımsız programların `exec`/`pipe` ile haberleşmesi). Bu nedenle:

- **Backend servis kodu** (`main.py`, `converter.py`) GPL DEĞİLDİR.
- **Mobil uygulama** LibreDWG'yi içermez, sadece bu backend'e HTTP isteği atar.
- Mobil uygulama **kapalı kaynak / ticari** olarak dağıtılabilir.

## Yükümlülük

LibreDWG binary'sini dağıtan taraf (bu backend imajını çalıştıran), talep halinde
LibreDWG'nin kaynak koduna erişim sağlamak zorundadır. Yukarıdaki resmi kaynak
linki bu yükümlülüğü karşılar; ayrıca kullanılan sürümün tarball'u Dockerfile'da
sabittir.
