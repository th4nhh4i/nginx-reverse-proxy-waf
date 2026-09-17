# Chương 2 — Cơ sở lý thuyết

## 2.1. Nguyên lý phòng thủ nhiều lớp

### 2.1.1. Khái niệm Defense in Depth

Defense in Depth là chiến lược an ninh lấy cảm hứng từ các mô hình quân sự cổ điển, nơi sự
an toàn của một mục tiêu không bao giờ được phó mặc cho một bức tường duy nhất. Áp dụng
vào an ninh mạng, đây không đơn thuần là việc cài nhiều phần mềm bảo mật mà là cách tiếp
cận kết hợp ba trụ cột: **kỹ thuật, con người và quy trình vận hành** (Chierici và cộng
sự, 2016).

Sức mạnh của mô hình nằm ở giả định nền tảng: **không có lớp bảo mật nào là hoàn hảo**
(McGuiness, 2001). Hệ thống được thiết kế sao cho nếu một chốt chặn bị xuyên thủng, các
lớp còn lại vẫn đứng vững để tiếp tục ngăn chặn hoặc trì hoãn hành vi xâm nhập.

### 2.1.2. Tính cần thiết

Khi các cuộc tấn công chuyển sang dạng đa vector — kết hợp DDoS, mã độc zero-day và chiến
dịch APT — việc đặt niềm tin vào một chốt chặn duy nhất trở nên quá mạo hiểm. Mô hình
nhiều lớp mang lại ba lợi ích cụ thể:

1. **Triệt tiêu điểm lỗi duy nhất (SPOF).** Một lớp sụp đổ không kéo theo toàn hệ thống.
2. **Tăng khả năng truy vết.** Kẻ tấn công để lại dấu vết ở nhiều giai đoạn khác nhau,
   thay vì chỉ một điểm quan sát (MixMode, 2023).
3. **Kéo dài thời gian phản ứng.** Mỗi lớp là một rào cản làm chậm kẻ địch, cho đội vận
   hành thêm thời gian cô lập sự cố.

Về mặt quản trị, kiến trúc nhiều tầng còn là con đường ngắn nhất để đáp ứng ISO/IEC 27001
và NIST SP 800-53 (Tschroub, 2019).

### 2.1.3. Mô hình bốn tầng của đề tài

Kiến trúc được xây dựng theo hình mẫu **mô hình củ hành** (Onion Model), bao bọc dữ liệu
nhạy cảm ở vị trí trung tâm.

| Tầng | Thành phần | Nhiệm vụ |
|---|---|---|
| 1 — Biên mạng | pfSense + Snort/Suricata | Lọc lưu lượng thô, nhận diện quét lỗ hổng, chặn flood tầng 3/4 |
| 2 — Ứng dụng | NGINX + ModSecurity + Rate Limit + Fail2Ban | Thẩm định nội dung HTTP, chặn SQLi/XSS, chặn DDoS tầng 7 |
| 3 — Lõi | Backend Windows Server | Ẩn hoàn toàn khỏi Internet, chỉ nhận traffic đã "làm sạch" |
| 4 — Giám sát | Splunk SIEM + SOAR | Tương quan sự kiện toàn cục, thực thi phản ứng tự động |

Tầng 4 là điểm khác biệt: thay vì chỉ là lớp phòng thủ tĩnh, Splunk đóng vai trò **điều
khiển toàn cục** — thu thập nhật ký từ tất cả các tầng, phân tích tương quan, rồi ra lệnh
ngược trở lại tầng 1 và 2 để cô lập nguồn tấn công. Đây chính là thứ khép kín chu trình.

---

## 2.2. Các tầng bảo mật

### 2.2.1. Tầng 1 — Biên mạng

#### pfSense

Giải pháp tường lửa mã nguồn mở trên nền FreeBSD, ra mắt 2006. Điểm mạnh là giao diện
quản trị trực quan nhưng khả năng mở rộng gần như vô hạn — tích hợp sẵn VPN, QoS và các
plugin cao cấp như Snort, Suricata (FreeBSD Foundation, 2017; Patel & Sharma, 2017).

#### Phân đoạn mạng

pfSense được triển khai với bốn giao diện tách biệt để hiện thực hóa nguyên lý **quyền hạn
tối thiểu** (Least Privilege):

