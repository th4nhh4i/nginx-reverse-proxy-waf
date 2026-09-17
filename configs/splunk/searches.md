# Truy vấn SPL dùng trong nghiên cứu

Các câu lệnh SPL để tái lập kết quả giám sát ở Chương 3. Chạy trong
**Search & Reporting** trên Splunk Enterprise.

## Xác thực luồng dữ liệu từ Nginx

Kiểm tra Universal Forwarder đã đẩy log về chưa.

```spl
index=web sourcetype=nginx_access
| head 50
| table _time, clientip, method, uri_path, status, upstream
```

## Các sự kiện bị ModSecurity chặn (403)

Tương ứng Hình 3.44 trong báo cáo.

```spl
index=security sourcetype=modsec_audit "Access denied"
| rex field=_raw "\[client (?<src_ip>[\d\.]+)\]"
| rex field=_raw "Inbound Anomaly Score Exceeded \(Total Score: (?<score>\d+)\)"
| rex field=_raw "\[file \"(?<rule_file>[^\"]+)\"\]"
| table _time, src_ip, uri, score, rule_file
| sort - _time
```

## Xếp hạng IP tấn công theo điểm anomaly tích lũy

Dùng làm đầu vào cho playbook chặn IP của SOAR.

```spl
index=security sourcetype=modsec_audit "Access denied"
| rex field=_raw "\[client (?<src_ip>[\d\.]+)\]"
| rex field=_raw "Total Score: (?<score>\d+)"
| stats sum(score) AS total_score, count AS hits, dc(uri) AS distinct_paths BY src_ip
| where total_score > 50
| sort - total_score
```

## Phát hiện HTTP Flood

Một IP bình thường hiếm khi vượt 300 request/phút. Ngưỡng này cần
hiệu chỉnh theo lưu lượng thực tế của từng hệ thống.

```spl
index=web sourcetype=nginx_access
| bin _time span=1m
| stats count AS reqs, dc(uri_path) AS paths BY _time, clientip
| where reqs > 300
| sort - reqs
```

## Phát hiện Slowloris

Slowloris đặc trưng ở chỗ **số kết nối cao nhưng số request thấp** —
ngược hẳn với HTTP Flood. Dấu hiệu là mã 429 từ `limit_conn`.

```spl
index=web sourcetype=nginx_error "limiting connections"
| rex field=_raw "client: (?<src_ip>[\d\.]+)"
| bin _time span=1m
| stats count AS conn_limited BY _time, src_ip
| where conn_limited > 20
```

## Thống kê phân phối tải giữa hai backend

Kiểm chứng load balancer (Hình 3.13). Với `ip_hash`, kết quả sẽ lệch
theo số IP nguồn chứ không chia đôi 50/50 — đó là hành vi đúng.

```spl
index=web sourcetype=nginx_access
| stats count BY upstream
| eventstats sum(count) AS total
| eval percent=round(count*100/total, 2)
| table upstream, count, percent
```

## Tương quan đa tầng: IP vừa bị WAF chặn vừa bị Fail2Ban ban

Đây là loại truy vấn mà SIEM mang lại giá trị so với việc đọc log rời rạc.

```spl
index=security (sourcetype=modsec_audit OR sourcetype=fail2ban)
| rex field=_raw "\[client (?<src_ip>[\d\.]+)\]"
| rex field=_raw "Ban (?<banned_ip>[\d\.]+)"
| eval ip=coalesce(src_ip, banned_ip)
| stats values(sourcetype) AS layers, count BY ip
| where mvcount(layers) > 1
```
