# --- Aşama 1: LibreDWG'yi kaynaktan derle (statik dwg2dxf binary) ---
# LibreDWG GPL. AYRI binary olarak derlenir, uygulamaya linklenmez (GPL bulaşmaz).
FROM debian:bookworm-slim AS libredwg

# git master derlenir — modern DWG (2013/2018/2020+) için release'ten çok daha iyi
ARG LIBREDWG_REF=master

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates git \
        autoconf automake libtool pkg-config texinfo python3 perl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
# git master'da configure yok → autogen.sh ile üret
RUN git clone --depth 1 --branch "${LIBREDWG_REF}" https://github.com/LibreDWG/libredwg.git \
    && cd libredwg \
    && sh ./autogen.sh \
    && ./configure --disable-shared --enable-static --disable-bindings --disable-werror PYTHON=python3 \
    && make -j"$(nproc)" \
    && cp programs/dwg2dxf /usr/local/bin/dwg2dxf \
    && strip /usr/local/bin/dwg2dxf

# --- Aşama 2: Python runtime ---
FROM python:3.12-slim-bookworm

# Statik derlenmiş dwg2dxf binary'sini kopyala (LibreDWG ayrı process)
COPY --from=libredwg /usr/local/bin/dwg2dxf /usr/local/bin/dwg2dxf

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py converter.py LICENSE-NOTICE.md ./

# Root olmayan kullanıcı (güvenlik)
RUN useradd -m appuser
USER appuser

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
