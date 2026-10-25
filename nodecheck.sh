#!/usr/bin/env bash

# ==============================================================================
# NodeCheck (RU Edition) v3.3.0
# Comprehensive Node Hardware, Network Quality, Geolocation & Access Auditor
# Tailored for Russian Federation Network Realities (Reverse Geoblocking / Multi-Region)
#
# GitHub: https://github.com/justik13/nodecheck
# License: MIT
# ==============================================================================

set -o pipefail

SCRIPT_VERSION="3.4.0-ru"

CURL_TIMEOUT=4
CURL_RETRIES=0
VERBOSE=false
DEBUG=false
JSON_OUTPUT=false
IPV4_ONLY=false
IPV6_ONLY=false
USE_DOH=true
SELECTED_DOH_URL=""
PROXY_ADDR=""
INTERFACE_NAME=""
CUSTOM_DOH_PROVIDER=""
RUN_IPERF=true
RUN_FULL_IPERF=false
IPERF_TIME_DL=5
IPERF_TIME_UL=3

EXTERNAL_IPV4=""
EXTERNAL_IPV6=""
IPV4_SUPPORTED=0
IPV6_SUPPORTED=0

NODE_ASN=""
NODE_ORG=""
NODE_CITY=""
NODE_COUNTRY_CODE=""
NODE_TYPE=""
NODE_RISK=""
NODE_RISK_COLOR="0;90"
NODE_CAPTCHA_STATUS=""
NODE_CAPTCHA_COLOR="0;90"
NODE_RKN_STATUS="Checking..."
NODE_RKN_COLOR="0;90"
NODE_BBR_STATUS=""
NODE_PORT25_STATUS=""
NODE_UDP_STATUS=""

NODE_CPU_MODEL=""
NODE_CPU_CORES=1
NODE_VIRT=""
NODE_UPTIME=""
NODE_OS=""
NODE_RAM=""
NODE_DISK=""
NODE_CPU_STEAL="0.0%"
NODE_CPU_STEAL_NUM="0.0"
NODE_CPU_STEAL_ALLTIME="0.0"
NODE_CPU_STEAL_COLOR="1;32"

RU_PING_MSK=""
RU_PING_SPB=""
RU_PING_ROSTOV=""
RU_PING_KZN=""
RU_PING_EKAT=""
RU_PING_NSK=""
RU_PING_IRK=""

YOUTUBE_AD_FREE=false
YOUTUBE_DETECTED_CC=""

CHATGPT_STATSIG_API_KEY="client-zUdXdSTygXJdzoE0sWTkP8GKTVsUMF2IRM7ShVO2JAG"
YOUTUBE_SOCS_COOKIE="CAISNQgDEitib3FfaWRlbnRpdHlmcm9udGVuZHVpc2VydmVyXzIwMjUwNzMwLjA1X3AwGgJlbiACGgYIgPC_xAY"
GEMINI_REGIONS_URL="https://ai.google.dev/gemini-api/docs/available-regions.md.txt"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"

DEBUG_LOG_FILE="/tmp/nodecheck_debug.log"
TMP_WORK_DIR=""

NO_COLOR_MODE=false

COLOR_SUCCESS="1;32"
COLOR_WARN="1;33"
COLOR_DANGER="1;31"
COLOR_INFO="1;36"
COLOR_ASN="1;33"
COLOR_TABLE_VALUE="1"
COLOR_NULL="0;90"
COLOR_ERROR="1;31"
COLOR_BOLD="1"
COLOR_RESET="0"

init_colors() {
  if [[ -n "${NO_COLOR:-}" || "$NO_COLOR_MODE" == "true" ]] || ! [[ -t 1 ]]; then
    COLOR_SUCCESS=""
    COLOR_WARN=""
    COLOR_DANGER=""
    COLOR_INFO=""
    COLOR_ASN=""
    COLOR_TABLE_VALUE=""
    COLOR_NULL=""
    COLOR_ERROR=""
    COLOR_BOLD=""
    COLOR_RESET=""
  fi
}

STATUS_NA="N/A"

RESULT_JSON=""
ARR_GEOIP=()
ARR_RU_UNBLOCK=()
ARR_RU_LOCAL=()
ARR_CONNECTIVITY=()

# ISO 3166-1 alpha-2 dictionary
declare -A COUNTRY_NAMES=(
  [AF]="Afghanistan" [AL]="Albania" [DZ]="Algeria" [AD]="Andorra" [AO]="Angola"
  [AR]="Argentina" [AM]="Armenia" [AU]="Australia" [AT]="Austria" [AZ]="Azerbaijan"
  [BY]="Belarus" [BE]="Belgium" [BR]="Brazil" [BG]="Bulgaria" [CA]="Canada"
  [CN]="China" [CY]="Cyprus" [CZ]="Czechia" [DK]="Denmark" [EE]="Estonia"
  [FI]="Finland" [FR]="France" [GE]="Georgia" [DE]="Germany" [GR]="Greece"
  [HK]="Hong Kong" [HU]="Hungary" [IS]="Iceland" [IN]="India" [ID]="Indonesia"
  [IE]="Ireland" [IL]="Israel" [IT]="Italy" [JP]="Japan" [KZ]="Kazakhstan"
  [LV]="Latvia" [LT]="Lithuania" [LU]="Luxembourg" [MD]="Moldova" [NL]="Netherlands"
  [NZ]="New Zealand" [NO]="Norway" [PL]="Poland" [PT]="Portugal" [RO]="Romania"
  [RU]="Russia" [RS]="Serbia" [SG]="Singapore" [SK]="Slovakia" [SI]="Slovenia"
  [ES]="Spain" [SE]="Sweden" [CH]="Switzerland" [TR]="Turkey" [UA]="Ukraine"
  [AE]="UAE" [GB]="United Kingdom" [US]="United States" [UZ]="Uzbekistan"
  [KH]="Cambodia" [MN]="Mongolia" [MM]="Myanmar"
)

color() {
  if [[ -z "$1" || -z "$COLOR_RESET" ]]; then
    printf "%s" "$2"
  else
    printf "\033[%sm%s\033[%sm" "$1" "$2" "$COLOR_RESET"
  fi
}

bold() {
  if [[ -z "$COLOR_BOLD" ]]; then
    printf "%s" "$1"
  else
    printf "\033[%sm%s\033[%sm" "$COLOR_BOLD" "$1" "$COLOR_RESET"
  fi
}

progress_status() {
  if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
    if [[ -n "$COLOR_WARN" ]]; then
      printf "  \033[%sm⏳\033[0m %s...\r" "$COLOR_WARN" "$1"
    else
      printf "  * %s...\r" "$1"
    fi
  fi
}

progress_clear() {
  if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
    printf "\r\033[2K\r"
  fi
}

pad_str() {
  local s="$1" w="$2"
  local clean
  clean=$(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' <<<"$s")
  local len=${#clean}
  local diff=$(( w - len ))
  if (( diff > 0 )); then
    printf "%s%*s" "$s" "$diff" ""
  else
    printf "%s" "$s"
  fi
}

format_value() {
  local val="$1"
  case "$val" in
    "—")
      color "$COLOR_NULL" "—"
      ;;
    ""|"null"|"$STATUS_NA")
      color "$COLOR_NULL" "$STATUS_NA"
      ;;
    "Yes"*|"OK"*|"Clean"*|"Active"*|"Open"*|"True"|"true"|*"Protected"*|*"Closed"*)
      color "$COLOR_SUCCESS" "$val"
      ;;
    *"[Без рекламы"*|*"Без рекламы"*)
      color "$COLOR_SUCCESS" "$val"
      ;;
    "No"*|*"Captcha"*|*"Blocked"*|*"Denied"*|*"High Risk"*|*"Leaks"*|*"Timeout"*)
      color "$COLOR_DANGER" "$val"
      ;;
    *"Rate limited"*|*"Server error"*|*"Moderate"*|*"Warning"*|*"Inactive"*)
      color "$COLOR_WARN" "$val"
      ;;
    *"ms")
      local num_ms
      num_ms=$(grep -oE '^[0-9]+' <<<"$val" || echo "999")
      if (( num_ms < 60 )); then
        color "$COLOR_SUCCESS" "$val"
      elif (( num_ms < 100 )); then
        color "$COLOR_WARN" "$val"
      else
        color "$COLOR_TABLE_VALUE" "$val"
      fi
      ;;
    *"Mbps"*)
      color "$COLOR_TABLE_VALUE" "$val"
      ;;
    *)
      if [[ "$val" =~ ^[A-Z]{2}$ ]] || [[ "$val" =~ ^[A-Z]{2}\ \([A-Z0-9-]+\)$ ]]; then
        color "$COLOR_TABLE_VALUE" "$val"
      else
        printf "%s" "$val"
      fi
      ;;
  esac
}

log() {
  local level="$1"
  shift
  local msg="$*"
  if [[ "$DEBUG" == "true" ]]; then
    printf "[%s] %s\n" "$level" "$msg" >> "$DEBUG_LOG_FILE"
  fi
  if [[ "$VERBOSE" == "true" ]]; then
    printf "\033[%sm[%s]\033[0m %s\n" "$COLOR_INFO" "$level" "$msg" >&2
  fi
}

error_exit() {
  if [[ -n "$COLOR_ERROR" ]]; then
    printf "\033[%smОшибка:\033[0m %s\n" "$COLOR_ERROR" "$1" >&2
  else
    printf "Ошибка: %s\n" "$1" >&2
  fi
  cleanup
  exit 1
}

cleanup() {
  progress_clear
  if [[ -n "$TMP_WORK_DIR" && -d "$TMP_WORK_DIR" ]]; then
    rm -rf "$TMP_WORK_DIR"
  fi
}

is_command_available() { command -v "$1" >/dev/null 2>&1; }

