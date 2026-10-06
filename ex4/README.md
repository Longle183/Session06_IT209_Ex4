# Bài 4: Quản Lý Tiến Trình Nền Với nohup Và Tín Hiệu Kill

## 1. Thông Tin Chung
- **Môn học:** DevOps Practice
- **Bài tập:** Bài 4 - Quản lý tiến trình nền với nohup và tín hiệu Kill
- **Thư mục nộp bài:** `homework/session_06/ex4/`
- **Mục tiêu:**
  - Thành thạo việc khởi chạy tiến trình chạy ngầm (background) độc lập với session Terminal bằng `nohup` và `&`.
  - Nắm vững các công cụ giám sát tiến trình hệ thống trong Linux: `ps`, `pgrep`, `top`/`htop`.
  - Hiểu rõ cơ chế hoạt động của tín hiệu hệ thống (POSIX Signals) và thực hiện tắt tiến trình an toàn bằng lệnh `kill` (`SIGTERM - 15` vs `SIGKILL - 9`).

---

## 2. Kịch Bản Giám Sát: `loop-monitor.sh`

Kịch bản được thiết kế để liên tục theo dõi và ghi nhận timestamp của hệ thống vào tệp tin `/tmp/monitor.log` sau mỗi chu kỳ 5 giây.

### Nội dung file `loop-monitor.sh`:
```bash
#!/bin/bash

# ==============================================================================
# Script: loop-monitor.sh
# Mục đích: Ghi thời gian hiện tại vào file log định kỳ mỗi 5 giây
# Đường dẫn file log: /tmp/monitor.log
# ==============================================================================

LOG_FILE="/tmp/monitor.log"

# Đảm bảo file log tồn tại
touch "$LOG_FILE"

# Vòng lặp vô tận ghi log mỗi 5 giây
while true; do
    echo "System time: $(date)" >> "$LOG_FILE"
    sleep 5
done
```

---

## 3. Các Bước Thực Hiện Chi Tiết & Giải Thích Câu Lệnh

### Bước 1: Cấp quyền thực thi cho kịch bản
Trước khi chạy script, cần cấp quyền thực thi (`execute`) cho file:
```bash
chmod +x loop-monitor.sh
```
- `chmod +x`: Gán cờ thực thi cho chủ sở hữu, nhóm và người dùng khác trên hệ thống.

---

### Bước 2: Khởi chạy script ở chế độ nền độc lập với `nohup`
Thực thi lệnh sau:
```bash
nohup ./loop-monitor.sh > /dev/null 2>&1 &
```

#### Phân tích cấu trúc câu lệnh:
1. **`nohup` (No Hang Up):**
   - Mặc định khi phiên làm việc Terminal/SSH bị ngắt (đóng cửa sổ, mất mạng, `exit`), shell sẽ gửi tín hiệu `SIGHUP` (Signal Hang Up - signal 1) đến tất cả các tiến trình con do nó khởi tạo, làm các tiến trình con này bị kết thúc.
   - Lệnh `nohup` chỉ thị cho tiến trình bỏ qua (ignore) tín hiệu `SIGHUP`, giúp tiến trình tiếp tục chạy ngầm dù session kết thúc.
2. **`./loop-monitor.sh`:** Đường dẫn file script cần thực thi.
3. **`> /dev/null`:** Chuyển hướng đầu ra tiêu chuẩn (`stdout - file descriptor 1`) vào thiết bị giả lập rỗng `/dev/null` để bỏ qua các log không cần thiết (do script đã chủ động ghi vào `/tmp/monitor.log`).
4. **`2>&1`:** Chuyển hướng đầu ra lỗi tiêu chuẩn (`stderr - file descriptor 2`) vào cùng đích với `stdout` (tức `/dev/null`).
5. **`&`:** Đưa tiến trình vào trạng thái chạy ngầm dưới nền (background process), trả lại quyền điều khiển dấu nhắc shell ngay lập tức cho người dùng.

