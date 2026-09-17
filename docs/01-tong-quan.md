# Chương 1 — Tổng quan về đề tài

## 1.1. Lý do chọn đề tài

Ứng dụng web đã vượt khỏi vai trò công cụ hỗ trợ để trở thành hạ tầng số cốt lõi, duy trì
mạch máu của các hoạt động kinh tế, tài chính và hành chính xã hội. Nhưng chính sự phụ
thuộc đó biến chúng thành mục tiêu hàng đầu của các cuộc tấn công mạng quy mô lớn.

Dữ liệu năm 2025 cho thấy mức độ leo thang:

| Chỉ số | Giá trị | Nguồn |
|---|---|---|
| Tổng số cuộc tấn công DDoS bị ngăn chặn | 47,1 triệu (+121% so với 2024) | Cloudflare 2025 |
| Tăng trưởng số đợt tấn công 2023–2025 | +236% | Cloudflare 2025 |
| Kỷ lục cường độ yêu cầu | 205 triệu req/giây | Botnet Aisuru-Kimwolf |
| Kỷ lục băng thông | 31,4 Tbps | Cloudflare Q4 2025 |
| Tăng trưởng quy mô tấn công so với cuối 2024 | +700% | Cloudflare 2025 |
| Thiệt hại trung bình một vụ rò rỉ dữ liệu | 4,88 triệu USD (6,08 triệu với ngành tài chính) | IBM 2024 |

Ba vấn đề nổi lên từ những con số này.

**Thứ nhất, phòng thủ truyền thống không còn đủ.** Tường lửa mạng và IDS/IPS hoạt động ở
tầng 3/4, trong khi vector tấn công đang dịch chuyển lên tầng 7 — nơi lưu lượng độc hại
trông y hệt lưu lượng hợp lệ. Một HTTP Flood chỉ cần băng thông rất thấp nhưng vẫn làm
sập được hệ thống vì nó đánh trực diện vào logic xử lý của ứng dụng.

**Thứ hai, tốc độ tấn công vượt quá khả năng phản ứng của con người.** Các chiến dịch hiện
đại được tự động hóa cao và thích nghi liên tục: chặn theo IP thì đổi dải IP, chặn TCP thì
chuyển sang HTTP. Can thiệp thủ công trở nên bất khả thi.

**Thứ ba, giải pháp thương mại nằm ngoài tầm với của SMB.** Cloud WAF và dịch vụ chống
DDoS từ các nhà cung cấp lớn đòi hỏi chi phí vận hành vượt khả năng của đại đa số doanh
nghiệp vừa và nhỏ.

