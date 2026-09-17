# 00 — Chuẩn bị môi trường lab

## Yêu cầu phần cứng

Toàn bộ mô hình chạy trên một máy vật lý qua VMware Workstation (hoặc ESXi).

| Tài nguyên | Tối thiểu | Khuyến nghị |
|---|---|---|
| RAM | 16 GB | 32 GB |
| Ổ đĩa | 200 GB | 300 GB SSD |
| CPU | 4 nhân | 8 nhân |

Splunk SOAR một mình đã chiếm 8 GB RAM và khoảng 100 GB đĩa. Nếu máy chỉ có 16 GB, hãy
tắt SOAR khi chạy các kịch bản kiểm thử không cần phản ứng tự động.

## Danh sách máy ảo

| Máy | Hệ điều hành | RAM | Đĩa | Card mạng |
|---|---|---|---|---|
| pfSense | pfSense 2.7.2 (FreeBSD) | 2 GB | 20 GB | 4 (WAN, LAN, OPT1, OPT2) |
| nginx-proxy | Ubuntu Server 22.04 LTS | 2 GB | 25 GB | 1 (DMZ) |
| backend-1 | Windows Server 2016 | 4 GB | 40 GB | 1 (LAN) |
| backend-2 | Windows Server 2016 | 4 GB | 40 GB | 1 (LAN) |
| splunk-server | Oracle Linux 9 | 8 GB | 100 GB | 1 (MGMT) |
| kali | Kali Linux | 2 GB | 25 GB | 1 (WAN) |

> Backend 2 có thể clone từ Backend 1 sau khi cài xong XAMPP + DVWA. Nhớ đổi hostname và
> IP, nếu không cả hai sẽ tranh chấp địa chỉ.

## Sơ đồ mạng ảo VMware

Tạo bốn mạng tùy chỉnh trong **Virtual Network Editor**:

| VMnet | Chế độ | Dải mạng | Vai trò |
|---|---|---|---|
| VMnet8 | NAT | DHCP | WAN — mô phỏng Internet |
| VMnet2 | Host-only | `192.168.170.0/24` | LAN — backend |
| VMnet3 | Host-only | `192.168.224.0/24` | DMZ — NGINX |
| VMnet4 | Host-only | `192.168.121.0/24` | MGMT — Splunk |

**Tắt DHCP** trên VMnet2, VMnet3 và VMnet4. pfSense sẽ đảm nhận việc này; nếu để DHCP của
VMware chạy song song, hai máy chủ DHCP sẽ tranh nhau cấp phát và gây xung đột địa chỉ.

## Bảng địa chỉ IP

| Máy | Giao diện | Địa chỉ |
|---|---|---|
| pfSense | WAN (em0) | DHCP từ VMnet8 |
| pfSense | LAN (em1) | `192.168.170.213/24` |
| pfSense | OPT1 (em2) | `192.168.224.222/24` |
| pfSense | OPT2 (em3) | `192.168.121.1/24` |
| nginx-proxy | ens33 | `192.168.121.142/24` |
| backend-1 | Ethernet0 | `192.168.63.132/24` |
| backend-2 | Ethernet0 | `192.168.63.135/24` |
| splunk-server | enp0s3 | `192.168.121.160/24` |
| kali | eth0 | `192.168.224.128/24` |

## Phân giải tên miền

Mô hình dùng tên miền `nginx.lab.com`. Không có DNS server nên phải khai báo thủ công.

Trên máy Kali và máy dùng để duyệt web, thêm vào `/etc/hosts`:

```
192.168.224.222  nginx.lab.com
```

Trên Windows, sửa `C:\Windows\System32\drivers\etc\hosts` (cần quyền Administrator).

## Chứng chỉ TLS tự cấp phát

Trên máy `nginx-proxy`:

```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.lab.com.key \
  -out /etc/nginx/ssl/nginx.lab.com.crt \
  -subj "/C=VN/ST=HCM/L=HCM/O=GDU/CN=nginx.lab.com"
```

Trình duyệt sẽ cảnh báo chứng chỉ không tin cậy — đúng như mong đợi với chứng chỉ tự ký.
Khi test bằng `curl`, dùng cờ `-k` để bỏ qua.

## Thứ tự triển khai

Phải theo đúng thứ tự vì mỗi bước phụ thuộc bước trước:

1. [pfSense](01-pfsense.md) — phải có mạng trước khi các máy khác nói chuyện được
2. [NGINX Reverse Proxy](02-nginx-reverse-proxy.md)
3. [ModSecurity WAF](03-modsecurity-waf.md) — cần NGINX đã biên dịch từ source
4. [Fail2Ban](04-fail2ban.md) — cần log của NGINX để đọc
5. [Backend DVWA](05-backend-dvwa.md)
6. [Splunk SIEM/SOAR](06-splunk-siem-soar.md) — cần tất cả các nguồn log đã sẵn sàng

## Cảnh báo

DVWA cố ý chứa lỗ hổng bảo mật. **Không bao giờ** expose lab này ra Internet, kể cả tạm
thời. Nếu VMnet8 của bạn ở chế độ Bridged thay vì NAT, backend sẽ lộ ra mạng LAN thật.