> *Lưu ý:* Nếu không chỉ định chuyển hướng đầu ra (ví dụ chạy `nohup ./loop-monitor.sh &`), `nohup` sẽ tự động tạo file `nohup.out` tại thư mục hiện hành để lưu toàn bộ `stdout` và `stderr`.

---

### Bước 3: Tìm số định danh tiến trình (PID - Process ID)

Có nhiều phương pháp để xác định PID của tiến trình vừa chạy:

#### Cách 1: Sử dụng `pgrep` (nhanh và chính xác)
```bash
pgrep -f loop-monitor.sh
```
*Kết quả:*
```text
34821
```

#### Cách 2: Sử dụng `ps aux` kết hợp `grep`
```bash
ps aux | grep loop-monitor.sh
```
*Kết quả thực tế trên Terminal:*
```text
user      34821  0.0  0.1  13420  3240 ?        S    14:20   0:00 /bin/bash ./loop-monitor.sh
user      34860  0.0  0.0   8900   896 pts/0    S+   14:21   0:00 grep --color=auto loop-monitor.sh
```
- **PID chính của tiến trình:** `34821`
- Trạng thái tiến trình là `S` (Interruptible Sleep - do đang ở câu lệnh `sleep 5`).
- `?` ở cột `TTY`: Tiến trình không còn gắn với terminal ảo cụ thể nào (đã tách độc lập).

#### Cách 3: Sử dụng `top` hoặc `htop`
```bash
htop -p $(pgrep -f loop-monitor.sh | paste -sd, -)
```
Giúp theo dõi thời gian thực mức tiêu thụ CPU, RAM và trạng thái phân bổ tài nguyên của tiến trình.

---

### Bước 4: Kiểm tra tệp tin log được ghi liên tục
Kiểm tra xem dữ liệu có được ghi đều đặn mỗi 5 giây hay không:

#### Xem 10 dòng log mới nhất:
```bash
tail -n 10 /tmp/monitor.log
```
*Kết quả:*
```text
System time: Wed Oct  7 14:20:05 UTC 2026
System time: Wed Oct  7 14:20:10 UTC 2026
System time: Wed Oct  7 14:20:15 UTC 2026
System time: Wed Oct  7 14:20:20 UTC 2026
System time: Wed Oct  7 14:20:25 UTC 2026
System time: Wed Oct  7 14:20:30 UTC 2026
System time: Wed Oct  7 14:20:35 UTC 2026
System time: Wed Oct  7 14:20:40 UTC 2026
System time: Wed Oct  7 14:20:45 UTC 2026
System time: Wed Oct  7 14:20:50 UTC 2026
```

#### Theo dõi trực tiếp (real-time stream):
```bash
tail -f /tmp/monitor.log
```
Mỗi 5 giây, một dòng thông tin thời gian hệ thống mới xuất hiện trên màn hình, chứng minh tiến trình đang chạy đúng chu kỳ.

---

### Bước 5: Kiểm chứng tính độc lập (Persistence test)
1. Đóng hẳn phiên kết nối terminal/SSH (`exit`).
2. Mở một terminal mới (hoặc SSH lại vào máy chủ).
3. Kiểm tra lại tiến trình và file log:
   ```bash
   ps aux | grep loop-monitor.sh
   tail -n 5 /tmp/monitor.log
   ```
4. **Kết quả:** Tiến trình với PID `34821` vẫn đang chạy bình thường và timestamp trong file `/tmp/monitor.log` tiếp tục được cập nhật liên tục không bị gián đoạn.

---

### Bước 6: Tắt tiến trình bằng lệnh `kill`

Quy trình chuẩn trong quản trị hệ thống Linux là luôn gửi tín hiệu kết thúc an toàn trước (`SIGTERM`), nếu sau thời gian chờ mà tiến trình vẫn bị treo/không phản hồi thì mới sử dụng tín hiệu cưỡng chế (`SIGKILL`).

#### 1. Gửi tín hiệu SIGTERM (Tín hiệu số 15 - Mặc định):
```bash
kill -15 34821
```
*(hoặc đơn giản là `kill 34821` vì 15 là tín hiệu mặc định)*