install_dependencies() {
  local required_cmds=()
  for cmd in curl jq ping awk openssl; do
    if ! is_command_available "$cmd"; then
      if [[ "$cmd" == "ping" ]]; then
        if is_command_available "apk"; then
          required_cmds+=("iputils")
        else
          required_cmds+=("iputils-ping")
        fi
      else
        required_cmds+=("$cmd")
      fi
    fi
  done

  if ! is_command_available "column"; then
    if is_command_available "apk"; then
      required_cmds+=("util-linux-misc")
    else
      required_cmds+=("bsdextrautils")
    fi
  fi

  if [[ "$RUN_IPERF" == "true" ]] && ! is_command_available "iperf3"; then
    required_cmds+=("iperf3")
  fi

  if [[ ${#required_cmds[@]} -eq 0 ]]; then
    return 0
  fi

  progress_status "Установка недостающих пакетов (${required_cmds[*]})"
  log "INFO" "Installing missing packages: ${required_cmds[*]}"
  if is_command_available "apt-get"; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1 || true
    apt-get install -y -qq "${required_cmds[@]}" >/dev/null 2>&1 || true
  elif is_command_available "apk"; then
    apk add --no-cache "${required_cmds[@]}" >/dev/null 2>&1 || true
  elif is_command_available "yum"; then
    yum install -y -q "${required_cmds[@]}" >/dev/null 2>&1 || true
  fi
  progress_clear

  for critical in curl jq; do
    if ! is_command_available "$critical"; then
      error_exit "Необходимая утилита '$critical' не найдена. Установите: sudo apt install -y $critical"
    fi
  done
}

check_doh() {
  if [[ "$USE_DOH" != "true" ]]; then
    return 0
  fi

  if ! curl --help all 2>/dev/null | grep -q -- "--doh-url"; then
    log "WARNING" "curl lacks DoH support; using standard resolver"
    USE_DOH=false
    return 0
  fi

  case "$CUSTOM_DOH_PROVIDER" in
    quad9)     SELECTED_DOH_URL="https://dns.quad9.net/dns-query" ;;
    adguard)   SELECTED_DOH_URL="https://dns.adguard-dns.com/dns-query" ;;
    opendns)   SELECTED_DOH_URL="https://doh.opendns.com/dns-query" ;;
    cloudflare|*) SELECTED_DOH_URL="https://cloudflare-dns.com/dns-query" ;;
  esac

  # Verify DoH connectivity
  if ! curl -s -m 2 --doh-url "$SELECTED_DOH_URL" -o /dev/null "https://1.1.1.1" 2>/dev/null; then
    log "WARNING" "DoH provider ($SELECTED_DOH_URL) unreachable; using standard resolver"
    USE_DOH=false
    SELECTED_DOH_URL=""
  fi
}

curl_wrapper() {
  local method="$1"
  local url="$2"
  shift 2

  local timeout="$CURL_TIMEOUT"
  local ip_version=""
  local extra_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --timeout)
        timeout="$2"
        shift 2
        ;;
      --ip-version)
        ip_version="$2"
        shift 2
        ;;
      *)
        extra_args+=("$1")
        shift
        ;;
    esac
  done

  local curl_cmd=(curl -sS -L --connect-timeout 2 --max-time "$timeout" --retry "$CURL_RETRIES" --retry-delay 0)
  curl_cmd+=(-A "$USER_AGENT")

  if [[ "$ip_version" == "4" ]]; then
    curl_cmd+=(-4)
  elif [[ "$ip_version" == "6" ]]; then
    curl_cmd+=(-6)
  fi

  if [[ "$USE_DOH" == "true" && -n "$SELECTED_DOH_URL" ]]; then
    curl_cmd+=(--doh-url "$SELECTED_DOH_URL")
  fi

  if [[ -n "$PROXY_ADDR" ]]; then
    curl_cmd+=(--proxy "socks5h://$PROXY_ADDR")
  fi

  if [[ -n "$INTERFACE_NAME" ]]; then
    curl_cmd+=(--interface "$INTERFACE_NAME")
  fi

  curl_cmd+=(-X "$method")
  curl_cmd+=("${extra_args[@]}")
  curl_cmd+=("$url")

  "${curl_cmd[@]}" 2>/dev/null
}

curl_http_code() {
  local url="$1"
  shift
  local res
  res=$(curl_wrapper GET "$url" -o /dev/null -w "%{http_code}" "$@" 2>/dev/null)
  echo "${res:-000}"
}

discover_external_ips() {
  local ipv4_endpoints=(
    "https://api.ipify.org"
    "https://ipv4.icanhazip.com"
    "https://ifconfig.me/ip"
  )
  local ipv6_endpoints=(
    "https://api64.ipify.org"
    "https://ipv6.icanhazip.com"
  )

  if [[ "$IPV6_ONLY" != "true" ]]; then
    for ep in "${ipv4_endpoints[@]}"; do
      local ip
      ip=$(curl_wrapper GET "$ep" --ip-version "4" --timeout 3 2>/dev/null | tr -d '[:space:]')
      if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        EXTERNAL_IPV4="$ip"
        IPV4_SUPPORTED=1
        break
      fi
    done
  fi

  if [[ "$IPV4_ONLY" != "true" ]]; then
    for ep in "${ipv6_endpoints[@]}"; do
      local ip
      ip=$(curl_wrapper GET "$ep" --ip-version "6" --timeout 3 2>/dev/null | tr -d '[:space:]')
      if [[ "$ip" =~ : ]]; then
        EXTERNAL_IPV6="$ip"
        IPV6_SUPPORTED=1
        break
      fi
    done
  fi
}

get_vpn_node_info() {
  local info_raw
  info_raw=$(curl_wrapper GET "https://ipinfo.io/json" --ip-version "4" --timeout 4 2>/dev/null)

  if [[ -n "$info_raw" ]] && jq -e . >/dev/null 2>&1 <<<"$info_raw"; then
    NODE_ASN=$(jq -r '.org // ""' <<<"$info_raw" | grep -oE "AS[0-9]+" || echo "AS0")
    NODE_ORG=$(jq -r '.org // ""' <<<"$info_raw" | sed -E 's/^AS[0-9]+ //')
    NODE_CITY=$(jq -r '.city // ""' <<<"$info_raw")
    NODE_COUNTRY_CODE=$(jq -r '.country // ""' <<<"$info_raw")
  fi

  # Classification & Anti-fraud via ipquery.io
  local query_raw
  query_raw=$(curl_wrapper GET "https://api.ipquery.io/${EXTERNAL_IPV4}" --timeout 4 2>/dev/null)
  local is_vpn=false is_tor=false is_datacenter=false risk_score=""

  if [[ -n "$query_raw" ]] && jq -e . >/dev/null 2>&1 <<<"$query_raw"; then
    is_vpn=$(jq -r '.risk.is_vpn // false' <<<"$query_raw")
    is_tor=$(jq -r '.risk.is_tor // false' <<<"$query_raw")
    is_datacenter=$(jq -r '.risk.is_datacenter // false' <<<"$query_raw")
    local raw_score
    raw_score=$(jq -r '.risk.risk_score // empty' <<<"$query_raw")
    if [[ "$raw_score" =~ ^[0-9]+$ ]] && (( raw_score >= 0 && raw_score <= 100 )); then
      risk_score="$raw_score"
    fi
  fi

  if [[ "$is_datacenter" == "true" ]]; then
    NODE_TYPE="Data Center / Hosting"
  elif [[ "$is_vpn" == "true" ]]; then
    NODE_TYPE="Commercial VPN / Proxy"
  elif [[ "$is_tor" == "true" ]]; then
    NODE_TYPE="Tor Exit Node"
  elif [[ -n "$query_raw" && "$query_raw" != "null" ]]; then
    NODE_TYPE="Residential / ISP"
  else
    NODE_TYPE="Data Center / Hosting"
  fi

  if [[ -n "$risk_score" ]]; then
    if (( risk_score > 60 )); then
      NODE_RISK="High Risk / Flagged ($risk_score/100)"
      NODE_RISK_COLOR="$COLOR_DANGER"
    elif (( risk_score > 25 )); then
      NODE_RISK="Moderate Risk ($risk_score/100)"
      NODE_RISK_COLOR="$COLOR_WARN"
    else
      NODE_RISK="Clean / Low Risk ($risk_score/100)"
      NODE_RISK_COLOR="$COLOR_SUCCESS"
    fi
  else
    NODE_RISK="N/A (API Unavailable)"
    NODE_RISK_COLOR="$COLOR_NULL"
  fi

  # Google Captcha Test
  local g_search
  g_search=$(curl_wrapper GET "https://www.google.com/search?q=test" --timeout 3 2>/dev/null)
  if [[ -z "$g_search" ]]; then
    NODE_CAPTCHA_STATUS="N/A (Timeout)"
    NODE_CAPTCHA_COLOR="$COLOR_NULL"
  elif [[ "$g_search" == *"recaptcha"* || "$g_search" == *"unusual traffic"* || "$g_search" == *"our systems have detected"* ]]; then
    NODE_CAPTCHA_STATUS="Triggered (Captcha)"
    NODE_CAPTCHA_COLOR="$COLOR_DANGER"
  else
    NODE_CAPTCHA_STATUS="Clean (No Captcha)"
    NODE_CAPTCHA_COLOR="$COLOR_SUCCESS"
  fi

  # TCP BBR status
  if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q "bbr"; then
    NODE_BBR_STATUS="Active"
  else
    NODE_BBR_STATUS="Inactive"
  fi

  # Port 25 Outbound (native bash /dev/tcp with nc fallback)
  if timeout 2 bash -c 'echo > /dev/tcp/smtp.gmail.com/25' 2>/dev/null; then
    NODE_PORT25_STATUS="Open"
  elif is_command_available nc && nc -z -w 2 smtp.gmail.com 25 2>/dev/null; then
    NODE_PORT25_STATUS="Open"
  else
    NODE_PORT25_STATUS="Blocked"
  fi

  # UDP Connectivity
  if is_command_available dig && dig +short +time=1 +tries=1 @1.1.1.1 cloudflare.com >/dev/null 2>&1; then
    NODE_UDP_STATUS="Open (DNS Bidirectional)"
  elif is_command_available nslookup && nslookup -timeout=1 cloudflare.com 1.1.1.1 >/dev/null 2>&1; then
    NODE_UDP_STATUS="Open (DNS Bidirectional)"
  elif timeout 2 bash -c 'echo > /dev/udp/1.1.1.1/53' 2>/dev/null; then
    NODE_UDP_STATUS="Open (Outbound only)"
  else
    NODE_UDP_STATUS="Blocked"
  fi

  # RKN / Antifilter IP Registry Check
  if [[ -n "$EXTERNAL_IPV4" ]]; then
    local rkn_hit=false
    local rkn_list
    rkn_list=$(curl -sL --connect-timeout 2 --max-time 3 "https://antifilter.download/list/ip.lst" 2>/dev/null || echo "")
    if [[ -n "$rkn_list" ]] && grep -Fxq "$EXTERNAL_IPV4" <<<"$rkn_list"; then
      rkn_hit=true
    else
      local prefix_24
      prefix_24=$(echo "$EXTERNAL_IPV4" | sed -E 's/\.[0-9]+$/.0\/24/')
      local ipsum_list
      ipsum_list=$(curl -sL --connect-timeout 2 --max-time 3 "https://antifilter.network/download/ipsum.lst" 2>/dev/null || echo "")
      if [[ -n "$ipsum_list" ]] && grep -Fq "$prefix_24" <<<"$ipsum_list"; then
        rkn_hit=true
      fi
    fi

    if [[ "$rkn_hit" == "true" ]]; then
      NODE_RKN_STATUS="BLOCKED in RU (Antifilter Registry)"
      NODE_RKN_COLOR="$COLOR_DANGER"
    else
      NODE_RKN_STATUS="Clean (Not in Registry)"
      NODE_RKN_COLOR="$COLOR_SUCCESS"
    fi
  else
    NODE_RKN_STATUS="N/A"
    NODE_RKN_COLOR="$COLOR_NULL"
  fi
}