- **WAN (em0)** — cửa ngõ duy nhất tiếp nhận lưu lượng Internet
- **LAN (em1)** — kết nối các máy chủ nội bộ
- **OPT1 (em2)** — vùng DMZ chứa NGINX Reverse Proxy
- **OPT2 (em3)** — phân vùng quản trị/giám sát biệt lập cho Splunk

Kết hợp Stateful Firewall và NAT, không gói tin nào xâm nhập được vào trong nếu không đáp
ứng các quy tắc đã thiết lập (Buqing, 2024).

#### Snort và Suricata

Hai động cơ IDS/IPS được triển khai song song, và đây **không phải là sự dư thừa** mà là
lựa chọn có chủ đích dựa trên điểm mạnh bù trừ:

| | Snort | Suricata |
|---|---|---|
| Cơ chế | So khớp dấu hiệu, đơn luồng | Đa luồng (multi-threaded) |
| Điểm mạnh | Độ chính xác cao | Xử lý lưu lượng tốc độ cao |
| Điểm yếu | Nghẽn khi băng thông lớn | Tiêu tốn tài nguyên phần cứng hơn |
| Phù hợp | Môi trường ưu tiên độ chính xác | Môi trường lưu lượng đột biến |

Kết hợp cả hai tạo ra cấu trúc giám sát đa tầng: tận dụng độ chính xác của Snort và tốc độ
của Suricata để tăng tỷ lệ phát hiện và khả năng chịu lỗi (Raza Shah & Issac, 2017;
Jonkman và cộng sự, 2015; Saber và cộng sự, 2023).

### 2.2.2. Tầng 2 — Reverse Proxy

#### Cơ chế vận hành

Reverse Proxy là thực thể trung gian đứng ra đại diện cho các máy chủ nội bộ giao tiếp với
người dùng. Mọi yêu cầu được tiếp nhận, thẩm định rồi mới chuyển tiếp (Bukhari & Iqbal,
2024). Ngoài bảo mật, lớp này còn mang lại:

- **Caching** — phục vụ nội dung tĩnh mà không làm phiền backend, tiết kiệm băng thông
- **Chuyển đổi giao thức** — nâng cấp HTTP→HTTPS, tối ưu giữa HTTP/1.1 và HTTP/2
- **Health check** — tự động loại bỏ máy chủ gặp sự cố khỏi vòng tải (NGINX, n.d.-c)
- **Xác thực tập trung** — tích hợp OAuth2, JWT ngay tại cửa ngõ (NGINX, n.d.-e)

#### NGINX làm Reverse Proxy

Triển khai trên Ubuntu Server 22.04, đạt ba mục tiêu: điều phối lưu lượng thông minh, che
giấu hoàn toàn sơ đồ mạng nội bộ, và bảo vệ tầng ứng dụng khỏi can thiệp trực tiếp.

Chi tiết kỹ thuật quan trọng là các trường `proxy_set_header`. Vì backend nằm sau proxy,
nếu không truyền `X-Real-IP` và `X-Forwarded-For` thì mọi request về backend đều mang IP
của proxy — làm mất hoàn toàn khả năng truy vết nguồn tấn công. Đây là yếu tố sống còn
cho tầng giám sát phía sau.

Cấu hình được tổ chức theo mô-đun qua `sites-available` / `sites-enabled`, cho phép
bật/tắt dịch vụ ảo bằng symlink mà không sửa file cấu hình gốc.

→ Xem [`configs/nginx/`](../configs/nginx/)

#### ModSecurity WAF

Bộ não phân tích của hệ thống WAF, mạnh nhờ tập luật **OWASP Core Rule Set (CRS)**. Thay
vì lập trình thủ công hàng nghìn quy tắc, CRS cho phép tự động nhận diện các mẫu tấn công
kinh điển (Muzaki và cộng sự, 2020).

ModSecurity có hai chế độ:

- `SecRuleEngine DetectionOnly` — chỉ ghi log, dùng khi tinh chỉnh luật để đo false positive
- `SecRuleEngine On` — chặn thật, dùng khi đã hiệu chỉnh xong (Feisty Duck, 2017)

