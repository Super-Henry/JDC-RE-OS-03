#!/bin/sh
# ----- 生成真正的转义字符 -----
ESC=$(printf '\033') 2>/dev/null
if [ -z "$ESC" ] || [ "$ESC" = "\\033" ]; then
    # 降级：尝试 echo -e
    ESC=$(echo -e '\033' 2>/dev/null)
fi

# 如果输出到终端且终端不是 dumb，且成功生成了ESC，则启用颜色
if [ -t 1 ] && [ "$TERM" != "dumb" ] && [ -n "$ESC" ] && [ "$ESC" != "\\033" ]; then
    RED="${ESC}[0;31m"
    GREEN="${ESC}[0;32m"
    YELLOW="${ESC}[0;33m"
    BLUE="${ESC}[0;34m"
    CYAN="${ESC}[0;36m"
    BOLD="${ESC}[1m"
    RESET="${ESC}[0m"
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; RESET=''
fi

# ----- ASCII Logo（无颜色）-----
cat << "EOF2"
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 -----------------------------------------------------
EOF2

echo "${BOLD}${GREEN}  Welcome, Super Henry!${RESET}"
echo "-----------------------------------------------------"

# ----- 设备IP -----
ip_addr_raw=$(ip -4 addr show br-lan 2>/dev/null | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1 | awk '{print $2}')
if [ -z "$ip_addr_raw" ]; then
    ip_addr_display="${RED}Not obtained (br-lan)${RESET}"
else
    ip_addr_display="${CYAN}${ip_addr_raw}${RESET}"
fi

# ----- 系统负载 -----
load1=$(cat /proc/loadavg | awk '{print $1}')
load5=$(cat /proc/loadavg | awk '{print $2}')
load15=$(cat /proc/loadavg | awk '{print $3}')

load_color="${GREEN}"
awk -v val="$load1" 'BEGIN{exit(val>1.0)}' || load_color="${YELLOW}"
awk -v val="$load1" 'BEGIN{exit(val>2.0)}' || load_color="${RED}"

printf "${BOLD}%-12s${RESET} : %s\n" "🌐 Device IP" "$ip_addr_display"
printf "${BOLD}%-12s${RESET} : ${load_color}%s, %s, %s${RESET}\n" "⚙️ System Load" "$load1" "$load5" "$load15"
echo "-----------------------------------------------------"

# ----- 当前时间 -----
current_time=$(date +"%Y-%m-%d %H:%M:%S")
printf "${BOLD}%-12s${RESET} : ${CYAN}%s${RESET}\n" "📅 Current Time" "$current_time"

# ----- 内存使用（KB转MB，带颜色）-----
mem_total_kb=$(free -k | awk 'NR==2 {print $2}')
mem_used_kb=$(free -k | awk 'NR==2 {print $3}')
if [ -n "$mem_total_kb" ] && [ "$mem_total_kb" -gt 0 ]; then
    mem_total_mb=$(awk "BEGIN{printf \"%.1f\", $mem_total_kb/1024}")
    mem_used_mb=$(awk "BEGIN{printf \"%.1f\", $mem_used_kb/1024}")
    mem_percent=$(awk "BEGIN{printf \"%.1f\", $mem_used_kb*100/$mem_total_kb}")
    mem_info="${mem_used_mb}MB / ${mem_total_mb}MB (${mem_percent}%)"
    # 根据百分比设置颜色
    if awk "BEGIN{exit($mem_percent>90)}"; then mem_color="${GREEN}"; elif awk "BEGIN{exit($mem_percent>70)}"; then mem_color="${YELLOW}"; else mem_color="${GREEN}"; fi
    # 修正：>90红，>70黄，其他绿
    if awk "BEGIN{exit($mem_percent>90)}"; then :; else mem_color="${RED}"; fi
    if awk "BEGIN{exit($mem_percent>70)}"; then :; else if awk "BEGIN{exit($mem_percent>90)}"; then :; else mem_color="${YELLOW}"; fi; fi
else
    mem_info="${RED}无法获取${RESET}"
    mem_color=""
fi
# 简化颜色逻辑
if [ -n "$mem_percent" ]; then
    if awk "BEGIN{exit($mem_percent>90)}"; then mem_color="${RED}"; elif awk "BEGIN{exit($mem_percent>70)}"; then mem_color="${YELLOW}"; else mem_color="${GREEN}"; fi
else
    mem_color=""
fi
printf "${BOLD}%-12s${RESET} : ${mem_color}%s${RESET}\n" "💾 Memory Usage" "$mem_info"

# ----- Swap使用 -----
swap_total_kb=$(free -k | awk 'NR==3 {print $2}')
swap_used_kb=$(free -k | awk 'NR==3 {print $3}')
if [ -n "$swap_total_kb" ] && [ "$swap_total_kb" -gt 0 ]; then
    swap_total_mb=$(awk "BEGIN{printf \"%.1f\", $swap_total_kb/1024}")
    swap_used_mb=$(awk "BEGIN{printf \"%.1f\", $swap_used_kb/1024}")
    swap_percent=$(awk "BEGIN{printf \"%.1f\", $swap_used_kb*100/$swap_total_kb}")
    swap_info="${swap_used_mb}MB / ${swap_total_mb}MB (${swap_percent}%)"
    # Swap 颜色：>50% 黄，>80% 红
    if awk "BEGIN{exit($swap_percent>80)}"; then swap_color="${RED}"; elif awk "BEGIN{exit($swap_percent>50)}"; then swap_color="${YELLOW}"; else swap_color="${GREEN}"; fi
else
    swap_info="${YELLOW}未配置${RESET}"
    swap_color=""
fi
printf "${BOLD}%-12s${RESET} : ${swap_color}%s${RESET}\n" "🔄 Swap Usage" "$swap_info"

# ----- 存储使用 -----
storage_info=$(df -h /overlay 2>/dev/null | awk 'NR==2 {used=$3; total=$2; percent=$5; printf "%s / %s (%s)", used, total, percent}')
storage_percent=$(df -h /overlay 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
if [ -n "$storage_percent" ]; then
    if [ "$storage_percent" -gt 90 ]; then storage_color="${RED}"; elif [ "$storage_percent" -gt 70 ]; then storage_color="${YELLOW}"; else storage_color="${GREEN}"; fi
else
    storage_info="${RED}无法获取${RESET}"
    storage_color=""
fi
printf "${BOLD}%-12s${RESET} : ${storage_color}%s${RESET}\n" "💽 Storage Usage" "$storage_info"

# ----- 运行时间 -----
uptime_sec=$(awk '{print int($1)}' /proc/uptime)
days=$((uptime_sec / 86400))
hours=$(((uptime_sec % 86400) / 3600))
mins=$(((uptime_sec % 3600) / 60))
if [ $days -gt 0 ]; then
    uptime_str="${days} days ${hours} hours ${mins} minutes"
else
    uptime_str="${hours} hours ${mins} minutes"
fi
printf "${BOLD}%-12s${RESET} : ${BLUE}%s${RESET}\n" "⏱️ Uptime" "$uptime_str"

# ----- LAN IP（再次显示）-----
printf "${BOLD}%-12s${RESET} : %s\n" "🏠 LAN IP" "$ip_addr_display"
echo "${GREEN}     System ready, enjoy your use!${RESET}"

echo "-----------------------------------------------------"
echo "${GREEN}firmware compilation Made by Henry ！"
echo "-----------------------------------------------------"