# ------------------------------------------------------------------------------
# 0. System Hardware & Virtualization Specs (CPU Steal, RAM, Disk, Uptime)
# ------------------------------------------------------------------------------

get_system_specs() {
  # 1. CPU Model & Cores
  NODE_CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | awk -F: '{print $2}' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' || echo "Unknown CPU")
  NODE_CPU_CORES=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1")
  if [[ -z "$NODE_CPU_MODEL" ]]; then NODE_CPU_MODEL="Generic CPU"; fi

  # 2. Virtualization & Uptime
  NODE_VIRT=$(systemd-detect-virt 2>/dev/null || echo "KVM")
  if [[ "$NODE_VIRT" == "none" ]]; then NODE_VIRT="Bare-Metal"; fi
  NODE_UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //' || uptime 2>/dev/null | awk -F'( |,|:)+' '{print $6"h "$7"m"}' || echo "N/A")

  # 3. OS & Kernel
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release 2>/dev/null
    NODE_OS="${PRETTY_NAME:-Linux} ($(uname -r) $(uname -m))"
  else
    NODE_OS="Linux ($(uname -r) $(uname -m))"
  fi

  # 4. RAM & Disk
  if is_command_available "free"; then
    NODE_RAM=$(free -m 2>/dev/null | awk '/Mem:/ {printf "%d MB / %d MB (%.1f%%)", $3, $2, ($3/$2)*100}')
  else
    NODE_RAM="N/A"
  fi
  if is_command_available "df"; then
    NODE_DISK=$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}')
  else
    NODE_DISK="N/A"
  fi

  # 5. CPU Steal measurement (Accurate 2.0s delta sample + all-time uptime ticks)
  local u1 n1 s1 i1 w1 x1 q1 st1 g1 gn1 u2 n2 s2 i2 w2 x2 q2 st2 g2 gn2
  if [[ -r /proc/stat ]]; then
    read -r _ u1 n1 s1 i1 w1 x1 q1 st1 g1 gn1 _ < /proc/stat
    local total_boot=$((u1 + n1 + s1 + i1 + w1 + x1 + q1 + st1 + ${g1:-0} + ${gn1:-0}))
    if (( total_boot > 0 )); then
      NODE_CPU_STEAL_ALLTIME=$(awk -v s="$st1" -v t="$total_boot" 'BEGIN { printf "%.2f", (s/t)*100 }')
    else
      NODE_CPU_STEAL_ALLTIME="0.00"
    fi

    sleep 2.0

    read -r _ u2 n2 s2 i2 w2 x2 q2 st2 g2 gn2 _ < /proc/stat
    local total2=$((u2 + n2 + s2 + i2 + w2 + x2 + q2 + st2 + ${g2:-0} + ${gn2:-0}))
    local diff_total=$((total2 - total_boot))
    local diff_steal=$((st2 - st1))
    if (( diff_total > 0 )); then
      NODE_CPU_STEAL_NUM=$(awk -v s="$diff_steal" -v t="$diff_total" 'BEGIN { printf "%.1f", (s/t)*100 }')
    else
      NODE_CPU_STEAL_NUM="0.0"
    fi
  else
    NODE_CPU_STEAL_NUM="0.0"
    NODE_CPU_STEAL_ALLTIME="0.00"
  fi

  local steal_int
  steal_int=$(grep -oE '^[0-9]+' <<<"$NODE_CPU_STEAL_NUM" || echo "0")
  local alltime_int
  alltime_int=$(grep -oE '^[0-9]+' <<<"$NODE_CPU_STEAL_ALLTIME" || echo "0")

  if (( steal_int > 10 || alltime_int > 5 )); then
    NODE_CPU_STEAL_COLOR="$COLOR_DANGER"
    NODE_CPU_STEAL="${NODE_CPU_STEAL_NUM}% (High Steal / Оверселл!) | ${NODE_CPU_STEAL_ALLTIME}% (за аптайм)"
  elif (( steal_int > 3 || alltime_int > 2 )); then
    NODE_CPU_STEAL_COLOR="$COLOR_WARN"
    NODE_CPU_STEAL="${NODE_CPU_STEAL_NUM}% (Moderate) | ${NODE_CPU_STEAL_ALLTIME}% (за аптайм)"
  else
    NODE_CPU_STEAL_COLOR="$COLOR_SUCCESS"
    NODE_CPU_STEAL="${NODE_CPU_STEAL_NUM}% (Clean, замер 2.0s) | ${NODE_CPU_STEAL_ALLTIME}% (за аптайм)"
  fi
}

# ------------------------------------------------------------------------------
# 1. 18 GeoIP Databases Consensus (Parallel Execution)
# ------------------------------------------------------------------------------

query_single_geoip() {
  local db_name="$1" ip_ver="$2" out_file="$3"
  local ip_val="" cc=""

  if [[ "$ip_ver" == "6" ]]; then
    ip_val="$EXTERNAL_IPV6"
  else
    ip_val="$EXTERNAL_IPV4"
  fi

  case "$db_name" in
    "IPinfo.io")
      local raw
      raw=$(curl_wrapper GET "https://ipinfo.io/${ip_val}/json" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw")
      ;;
    "IP-API.com")
      local raw
      raw=$(curl_wrapper GET "http://ip-api.com/json/${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.countryCode // empty' <<<"$raw")
      ;;
    "Cloudflare")
      local raw
      raw=$(curl_wrapper GET "https://cloudflare.com/cdn-cgi/trace" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(grep "^loc=" <<<"$raw" | head -n1 | cut -d= -f2 | tr -d '[:space:]')
      ;;
    "IP.SB")
      local raw
      raw=$(curl_wrapper GET "https://api.ip.sb/geoip/${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "Ipregistry")
      local raw
      raw=$(curl_wrapper GET "https://api.ipregistry.co/${ip_val}?key=tryout" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.location.country.code // empty' <<<"$raw")
      ;;
    "IP-API.co")
      local raw
      raw=$(curl_wrapper GET "https://ipapi.co/${ip_val}/json/" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "IP2Location.io")
      local raw
      raw=$(curl_wrapper GET "https://api.ip2location.io/?ip=${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "Country.is")
      local raw
      raw=$(curl_wrapper GET "https://api.country.is/${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw")
      ;;
    "GeoJS")
      local raw
      raw=$(curl_wrapper GET "https://get.geojs.io/v1/ip/country/${ip_val}.json" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw")
      ;;
    "2ip.io")
      local raw
      raw=$(curl_wrapper GET "https://api.2ip.io/${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.code // empty' <<<"$raw")
      ;;
    "ipwho.is")
      local raw
      raw=$(curl_wrapper GET "https://ipwho.is/${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "ifconfig.co")
      cc=$(curl_wrapper GET "https://ifconfig.co/country-iso" --ip-version "$ip_ver" --timeout 3 2>/dev/null | tr -d '[:space:]')
      ;;
    "IPLocation.net")
      local raw
      raw=$(curl_wrapper GET "https://api.iplocation.net/?ip=${ip_val}" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code2 // empty' <<<"$raw")
      ;;
    "ipbase.com")
      local raw
      raw=$(curl_wrapper GET "https://api.ipbase.com/v1/json/?ip=${ip_val}" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "ipquery.io")
      local raw
      raw=$(curl_wrapper GET "https://api.ipquery.io/${ip_val}" --timeout 3 2>/dev/null)
      cc=$(jq -r '.location.country_code // empty' <<<"$raw")
      ;;
    "IPAPI.is")
      local raw
      raw=$(curl_wrapper GET "https://api.ipapi.is/?q=${ip_val}" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // .country // empty' <<<"$raw")
      ;;
    "RIPE NCC")
      local raw
      raw=$(curl_wrapper GET "https://stat.ripe.net/data/whois/data.json?resource=${ip_val}" --timeout 3 2>/dev/null)
      cc=$(jq -r '[(.data.records[0][]? | select(.key == "country") | .value)][0] // empty' <<<"$raw")
      ;;
    "IP.Guide")
      local raw
      raw=$(curl_wrapper GET "https://ip.guide/${ip_val}" --timeout 3 2>/dev/null)
      cc=$(jq -r '.location.country // .network.autonomous_system.country // empty' <<<"$raw")
      ;;
  esac

  # Normalize 2-letter uppercase or N/A
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    cc="${cc^^}"
  elif [[ "$cc" =~ ^[A-Za-z]{3,}$ ]]; then
    # Full name fallback
    for code in "${!COUNTRY_NAMES[@]}"; do
      if [[ "${COUNTRY_NAMES[$code],,}" == "${cc,,}" ]]; then
        cc="$code"
        break
      fi
    done
  else
    cc="$STATUS_NA"
  fi

  printf "%s" "$cc" > "$out_file"
}

