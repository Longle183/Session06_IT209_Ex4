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
