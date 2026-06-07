#!/usr/bin/env bash
# Oracle Cloud Always-Free VM'de DWG convert backend'i kur + çalıştır.
# VM'e SSH ile bağlanıp backend/ klasörü içinde çalıştır: bash deploy-oracle.sh
set -euo pipefail

PORT="${PORT:-8000}"
IMAGE="dwg-convert"
CONTAINER="dwg-convert"

echo "==> Docker kurulu mu?"
if ! command -v docker >/dev/null 2>&1; then
  echo "==> Docker kuruluyor..."
  sudo apt-get update
  sudo apt-get install -y docker.io
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER" || true
fi

echo "==> İmaj derleniyor (LibreDWG kaynaktan, birkaç dakika sürebilir)..."
sudo docker build -t "$IMAGE" .

echo "==> Eski container varsa durdur/sil..."
sudo docker rm -f "$CONTAINER" 2>/dev/null || true

echo "==> Container başlatılıyor (port $PORT)..."
sudo docker run -d --name "$CONTAINER" --restart=always -p "$PORT:8000" "$IMAGE"

echo "==> Firewall (iptables) $PORT açılıyor..."
# Oracle Ubuntu imajları INPUT'u varsayılan DROP'lar → kuralı ekle
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport "$PORT" -j ACCEPT || true
# Kalıcı yap (netfilter-persistent varsa)
if command -v netfilter-persistent >/dev/null 2>&1; then
  sudo netfilter-persistent save || true
fi

echo "==> Sağlık kontrolü..."
sleep 3
curl -fsS "http://localhost:$PORT/health" && echo

cat <<EOF

✅ Backend ayakta: http://localhost:$PORT
ÖNEMLİ: Oracle Console > VCN > Security List'te $PORT/TCP Ingress kuralını
        (Source 0.0.0.0/0) AÇMAYI unutma; yoksa dışarıdan erişilmez.

Dışarıdan test (kendi makinenden):
  curl http://<VM_PUBLIC_IP>:$PORT/health
EOF