run_geoip_consensus() {
  local geoip_dbs=(
    "IPinfo.io" "IP-API.com" "Cloudflare" "IP.SB" "Ipregistry" "IP-API.co"
    "IP2Location.io" "Country.is" "GeoJS" "2ip.io" "ipwho.is" "ifconfig.co"
    "IPLocation.net" "ipbase.com" "ipquery.io" "IPAPI.is" "RIPE NCC" "IP.Guide"
  )

  local v4_dir="$TMP_WORK_DIR/geoip_v4"
  local v6_dir="$TMP_WORK_DIR/geoip_v6"
  mkdir -p "$v4_dir" "$v6_dir"

  # Launch parallel background queries
  for db in "${geoip_dbs[@]}"; do
    if [[ $IPV4_SUPPORTED -eq 1 ]]; then
      ( query_single_geoip "$db" "4" "$v4_dir/$db" ) &
    fi
    if [[ $IPV6_SUPPORTED -eq 1 ]]; then
      ( query_single_geoip "$db" "6" "$v6_dir/$db" ) &
    fi
  done
  wait

  for db in "${geoip_dbs[@]}"; do
    local v4="N/A" v6="N/A"
    if [[ -f "$v4_dir/$db" ]]; then
      v4=$(<"$v4_dir/$db")
    fi
    if [[ -f "$v6_dir/$db" ]]; then
      v6=$(<"$v6_dir/$db")
    fi
    ARR_GEOIP+=( "$db"$'\t'"$v4"$'\t'"$v6" )
  done
}

# ------------------------------------------------------------------------------
# 2. Western Unblock Lookups
# ------------------------------------------------------------------------------

lookup_instagram() {
  local code
  code=$(curl_http_code "https://www.instagram.com")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
}

lookup_discord() {
  local resp
  resp=$(curl_wrapper GET "https://discord.com/api/v9/gateway" --timeout 3 2>/dev/null)
  if [[ "$resp" == *"gateway.discord"* ]]; then echo "Yes"; else echo "No"; fi
}

lookup_twitter_x() {
  local code
  code=$(curl_http_code "https://x.com")
  if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
}

lookup_claude_ai() {
  local code resp
  code=$(curl_http_code "https://claude.ai")
  resp=$(curl_wrapper GET "https://claude.ai" --timeout 3 2>/dev/null)
  if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then
    echo "Yes"
  elif [[ "$code" == "403" ]]; then
    if [[ "$resp" == *"cf-mitigated"* || "$resp" == *"challenges.cloudflare.com"* || "$resp" == *"Just a moment"* ]]; then
      echo "No (403 Cloudflare Challenge)"
    else
      echo "No (403 Region Blocked)"
    fi
  else
    echo "No ($code)"
  fi
}

lookup_rutracker() {
  local code
  code=$(curl_http_code "https://rutracker.org")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
}

lookup_chatgpt() {
  local resp
  resp=$(curl_wrapper POST "https://ab.chatgpt.com/v1/initialize" --ip-version "4" \
    --header "Statsig-Api-Key: $CHATGPT_STATSIG_API_KEY" --header "Content-Type: application/json" --data '{}' 2>/dev/null)
  local cc
  cc=$(jq -r '.derived_fields.country // empty' <<<"$resp" 2>/dev/null)
  if [[ -n "$cc" ]]; then
    case "$cc" in
      RU|CN|IR|KP|CU|SY)
        echo "No ($cc - Unsupported)"
        ;;
      *)
        echo "$cc"
        ;;
    esac
  else
    local code
    code=$(curl_http_code "https://chatgpt.com")
    if [[ "$code" =~ ^(200|301|302)$ ]]; then
      echo "Yes"
    else
      echo "No ($code)"
    fi
  fi
}

lookup_google() {
  local resp result
  resp=$(curl_wrapper GET "https://accounts.google.com/v3/signin/identifier?flowName=GlifSetupAndroid" 2>/dev/null)
  result=$(sed -n 's/.*name="region" value="\([^"]*\)".*/\1/p' <<<"$resp" | head -n1)

  if [[ -z "$result" ]]; then
    resp=$(curl_wrapper GET "https://www.google.com" 2>/dev/null)
    result=$(sed -n 's/.*"[a-z]\{2\}_\([A-Z]\{2\}\)".*/\1/p' <<<"$resp" | head -n1)
  fi

  echo "${result^^}"
}

lookup_gemini() {
  local g_cc
  g_cc=$(lookup_google)
  if [[ -z "$g_cc" ]]; then
    local code
    code=$(curl_http_code "https://gemini.google.com")
    if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
    return
  fi

  local regions
  regions=$(curl_wrapper GET "$GEMINI_REGIONS_URL" --timeout 3 2>/dev/null)
  local country_name="${COUNTRY_NAMES[$g_cc]:-}"

  if [[ -n "$country_name" ]] && grep -qi "^- ${country_name}$" <<<"$regions"; then
    echo "Yes ($g_cc)"
  elif [[ -n "$regions" ]]; then
    echo "No ($g_cc - Region blocked)"
  else
    echo "Yes ($g_cc)"
  fi
}

lookup_youtube() {
  local code resp cc=""
  code=$(curl_http_code "https://www.youtube.com")
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi

  # Method 1: sw.js_data
  resp=$(curl_wrapper GET "https://www.youtube.com/sw.js_data" 2>/dev/null)
  cc=$(tail -n +3 <<<"$resp" | jq -r '.[0][2][0][0][1]' 2>/dev/null || echo "")

  # Method 2: HTML fallback
  if [[ -z "$cc" || "$cc" == "null" ]]; then
    resp=$(curl_wrapper GET "https://www.youtube.com" 2>/dev/null)
    cc=$(sed -n 's/.*"countryCode":"\([^"]*\)".*/\1/p' <<<"$resp" | head -n1)
  fi

  cc="${cc^^}"

  # Ad-free countries where Google serves zero ads:
  # AL (Albania), RU (Russia), MD (Moldova), MM (Myanmar), MN (Mongolia), KH (Cambodia)
  case "$cc" in
    AL|RU|MD|MM|MN|KH)
      echo "${cc} [Без рекламы 🎬]"
      ;;
    *)
      if [[ -n "$cc" ]]; then
        echo "$cc"
      else
        echo "Yes"
      fi
      ;;
  esac
}

lookup_youtube_cdn() {
  local resp code
  code=$(curl_http_code "https://redirector.googlevideo.com/report_mapping")
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi
  resp=$(curl_wrapper GET "https://redirector.googlevideo.com/report_mapping" 2>/dev/null)
  local iata
  iata=$(sed -n -E 's/.*=> *(tz)?([a-zA-Z]{3}).*/\2/p' <<<"$resp" | head -n 1 | tr '[:lower:]' '[:upper:]')
  if [[ -z "$iata" ]]; then
    iata=$(grep -oE "[a-z]{3}[0-9]+s[0-9]+" <<<"$resp" | head -n 1 | cut -c 1-3 | tr '[:lower:]' '[:upper:]')
  fi
  if [[ -n "$iata" ]]; then echo "Yes ($iata)"; else echo "Yes"; fi
}

