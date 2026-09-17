# Chương 4 — Kết luận và hướng phát triển

## 4.1. Kết luận

### Phòng thủ chiều sâu là phương án tối ưu

Thực nghiệm chứng minh việc áp dụng nguyên lý Defense in Depth — từ lớp mạng (pfSense) đến
lớp biên ứng dụng (NGINX) — triệt tiêu rủi ro theo từng giai đoạn xâm nhập. Hệ thống ngăn
chặn thành công các vector tấn công trọng điểm trong OWASP Top 10: SQL Injection, XSS
(cả ba biến thể), Command Injection và CSP Bypass.

Điểm quan trọng về mặt phương pháp: việc chuyển trọng tâm bảo mật sang lớp Reverse Proxy
tạo ra rào cản tiền phương, đảm bảo tính toàn vẹn cho backend **ngay cả khi mã nguồn ứng
dụng tồn tại lỗ hổng chưa được vá**. Đây là điều mà bảo mật ở tầng ứng dụng đơn thuần
không làm được — vì nó đòi hỏi phải sửa mã nguồn, vốn thường nằm ngoài tầm kiểm soát của
đội vận hành.

### Phản ứng tự động rút ngắn MTTR

Đóng góp có giá trị nhất của đề tài là hiện thực hóa chu trình phản ứng khép kín qua
Splunk SOAR. Khả năng tự động phân tích điểm anomaly từ SIEM rồi ra lệnh phong tỏa IP độc
hại trên pfSense theo thời gian thực đã biến hệ thống từ một **tấm khiên tĩnh** thành một
**thực thể phản xạ**, loại bỏ hoàn toàn độ trễ do yếu tố con người.

Trong bối cảnh các chiến dịch tấn công hiện đại được tự động hóa cao và thích nghi liên
tục, tốc độ phản ứng không còn là yếu tố phụ mà là điều kiện sống còn.

### NGINX tối ưu tài nguyên vượt trội

Một kết luận khoa học đáng chú ý: mặc dù phải xử lý **hơn 800 tập luật WAF** phức tạp dưới
áp lực tấn công DDoS tầng 7 (Slowloris), máy chủ Reverse Proxy vẫn duy trì mức chiếm dụng
tài nguyên rất khiêm tốn — Fail2Ban chỉ tiêu tốn khoảng 8,4 MB bộ nhớ.

Kết quả này khẳng định tính thực tiễn của giải pháp: có thể triển khai bảo mật chuyên sâu
trên hạ tầng phần cứng hạn chế mà vẫn giữ độ trễ thấp cho người dùng hợp lệ.

### Giải quyết bài toán kinh tế cho SMB

Đề tài cung cấp bản thiết kế một SOC thu nhỏ nhưng đầy đủ chức năng, thay thế các dịch vụ
Cloud WAF tốn kém bằng hệ thống tự chủ và linh hoạt. Trong bối cảnh **chủ quyền dữ liệu**
đang trở thành ưu tiên hàng đầu, quyền làm chủ hoàn toàn nhật ký và khả năng tùy biến kịch
bản phòng thủ theo đặc thù tổ chức là giá trị cốt lõi mà mô hình mang lại.

---

## 4.2. Hạn chế

Nhóm nghiên cứu thẳng thắn nhìn nhận bốn giới hạn kỹ thuật.

**Phụ thuộc vào luật tĩnh.** ModSecurity vận hành dựa trên tập luật logic tĩnh. Dù đồ sộ
(812 luật), nó vẫn có nguy cơ bị vượt qua bởi các biến thể zero-day tinh vi hoặc kỹ thuật
bypass payload do AI sinh ra. Anomaly Scoring giảm bớt rủi ro này nhưng không loại bỏ nó.

**Điểm nghẽn tại lớp giải mã SSL/TLS.** Việc giải mã cường độ cao tại một máy chủ Proxy
đơn lẻ là điểm nghẽn hiệu năng tiềm ẩn khi đối mặt các đợt tấn công siêu khối lượng trong
môi trường thực tế.

**SPOF ở lớp Reverse Proxy.** Mô hình hiện tại chỉ có một nút NGINX. Nếu nút này sập, toàn
bộ dịch vụ ngừng hoạt động — nghịch lý so với chính nguyên lý Defense in Depth mà đề tài
theo đuổi.

**Giới hạn của môi trường thực nghiệm.** Toàn bộ đánh giá thực hiện trên VMware với quy mô
lưu lượng lab. Kết luận về khả năng chịu tải **không được ngoại suy** sang mạng sản xuất
có lưu lượng thực tế siêu lớn.

---

## 4.3. Hướng phát triển

### Bảo mật chủ động bằng AI

Chuyển dịch từ phòng thủ dựa trên kịch bản sang **AI-Driven Security**. Tích hợp các thuật
toán học máy không giám sát như **Isolation Forest** vào tầng phân tích SIEM cho phép hệ
thống học hành vi lưu lượng thực tế, từ đó dự báo và ngăn chặn sớm các mẫu tấn công biến
dị mà **không cần đợi cập nhật luật thủ công**.

Nâng cấp này biến hệ thống giám sát từ bộ máy hậu kiểm thành thực thể có khả năng phòng
thủ dự báo.

### Kiến trúc sẵn sàng cao (HA)

Triển khai cụm Reverse Proxy hoạt động song song để loại bỏ hoàn toàn rủi ro SPOF và mang
lại khả năng mở rộng linh hoạt.

Kết hợp với công nghệ tăng tốc phần cứng như **DPDK** hoặc card mạng chuyên dụng
**SmartNIC**, hệ thống có thể đạt năng lực xử lý gói tin ở tốc độ dây (line-rate) — điều
kiện cần cho các dịch vụ đòi hỏi độ trễ cực thấp như giao dịch tài chính hay ngân hàng số.

### Tích hợp tình báo mối đe dọa

Kết nối tự động SOAR với các nguồn **Threat Intelligence** uy tín quốc tế để hệ thống tự
cập nhật danh sách đen IP và chữ ký mã độc theo thời gian thực. Quy trình này vừa nâng cao
năng lực thẩm định đối tượng xâm nhập, vừa giảm áp lực phân tích cho đội vận hành SOC.

---

Sự kết hợp giữa **học máy**, **kiến trúc phân tán** và **tình báo an ninh** là lộ trình
chiến lược để nâng tầm mô hình nghiên cứu thành một giải pháp bảo mật lớp biên toàn diện
và bền vững.

---

→ [Danh mục tài liệu tham khảo](tai-lieu-tham-khao.md)