NGINX — với kiến trúc hướng sự kiện xử lý được hàng chục nghìn kết nối đồng thời và
[33,8% thị phần website toàn cầu](https://w3techs.com/technologies/overview/web_server) —
là nền tảng phù hợp để giải bài toán này. Tuy nhiên việc kết hợp nó với điều phối tải,
Rate Limiting, ModSecurity WAF và các công cụ phản ứng tự động thành một hàng rào đa lớp
hoàn chỉnh vẫn cần nghiên cứu hệ thống và thực nghiệm chặt chẽ. Đó là khoảng trống mà đề
tài này nhắm tới.

## 1.2. Phương pháp nghiên cứu

Nghiên cứu kết hợp phân tích hệ thống với thực nghiệm kỹ thuật, chia làm bốn giai đoạn.

**Hệ thống hóa lý thuyết.** Khảo sát kiến trúc Reverse Proxy, cơ chế điều phối tải và các
thuật toán giới hạn lưu lượng trên NGINX, đối chiếu với các tiêu chuẩn an ninh hiện đại
(OWASP Top 10, ISO/IEC 27001, NIST SP 800-53) để xác lập khung tham chiếu kỹ thuật.

**Mô hình hóa kiến trúc.** Thiết kế hệ thống theo nguyên lý Defense in Depth, phân tách
các phân vùng mạng từ tường lửa biên pfSense đến nút NGINX và cụm backend. Triển khai
trên VMware để đảm bảo tính cô lập và khả năng kiểm soát biến số.

**Thực nghiệm có đối chứng.** Giả lập các kịch bản tấn công trong môi trường kiểm soát,
so sánh hành vi hệ thống khi **có** và **không có** lớp Reverse Proxy. Nhóm đối chứng
này là điều kiện cần để quy kết kết quả cho giải pháp thay vì cho may rủi.

**Phân tích định lượng.** Đo độ trễ phản hồi, tỷ lệ chặn yêu cầu độc hại và mức chiếm dụng
tài nguyên dưới các điều kiện tải khác nhau, làm rõ tương quan giữa cấu hình bảo mật và
hiệu suất vận hành thực tế.

## 1.3. Đối tượng và phạm vi

### Đối tượng nghiên cứu

Hệ thống Reverse Proxy bảo mật trên nền NGINX, cụ thể là các cơ chế cấu hình chuyên sâu,
module tích hợp (điều phối tải, giới hạn lưu lượng) và khả năng tương tác của NGINX với
các thành phần an ninh bổ trợ.

### Trong phạm vi

- Tối ưu hóa cấu hình NGINX như một nút bảo mật trung tâm
- Các vector tấn công tầng ứng dụng: HTTP Flood, web scraping, tấn công vét cạn,
  truy cập trái phép qua kiểm soát đường dẫn
- Các kỹ thuật khai thác trong OWASP Top 10: SQLi, XSS, Command Injection, Path Traversal

### Ngoài phạm vi

- Lỗ hổng sâu trong mã nguồn ứng dụng backend
- Mối đe dọa nội tại (insider threat)
- Tấn công zero-day nằm ngoài khả năng xử lý của lớp biên

pfSense, cụm backend Windows Server 2016 và Splunk SIEM/SOAR đóng vai trò **môi trường
nền tảng** để đo lường hiệu quả của lớp Reverse Proxy, không phải đối tượng nghiên cứu
chính về cấu hình bảo mật nội tại của chúng.

### Giới hạn của kết luận

Toàn bộ đánh giá thực hiện trên VMware. Kết luận về hiệu quả và khả năng chịu tải được
quy chiếu vào cấu trúc thực nghiệm đã xây dựng, **không ngoại suy** sang các mạng sản xuất
có quy mô lưu lượng siêu lớn.

Lộ trình: 09/12/2024 – 04/2026.

## 1.4. Ý nghĩa

### Khoa học

Đóng góp một khung tham chiếu về kiến trúc phòng thủ chiều sâu, với điểm nhấn là sự
chuyển dịch từ **phòng thủ thụ động dựa trên luật tĩnh** sang **chu trình phản ứng khép
kín và tự động hóa**. Việc tích hợp Splunk SIEM/SOAR với năng lực điều phối của NGINX
cung cấp bằng chứng định lượng về khả năng giảm thiểu độ trễ phản ứng sự cố.

### Ứng dụng

Cung cấp một mô hình SOC thu nhỏ, hiệu năng cao và tối ưu chi phí. Các bộ cấu hình chuẩn
hóa trên NGINX, quy tắc lọc gói tin trên pfSense và kịch bản phản ứng tự động trên Splunk
SOAR có thể dùng làm bản mẫu thực tế cho quản trị viên hệ thống, giúp tổ chức tự chủ hạ
tầng an ninh mà không phụ thuộc dịch vụ đám mây đắt đỏ.

## 1.5. Cấu trúc đề tài

| Chương | Nội dung |
|---|---|
| [1 — Tổng quan](01-tong-quan.md) | Bối cảnh, mục tiêu, phương pháp, phạm vi |
| [2 — Cơ sở lý thuyết](02-co-so-ly-thuyet.md) | Defense in Depth, bốn tầng bảo mật, phân tích vector tấn công |
| [3 — Mô hình thực nghiệm](03-mo-hinh-thuc-nghiem.md) | Triển khai hạ tầng, cấu hình, tám kịch bản kiểm thử |
| [4 — Kết luận](04-ket-luan.md) | Đánh giá kết quả, hạn chế, hướng phát triển |
