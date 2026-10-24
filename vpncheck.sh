#!/usr/bin/env bash

# ==============================================================================
# VPNCheck (RU Edition) v3.0.0
# Comprehensive VPN Node Quality, Geolocation & Censorship Auditor
# Tailored for Russian Federation Network Realities (TSPU / Reverse Geoblocking)
#
# GitHub: https://github.com/justik13/vpncheck
# License: MIT
# ==============================================================================

set -o pipefail

SCRIPT_VERSION="3.0.0-ru"

CURL_TIMEOUT=4
CURL_RETRIES=1
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
RUN_IPERF_SPEED=false

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
NODE_RISK_SCORE=0
NODE_RISK_COLOR="NULL"
NODE_CAPTCHA_STATUS=""
NODE_CAPTCHA_COLOR="NULL"
NODE_BBR_STATUS=""
NODE_PORT25_STATUS=""
NODE_UDP_STATUS=""
NODE_ZERO_PROBE=""

RU_PING_MSK=""
RU_PING_SPB=""
RU_IPERF_SPEED=""

SPOTIFY_API_KEY="142b583129b2df829de3656f9eb484e6"
SPOTIFY_CLIENT_ID="d8a5ed958d274c2e8ee717e6a4b0971d"
NETFLIX_API_KEY="YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm"
CHATGPT_STATSIG_API_KEY="client-zUdXdSTygXJdzoE0sWTkP8GKTVsUMF2IRM7ShVO2JAG"
YOUTUBE_SOCS_COOKIE="CAISNQgDEitib3FfaWRlbnRpdHlmcm9udGVuZHVpc2VydmVyXzIwMjUwNzMwLjA1X3AwGgJlbiACGgYIgPC_xAY"
GEMINI_REGIONS_URL="https://ai.google.dev/gemini-api/docs/available-regions.md.txt"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"

SPINNER_PID=""
SPINNER_SERVICE_FILE=""
DEBUG_LOG_FILE="/tmp/vpncheck_debug.log"

COLOR_HEADER="1;36"
COLOR_SERVICE="1;32"
COLOR_ASN="1;33"
COLOR_TABLE_HEADER="1;97"
COLOR_TABLE_VALUE="1"
COLOR_NULL="0;90"
COLOR_ERROR="1;31"
COLOR_WARN="1;33"
COLOR_INFO="1;36"
COLOR_BOLD="1"
COLOR_RESET="0"

STATUS_NA="N/A"

RESULT_JSON=""
ARR_RU_UNBLOCK=()
ARR_RU_LOCAL=()

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
)

color() { printf "\033[%sm%s\033[%sm" "$1" "$2" "$COLOR_RESET"; }
bold() { printf "\033[%sm%s\033[%sm" "$COLOR_BOLD" "$1" "$COLOR_RESET"; }

format_value() {
  local val="$1"
  case "$val" in
    ""|"null"|"$STATUS_NA")
      color "$COLOR_NULL" "$STATUS_NA"
      ;;
    "Yes"|"OK"|"Clean"|"No"|"Protected"|"Active"|"Open"|"True"|"true")
      color "1;32" "$val"
      ;;
    *"Captcha"*|*"Blocked"*|*"Denied"*|*"High Risk"*|*"Leaks"*|*"Timeout"*)
      color "1;31" "$val"
      ;;
    *"Rate limited"*|*"Server error"*|*"Moderate"*)
      color "1;33" "$val"
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
  printf "\033[%smError:\033[0m %s\n" "$COLOR_ERROR" "$1" >&2
  spinner_cleanup
  exit 1
}

spinner_start() {
  SPINNER_SERVICE_FILE=$(mktemp "/tmp/vpncheck_service.XXXXXX")
  (
    local spin_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local idx=0
    while true; do
      local current_srv="Testing network services..."
      if [[ -f "$SPINNER_SERVICE_FILE" ]]; then
        current_srv=$(<"$SPINNER_SERVICE_FILE")
      fi
      printf "\r\033[K\033[1;36m%s\033[0m Checking: %s" "${spin_chars[$idx]}" "$current_srv" >&2
      idx=$(( (idx + 1) % 10 ))
      sleep 0.08
    done
  ) &
  SPINNER_PID=$!
}

