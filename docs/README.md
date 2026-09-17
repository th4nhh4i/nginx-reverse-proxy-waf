# Báo cáo nghiên cứu

Toàn văn báo cáo, chia theo chương để đọc trực tiếp trên GitHub.

## Mục lục

- [Chương 1 — Tổng quan về đề tài](01-tong-quan.md)
  - Bối cảnh an ninh mạng 2025, mục tiêu, phương pháp, phạm vi
- [Chương 2 — Cơ sở lý thuyết](02-co-so-ly-thuyet.md)
  - Defense in Depth, bốn tầng bảo mật, phân tích vector DDoS và khai thác dữ liệu
- [Chương 3 — Mô hình thực nghiệm](03-mo-hinh-thuc-nghiem.md)
  - Triển khai hạ tầng, cấu hình chi tiết, tám kịch bản kiểm thử có đối chứng
- [Chương 4 — Kết luận và hướng phát triển](04-ket-luan.md)
  - Đánh giá kết quả, hạn chế, lộ trình AI/HA/Threat Intelligence
- [Danh mục tài liệu tham khảo](tai-lieu-tham-khao.md)

## Hướng dẫn triển khai

Thư mục [`setup/`](setup/) chứa hướng dẫn cài đặt từng bước, tái lập được toàn bộ mô hình:

| Bước | Tài liệu |
|---|---|
| 0 | [Chuẩn bị lab](setup/00-chuan-bi.md) |
| 1 | [pfSense](setup/01-pfsense.md) |
| 2 | [NGINX Reverse Proxy](setup/02-nginx-reverse-proxy.md) |
| 3 | [ModSecurity WAF](setup/03-modsecurity-waf.md) |
| 4 | [Fail2Ban](setup/04-fail2ban.md) |
| 5 | [Backend DVWA](setup/05-backend-dvwa.md) |
| 6 | [Splunk SIEM/SOAR](setup/06-splunk-siem-soar.md) |

## Hình ảnh

Thư mục [`images/`](images/) chứa 45 ảnh chụp thực nghiệm:

- `logo-gdu.png` — logo Trường Đại học Gia Định
- `hinh-3-01.png` đến `hinh-3-44.png` — tương ứng Hình 3.1 đến 3.44 trong báo cáo
