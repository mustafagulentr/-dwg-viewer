# --- Aşama 1: LibreDWG'yi kaynaktan derle (statik dwg2dxf binary) ---
# LibreDWG GPL. AYRI binary olarak derlenir, uygulamaya linklenmez (GPL bulaşmaz).
FROM debian:bookworm-slim AS libredwg

ARG LIBREDWG_VERSION=0.13.3

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl xz-utils \
        libtool pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
# Release tarball'unda configure hazır gelir (autogen gerekmez)
RUN curl -fsSL "https://github.com/LibreDWG/libredwg/releases/download/${LIBREDWG_VERSION}/libredwg-${LIBREDWG_VERSION}.tar.xz" \
        -o libredwg.tar.xz \
    && tar xf libredwg.tar.xz \
    && cd "libredwg-${LIBREDWG_VERSION}" \
    && ./configure --disable-shared --enable-static --disable-bindings --disable-werror \
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
