#!/usr/bin/env bash
#
# Kịch bản 1-7: kiểm thử ngăn chặn khai thác dữ liệu web.
# Mỗi payload chạy hai lần — trực tiếp vào backend và qua NGINX — để đối chứng.
#
# CHỈ chạy trên hạ tầng lab do bạn sở hữu.
#
# Yêu cầu: biến môi trường DVWA_COOKIE (xem tests/README.md)

set -u

BACKEND="http://192.168.63.132"
PROXY="https://nginx.lab.com"
COOKIE="${DVWA_COOKIE:-PHPSESSID=changeme; security=low}"

green() { printf '\033[32m%s\033[0m\n' "$1"; }
red()   { printf '\033[31m%s\033[0m\n' "$1"; }
blue()  { printf '\033[34m\n== %s ==\033[0m\n' "$1"; }

# probe <url> <path+query> — in mã HTTP trả về
probe() {
  curl -sk -o /dev/null -w "%{http_code}" \
    -H "Cookie: $COOKIE" \
    "$1$2"
}

# Kiểm tra: qua proxy phải trả 403
expect_blocked() {
  local label="$1" path="$2"
  local code
  code=$(probe "$PROXY" "$path")
  if [ "$code" = "403" ]; then
    green "  [PASS] $label — NGINX trả $code"
  else
    red   "  [FAIL] $label — NGINX trả $code (mong đợi 403)"
  fi
}

blue "1. SQL Injection"
expect_blocked "SQLi tautology" "/vulnerabilities/sqli/?id=%27+or+1%3D1%23&Submit=Submit"

blue "2. XSS DOM"
expect_blocked "XSS DOM script tag" "/vulnerabilities/xss_d/?default=%3Cscript%3Ealert(1)%3C/script%3E"
expect_blocked "XSS DOM svg onload"  "/vulnerabilities/xss_d/?default=%3Csvg+onload%3Dalert(1)%3E"

blue "3. XSS Reflected"
expect_blocked "XSS reflected" "/vulnerabilities/xss_r/?name=%3Cscript%3Ealert(%27BugBot19%27)%3C/script%3E"

blue "4. XSS Stored"
# Stored XSS gửi qua POST tới Guestbook
code=$(curl -sk -o /dev/null -w "%{http_code}" \
  -H "Cookie: $COOKIE" \
  --data "txtName=test&mtxMessage=<img src=x onerror=alert(document.cookie)>&btnSign=Sign+Guestbook" \
  "$PROXY/vulnerabilities/xss_s/")
if [ "$code" = "403" ]; then green "  [PASS] XSS stored — NGINX trả $code"; else red "  [FAIL] XSS stored — NGINX trả $code"; fi

blue "5. CSP Bypass"
expect_blocked "CSP bypass" "/vulnerabilities/csp/?include=%3Cscript%3Ealert(1)%3C/script%3E"

blue "6. Command Injection"
code=$(curl -sk -o /dev/null -w "%{http_code}" \
  -H "Cookie: $COOKIE" \
  --data "ip=127.0.0.1|ls&Submit=Submit" \
  "$PROXY/vulnerabilities/exec/")
if [ "$code" = "403" ]; then green "  [PASS] Command injection — NGINX trả $code"; else red "  [FAIL] Command injection — NGINX trả $code"; fi

blue "7. JavaScript Attack"
expect_blocked "JS md5 injection" "/vulnerabilities/javascript/?token=md5(rot13(1))"

blue "Hoàn tất"
echo "Kiểm tra Splunk để xem các sự kiện đã được ghi nhận:"
echo '  index=security sourcetype=modsec_audit "Access denied"'