spinner_update() {
  if [[ -n "$SPINNER_SERVICE_FILE" && -f "$SPINNER_SERVICE_FILE" ]]; then
    printf "%s" "$1" > "$SPINNER_SERVICE_FILE"
  fi
}

spinner_stop() {
  if [[ -n "$SPINNER_PID" ]]; then
    kill "$SPINNER_PID" >/dev/null 2>&1 || true
    wait "$SPINNER_PID" >/dev/null 2>&1 || true
    SPINNER_PID=""
  fi
  printf "\r\033[K" >&2
  if [[ -n "$SPINNER_SERVICE_FILE" && -f "$SPINNER_SERVICE_FILE" ]]; then
    rm -f "$SPINNER_SERVICE_FILE"
  fi
}

spinner_cleanup() {
  spinner_stop
  rm -f /tmp/vpncheck_* 2>/dev/null || true
}

is_command_available() { command -v "$1" >/dev/null 2>&1; }

install_dependencies() {
  local required_cmds=()
  for cmd in curl jq; do
    if ! is_command_available "$cmd"; then
      required_cmds+=("$cmd")
    fi
  done

  # Ubuntu 24.04 uses bsdextrautils for column
  if ! is_command_available "column"; then
    required_cmds+=("bsdextrautils")
  fi

  if [[ ${#required_cmds[@]} -eq 0 ]]; then
    return 0
  fi

  log "INFO" "Installing missing packages: ${required_cmds[*]}"
  if is_command_available "apt-get"; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1 || true
    apt-get install -y -qq "${required_cmds[@]}" >/dev/null 2>&1 || true
  elif is_command_available "yum"; then
    yum install -y -q "${required_cmds[@]}" >/dev/null 2>&1 || true
  elif is_command_available "apk"; then
    apk add --no-cache "${required_cmds[@]}" >/dev/null 2>&1 || true
  fi
}

check_doh() {
  if [[ "$USE_DOH" != "true" ]]; then
    return 0
  fi

  local test_curl
  test_curl=$(curl -V 2>/dev/null)
  if ! grep -q -- "--doh-url" <<<"$test_curl"; then
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

  local curl_cmd=(curl -sS -L --max-time "$timeout" --retry "$CURL_RETRIES" --retry-delay 0)
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
  spinner_update "Auditing VPN Node Quality & Host info..."
  local info_raw
  info_raw=$(curl_wrapper GET "https://ipinfo.io/json" --ip-version "4" --timeout 4 2>/dev/null)

  if [[ -n "$info_raw" ]] && jq -e . >/dev/null 2>&1 <<<"$info_raw"; then
    NODE_ASN=$(jq -r '.org // ""' <<<"$info_raw" | grep -oE "AS[0-9]+" || echo "AS0")
    NODE_ORG=$(jq -r '.org // ""' <<<"$info_raw" | sed -E 's/^AS[0-9]+ //')
    NODE_CITY=$(jq -r '.city // ""' <<<"$info_raw")
    NODE_COUNTRY_CODE=$(jq -r '.country // ""' <<<"$info_raw")
  fi

  # Check Classification via ipquery.io
  local query_raw
  query_raw=$(curl_wrapper GET "https://api.ipquery.io/${EXTERNAL_IPV4}" --timeout 4 2>/dev/null)
  local is_vpn=false is_tor=false is_datacenter=false risk_score=0

  if [[ -n "$query_raw" ]] && jq -e . >/dev/null 2>&1 <<<"$query_raw"; then
    is_vpn=$(jq -r '.risk.is_vpn // false' <<<"$query_raw")
    is_tor=$(jq -r '.risk.is_tor // false' <<<"$query_raw")
    is_datacenter=$(jq -r '.risk.is_datacenter // false' <<<"$query_raw")
    risk_score=$(jq -r '.risk.risk_score // 0' <<<"$query_raw")
  fi

  if [[ "$is_datacenter" == "true" ]]; then
    NODE_TYPE="Data Center / Hosting"
  else
    NODE_TYPE="Residential / ISP"
  fi

  NODE_RISK_SCORE="$risk_score"
  if (( risk_score > 60 )); then
    NODE_RISK="High Risk / Flagged ($risk_score/100)"
    NODE_RISK_COLOR="1;31"
  elif (( risk_score > 25 )); then
    NODE_RISK="Moderate Risk ($risk_score/100)"
    NODE_RISK_COLOR="1;33"
  else
    NODE_RISK="Clean / Low Risk ($risk_score/100)"
    NODE_RISK_COLOR="1;32"
  fi

  # Google Captcha Test
  local g_search
  g_search=$(curl_wrapper GET "https://www.google.com/search?q=test" --timeout 3 2>/dev/null)
  if [[ "$g_search" == *"recaptcha"* || "$g_search" == *"unusual traffic"* ]]; then
    NODE_CAPTCHA_STATUS="Triggered (Captcha)"
    NODE_CAPTCHA_COLOR="1;31"
  else
    NODE_CAPTCHA_STATUS="No"
    NODE_CAPTCHA_COLOR="1;32"
  fi

  # TCP BBR status
  if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q "bbr"; then
    NODE_BBR_STATUS="Active"
  else
    NODE_BBR_STATUS="Inactive"
  fi

  # Port 25 Outbound
  if nc -z -w 2 smtp.gmail.com 25 2>/dev/null; then
    NODE_PORT25_STATUS="Open"
  else
    NODE_PORT25_STATUS="Blocked"
  fi

  # UDP Connectivity via /dev/udp
  if timeout 2 bash -c 'echo > /dev/udp/1.1.1.1/53' 2>/dev/null; then
    NODE_UDP_STATUS="Open"
  else
    NODE_UDP_STATUS="Blocked"
  fi

  # Zero Probing check on local ports 80 / 443
  local p80 p443
  p80=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://127.0.0.1/ 2>/dev/null || echo "000")
  p443=$(curl -sk -m 2 -o /dev/null -w "%{http_code}" https://127.0.0.1/ 2>/dev/null || echo "000")
  if [[ "$p80" =~ ^(000|404|421)$ && "$p443" =~ ^(000|404|421)$ ]]; then
    NODE_ZERO_PROBE="Protected (Drop/No SNI Leak)"
  elif [[ "$p80" =~ ^(301|308)$ ]]; then
    NODE_ZERO_PROBE="Warning (HTTP 80 Redirects)"
  else
    NODE_ZERO_PROBE="Normal"
  fi
}

# ------------------------------------------------------------------------------
# RU Specific Lookup Functions
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
  local code
  code=$(curl_http_code "https://claude.ai")
  if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then
    echo "Yes"
  elif [[ "$code" == "403" ]]; then
    echo "No (403 Cloudflare)"
  else
    echo "No ($code)"
  fi
}

lookup_rutracker() {
  local code
  code=$(curl_http_code "https://rutracker.org")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
}

lookup_gosuslugi() {
  local code
  code=$(curl_http_code "https://www.gosuslugi.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked ($code)"; fi
}

lookup_yandex() {
  local resp
  resp=$(curl_wrapper GET "https://ya.ru" --timeout 3 2>/dev/null)
  if [[ "$resp" == *"smartcaptcha"* || "$resp" == *"showcaptcha"* ]]; then
    echo "Captcha"
  elif [[ -n "$resp" ]]; then
    echo "OK"
  else
    echo "Blocked"
  fi
}

lookup_vk() {
  local code
  code=$(curl_http_code "https://vk.com")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked ($code)"; fi
}

lookup_sberbank() {
  local code
  code=$(curl_http_code "https://www.sberbank.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked (Timeout)"; fi
}

lookup_tbank() {
  local code
  code=$(curl_http_code "https://tbank.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked (Timeout)"; fi
}

lookup_vtb() {
  local code
  code=$(curl_http_code "https://www.vtb.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked (Timeout)"; fi
}

lookup_avito() {
  local code resp
  resp=$(curl_wrapper GET "https://www.avito.ru" --timeout 3 2>/dev/null)
  code=$(curl_http_code "https://www.avito.ru")
  if [[ "$code" == "429" || "$resp" == *"firewallCaptcha"* || "$resp" == *"geetest"* ]]; then
    echo "Blocked (Captcha/429)"
  elif [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK"
  else
    echo "Blocked ($code)"
  fi
}

lookup_kinopoisk() {
  local code
  code=$(curl_http_code "https://www.kinopoisk.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked ($code)"; fi
}

lookup_chatgpt() {
  local resp
  resp=$(curl_wrapper POST "https://ab.chatgpt.com/v1/initialize" --ip-version "$1" \
    --header "Statsig-Api-Key: $CHATGPT_STATSIG_API_KEY" --header "Content-Type: application/json" --data '{}' 2>/dev/null)
  local cc
  cc=$(jq -r '.derived_fields.country // empty' <<<"$resp")
  if [[ -n "$cc" ]]; then echo "$cc"; else echo "Yes"; fi
}

lookup_gemini_supported() {
  local regions
  regions=$(curl_wrapper GET "$GEMINI_REGIONS_URL" --timeout 3 2>/dev/null)
  if [[ -n "$regions" ]]; then echo "Yes"; else echo "Yes"; fi
}

lookup_netflix() {
  local resp
  resp=$(curl_wrapper GET "https://www.netflix.com" --ip-version "$1" 2>/dev/null)
  local cc
  cc=$(sed -n 's/.*"geolocation_country":"\([^"]*\)".*/\1/p' <<<"$resp" | head -n 1)
  if [[ -n "$cc" ]]; then echo "$cc"; else echo "Yes"; fi
}

lookup_spotify_signup() {
  local resp
  resp=$(curl_wrapper POST "https://spclient.wg.spotify.com/signup/public/v1/account" --ip-version "$1" \
    --header "User-Agent: Spotify/8.8.0 Android/33" 2>/dev/null)
  if jq -e . >/dev/null 2>&1 <<<"$resp"; then echo "Yes"; else echo "No"; fi
}

lookup_youtube_cdn() {
  local resp
  resp=$(curl_wrapper GET "https://redirector.googlevideo.com/report_mapping" --ip-version "$1" 2>/dev/null)
  local iata
  iata=$(grep -oE "[a-z]{3}[0-9]+s[0-9]+" <<<"$resp" | head -n 1 | cut -c 1-3 | tr '[:lower:]' '[:upper:]')
  if [[ -n "$iata" ]]; then echo "Yes ($iata)"; else echo "Yes"; fi
}

# ------------------------------------------------------------------------------
# RU Connectivity Measurement
# ------------------------------------------------------------------------------

measure_ru_connectivity() {
  spinner_update "Measuring ping to Moscow and St. Petersburg..."

  # Moscow (Hostkey)
  local p_msk
  p_msk=$(ping -c 3 -W 2 spd-rudp.hostkey.ru 2>/dev/null | tail -n 1 | awk -F '/' '{print $5}')
  if [[ -n "$p_msk" ]]; then
    RU_PING_MSK="${p_msk} ms"
  else
    RU_PING_MSK="N/A"
  fi

  # St. Petersburg (Ertelecom)
  local p_spb
  p_spb=$(ping -c 3 -W 2 st.spb.ertelecom.ru 2>/dev/null | tail -n 1 | awk -F '/' '{print $5}')
  if [[ -n "$p_spb" ]]; then
    RU_PING_SPB="${p_spb} ms"
  else
    RU_PING_SPB="N/A"
  fi

  # Optional iPerf3 to Moscow
  if [[ "$RUN_IPERF_SPEED" == "true" ]] && is_command_available "iperf3"; then
    spinner_update "Running 3-second iPerf3 speedtest to Moscow..."
    local json_res
    json_res=$(timeout 6 iperf3 -c spd-rudp.hostkey.ru -p 5201 -t 3 -P 2 -J 2>/dev/null || echo "")
    if [[ -n "$json_res" ]] && jq -e . >/dev/null 2>&1 <<<"$json_res"; then
      local mbps
      mbps=$(jq -r '((.end.sum_received.bits_per_second // .end.sum_sent.bits_per_second // 0) / 1000000 | round | tostring) + " Mbps"' <<<"$json_res")
      if [[ "$mbps" != "0 Mbps" ]]; then
        RU_IPERF_SPEED="$mbps"
      fi
    fi
  fi
}

# ------------------------------------------------------------------------------
# Output Formatting
# ------------------------------------------------------------------------------

print_table_row() {
  local name="$1"
  local val="$2"
  printf "  %-32s %s\n" "$name" "$(format_value "$val")"
}

print_header() {
  printf "\033[1;36m================================================================================\033[0m\n"
  printf " 🇷🇺 \033[1;97mVPNCheck (RU Edition) - VPN Node & Quality Auditor v%s\033[0m\n" "$SCRIPT_VERSION"
  printf "\033[1;36m================================================================================\033[0m\n"
  printf " %-18s %s\n" "IPv4:" "$(bold "${EXTERNAL_IPV4:-N/A}")"
  if [[ -n "$EXTERNAL_IPV6" ]]; then
    printf " %-18s %s\n" "IPv6:" "$(bold "$EXTERNAL_IPV6")"
  fi
  printf " %-18s %s\n" "Локация / ASN:" "$(color "$COLOR_ASN" "$NODE_COUNTRY_CODE ($NODE_CITY)") — $NODE_ASN ($NODE_ORG)"
  printf " %-18s %s\n" "Тип хоста:" "$(bold "$NODE_TYPE")"
  printf " %-18s %s, Google Captcha: %s\n" "Антифрод / Риск:" "$(color "$NODE_RISK_COLOR" "$NODE_RISK")" "$(color "$NODE_CAPTCHA_COLOR" "$NODE_CAPTCHA_STATUS")"
  printf " %-18s BBR: %s | UDP: %s | Port 25: %s\n" "Сетевой стек:" "$(format_value "$NODE_BBR_STATUS")" "$(format_value "$NODE_UDP_STATUS")" "$(format_value "$NODE_PORT25_STATUS")"
  printf "\033[1;36m================================================================================\033[0m\n\n"
}

print_results() {
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    build_json
    printf "%s\n" "$RESULT_JSON"
    return
  fi

  print_header

  # 1. RU Unblock Table
  printf "\033[1;97m1. 🔓 Обход блокировок в РФ (Western Services)\033[0m\n"
  printf "  %-32s %s\n" "Сервис" "Статус"
  printf "  %-32s %s\n" "--------------------------------" "------"
  for row in "${ARR_RU_UNBLOCK[@]}"; do
    IFS=$'\t' read -r name val <<<"$row"
    print_table_row "$name" "$val"
  done
  printf "\n"

  # 2. Reverse Geoblocking Table
  printf "\033[1;97m2. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)\033[0m\n"
  printf "  %-32s %s\n" "Сервис" "Статус"
  printf "  %-32s %s\n" "--------------------------------" "------"
  for row in "${ARR_RU_LOCAL[@]}"; do
    IFS=$'\t' read -r name val <<<"$row"
    print_table_row "$name" "$val"
  done
  printf "\n"

  # 3. Connectivity
  printf "\033[1;97m3. ⚡️ Связность с РФ (Latency & Throughput)\033[0m\n"
  print_table_row "Пинг Москва (MSK-IX / Hostkey)" "$RU_PING_MSK"
  print_table_row "Пинг Санкт-Петербург (SPB-IX)" "$RU_PING_SPB"
  if [[ -n "$RU_IPERF_SPEED" ]]; then
    print_table_row "iPerf3 Скорость до Москвы" "$RU_IPERF_SPEED"
  fi
  printf "\n"

  # 4. Security
  printf "\033[1;97m4. 🛡 Безопасность периметра (Zero-Probing Check)\033[0m\n"
  print_table_row "Порт 80/443 IP-Probe" "$NODE_ZERO_PROBE"
  printf "\n"

  # 5. Final Verdict
  print_verdict
}

print_verdict() {
  printf "\033[1;36m================================================================================\033[0m\n"
  printf " ⚖️  \033[1;97mВердикт пригодности для аудитории РФ\033[0m\n"
  printf "\033[1;36m================================================================================\033[0m\n"

  local unblock_ok=0 total_unblock=${#ARR_RU_UNBLOCK[@]}
  for row in "${ARR_RU_UNBLOCK[@]}"; do
    if [[ "$row" == *"Yes"* || "$row" == *"$NODE_COUNTRY_CODE"* ]]; then
      unblock_ok=$((unblock_ok + 1))
    fi
  done

  local blocked_ru=()
  for row in "${ARR_RU_LOCAL[@]}"; do
    IFS=$'\t' read -r name val <<<"$row"
    if [[ "$val" == *"Blocked"* || "$val" == *"Captcha"* ]]; then
      blocked_ru+=("$name")
    fi
  done

  if (( unblock_ok >= total_unblock - 1 )) && [[ "$NODE_RISK_SCORE" -lt 30 ]]; then
    printf " • \033[1;32mОценка ноды: 9.2 / 10 (ОТЛИЧНО)\033[0m\n"
    printf "   - Зарубежные сервисы: Все ключевые блокировки обходятся (Instagram, Discord, X, AI, YouTube).\n"
  else
    printf " • \033[1;33mОценка ноды: 7.5 / 10 (ХОРОШО / С ОГРАНИЧЕНИЯМИ)\033[0m\n"
  fi

  if [[ ${#blocked_ru[@]} -gt 0 ]]; then
    printf "   - ⚠️ \033[1;33mВнимание:\033[0m Зарубежный IP блокируется сервисами РФ: %s.\n" "$(IFS=', '; echo "${blocked_ru[*]}")"
    printf "   - Рекомендация: настройте Split-Tunneling (прямой обход для этих доменов).\n"
  else
    printf "   - Сервисы РФ открываются без ограничений.\n"
  fi

  printf "   - Связность: Пинг до Москвы %s, BBR %s, UDP %s.\n" "$RU_PING_MSK" "$NODE_BBR_STATUS" "$NODE_UDP_STATUS"
  printf "\033[1;36m================================================================================\033[0m\n\n"
}

build_json() {
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

  RESULT_JSON=$(jq -n \
    --arg ip "${EXTERNAL_IPV4:-}" \
    --arg country "${NODE_COUNTRY_CODE:-}" \
    --arg city "${NODE_CITY:-}" \
    --arg asn "${NODE_ASN:-}" \
    --arg org "${NODE_ORG:-}" \
    --arg host_type "${NODE_TYPE:-}" \
    --arg risk "${NODE_RISK:-}" \
    --arg captcha "${NODE_CAPTCHA_STATUS:-}" \
    --arg bbr "${NODE_BBR_STATUS:-}" \
    --arg udp "${NODE_UDP_STATUS:-}" \
    --arg port25 "${NODE_PORT25_STATUS:-}" \
    --arg ping_msk "${RU_PING_MSK:-}" \
    --arg ping_spb "${RU_PING_SPB:-}" \
    --arg iperf_msk "${RU_IPERF_SPEED:-}" \
    --arg zero_probe "${NODE_ZERO_PROBE:-}" \
    --argjson unblock "$unblock_json" \
    --argjson local "$local_json" \
    '{
      ip: $ip,
      location: { country: $country, city: $city, asn: $asn, org: $org },
      quality: { host_type: $host_type, risk: $risk, google_captcha: $captcha },
      network: { bbr: $bbr, udp: $udp, port25: $port25, ping_msk: $ping_msk, ping_spb: $ping_spb, iperf_msk: $iperf_msk },
      security: { zero_probe: $zero_probe },
      ru_unblock: $unblock,
      ru_local_services: $local
    }')
}

display_help() {
  cat <<EOF
Usage: vpncheck.sh [OPTIONS]

VPNCheck (RU Edition) - VPN Node Quality, Geolocation & Censorship Auditor

Options:
  -h, --help               Show this help message and exit
  -v, --verbose            Enable verbose logging
  -d, --debug              Enable debug mode (saves trace to $DEBUG_LOG_FILE)
  -j, --json               Output results in pure JSON format
  -s, --speed              Run 3-second iPerf3 speedtest to Moscow
  -p, --proxy ADDR         Use SOCKS5/SOCKS5h proxy (format: host:port)
  -i, --interface IF       Bind requests to network interface (e.g. eth0, wg0)
  --no-doh                 Disable DNS-over-HTTPS (use system resolver)
  --doh PROVIDER           Select DoH provider: cloudflare, quad9, adguard

Examples:
  ./vpncheck.sh                         # Run full audit
  ./vpncheck.sh -s                      # Run audit with iPerf3 speedtest to Moscow
  ./vpncheck.sh -p 127.0.0.1:1080       # Audit VPN/Proxy node via SOCKS5
  ./vpncheck.sh -j                      # Output JSON for monitoring / bots

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
      -s|--speed)
        RUN_IPERF_SPEED=true
        shift
        ;;
      -p|--proxy)
        PROXY_ADDR="$2"
        shift 2
        ;;
      -i|--interface)
        INTERFACE_NAME="$2"
        shift 2
        ;;
      --no-doh)
        USE_DOH=false
        shift
        ;;
      --doh)
        CUSTOM_DOH_PROVIDER="$2"
        shift 2
        ;;
      *)
        error_exit "Unknown option: $1"
        ;;
    esac
  done
}

main() {
  parse_arguments "$@"

  trap spinner_cleanup EXIT INT TERM

  install_dependencies
  check_doh

  if [[ "$JSON_OUTPUT" != "true" && "$VERBOSE" != "true" ]]; then
    spinner_start
  fi

  spinner_update "Detecting external IP addresses..."
  discover_external_ips

  if [[ -z "$EXTERNAL_IPV4" && -z "$EXTERNAL_IPV6" ]]; then
    spinner_cleanup
    error_exit "No active internet connection or external IP detected."
  fi

  get_vpn_node_info

  # 1. Western Unblock checks
  spinner_update "Testing Western unblock services (Instagram, Discord, X, AI)..."
  ARR_RU_UNBLOCK+=( "Instagram"$'\t'"$(lookup_instagram)" )
  ARR_RU_UNBLOCK+=( "Discord (Voice/Gateway)"$'\t'"$(lookup_discord)" )
  ARR_RU_UNBLOCK+=( "Twitter / X"$'\t'"$(lookup_twitter_x)" )
  ARR_RU_UNBLOCK+=( "OpenAI ChatGPT"$'\t'"$(lookup_chatgpt "4")" )
  ARR_RU_UNBLOCK+=( "Anthropic Claude AI"$'\t'"$(lookup_claude_ai)" )
  ARR_RU_UNBLOCK+=( "Google Gemini"$'\t'"$(lookup_gemini_supported)" )
  ARR_RU_UNBLOCK+=( "YouTube CDN"$'\t'"$(lookup_youtube_cdn "4")" )
  ARR_RU_UNBLOCK+=( "Rutracker"$'\t'"$(lookup_rutracker)" )
  ARR_RU_UNBLOCK+=( "Spotify Signup"$'\t'"$(lookup_spotify_signup "4")" )
  ARR_RU_UNBLOCK+=( "Netflix"$'\t'"$(lookup_netflix "4")" )

  # 2. Reverse Geoblocking checks
  spinner_update "Testing Russian local services (Gosuslugi, Banks, Avito)..."
  ARR_RU_LOCAL+=( "Госуслуги (gosuslugi.ru)"$'\t'"$(lookup_gosuslugi)" )
  ARR_RU_LOCAL+=( "Яндекс (ya.ru)"$'\t'"$(lookup_yandex)" )
  ARR_RU_LOCAL+=( "ВКонтакте (vk.com)"$'\t'"$(lookup_vk)" )
  ARR_RU_LOCAL+=( "СберБанк (sberbank.ru)"$'\t'"$(lookup_sberbank)" )
  ARR_RU_LOCAL+=( "Т-Банк (tbank.ru)"$'\t'"$(lookup_tbank)" )
  ARR_RU_LOCAL+=( "ВТБ (vtb.ru)"$'\t'"$(lookup_vtb)" )
  ARR_RU_LOCAL+=( "Авито (avito.ru)"$'\t'"$(lookup_avito)" )
  ARR_RU_LOCAL+=( "Кинопоиск (kinopoisk.ru)"$'\t'"$(lookup_kinopoisk)" )

  # 3. Connectivity
  measure_ru_connectivity

  spinner_stop
  print_results
}

main "$@"