CRS hoạt động theo **Anomaly Scoring**: mỗi luật vi phạm cộng điểm, chỉ khi tổng điểm vượt
ngưỡng mới chặn. Cách này giảm false positive đáng kể so với chặn theo từng luật đơn lẻ.

→ Xem [`configs/modsecurity/`](../configs/modsecurity/)

#### Rate Limiting

Dựa trên thuật toán **Leaky Bucket** (chiếc xô thủng), NGINX điều tiết số yêu cầu từ mỗi
IP qua chỉ thị `limit_req_zone`. Cơ chế này duy trì cân bằng: người dùng bình thường không
bị ảnh hưởng, nhưng các bot gửi yêu cầu liên tục tần suất cao bị chặn đứng (NGINX, 2016).

Đây là phương pháp **chi phí thấp, hiệu quả cao** trong việc bảo vệ tài nguyên trước nguy
cơ quá tải (Serbout và cộng sự, 2023).

Cần phân biệt hai chỉ thị:

- `limit_req` — giới hạn **số request/giây**, chặn HTTP Flood
- `limit_conn` — giới hạn **số kết nối đồng thời**, chặn Slowloris

Slowloris không gửi nhiều request mà giữ nhiều kết nối mở, nên `limit_req` một mình không
chặn được nó.

→ Xem [`configs/nginx/conf.d/rate-limit.conf`](../configs/nginx/conf.d/rate-limit.conf)

#### Fail2Ban

Nếu ModSecurity mạnh về lọc nội dung, Fail2Ban xử lý các hành vi lạm dụng dựa trên
**nhật ký**. Khi một IP liên tục nhận mã lỗi 403 (truy cập vùng cấm) hoặc 401 (dò mật
khẩu), Fail2Ban ra lệnh cho tường lửa nội bộ chặn IP đó trong khoảng thời gian định sẵn
(Jaquier, 2023; DigitalOcean, 2021).

Điểm giá trị: biến những dòng nhật ký thụ động thành hành động phòng thủ chủ động.

→ Xem [`configs/fail2ban/`](../configs/fail2ban/)

#### Load Balancer

Khối `upstream` định nghĩa cụm máy chủ, NGINX phân phối yêu cầu theo Round Robin,
Least Connections hoặc `ip_hash`.

Đề tài chọn **`ip_hash`** vì DVWA lưu session PHP cục bộ trên từng máy. Với Round Robin,
người dùng đăng nhập ở backend 1 rồi request kế tiếp rơi vào backend 2 sẽ bị đăng xuất.
Đánh đổi là tải không chia đều tuyệt đối — phân phối phụ thuộc số lượng IP nguồn.

Ngoài hiệu suất, Load Balancer còn cung cấp khả năng chịu lỗi: backend sập thì lưu lượng
tự động chuyển sang nút còn lại mà người dùng không hay biết (Kinza & Irei, 2023).

### 2.2.3. Tầng 3 — Máy chủ ứng dụng

#### XAMPP và DVWA

Backend triển khai trên Windows Server 2016 với XAMPP (Apache + MySQL + PHP). Ứng dụng
mục tiêu là **DVWA** — một ứng dụng web cố ý chứa các lỗ hổng kinh điển.

Lựa chọn DVWA có ý nghĩa phương pháp luận quan trọng: nó cho phép kiểm chứng xem lớp
Reverse Proxy và WAF có thực sự bắt được tấn công hay không. Nếu dùng một ứng dụng web
đã an toàn sẵn, ta không thể phân biệt "WAF đã chặn" với "vốn dĩ không có gì để khai thác".

DVWA còn có các mức bảo mật (Low / Medium / High / Impossible), tạo ra **nhóm đối chứng**:
ở mức Impossible, mã nguồn đã được gia cố tối đa, nên nếu WAF vẫn chặn thì đó là bằng
chứng cho tầng bảo vệ bổ sung thật sự.

#### Cô lập mạng

Web Server được đặt trong vùng mạng nội bộ ảo riêng, tuân thủ một quy tắc tuyệt đối:
**backend không bao giờ tiếp xúc trực tiếp với lưu lượng Internet**, chỉ chấp nhận kết nối
đã qua sàng lọc từ Reverse Proxy. Ngay cả khi lớp biên bị xuyên thủng, kẻ tấn công vẫn gặp
rào cản khi leo thang sang các vùng mạng khác.

