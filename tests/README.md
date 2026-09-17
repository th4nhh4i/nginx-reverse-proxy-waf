# Kịch bản kiểm thử

Tái lập tám kịch bản tấn công của Chương 3. Thực hiện từ máy Kali Linux
`192.168.224.128`.

> **Chỉ chạy trên hạ tầng lab do bạn sở hữu.** Dùng các script này với hệ thống không
> thuộc quyền sở hữu của bạn là hành vi vi phạm pháp luật.

## Nguyên tắc đối chứng

Mỗi kịch bản khai thác dữ liệu được chạy ở **hai điều kiện** để tách biệt hiệu quả của WAF:

1. **Trực tiếp vào backend** (`http://192.168.63.132`) với DVWA ở mức **Low** → tấn công
   phải **thành công**, xác nhận payload hợp lệ.
2. **Qua NGINX** (`https://nginx.lab.com`) → phải bị chặn **`403 Forbidden`**.

Nếu bước 1 không thành công, payload sai — sửa nó trước, đừng vội kết luận WAF đã chặn.

## Chuẩn bị

```bash
# Trên Kali, đảm bảo phân giải được tên miền
echo "192.168.224.222  nginx.lab.com" | sudo tee -a /etc/hosts

# Lấy session cookie hợp lệ của DVWA để các script tấn công dùng
# (đăng nhập admin/password qua trình duyệt, copy cookie PHPSESSID)
export DVWA_COOKIE="PHPSESSID=xxxx; security=low"
```

## Chạy từng kịch bản

| # | Script | Kịch bản |
|---|---|---|
| 1–7 | [`web-attacks.sh`](web-attacks.sh) | SQLi, XSS (×3), CSP, Command Injection, JS |
| 8 | [`ddos-slowloris.sh`](ddos-slowloris.sh) | DDoS tầng 7 có đối chứng |

```bash
chmod +x web-attacks.sh ddos-slowloris.sh
./web-attacks.sh
./ddos-slowloris.sh
```

## Kết quả mong đợi

| # | Kịch bản | Payload | Trực tiếp (Low) | Qua NGINX |
|---|---|---|---|---|
| 1 | SQL Injection | `' or 1=1#` | Lộ dữ liệu users | `403` |
| 2 | XSS DOM | `<svg onload=alert(1)>` | Script chạy | `403` |
| 3 | XSS Reflected | `<script>alert(...)</script>` | Script chạy | `403` |
| 4 | XSS Stored | `<img src=x onerror=...>` | Lưu vào DB | `403` |
| 5 | CSP Bypass | `<script>alert(1)</script>` | Tùy CSP | `403` |
| 6 | Command Injection | `127.0.0.1 \| ls` | Liệt kê thư mục | `403` |
| 7 | JavaScript Attack | `md5()` injection | Thao túng logic | `403` |
| 8 | DDoS | 150 sockets | Backend timeout | Dịch vụ duy trì |

## Xác minh trên Splunk

Sau khi chạy, kiểm tra hệ thống giám sát đã ghi nhận:

```spl
index=security sourcetype=modsec_audit "Access denied" src_ip="192.168.224.128"
| rex field=_raw "Total Score: (?<score>\d+)"
| table _time, uri, score, rule_id
| sort - _time
```

Kết quả sẽ hiển thị các sự kiện chặn kèm điểm anomaly — đối chiếu với
[Hình 3.44](../docs/images/hinh-3-44.png).