lookup_youtube_premium() {
  local resp code
  code=$(curl_http_code "https://www.youtube.com/premium" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9")
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi
  resp=$(curl_wrapper GET "https://www.youtube.com/premium" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9" 2>/dev/null)
  if [[ -z "$resp" ]]; then
    echo "No (Empty)"
  elif grep -qi "YouTube Premium is not available in your country" <<<"$resp"; then
    echo "No"
  else
    echo "Yes"
  fi
}

lookup_youtube_music() {
  local resp code
  code=$(curl_http_code "https://music.youtube.com/" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9")
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi
  resp=$(curl_wrapper GET "https://music.youtube.com/" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9" 2>/dev/null)
  if [[ -z "$resp" ]]; then
    echo "No (Empty)"
  elif grep -qi "YouTube Music is not available in your area" <<<"$resp"; then
    echo "No"
  else
    echo "Yes"
  fi
}

lookup_spotify_signup() {
  local resp
  resp=$(curl_wrapper POST "https://spclient.wg.spotify.com/signup/public/v1/account" \
    --header "User-Agent: Spotify/8.8.0 Android/33" \
    --header "Content-Type: application/json" \
    --data "{}" 2>/dev/null)
  if jq -e . >/dev/null 2>&1 <<<"$resp"; then echo "Yes"; else echo "No"; fi
}

lookup_netflix() {
  local code resp cc=""
  code=$(curl_http_code "https://www.netflix.com")
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi
  resp=$(curl_wrapper GET "https://www.netflix.com" 2>/dev/null)
  local cc
  cc=$(sed -n 's/.*"geolocation_country":"\([^"]*\)".*/\1/p' <<<"$resp" | head -n 1)
  if [[ -n "$cc" ]]; then echo "$cc"; else echo "Yes"; fi
}

lookup_apple() {
  local cc
  cc=$(curl_wrapper GET "https://gspe1-ssl.ls.apple.com/pep/gcc" --timeout 3 2>/dev/null)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  elif [[ -n "$cc" ]]; then
    echo "Yes"
  else
    echo "No (Timeout)"
  fi
}

lookup_steam() {
  local code
  code=$(curl_http_code "https://store.steampowered.com")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
}

lookup_playstation() {
  local code
  code=$(curl_http_code "https://www.playstation.com")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
}

lookup_reddit() {
  local code
  code=$(curl_http_code "https://www.reddit.com")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
}

lookup_signal() {
  local code
  code=$(curl_http_code "https://chat.signal.org")
  if [[ "$code" =~ ^(200|301|302|404)$ ]]; then
    echo "Yes"
  elif [[ "$code" == "000" ]]; then
    echo "No (Timeout / TSPU Block)"
  else
    echo "No ($code)"
  fi
}

lookup_notion() {
  local code
  code=$(curl_http_code "https://www.notion.so")
  if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then
    echo "Yes"
  elif [[ "$code" == "403" ]]; then
    echo "No (403 Geoblocked)"
  else
    echo "No ($code)"
  fi
}

# ------------------------------------------------------------------------------
# 3. RU Reverse Geoblocking Lookups
# ------------------------------------------------------------------------------

# Uses -k to validate reachability even when Russian Минцифры CA is not in system trust store
curl_ru_code() {
  local url="$1" timeout="${2:-4}"
  local res
  res=$(curl_wrapper GET "$url" -k --timeout "$timeout" -o /dev/null -w "%{http_code}" 2>/dev/null)
  res="${res: -3}"
  echo "${res:-000}"
}

lookup_gosuslugi() {
  local code
  code=$(curl_ru_code "https://www.gosuslugi.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked ($code)"; fi
}

lookup_nalog() {
  local code
  code=$(curl_ru_code "https://nalog.gov.ru" 4)
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_mosru() {
  local code
  code=$(curl_ru_code "https://www.mos.ru" 4)
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_rzd() {
  local code
  code=$(curl_ru_code "https://ticket.rzd.ru" 4)
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_yandex() {
  local resp
  resp=$(curl_wrapper GET "https://ya.ru" -k --timeout 3 2>/dev/null)
  if [[ "$resp" == *"smartcaptcha"* || "$resp" == *"showcaptcha"* ]]; then
    echo "Captcha"
  elif [[ -n "$resp" ]]; then
    echo "OK"
  else
    echo "Blocked (Timeout)"
  fi
}

lookup_vk() {
  local code
  code=$(curl_ru_code "https://vk.com")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked ($code)"; fi
}

lookup_sberbank() {
  local code
  code=$(curl_ru_code "https://www.sberbank.ru" 4)
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_tbank() {
  local code
  code=$(curl_ru_code "https://tbank.ru" 4)
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_vtb() {
  local code
  code=$(curl_ru_code "https://www.vtb.ru" 4)
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_alfabank() {
  local code
  code=$(curl_ru_code "https://alfabank.ru" 4)
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_avito() {
  local code resp
  resp=$(curl_wrapper GET "https://www.avito.ru" -k --timeout 3 2>/dev/null)
  code=$(curl_ru_code "https://www.avito.ru" 3)
  if [[ "$code" == "439" || "$code" == "429" || "$resp" == *"QRATOR"* || "$resp" == *"firewallCaptcha"* || "$resp" == *"pow_challenge"* ]]; then
    echo "Blocked (439 Qrator Captcha)"
  elif [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_wildberries() {
  local code
  code=$(curl_ru_code "https://www.wildberries.ru" 4)
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  elif [[ "$code" =~ ^(498|403|429)$ ]]; then
    echo "Blocked (WAF $code)"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_ozon() {
  local code body
  code=$(curl_ru_code "https://www.ozon.ru" 4)
  if [[ "$code" == "307" || "$code" =~ ^(200|301|302)$ ]]; then
    body=$(curl_wrapper GET "https://www.ozon.ru" -k -L -b dummy --timeout 4 2>/dev/null)
    if [[ "$body" == *"abt-challenge"* || "$body" == *"Выключите VPN"* || "$body" == *"Похоже, нет соединения"* ]]; then
      echo "Blocked (Anti-VPN 403)"
    else
      echo "OK"
    fi
  elif [[ "$code" =~ ^(403|429)$ ]]; then
    echo "Blocked (WAF $code)"
  elif [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
  else
    echo "Blocked ($code)"
  fi
}

lookup_kinopoisk() {
  local code
  code=$(curl_ru_code "https://www.kinopoisk.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked ($code)"; fi
}

run_services_check() {
  local s_dir="$TMP_WORK_DIR/services"
  mkdir -p "$s_dir"

  # Parallel execution of 26 censorship and domestic checks
  ( lookup_instagram > "$s_dir/instagram" ) &
  ( lookup_discord > "$s_dir/discord" ) &
  ( lookup_twitter_x > "$s_dir/twitter" ) &
  ( lookup_chatgpt > "$s_dir/chatgpt" ) &
  ( lookup_claude_ai > "$s_dir/claude" ) &
  ( lookup_google > "$s_dir/google" ) &
  ( lookup_gemini > "$s_dir/gemini" ) &
  ( lookup_youtube > "$s_dir/youtube" ) &
  ( lookup_youtube_cdn > "$s_dir/youtube_cdn" ) &
  ( lookup_youtube_premium > "$s_dir/youtube_premium" ) &
  ( lookup_youtube_music > "$s_dir/youtube_music" ) &
  ( lookup_rutracker > "$s_dir/rutracker" ) &
  ( lookup_spotify_signup > "$s_dir/spotify" ) &
  ( lookup_netflix > "$s_dir/netflix" ) &
  ( lookup_steam > "$s_dir/steam" ) &
  ( lookup_playstation > "$s_dir/playstation" ) &
  ( lookup_reddit > "$s_dir/reddit" ) &
  ( lookup_apple > "$s_dir/apple" ) &
  ( lookup_signal > "$s_dir/signal" ) &
  ( lookup_notion > "$s_dir/notion" ) &

  ( lookup_gosuslugi > "$s_dir/gosuslugi" ) &
  ( lookup_nalog > "$s_dir/nalog" ) &
  ( lookup_mosru > "$s_dir/mosru" ) &
  ( lookup_rzd > "$s_dir/rzd" ) &
  ( lookup_yandex > "$s_dir/yandex" ) &
  ( lookup_vk > "$s_dir/vk" ) &
  ( lookup_sberbank > "$s_dir/sberbank" ) &
  ( lookup_tbank > "$s_dir/tbank" ) &
  ( lookup_vtb > "$s_dir/vtb" ) &
  ( lookup_alfabank > "$s_dir/alfabank" ) &
  ( lookup_avito > "$s_dir/avito" ) &
  ( lookup_wildberries > "$s_dir/wildberries" ) &
  ( lookup_ozon > "$s_dir/ozon" ) &
  ( lookup_kinopoisk > "$s_dir/kinopoisk" ) &

  wait

  local yt_res
  yt_res=$(<"$s_dir/youtube")
  YOUTUBE_DETECTED_CC=$(awk '{print $1}' <<<"$yt_res")
  if [[ "$yt_res" == *"Без рекламы"* ]]; then
    YOUTUBE_AD_FREE=true
  fi

  ARR_RU_UNBLOCK+=( "Instagram (Meta)"$'\t'"$(<"$s_dir/instagram")" )
  ARR_RU_UNBLOCK+=( "Discord (Voice/Gateway)"$'\t'"$(<"$s_dir/discord")" )
  ARR_RU_UNBLOCK+=( "Twitter / X"$'\t'"$(<"$s_dir/twitter")" )
  ARR_RU_UNBLOCK+=( "OpenAI ChatGPT"$'\t'"$(<"$s_dir/chatgpt")" )
  ARR_RU_UNBLOCK+=( "Anthropic Claude AI"$'\t'"$(<"$s_dir/claude")" )
  ARR_RU_UNBLOCK+=( "Google (Регион)"$'\t'"$(<"$s_dir/google")" )
  ARR_RU_UNBLOCK+=( "Google Gemini"$'\t'"$(<"$s_dir/gemini")" )
  ARR_RU_UNBLOCK+=( "YouTube"$'\t'"$yt_res" )
  ARR_RU_UNBLOCK+=( "YouTube CDN"$'\t'"$(<"$s_dir/youtube_cdn")" )
  ARR_RU_UNBLOCK+=( "YouTube Premium"$'\t'"$(<"$s_dir/youtube_premium")" )
  ARR_RU_UNBLOCK+=( "YouTube Music"$'\t'"$(<"$s_dir/youtube_music")" )
  ARR_RU_UNBLOCK+=( "Rutracker"$'\t'"$(<"$s_dir/rutracker")" )
  ARR_RU_UNBLOCK+=( "Spotify Signup"$'\t'"$(<"$s_dir/spotify")" )
  ARR_RU_UNBLOCK+=( "Netflix"$'\t'"$(<"$s_dir/netflix")" )
  ARR_RU_UNBLOCK+=( "Steam Store (Игры)"$'\t'"$(<"$s_dir/steam")" )
  ARR_RU_UNBLOCK+=( "PlayStation Network"$'\t'"$(<"$s_dir/playstation")" )
  ARR_RU_UNBLOCK+=( "Reddit"$'\t'"$(<"$s_dir/reddit")" )
  ARR_RU_UNBLOCK+=( "Apple Services"$'\t'"$(<"$s_dir/apple")" )
  ARR_RU_UNBLOCK+=( "Signal"$'\t'"$(<"$s_dir/signal")" )
  ARR_RU_UNBLOCK+=( "Notion"$'\t'"$(<"$s_dir/notion")" )

  ARR_RU_LOCAL+=( "Госуслуги (gosuslugi.ru)"$'\t'"$(<"$s_dir/gosuslugi")" )
  ARR_RU_LOCAL+=( "ФНС (nalog.gov.ru)"$'\t'"$(<"$s_dir/nalog")" )
  ARR_RU_LOCAL+=( "Мос.ру (mos.ru)"$'\t'"$(<"$s_dir/mosru")" )
  ARR_RU_LOCAL+=( "РЖД (ticket.rzd.ru)"$'\t'"$(<"$s_dir/rzd")" )
  ARR_RU_LOCAL+=( "Яндекс (ya.ru)"$'\t'"$(<"$s_dir/yandex")" )
  ARR_RU_LOCAL+=( "ВКонтакте (vk.com)"$'\t'"$(<"$s_dir/vk")" )
  ARR_RU_LOCAL+=( "СберБанк (sberbank.ru)"$'\t'"$(<"$s_dir/sberbank")" )
  ARR_RU_LOCAL+=( "Т-Банк (tbank.ru)"$'\t'"$(<"$s_dir/tbank")" )
  ARR_RU_LOCAL+=( "ВТБ (vtb.ru)"$'\t'"$(<"$s_dir/vtb")" )
  ARR_RU_LOCAL+=( "Альфа-Банк (alfabank.ru)"$'\t'"$(<"$s_dir/alfabank")" )
  ARR_RU_LOCAL+=( "Авито (avito.ru)"$'\t'"$(<"$s_dir/avito")" )
  ARR_RU_LOCAL+=( "Wildberries (wildberries.ru)"$'\t'"$(<"$s_dir/wildberries")" )
  ARR_RU_LOCAL+=( "Озон (ozon.ru)"$'\t'"$(<"$s_dir/ozon")" )
  ARR_RU_LOCAL+=( "Кинопоиск (kinopoisk.ru)"$'\t'"$(<"$s_dir/kinopoisk")" )
}

# ------------------------------------------------------------------------------
# 4. Multi-Region RU Connectivity & Speed
# ------------------------------------------------------------------------------

ping_host() {
  local host="$1" out_file="$2"
  local p
  p=$(LC_ALL=C ping -c 2 -W 2 "$host" 2>/dev/null | tail -n 1 | awk -F '/' '{print $5}')
  if [[ -n "$p" && "$p" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    printf "%.1f ms" "$p" > "$out_file"
  else
    printf "N/A" > "$out_file"
  fi
}

iperf_speed_test() {
  local host="$1"
  local fallback_host="${2:-}"
  local label="$3"
  local ping_val="$4"
  local ports=(5201 5202 5203 5204 5205 5206 5207 5208 5209)

  local target_hosts=("$host")
  if [[ -n "$fallback_host" && "$fallback_host" != "$host" ]]; then
    target_hosts+=("$fallback_host")
  fi

  local time_dl="$IPERF_TIME_DL"
  local time_ul="$IPERF_TIME_UL"

  for cur_host in "${target_hosts[@]}"; do
    for p in "${ports[@]}"; do
      # Fast TCP pre-check (0.8s timeout)
      if ! timeout 0.8 bash -c "echo > /dev/tcp/$cur_host/$p" 2>/dev/null; then
        continue
      fi

      # 1. Download (Server -> Client, Reverse mode -R)
      if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
        if [[ -n "$COLOR_WARN" ]]; then
          printf "  %s  %s  \033[%sm⏳ Замер DL (%ss)...\033[0m\r" \
            "$(pad_str "$label" 38)" "$(pad_str "$ping_val" 14)" "$COLOR_WARN" "$time_dl"
        else
          printf "  %s  %s  * Замер DL (%ss)...\r" \
            "$(pad_str "$label" 38)" "$(pad_str "$ping_val" 14)" "$time_dl"
        fi
      fi

      local res_dl dl_bps dl="—"
      res_dl=$(timeout $((time_dl + 3)) iperf3 -c "$cur_host" -p "$p" -R -t "$time_dl" -P 2 -J 2>/dev/null || echo "")
      if [[ -n "$res_dl" ]]; then
        dl_bps=$(jq -r '.end.sum_received.bits_per_second // .end.sum_sent.bits_per_second // 0' <<<"$res_dl")
        if (( $(awk -v a="$dl_bps" 'BEGIN { print (a > 1000000) ? 1 : 0 }') )); then
          dl=$(awk -v b="$dl_bps" 'BEGIN { printf "%d Mbps", (b/1000000)+0.5 }')
        fi
      fi

      # 2. Upload (Client -> Server, Normal mode)
      if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
        local dl_hint="↓ $dl"
        if [[ "$dl" == "—" ]]; then dl_hint="DL —"; fi
        if [[ -n "$COLOR_WARN" ]]; then
          printf "  %s  %s  \033[%sm⏳ Замер UL (%ss) [%s]...\033[0m\r" \
            "$(pad_str "$label" 38)" "$(pad_str "$ping_val" 14)" "$COLOR_WARN" "$time_ul" "$dl_hint"
        else
          printf "  %s  %s  * Замер UL (%ss) [%s]...\r" \
            "$(pad_str "$label" 38)" "$(pad_str "$ping_val" 14)" "$time_ul" "$dl_hint"
        fi
      fi

      local res_ul ul_bps ul="—"
      res_ul=$(timeout $((time_ul + 3)) iperf3 -c "$cur_host" -p "$p" -t "$time_ul" -P 2 -J 2>/dev/null || echo "")
      if [[ -n "$res_ul" ]]; then
        ul_bps=$(jq -r '.end.sum_received.bits_per_second // .end.sum_sent.bits_per_second // 0' <<<"$res_ul")
        if (( $(awk -v a="$ul_bps" 'BEGIN { print (a > 1000000) ? 1 : 0 }') )); then
          ul=$(awk -v b="$ul_bps" 'BEGIN { printf "%d Mbps", (b/1000000)+0.5 }')
        fi
      fi

      if [[ "$dl" != "—" || "$ul" != "—" ]]; then
        local note=""
        if [[ "$cur_host" == "$fallback_host" ]]; then note=" (F)"; fi
        echo "↓ $dl / ↑ $ul$note"
        return
      fi
    done
  done

  echo "—"
}

measure_ru_pings() {
  local p_dir="$TMP_WORK_DIR/pings"
  mkdir -p "$p_dir"

  # Ping 7 macro-regions across Russia in parallel
  ( ping_host "spd-rudp.hostkey.ru" "$p_dir/msk" ) &
  ( ping_host "st.spb.ertelecom.ru" "$p_dir/spb" ) &
  ( ping_host "st.kzn.ertelecom.ru" "$p_dir/kzn" ) &
  ( ping_host "st.rostov.ertelecom.ru" "$p_dir/rostov" ) &
  ( ping_host "st.ekat.ertelecom.ru" "$p_dir/ekat" ) &
  ( ping_host "st.nsk.ertelecom.ru" "$p_dir/nsk" ) &
  ( ping_host "st.irkutsk.ertelecom.ru" "$p_dir/irk" ) &
  wait

  RU_PING_MSK=$(<"$p_dir/msk")
  RU_PING_SPB=$(<"$p_dir/spb")
  RU_PING_KZN=$(<"$p_dir/kzn")
  RU_PING_ROSTOV=$(<"$p_dir/rostov")
  RU_PING_EKAT=$(<"$p_dir/ekat")
  RU_PING_NSK=$(<"$p_dir/nsk")
  RU_PING_IRK=$(<"$p_dir/irk")
}

measure_ru_iperf() {
  local regions=(
    "Москва (Центр, Hostkey / MSK-IX)"$'\t'"$RU_PING_MSK"$'\t'"spd-rudp.hostkey.ru"$'\t'"st.tver.ertelecom.ru"
    "Санкт-Петербург (Северо-Запад, SPB)"$'\t'"$RU_PING_SPB"$'\t'"st.spb.ertelecom.ru"$'\t'"st.yar.ertelecom.ru"
    "Казань (Поволжье, ER-Telecom)"$'\t'"$RU_PING_KZN"$'\t'"st.kzn.ertelecom.ru"$'\t'"st.chelny.ertelecom.ru"
    "Ростов-на-Дону (Юг, ER-Telecom)"$'\t'"$RU_PING_ROSTOV"$'\t'"st.rostov.ertelecom.ru"$'\t'"st.volgograd.ertelecom.ru"
    "Екатеринбург (Урал, ER-Telecom)"$'\t'"$RU_PING_EKAT"$'\t'"st.ekat.ertelecom.ru"$'\t'"st.chel.ertelecom.ru"
    "Новосибирск (Сибирь, ER-Telecom)"$'\t'"$RU_PING_NSK"$'\t'"st.nsk.ertelecom.ru"$'\t'"st.tomsk.ertelecom.ru"
    "Иркутск (Восточная Сибирь, ER)"$'\t'"$RU_PING_IRK"$'\t'"st.irkutsk.ertelecom.ru"$'\t'"st.krsk.ertelecom.ru"
  )

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "  %s  %s  %s\n" \
      "$(pad_str "Регион (Узел связи)" 38)" \
      "$(pad_str "Задержка (RTT)" 14)" \
      "Скорость (↓ DL / ↑ UL)"
    printf "  %s  %s  %s\n" \
      "$(pad_str "--------------------------------------" 38)" \
      "$(pad_str "--------------" 14)" \
      "-----------------------"
  fi

  for reg_entry in "${regions[@]}"; do
    IFS=$'\t' read -r label ping_val host fallback_host <<<"$reg_entry"
    local speed="—"

    if [[ "$RUN_IPERF" == "true" || "$RUN_FULL_IPERF" == "true" ]] && is_command_available "iperf3"; then
      speed=$(iperf_speed_test "$host" "$fallback_host" "$label" "$ping_val")
    fi

    ARR_CONNECTIVITY+=( "$label"$'\t'"$ping_val"$'\t'"$speed" )

    if [[ "$JSON_OUTPUT" != "true" ]]; then
      if [[ -t 1 ]]; then
        printf "\r\033[2K  %s  %s  %s\n" \
          "$(pad_str "$label" 38)" \
          "$(pad_str "$(format_value "$ping_val")" 14)" \
          "$(format_value "$speed")"
      else
        printf "  %s  %s  %s\n" \
          "$(pad_str "$label" 38)" \
          "$(pad_str "$ping_val" 14)" \
          "$speed"
      fi
    fi
  done

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    if ! is_command_available "iperf3"; then
      if [[ -n "$COLOR_NULL" ]]; then
        printf "  \033[%sm* Для замера пропускной способности iPerf3: apt install -y iperf3\033[0m\n" "$COLOR_NULL"
      else
        printf "  * Для замера пропускной способности iPerf3: apt install -y iperf3\n"
      fi
    fi
    printf "\n"
  fi
}

# ------------------------------------------------------------------------------
# Output Formatting
# ------------------------------------------------------------------------------

format_table() {
  if is_command_available column; then
    column -t -s $'\t'
  else
    awk -F '\t' '{
      for (i=1; i<=NF; i++) {
        clean = $i; gsub(/\033\[[0-9;]*m/, "", clean)
        if (length(clean) > w[i]) w[i] = length(clean)
      }
      rows[NR] = $0
    }
    END {
      for (r=1; r<=NR; r++) {
        n = split(rows[r], cols, "\t")
        line = ""
        for (i=1; i<=n; i++) {
          clean = cols[i]; gsub(/\033\[[0-9;]*m/, "", clean)
          pad = w[i] - length(clean) + 2
          line = line cols[i] sprintf("%*s", (i==n ? 0 : pad), "")
        }
        print line
      }
    }'
  fi
}

print_header() {
  local line_sep
  line_sep=$(printf '%0.s=' {1..80})
  if [[ -n "$COLOR_INFO" ]]; then
    printf "\033[%sm%s\033[0m\n" "$COLOR_INFO" "$line_sep"
    printf " 🇷🇺 \033[%smNodeCheck (RU Edition) - Node & Network Quality Auditor v%s\033[0m\n" "$COLOR_BOLD" "$SCRIPT_VERSION"
    printf "\033[%sm%s\033[0m\n" "$COLOR_INFO" "$line_sep"
  else
    printf "%s\n" "$line_sep"
    printf " 🇷🇺 NodeCheck (RU Edition) - Node & Network Quality Auditor v%s\n" "$SCRIPT_VERSION"
    printf "%s\n" "$line_sep"
  fi
  {
    echo -e " IPv4:\t$(bold "${EXTERNAL_IPV4:-N/A}")"
    if [[ -n "$EXTERNAL_IPV6" ]]; then
      echo -e " IPv6:\t$(bold "$EXTERNAL_IPV6")"
    else
      echo -e " IPv6:\t$(color "$COLOR_NULL" "None (Not configured)")"
    fi
    echo -e " Локация / ASN:\t$(color "$COLOR_ASN" "$NODE_COUNTRY_CODE ($NODE_CITY)") — $NODE_ASN ($NODE_ORG)"
    echo -e " ОС и ядро:\t$(bold "$NODE_OS")"
    echo -e " Платформа:\t$(bold "${NODE_VIRT^^}") | Аптайм: $(bold "$NODE_UPTIME")"
    echo -e " Процессор (CPU):\t$(bold "$NODE_CPU_MODEL") (${NODE_CPU_CORES} vCPU)"
    echo -e " CPU Steal:\t$(color "$NODE_CPU_STEAL_COLOR" "$NODE_CPU_STEAL")"
    echo -e " Память / Диск:\tRAM: $(bold "$NODE_RAM") | Диск: $(bold "$NODE_DISK")"
    echo -e " Тип хоста:\t$(bold "$NODE_TYPE")"
    echo -e " Реестр РКН:\t$(color "$NODE_RKN_COLOR" "$NODE_RKN_STATUS")"
    echo -e " Антифрод / Риск:\t$(color "$NODE_RISK_COLOR" "$NODE_RISK"), Google Captcha: $(color "$NODE_CAPTCHA_COLOR" "$NODE_CAPTCHA_STATUS")"
    echo -e " Сетевой стек:\tBBR: $(format_value "$NODE_BBR_STATUS") | UDP: $(format_value "$NODE_UDP_STATUS") | Port 25: $(format_value "$NODE_PORT25_STATUS")"
  } | format_table
  if [[ -n "$COLOR_INFO" ]]; then
    printf "\033[%sm%s\033[0m\n\n" "$COLOR_INFO" "$line_sep"
  else
    printf "%s\n\n" "$line_sep"
  fi
}

calculate_geoip_stats() {
  local top_code="" top_count=0 total=0
  declare -A counts=()

  for row in "${ARR_GEOIP[@]}"; do
    IFS=$'\t' read -r _ v4 _ <<<"$row"
    if [[ "$v4" =~ ^[A-Z]{2}$ ]]; then
      counts["$v4"]=$(( counts["$v4"] + 1 ))
      total=$(( total + 1 ))
    fi
  done

  if (( total == 0 )); then
    return
  fi

  for c in "${!counts[@]}"; do
    if (( counts["$c"] > top_count )); then
      top_count=${counts["$c"]}
      top_code="$c"
    fi
  done

  local top_pct
  top_pct=$(awk "BEGIN { printf \"%.1f\", ($top_count / $total) * 100 }")
  local top_country="${COUNTRY_NAMES[$top_code]:-Unknown}"

  local consensus_color="$COLOR_SUCCESS"
  local top_pct_int
  top_pct_int=$(awk "BEGIN { print int(($top_count / $total) * 100) }")
  if (( top_pct_int < 50 )); then
    consensus_color="$COLOR_DANGER"
  elif (( top_pct_int < 80 )); then
    consensus_color="$COLOR_WARN"
  fi

  if [[ -n "$consensus_color" ]]; then
    printf "  Консенсус: \033[%sm%s (%s)\033[0m — %s/%s (%s%%)\n\n" "$consensus_color" "$top_code" "$top_country" "$top_count" "$total" "$top_pct"
  else
    printf "  Консенсус: %s (%s) — %s/%s (%s%%)\n\n" "$top_code" "$top_country" "$top_count" "$total" "$top_pct"
  fi

  {
    echo -e "  Код\tСтрана\tДоля (IPv4)"
    echo -e "  ---\t------\t-----------"
    for c in "${!counts[@]}"; do
      echo -e "${counts[$c]}\t$c"
    done | sort -rn | while read -r cnt c; do
      local pct
      pct=$(awk "BEGIN { printf \"%.1f\", ($cnt / $total) * 100 }")
      local country="${COUNTRY_NAMES[$c]:-$c}"
      echo -e "  $c\t$country\t$pct% ($cnt/$total)"
    done
  } | format_table
  printf "\n"
}

print_geoip_table() {
  printf "\033[1m1. 📍 Консенсус GeoIP баз данных (18 источников)\033[0m\n"
  if [[ $IPV6_SUPPORTED -eq 1 ]]; then
    {
      echo -e "  База данных\tIPv4\tIPv6"
      echo -e "  ------------------------\t------------\t------------"
      for row in "${ARR_GEOIP[@]}"; do
        IFS=$'\t' read -r name v4 v6 <<<"$row"
        echo -e "  $name\t$(format_value "$v4")\t$(format_value "$v6")"
      done
    } | format_table
  else
    {
      echo -e "  База данных\tСтрана (IPv4)"
      echo -e "  ----------------------------\t-------------"
      for row in "${ARR_GEOIP[@]}"; do
        IFS=$'\t' read -r name v4 _ <<<"$row"
        echo -e "  $name\t$(format_value "$v4")"
      done
    } | format_table
  fi
  printf "\n"
  calculate_geoip_stats
}

print_western_unblock_table() {
  printf "\033[1m2. 🌍 Доступность зарубежных сервисов (Western Services)\033[0m\n"
  {
    echo -e "  Сервис\tСтатус"
    echo -e "  ------------------------------------\t------"
    for row in "${ARR_RU_UNBLOCK[@]}"; do
      IFS=$'\t' read -r name val <<<"$row"
      echo -e "  $name\t$(format_value "$val")"
    done
  } | format_table
  printf "\n"
}

print_ru_local_table() {
  printf "\033[1m3. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)\033[0m\n"
  {
    echo -e "  Сервис\tСтатус"
    echo -e "  ------------------------------------\t------"
    for row in "${ARR_RU_LOCAL[@]}"; do
      IFS=$'\t' read -r name val <<<"$row"
      echo -e "  $name\t$(format_value "$val")"
    done
  } | format_table
  printf "\n"
}

print_connectivity_table() {
  {
    echo -e "  Регион (Узел связи)\tЗадержка (RTT)\tСкорость (↓ DL / ↑ UL)"
    echo -e "  ------------------------------------\t--------------\t-----------------------"
    for row in "${ARR_CONNECTIVITY[@]}"; do
      IFS=$'\t' read -r name ping_val speed_val <<<"$row"
      echo -e "  $name\t$(format_value "$ping_val")\t$(format_value "$speed_val")"
    done
  } | format_table
  if ! is_command_available "iperf3"; then
    if [[ -n "$COLOR_NULL" ]]; then
      printf "  \033[%sm* Для замера пропускной способности iPerf3: apt install -y iperf3\033[0m\n" "$COLOR_NULL"
    else
      printf "  * Для замера пропускной способности iPerf3: apt install -y iperf3\n"
    fi
  fi
  printf "\n"
}

print_executive_summary() {
  local ru_total=${#ARR_RU_LOCAL[@]}
  local ru_ok=0
  for row in "${ARR_RU_LOCAL[@]}"; do
    IFS=$'\t' read -r _ val <<<"$row"
    if [[ "$val" == "OK"* ]]; then
      ru_ok=$((ru_ok + 1))
    fi
  done

  local west_total=${#ARR_RU_UNBLOCK[@]}
  local west_ok=0
  for row in "${ARR_RU_UNBLOCK[@]}"; do
    IFS=$'\t' read -r _ val <<<"$row"
    if [[ "$val" != "No"* ]]; then
      west_ok=$((west_ok + 1))
    fi
  done

  local line_sep
  line_sep=$(printf '%0.s─' {1..80})
  if [[ -n "$COLOR_INFO" ]]; then
    printf "\033[%sm%s\033[0m\n" "$COLOR_INFO" "$line_sep"
    printf " \033[1m📊 Итоговый вердикт качества ноды под аудиторию РФ\033[0m\n"
    printf "\033[%sm%s\033[0m\n" "$COLOR_INFO" "$line_sep"
  else
    printf "%s\n" "$line_sep"
    printf " 📊 Итоговый вердикт качества ноды под аудиторию РФ\n"
    printf "%s\n" "$line_sep"
  fi

  local verdict_str verdict_color
  if [[ "$NODE_RKN_STATUS" == *"BLOCKED"* ]]; then
    verdict_str="Критично: IP ноды заблокирован в РФ (реестр РКН)"
    verdict_color="$COLOR_DANGER"
  elif (( ru_ok >= 11 && west_ok >= 16 )); then
    verdict_str="Отлично: подходит для VPN/прокси под РФ (доступ к Западу + нет гео-блокировок РФ)"
    verdict_color="$COLOR_SUCCESS"
  elif (( ru_ok >= 8 && west_ok >= 12 )); then
    verdict_str="Удовлетворительно: базовые сервисы доступны, возможны ограничения части сервисов"
    verdict_color="$COLOR_WARN"
  else
    verdict_str="Проблемная нода: высокий риск блокировок или утечек региона"
    verdict_color="$COLOR_DANGER"
  fi

  {
    echo -e "  Вердикт качества:\t$(color "$verdict_color" "$verdict_str")"
    echo -e "  Зарубежные сервисы:\t$(format_value "$west_ok/$west_total доступны")"
    echo -e "  Ресурсы РФ (Reverse Geo):\t$(format_value "$ru_ok/$ru_total открываются")"
    echo -e "  Репутация IP и РКН:\t$NODE_RKN_STATUS | $NODE_RISK"
  } | format_table
  if [[ -n "$COLOR_INFO" ]]; then
    printf "\033[%sm%s\033[0m\n\n" "$COLOR_INFO" "$line_sep"
  else
    printf "%s\n\n" "$line_sep"
  fi
}

build_json() {
  local geoip_json="{}"
  for row in "${ARR_GEOIP[@]}"; do
    IFS=$'\t' read -r name v4 v6 <<<"$row"
    geoip_json=$(jq --arg k "$name" --arg v4 "$v4" --arg v6 "$v6" '.[$k] = {ipv4: $v4, ipv6: $v6}' <<<"$geoip_json")
  done

  local unblock_json="{}"
  for row in "${ARR_RU_UNBLOCK[@]}"; do
    IFS=$'\t' read -r name val <<<"$row"
    unblock_json=$(jq --arg k "$name" --arg v "$val" '.[$k] = $v' <<<"$unblock_json")
  done

  local local_json="{}"
  for row in "${ARR_RU_LOCAL[@]}"; do
    IFS=$'\t' read -r name val <<<"$row"
    local_json=$(jq --arg k "$name" --arg v "$val" '.[$k] = $v' <<<"$local_json")
  done

  local conn_json="{}"
  for row in "${ARR_CONNECTIVITY[@]}"; do
    IFS=$'\t' read -r name ping_val speed_val <<<"$row"
    conn_json=$(jq --arg k "$name" --arg p "$ping_val" --arg s "$speed_val" '.[$k] = {latency: $p, speed: $s}' <<<"$conn_json")
  done

  RESULT_JSON=$(jq -n \
    --arg ip "${EXTERNAL_IPV4:-}" \
    --arg ipv6 "${EXTERNAL_IPV6:-}" \
    --arg os "${NODE_OS:-}" \
    --arg virt "${NODE_VIRT:-}" \
    --arg uptime "${NODE_UPTIME:-}" \
    --arg cpu_model "${NODE_CPU_MODEL:-}" \
    --arg cpu_cores "${NODE_CPU_CORES:-1}" \
    --arg cpu_steal "${NODE_CPU_STEAL_NUM:-0.0}" \
    --arg cpu_steal_alltime "${NODE_CPU_STEAL_ALLTIME:-0.00}" \
    --arg ram "${NODE_RAM:-}" \
    --arg disk "${NODE_DISK:-}" \
    --arg country "${NODE_COUNTRY_CODE:-}" \
    --arg city "${NODE_CITY:-}" \
    --arg asn "${NODE_ASN:-}" \
    --arg org "${NODE_ORG:-}" \
    --arg host_type "${NODE_TYPE:-}" \
    --arg risk "${NODE_RISK:-}" \
    --arg captcha "${NODE_CAPTCHA_STATUS:-}" \
    --arg rkn "${NODE_RKN_STATUS:-}" \
    --arg bbr "${NODE_BBR_STATUS:-}" \
    --arg udp "${NODE_UDP_STATUS:-}" \
    --arg port25 "${NODE_PORT25_STATUS:-}" \
    --arg yt_ad_free "$YOUTUBE_AD_FREE" \
    --arg yt_cc "$YOUTUBE_DETECTED_CC" \
    --argjson geoip "$geoip_json" \
    --argjson unblock "$unblock_json" \
    --argjson local "$local_json" \
    --argjson connectivity "$conn_json" \
    '{
      ip: $ip,
      ipv6: (if $ipv6 != "" then $ipv6 else null end),
      system: {
        os: $os,
        virt: $virt,
        uptime: $uptime,
        cpu_model: $cpu_model,
        cpu_cores: ($cpu_cores | tonumber),
        cpu_steal_pct: ($cpu_steal | tonumber),
        cpu_steal_all_time_pct: ($cpu_steal_alltime | tonumber),
        ram: $ram,
        disk: $disk
      },
      location: { country: $country, city: $city, asn: $asn, org: $org },
      quality: { host_type: $host_type, risk: $risk, google_captcha: $captcha, rkn_registry: $rkn },
      network: { bbr: $bbr, udp: $udp, port25: $port25 },
      youtube: { ad_free: ($yt_ad_free == "true"), country: $yt_cc },
      geoip_consensus: $geoip,
      ru_unblock: $unblock,
      ru_local_services: $local,
      connectivity: $connectivity
    }')
}

display_help() {
  cat <<EOF
Использование: nodecheck.sh [ОПЦИИ]

NodeCheck (RU Edition) — комплексный аудит серверных нод и сетевого стека под РФ

Опции:
  -h, --help               Показать эту справку и выйти
  -j, --json               Вывод результатов в чистом формате JSON
  --no-iperf               Пропустить замер скорости iPerf3 (только пинг)
  --full-iperf             Полный тест iPerf3 (по 5с на DL и UL)
  --iperf-time СЕК         Время замера iPerf3 (по умолч.: 5с DL / 3с UL)
  --no-color               Отключить цветовое форматирование ANSI
  -p, --proxy АДРЕС        Использовать SOCKS5/SOCKS5h прокси (хост:порт)
  -i, --interface ИНТЕРФЕЙС Привязать запросы к сетевому интерфейсу (eth0, ens3)
  --no-doh                 Отключить DNS-over-HTTPS (системный резолвер)
  --doh ПРОВАЙДЕР          Выбор DoH: cloudflare, quad9, adguard
  -v, --verbose            Подробное логирование сетевых запросов
  -d, --debug              Режим отладки (сохранение трассировки в $DEBUG_LOG_FILE)

Примеры:
  ./nodecheck.sh                         # Полный аудит (железо, GeoIP, сервисы, пинг и iPerf3)
  ./nodecheck.sh --no-iperf              # Быстрый аудит без замера скорости (~10-12 секунд)
  ./nodecheck.sh -j                      # Вывод в формате JSON для мониторинга и ботов
  ./nodecheck.sh --no-color > report.txt # Сохранение чистого отчета без ANSI-кодов

EOF
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        display_help
        exit 0
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -d|--debug)
        DEBUG=true
        shift
        ;;
      -j|--json)
        JSON_OUTPUT=true
        shift
        ;;
      --no-iperf)
        RUN_IPERF=false
        shift
        ;;
      --full-iperf)
        RUN_FULL_IPERF=true
        IPERF_TIME_DL=5
        IPERF_TIME_UL=5
        shift
        ;;
      --iperf-time)
        if [[ $# -lt 2 || "$2" =~ [^0-9] ]]; then
          error_exit "Для опции $1 требуется число секунд"
        fi
        IPERF_TIME_DL="$2"
        IPERF_TIME_UL="$2"
        shift 2
        ;;
      --no-color)
        NO_COLOR_MODE=true
        shift
        ;;
      -p|--proxy)
        if [[ $# -lt 2 || "$2" == -* ]]; then
          error_exit "Для опции $1 требуется аргумент (хост:порт)"
        fi
        PROXY_ADDR="$2"
        shift 2
        ;;
      -i|--interface)
        if [[ $# -lt 2 || "$2" == -* ]]; then
          error_exit "Для опции $1 требуется аргумент (имя интерфейса)"
        fi
        INTERFACE_NAME="$2"
        shift 2
        ;;
      --no-doh)
        USE_DOH=false
        shift
        ;;
      --doh)
        if [[ $# -lt 2 || "$2" == -* ]]; then
          error_exit "Для опции $1 требуется аргумент (cloudflare|quad9|adguard)"
        fi
        CUSTOM_DOH_PROVIDER="$2"
        shift 2
        ;;
      *)
        error_exit "Неизвестная опция: $1 (используйте --help для справки)"
        ;;
    esac
  done
}

main() {
  parse_arguments "$@"
  init_colors

  TMP_WORK_DIR=$(mktemp -d "/tmp/nodecheck.XXXXXX" 2>/dev/null || mktemp -d)
  if [[ -z "$TMP_WORK_DIR" || ! -d "$TMP_WORK_DIR" ]]; then
    error_exit "Не удалось создать защищенный временный каталог в /tmp"
  fi
  trap cleanup EXIT
  trap 'cleanup; exit 130' INT
  trap 'cleanup; exit 143' TERM

  install_dependencies
  check_doh

  # 1. External IP & Node Parameters
  progress_status "Определение внешнего IP и параметров хоста"
  discover_external_ips

  if [[ -z "$EXTERNAL_IPV4" && -z "$EXTERNAL_IPV6" ]]; then
    progress_clear
    error_exit "Нет активного подключения к сети или внешний IP не определен."
  fi

  get_vpn_node_info
  progress_status "Анализ CPU Steal, памяти и виртуализации"
  get_system_specs
  progress_clear

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    print_header
  fi

  # 2. 18 GeoIP Databases
  progress_status "Опрос 18 баз GeoIP (параллельно)"
  run_geoip_consensus
  progress_clear

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    print_geoip_table
  fi

  # 3. Western Services & RU Local Services
  progress_status "Проверка доступности 34 сервисов (зарубежные и РФ)"
  run_services_check
  progress_clear

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    print_western_unblock_table
    print_ru_local_table
  fi

  # 4. Multi-Region Pings & Speedtest
  progress_status "Замер задержки RTT до 7 регионов РФ"
  measure_ru_pings
  progress_clear

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1m4. ⚡️ Связность и скорость по регионам РФ (Multi-Region Latency & Throughput)\033[0m\n"
  fi
  measure_ru_iperf

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    print_executive_summary
  fi

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    build_json
    printf "%s\n" "$RESULT_JSON"
  fi
}

main "$@"