### 2.2.4. Tầng 4 — Giám sát và phản ứng

#### Oracle Linux

Nền tảng cho các công cụ giám sát, chọn vì tương thích với hệ sinh thái Enterprise và hiệu
năng xử lý tệp tin cao. Quan trọng hơn: **tách biệt hệ thống giám sát ra máy chủ riêng**
đảm bảo rằng khi các nút dịch vụ (Proxy, Web Server) gặp sự cố, SOC vẫn vận hành để ghi
lại diễn biến — đúng lúc dữ liệu đó có giá trị nhất.

Lưu ý thực tế: Splunk SOAR chỉ hỗ trợ bản phân phối RHEL 9, nên Oracle Linux 9 là lựa chọn
bắt buộc chứ không phải tùy chọn.

#### Splunk SIEM

Splunk Enterprise lập chỉ mục dữ liệu theo thời gian thực từ mọi nguồn: access log của
NGINX, cảnh báo ModSecurity, báo cáo lọc gói tin pfSense.

Điểm mạnh vượt trội là **tương quan sự kiện**. Qua ngôn ngữ truy vấn SPL, các dấu hiệu
đơn lẻ được xâu chuỗi lại — ví dụ một chuỗi lỗi 403 liên tiếp từ NGINX kết hợp với gia
tăng đột biến băng thông tại pfSense — để nhận diện chính xác kịch bản tấn công mà từng
lớp riêng lẻ không thấy được.

→ Xem [`configs/splunk/searches.md`](../configs/splunk/searches.md)

#### Splunk SOAR

Nếu SIEM là **mắt nhìn** thì SOAR là **cánh tay thực thi**. Công nghệ này vượt qua giới
hạn thời gian phản ứng của con người.

Các kịch bản **Playbook** kết nối các tầng bảo mật với nhau: khi SIEM phát hiện một IP có
hành vi tấn công vượt ngưỡng, SOAR lập tức gửi lệnh chặn xuống pfSense (qua REST API) hoặc
cập nhật danh sách đen trên NGINX (qua SSH/SCP). Chu trình khép kín này rút ngắn tối đa
**MTTR** (Mean Time to Respond).

---

## 2.3. Phân tích vector tấn công

### 2.3.1. Tấn công từ chối dịch vụ (DDoS)

Trong ba trụ cột CIA, **tính sẵn sàng** là mục tiêu hàng đầu của DDoS. Thách thức thực sự
nằm ở tính phân tán: hàng nghìn tới hàng triệu địa chỉ IP từ khắp nơi khiến việc tách biệt
người dùng thật với kẻ tấn công trở thành bài toán hóc búa (Cisco, 2023).

#### Phân loại theo mô hình OSI

**Tầng 3/4 — Tấn công băng thông và tài nguyên phần cứng.** SYN flood, UDP flood, ICMP
flood làm cạn kiệt bảng trạng thái kết nối của tường lửa hoặc chiếm dụng toàn bộ đường
truyền. Mục tiêu là làm nghẽn hạ tầng trước khi dữ liệu chạm tới tầng ứng dụng (CISA, 2020).

**Tầng 7 — Tấn công logic ứng dụng.** Đây là xu hướng nguy hiểm nhất hiện nay. Kẻ tấn công
giả lập hành vi người dùng thật, gửi các yêu cầu HTTP **hợp lệ** nhưng tần suất cực cao,
nhắm vào các tác vụ tốn kém nhất của máy chủ (truy vấn CSDL, xử lý tệp tin). Loại tấn công
này đòi hỏi băng thông rất thấp nhưng làm sập hệ thống nhanh chóng (Imperva, 2023).

#### Chu kỳ sống của một chiến dịch

1. **Xây dựng botnet** — quét lỗ hổng toàn cầu, lây nhiễm thiết bị IoT và máy chủ cấu hình
   sai. Các thiết bị này trở thành "xác sống" chờ lệnh từ máy chủ C&C (CompTIA, n.d.).