- **Cơ chế:** `SIGTERM` là tín hiệu yêu cầu tiến trình tự dọn dẹp (ghi nốt dữ liệu còn trong buffer, giải phóng file lock, đóng socket/kết nối) và kết thúc một cách an toàn (Graceful Shutdown). Tiến trình có quyền bắt (catch) hoặc bỏ qua tín hiệu này nếu được lập trình.

#### 2. Kiểm tra tiến trình sau khi gửi SIGTERM:
```bash
ps aux | grep loop-monitor.sh
```
*Kết quả:*
```text
user      34992  0.0  0.0   8900   904 pts/1    S+   14:25   0:00 grep --color=auto loop-monitor.sh
```
-> Tiến trình `34821` đã kết thúc hoàn toàn và biến mất khỏi danh sách tiến trình.

#### 3. Trường hợp dự phòng với SIGKILL (Tín hiệu số 9):
Nếu tiến trình không phản hồi sau lệnh `kill -15`:
```bash
kill -9 34821
```
- **Cơ chế:** `SIGKILL` được xử lý trực tiếp bởi Linux Kernel, tiến trình không thể bắt (catch) hay phớt lờ tín hiệu này. Kernel sẽ giải phóng bộ nhớ và tiêu diệt tiến trình ngay lập tức. Cần hạn chế lạm dụng vì có thể gây hỏng file hoặc mất dữ liệu chưa kịp flush vào ổ đĩa.

---

## 4. Bảng So Sánh Các Tín Hiệu Linux Thường Dùng

| Tên Signal | Mã Số | Mô Tả | Có Thể Bắt / Bỏ Qua? | Hành Động |
| :--- | :---: | :--- | :---: | :--- |
| **SIGHUP** | `1` | Hangup (ngắt kết nối terminal) | Có | Thường dùng để reload file cấu hình |
| **SIGINT** | `2` | Interrupt (ngắt từ bàn phím `Ctrl + C`) | Có | Yêu cầu dừng tiến trình đang chạy foreground |
| **SIGKILL** | `9` | Kill (tiêu diệt cưỡng chế) | **Không** | Kernel ép dừng ngay lập tức |
| **SIGTERM** | `15` | Terminate (yêu cầu kết thúc an toàn) | Có | Lệnh kill mặc định, dọn dẹp tài nguyên |
| **SIGSTOP** | `19` | Stop (tạm dừng tiến trình) | **Không** | Tạm dừng tiến trình (`Ctrl + Z` tương đương `SIGTSTP`) |
| **SIGCONT** | `18` | Continue (tiếp tục chạy) | Có | Đánh thức tiến trình đang bị dừng |

---

## 5. So Sánh `nohup &` Với Các Giải Pháp Khác

| Giải pháp | Đặc điểm | Trường hợp phù hợp |
| :--- | :--- | :--- |
| **`command &`** | Chạy background nhưng vẫn nhận `SIGHUP` khi đóng session | Chạy tác vụ ngắn trong phiên làm việc hiện tại |
| **`nohup command &`** | Miễn nhiễm với `SIGHUP`, đơn giản, không cần cài đặt thêm gói | Script chạy nền đơn giản, kiểm tra nhanh |
| **`screen` / `tmux`** | Duy trì cả session terminal, có thể detach và re-attach lại | Tác vụ tương tác dài hạn, debug live |
| **`systemd service`** | Tự khởi động cùng OS, quản lý lifecycle, auto restart khi crash | Ứng dụng production, daemon giám sát chính thức |

---

## 6. Tổng Kết

Qua bài thực hành, chúng ta đã:
1. Xây dựng thành công script shell tự động hóa giám sát `/tmp/monitor.log`.
2. Vận dụng hiệu quả `nohup` và toán tử `&` để cô lập tiến trình khỏi vòng đời của Terminal SSH.
3. Sử dụng thành thạo `ps aux`, `pgrep` để định danh tiến trình mục tiêu.
4. Tuân thủ nguyên tắc quản trị an toàn: Ưu tiên `SIGTERM (15)` để tắt tiến trình một cách gọn gàng, hạn chế tối đa rủi ro từ `SIGKILL (9)`.