2. **Phát động** — lệnh tấn công phát đi đồng loạt, lưu lượng khổng lồ dồn về một điểm.
3. **Thích nghi** — đây là điểm khiến DDoS hiện đại khó lường. Kẻ tấn công theo dõi phản
   ứng phòng thủ và đổi chiến thuật: chặn theo IP thì đổi dải IP, chặn TCP thì chuyển sang
   HTTP. Các lớp bảo mật tĩnh dễ dàng bị vô hiệu hóa.

#### Cơ chế hiệp đồng đa tầng

| Tầng | Vai trò trước DDoS |
|---|---|
| pfSense | Lọc gói tin dị hình, chặn SYN/UDP flood tầng thấp, IDS nhận diện quét cổng |
| NGINX | `limit_req` chặn HTTP Flood, `limit_conn` chặn Slowloris |
| Fail2Ban | Soi log, cấm truy cập IP có hành vi lặp lại |
| Splunk SIEM/SOAR | Tương quan toàn cục, thực thi playbook khi vượt ngưỡng xử lý của NGINX |

Chính khả năng **thích nghi** của kẻ tấn công là lý do cần lớp SOAR: một luật tĩnh không
theo kịp một đối thủ đang đổi chiến thuật theo thời gian thực.

### 2.3.2. Khai thác dữ liệu

Khác với mục tiêu gây tắc nghẽn của DDoS, tấn công khai thác dữ liệu hướng tới phá vỡ
**tính bảo mật và tính toàn vẹn**. Quá trình này tinh vi, kéo dài và trải qua nhiều giai
đoạn để tránh gây chú ý.

#### Theo mô hình Cyber Kill Chain

| Giai đoạn | Hành vi của kẻ tấn công | Lớp đối phó |
|---|---|---|
| Thăm dò | Rà soát bề mặt ứng dụng tìm tham số URL không lọc, form lỏng lẻo | NGINX ghi nhận tần suất dị thường vào đường dẫn nhạy cảm |
| Tiêm mã | SQLi ép CSDL thực thi lệnh trái phép, Stored XSS lưu mã độc vĩnh viễn | ModSecurity bóc tách payload, chặn ngay tại biên |
| Leo thang | Command Injection, Path Traversal để đọc `/etc/shadow`, `.env` | Chuẩn hóa URL, kiểm soát nghiêm ngặt quyền truy cập đường dẫn |
| Trích xuất | Đóng gói và gửi dữ liệu ra ngoài | Splunk SIEM giám sát thông lượng, phát hiện truyền tải khối lượng bất thường |

Giai đoạn cuối đáng chú ý: **SIEM là chốt chặn cuối cùng**, đảm bảo dữ liệu không thất
thoát ngay cả khi các bước xâm nhập trước đó đã thành công.

#### Các kỹ thuật trọng tâm theo OWASP Top 10

**A03:2021 — Injection.** Ngoài việc vượt qua cơ chế đăng nhập, kỹ thuật hiện đại gồm
*Union-based SQLi* (gộp kết quả truy vấn hợp lệ với dữ liệu nhạy cảm từ bảng users) và
*Error-based SQLi* (ép máy chủ lộ thông tin cấu hình qua thông báo lỗi). ModSecurity nhận
diện từ khóa SQL và cấu trúc truy vấn dị thường.

**Cross-Site Scripting.** Nguy hiểm nhất là *Stored XSS*, nhúng mã độc trực tiếp vào ứng
dụng để tự động đánh cắp Cookie và Session Token của **mọi** người dùng truy cập. Đánh
chặn tại lớp biên bảo vệ dữ liệu PII ngay cả khi mã nguồn backend còn lỗ hổng chưa vá.

**A01:2021 — Broken Access Control.** *Path Traversal* và *LFI* dùng chuỗi `../` để truy
cập trái phép các phân vùng nhạy cảm của hệ điều hành. Xử lý bằng cơ chế **URL
Normalization** ngay tại tầng NGINX.

**Malicious File Upload.** Tải lên tệp thực thi núp bóng hình ảnh (WebShell) là con đường
ngắn nhất để chiếm quyền điều khiển toàn diện. Thay vì chỉ kiểm tra phần mở rộng, SOAR
thực hiện thẩm định thông minh và tự động xóa bỏ tệp có dấu hiệu mã độc.

---

→ Tiếp theo: [Chương 3 — Mô hình thực nghiệm](03-mo-hinh-thuc-nghiem.md)
