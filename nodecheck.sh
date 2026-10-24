#!/usr/bin/env bash

# ==============================================================================
# NodeCheck (RU Edition) v3.1.0
# Comprehensive VPN Node Quality, Geolocation & Censorship Auditor
# Tailored for Russian Federation Network Realities (TSPU / Reverse Geoblocking)
#
# GitHub: https://github.com/justik13/nodecheck
# License: MIT
# ==============================================================================

set -o pipefail

SCRIPT_VERSION="3.2.0-ru"

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
CHECK_SNI=""
CUSTOM_CDN_ENDPOINT=""

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
NODE_RKN_STATUS="Checking..."
NODE_RKN_COLOR="NULL"
NODE_PMTU="Unknown"
NODE_RECOMMENDED_MTU="1360"
NODE_BBR_STATUS=""
NODE_PORT25_STATUS=""
NODE_UDP_STATUS=""
NODE_ZERO_PROBE=""
NODE_ZERO_PROBE_COLOR="NULL"
NODE_SNI_STATUS=""
NODE_SNI_COLOR="NULL"

WL_NODE_ROLE=""
WL_ANYCAST_RTT="N/A"
WL_CASCADE_STATUS=""
ARR_WHITELIST=()

RU_PING_MSK=""
RU_PING_SPB=""
RU_PING_ROSTOV=""
RU_PING_KZN=""
RU_PING_EKAT=""
RU_PING_NSK=""
RU_PING_IRK=""
RU_IPERF_SPEED=""

VERDICT_SCORE="0.0"
VERDICT_RATING=""
VERDICT_COLOR=""
VERDICT_UNBLOCK_OK=0
VERDICT_UNBLOCK_TOTAL=0
VERDICT_DEDUCTIONS=()

YOUTUBE_AD_FREE=false
YOUTUBE_DETECTED_CC=""

CHATGPT_STATSIG_API_KEY="client-zUdXdSTygXJdzoE0sWTkP8GKTVsUMF2IRM7ShVO2JAG"
YOUTUBE_SOCS_COOKIE="CAISNQgDEitib3FfaWRlbnRpdHlmcm9udGVuZHVpc2VydmVyXzIwMjUwNzMwLjA1X3AwGgJlbiACGgYIgPC_xAY"
GEMINI_REGIONS_URL="https://ai.google.dev/gemini-api/docs/available-regions.md.txt"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"

DEBUG_LOG_FILE="/tmp/nodecheck_debug.log"
TMP_WORK_DIR=""

COLOR_ASN="1;33"
COLOR_TABLE_VALUE="1"
COLOR_NULL="0;90"
COLOR_ERROR="1;31"
COLOR_INFO="1;36"
COLOR_BOLD="1"
COLOR_RESET="0"

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

color() { printf "\033[%sm%s\033[%sm" "$1" "$2" "$COLOR_RESET"; }
bold() { printf "\033[%sm%s\033[%sm" "$COLOR_BOLD" "$1" "$COLOR_RESET"; }

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
      color "1;32" "$val"
      ;;
    *"[Без рекламы"*|*"Без рекламы"*)
      color "1;32" "$val"
      ;;
    "No"*|*"Captcha"*|*"Blocked"*|*"Denied"*|*"High Risk"*|*"Leaks"*|*"Timeout"*)
      color "1;31" "$val"
      ;;
    *"Rate limited"*|*"Server error"*|*"Moderate"*|*"Warning"*|*"Inactive"*)
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
  cleanup
  exit 1
}

cleanup() {
  if [[ -n "$TMP_WORK_DIR" && -d "$TMP_WORK_DIR" ]]; then
    rm -rf "$TMP_WORK_DIR"
  fi
}

is_command_available() { command -v "$1" >/dev/null 2>&1; }

install_dependencies() {
  local required_cmds=()
  for cmd in curl jq ping awk; do
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
  else
    NODE_RISK_SCORE="N/A"
    NODE_RISK="N/A (API Unavailable)"
    NODE_RISK_COLOR="0;90"
  fi

  # Google Captcha Test
  local g_search
  g_search=$(curl_wrapper GET "https://www.google.com/search?q=test" --timeout 3 2>/dev/null)
  if [[ -z "$g_search" ]]; then
    NODE_CAPTCHA_STATUS="N/A (Timeout)"
    NODE_CAPTCHA_COLOR="0;90"
  elif [[ "$g_search" == *"recaptcha"* || "$g_search" == *"unusual traffic"* || "$g_search" == *"our systems have detected"* ]]; then
    NODE_CAPTCHA_STATUS="Triggered (Captcha)"
    NODE_CAPTCHA_COLOR="1;31"
  else
    NODE_CAPTCHA_STATUS="Clean (No Captcha)"
    NODE_CAPTCHA_COLOR="1;32"
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

  # Path MTU Detection (PMTU to Russian hubs)
  if is_command_available ping; then
    if ping -c 1 -M do -s 1472 -W 1 ya.ru >/dev/null 2>&1 || ping -c 1 -M do -s 1472 -W 1 77.88.55.242 >/dev/null 2>&1; then
      NODE_PMTU="1500 (Standard Ethernet)"
      NODE_RECOMMENDED_MTU="1420 (WG) / 1360 (AWG)"
    elif ping -c 1 -M do -s 1392 -W 1 ya.ru >/dev/null 2>&1; then
      NODE_PMTU="1420 (WireGuard)"
      NODE_RECOMMENDED_MTU="1360 (Clamped)"
    elif ping -c 1 -M do -s 1332 -W 1 ya.ru >/dev/null 2>&1; then
      NODE_PMTU="1360 (PPPoE / Tunnel)"
      NODE_RECOMMENDED_MTU="1280 (Min)"
    elif ping -c 1 -M do -s 1252 -W 1 ya.ru >/dev/null 2>&1; then
      NODE_PMTU="1280 (IPv6 Min / Mobile)"
      NODE_RECOMMENDED_MTU="1240"
    else
      NODE_PMTU="Non-standard / ICMP Drop"
      NODE_RECOMMENDED_MTU="1360 (Safe default)"
    fi
  else
    NODE_PMTU="N/A (ping not found)"
    NODE_RECOMMENDED_MTU="1360"
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
      NODE_RKN_COLOR="1;31"
    else
      NODE_RKN_STATUS="Clean (Not in Registry)"
      NODE_RKN_COLOR="1;32"
    fi
  else
    NODE_RKN_STATUS="N/A"
    NODE_RKN_COLOR="0;90"
  fi

  # Zero-Probing & Active Anti-Censorship Perimeter Check (Ports 80/443)
  local p80 p443 p80_loc="" p443_cert="" leak_found=false
  p80=$(curl -s -m 2 -o /dev/null -w "%{http_code}" http://127.0.0.1/ 2>/dev/null)
  p80="${p80: -3}"; p80="${p80:-000}"

  p443=$(curl -sk -m 2 -o /dev/null -w "%{http_code}" https://127.0.0.1/ 2>/dev/null)
  p443="${p443: -3}"; p443="${p443:-000}"

  # Check domain leak in HTTP redirect
  if [[ "$p80" =~ ^(301|308)$ ]]; then
    p80_loc=$(curl -s -I -m 2 http://127.0.0.1/ 2>/dev/null | grep -i '^Location:' | tr -d '\r\n')
    if [[ -n "$p80_loc" ]] && grep -oE 'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' <<<"$p80_loc" | grep -qvE '(127\.0\.0\.1|localhost)'; then
      leak_found=true
    fi
  fi

  # Check domain leak in TLS certificate CN/SAN
  if [[ "$p443" != "000" ]] && is_command_available openssl; then
    p443_cert=$(echo | timeout 2 openssl s_client -connect 127.0.0.1:443 2>/dev/null | openssl x509 -noout -subject -ext subjectAltName 2>/dev/null || echo "")
    if grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' <<<"$p443_cert" | grep -qvE '(127\.0\.0\.1|localhost|local|example)'; then
      leak_found=true
    fi
  fi

  if [[ "$leak_found" == "true" ]]; then
    NODE_ZERO_PROBE="⚠️ Vulnerable (Domain Leak to TSPU in Redirect/Cert)"
    NODE_ZERO_PROBE_COLOR="1;31"
  elif [[ "$p80" == "000" && "$p443" == "000" ]]; then
    NODE_ZERO_PROBE="Protected (Ports Closed / Silent Drop)"
    NODE_ZERO_PROBE_COLOR="1;32"
  elif [[ "$p80" =~ ^(404|421)$ || "$p443" =~ ^(404|421)$ ]]; then
    NODE_ZERO_PROBE="Protected (Active Fallback HTTP $p80/$p443)"
    NODE_ZERO_PROBE_COLOR="1;32"
  elif [[ "$p80" == "200" || "$p443" == "200" ]]; then
    NODE_ZERO_PROBE="Caution (Web Server Active HTTP 200, Check Camouflage)"
    NODE_ZERO_PROBE_COLOR="1;33"
  else
    NODE_ZERO_PROBE="Protected (HTTP $p80/$p443 No Leaks)"
    NODE_ZERO_PROBE_COLOR="1;32"
  fi

  # SelfSteal SNI Verification (nDPI NDPI_UNRESOLVED_HOSTNAME check)
  if [[ -n "$CHECK_SNI" ]]; then
    local sni_ip
    sni_ip=$(curl_wrapper GET "https://cloudflare-dns.com/dns-query?name=${CHECK_SNI}&type=A" -H "accept: application/dns-json" --timeout 3 2>/dev/null | jq -r '.Answer[]? | select(.type==1) | .data' 2>/dev/null | head -n1 || echo "")
    if [[ -n "$sni_ip" ]]; then
      if [[ "$sni_ip" == "$EXTERNAL_IPV4" ]]; then
        NODE_SNI_STATUS="Valid SelfSteal (Domain resolves to node IP $EXTERNAL_IPV4)"
        NODE_SNI_COLOR="1;32"
      else
        NODE_SNI_STATUS="⚠️ Mismatch! Domain resolves to $sni_ip, node is $EXTERNAL_IPV4 (Risk of NDPI_UNRESOLVED_HOSTNAME)"
        NODE_SNI_COLOR="1;31"
      fi
    else
      NODE_SNI_STATUS="Cannot resolve domain $CHECK_SNI"
      NODE_SNI_COLOR="0;90"
    fi
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
  local ports=(5201 5202 5203 5204 5205 5206 5207 5208 5209)

  local target_hosts=("$host")
  if [[ -n "$fallback_host" && "$fallback_host" != "$host" ]]; then
    target_hosts+=("$fallback_host")
  fi

  for cur_host in "${target_hosts[@]}"; do
    for p in "${ports[@]}"; do
      # Fast TCP pre-check (0.8s timeout)
      if ! timeout 0.8 bash -c "echo > /dev/tcp/$cur_host/$p" 2>/dev/null; then
        continue
      fi

      # 1. Try --bidir first (duplex test in 1.5s, 2 parallel streams)
      local res
      res=$(timeout 3 iperf3 -c "$cur_host" -p "$p" -t 1.5 -P 2 --bidir -J 2>/dev/null || echo "")
      if [[ -n "$res" ]] && jq -e '.end.sum_sent_bidir_reverse.bits_per_second' >/dev/null 2>&1 <<<"$res"; then
        local tx_bps rx_bps dl ul
        tx_bps=$(jq -r '.end.sum_sent.bits_per_second // 0' <<<"$res")
        rx_bps=$(jq -r '.end.sum_sent_bidir_reverse.bits_per_second // 0' <<<"$res")
        if (( $(awk -v a="$tx_bps" 'BEGIN { print (a > 1000000) ? 1 : 0 }') )); then
          dl=$(awk -v b="$tx_bps" 'BEGIN { printf "%d Mbps", (b/1000000)+0.5 }')
          ul=$(awk -v b="$rx_bps" 'BEGIN { printf "%d Mbps", (b/1000000)+0.5 }')
          local note=""
          if [[ "$cur_host" == "$fallback_host" ]]; then note=" (F)"; fi
          echo "↓ $dl / ↑ $ul$note"
          return
        fi
      fi

      # 2. If --bidir not supported, test TX then RX (-R)
      res=$(timeout 2.5 iperf3 -c "$cur_host" -p "$p" -t 1.5 -P 2 -J 2>/dev/null || echo "")
      if [[ -n "$res" ]] && jq -e '.end.sum_sent.bits_per_second' >/dev/null 2>&1 <<<"$res"; then
        local tx_bps rx_bps dl="—" ul="—"
        tx_bps=$(jq -r '.end.sum_sent.bits_per_second // 0' <<<"$res")
        if (( $(awk -v a="$tx_bps" 'BEGIN { print (a > 1000000) ? 1 : 0 }') )); then
          dl=$(awk -v b="$tx_bps" 'BEGIN { printf "%d Mbps", (b/1000000)+0.5 }')

          local res_rx
          res_rx=$(timeout 2.5 iperf3 -c "$cur_host" -p "$p" -R -t 1.5 -P 2 -J 2>/dev/null || echo "")
          if [[ -n "$res_rx" ]] && jq -e '.end.sum_received.bits_per_second' >/dev/null 2>&1 <<<"$res_rx"; then
            rx_bps=$(jq -r '.end.sum_received.bits_per_second // 0' <<<"$res_rx")
            ul=$(awk -v b="$rx_bps" 'BEGIN { printf "%d Mbps", (b/1000000)+0.5 }')
          fi
          local note=""
          if [[ "$cur_host" == "$fallback_host" ]]; then note=" (F)"; fi
          echo "↓ $dl / ↑ $ul$note"
          return
        fi
      fi
    done
  done

  echo "—"
}

measure_ru_connectivity() {
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

  test_region_speed() {
    local label="$1" ping_val="$2" host="$3" fallback_host="$4" test_iperf_default="$5"
    local speed="—"

    local should_run=false
    if [[ "$RUN_IPERF" == "true" ]] && is_command_available "iperf3"; then
      if [[ "$RUN_FULL_IPERF" == "true" || "$test_iperf_default" == "true" ]]; then
        should_run=true
      fi
    fi

    if [[ "$should_run" == "true" ]]; then
      if [[ "$JSON_OUTPUT" != "true" ]]; then
        printf "    \033[1;33m⏳\033[0m %s: %s | замер iPerf3...\r" "$label" "$ping_val"
      fi
      speed=$(iperf_speed_test "$host" "$fallback_host")
    elif [[ "$RUN_IPERF" == "true" && "$RUN_FULL_IPERF" != "true" ]]; then
      speed="— (--full-iperf)"
    fi

    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "\r\033[K    \033[1;32m✓\033[0m %s: \033[1;97m%s\033[0m | \033[1;36m%s\033[0m\n" "$label" "$ping_val" "$speed"
    fi

    ARR_CONNECTIVITY+=( "$label"$'\t'"$ping_val"$'\t'"$speed" )
  }

  test_region_speed "Москва (Центр, Hostkey / MSK-IX)" "$RU_PING_MSK" "spd-rudp.hostkey.ru" "st.tver.ertelecom.ru" true
  test_region_speed "Санкт-Петербург (Северо-Запад, SPB)" "$RU_PING_SPB" "st.spb.ertelecom.ru" "st.yar.ertelecom.ru" false
  test_region_speed "Казань (Поволжье, ER-Telecom)" "$RU_PING_KZN" "st.kzn.ertelecom.ru" "st.chelny.ertelecom.ru" false
  test_region_speed "Ростов-на-Дону (Юг, ER-Telecom)" "$RU_PING_ROSTOV" "st.rostov.ertelecom.ru" "st.volgograd.ertelecom.ru" false
  test_region_speed "Екатеринбург (Урал, ER-Telecom)" "$RU_PING_EKAT" "st.ekat.ertelecom.ru" "st.chel.ertelecom.ru" true
  test_region_speed "Новосибирск (Сибирь, ER-Telecom)" "$RU_PING_NSK" "st.nsk.ertelecom.ru" "st.tomsk.ertelecom.ru" false
  test_region_speed "Иркутск (Восточная Сибирь, ER)" "$RU_PING_IRK" "st.irkutsk.ertelecom.ru" "st.krsk.ertelecom.ru" false

  IFS=$'\t' read -r _ _ RU_IPERF_SPEED <<<"${ARR_CONNECTIVITY[0]}"
}

# ------------------------------------------------------------------------------
# 5. White List (WL) & Russian CDN Readiness
# ------------------------------------------------------------------------------

measure_whitelist_readiness() {
  if [[ "$NODE_COUNTRY_CODE" == "RU" ]]; then
    WL_NODE_ROLE="Origin / Ingress (Внутри РФ)"
  else
    WL_NODE_ROLE="Exit / Outbound (Зарубежный шлюз)"
  fi

  local wl_dir="$TMP_WORK_DIR/wl"
  mkdir -p "$wl_dir"

  (
    # Tier 1: State Messenger MAX (max.ru)
    local c1
    c1=$(curl_http_code "https://max.ru/")
    echo "$c1" > "$wl_dir/max"
  ) &

  (
    # Tier 2: Yandex Anycast CDN (yastatic.net)
    local c2
    c2=$(curl_http_code "https://yastatic.net/")
    echo "$c2" > "$wl_dir/yandex"
  ) &

  (
    # Tier 2: VK Cloud (vk.com)
    local c3
    c3=$(curl_http_code "https://vk.com/")
    echo "$c3" > "$wl_dir/vk"
  ) &

  (
    # Tier 2: Gosuslugi (gosuslugi.ru)
    local c4
    c4=$(curl_http_code "https://gosuslugi.ru/")
    echo "$c4" > "$wl_dir/gosuslugi"
  ) &

  wait

  local res_max res_ya res_vk res_gu
  res_max=$(<"$wl_dir/max")
  res_ya=$(<"$wl_dir/yandex")
  res_vk=$(<"$wl_dir/vk")
  res_gu=$(<"$wl_dir/gosuslugi")

  WL_ANYCAST_RTT="N/A"
  if [[ -n "$RU_PING_MSK" && "$RU_PING_MSK" != "N/A" ]]; then
    WL_ANYCAST_RTT="$RU_PING_MSK"
  fi

  local rtt_num
  rtt_num=$(echo "$WL_ANYCAST_RTT" | grep -oE '^[0-9]+(\.[0-9]+)?' || echo "999")
  if (( $(awk -v r="$rtt_num" 'BEGIN { print (r <= 80) ? 1 : 0 }') )); then
    WL_CASCADE_STATUS="Отлично (<80 ms, минимальный джиттер)"
  elif (( $(awk -v r="$rtt_num" 'BEGIN { print (r <= 120) ? 1 : 0 }') )); then
    WL_CASCADE_STATUS="Допустимо (80–120 ms, возможен джиттер)"
  else
    WL_CASCADE_STATUS="В зоне риска (>120 ms: риск 504 Gateway Timeout)"
  fi

  local cdn_check_status=""
  if [[ -n "$CUSTOM_CDN_ENDPOINT" ]]; then
    local cdn_res
    cdn_res=$(curl -sS -D - -o /dev/null -X GET -H "data-0: dGVzdA==" --max-time 4 "$CUSTOM_CDN_ENDPOINT?nocache=$(date +%s)" 2>/dev/null || echo "")
    if grep -q "204" <<<"$cdn_res" || grep -iq "x-cdn-origin: ok" <<<"$cdn_res"; then
      cdn_check_status="OK (HTTP 204 / Bodiless Header Uplink)"
    elif grep -q "413" <<<"$cdn_res"; then
      cdn_check_status="⚠️ 413 (CDN blocks bodies, use Header Uplink)"
    elif grep -q "504" <<<"$cdn_res"; then
      cdn_check_status="⚠️ 504 (Gateway Timeout, Origin unreachable)"
    elif grep -q "502" <<<"$cdn_res"; then
      cdn_check_status="⚠️ 502 (Bad Gateway, check Origin port/cert)"
    else
      local http_code
      http_code=$(grep -oE "HTTP/[0-9.]+ [0-9]{3}" <<<"$cdn_res" | head -n1 || echo "Error")
      cdn_check_status="$http_code"
    fi
  fi

  ARR_WHITELIST=()
  ARR_WHITELIST+=( "Роль ноды в топологии"$'\t'"$WL_NODE_ROLE" )
  ARR_WHITELIST+=( "Мессенджер MAX (max.ru, Уровень 1)"$'\t'"$([[ "$res_max" =~ ^(200|301|302)$ ]] && echo "OK (Доступен)" || echo "Blocked ($res_max)")" )
  ARR_WHITELIST+=( "Anycast Яндекс / CDN (yastatic.net, Уровень 2)"$'\t'"$([[ "$res_ya" =~ ^(200|301|302)$ ]] && echo "OK (Доступен)" || echo "Blocked ($res_ya)")" )
  ARR_WHITELIST+=( "VK Cloud / ВКонтакте (vk.com, Уровень 2)"$'\t'"$([[ "$res_vk" =~ ^(200|301|302)$ ]] && echo "OK (Доступен)" || echo "Blocked ($res_vk)")" )
  ARR_WHITELIST+=( "Портал Госуслуг (gosuslugi.ru, Уровень 2)"$'\t'"$([[ "$res_gu" =~ ^(200|301|302)$ ]] && echo "OK (Доступен)" || echo "Blocked ($res_gu)")" )
  ARR_WHITELIST+=( "Задержка до Anycast РФ (RTT)"$'\t'"$WL_ANYCAST_RTT — $WL_CASCADE_STATUS" )
  ARR_WHITELIST+=( "Стек протоколов под Белые Списки"$'\t'"UDP мертв в WL ➔ VLESS XHTTP over TCP/TLS 443" )
  if [[ -n "$CUSTOM_CDN_ENDPOINT" ]]; then
    ARR_WHITELIST+=( "Кастомный CDN ($CUSTOM_CDN_ENDPOINT)"$'\t'"$cdn_check_status" )
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
  printf "\033[1;36m================================================================================\033[0m\n"
  printf " 🇷🇺 \033[1;97mNodeCheck (RU Edition) - VPN Node & Quality Auditor v%s\033[0m\n" "$SCRIPT_VERSION"
  printf "\033[1;36m================================================================================\033[0m\n"
  {
    echo -e " IPv4:\t$(bold "${EXTERNAL_IPV4:-N/A}")"
    if [[ -n "$EXTERNAL_IPV6" ]]; then
      echo -e " IPv6:\t$(bold "$EXTERNAL_IPV6")"
    fi
    echo -e " Локация / ASN:\t$(color "$COLOR_ASN" "$NODE_COUNTRY_CODE ($NODE_CITY)") — $NODE_ASN ($NODE_ORG)"
    echo -e " Тип хоста:\t$(bold "$NODE_TYPE")"
    echo -e " Реестр РКН:\t$(color "$NODE_RKN_COLOR" "$NODE_RKN_STATUS")"
    echo -e " Антифрод / Риск:\t$(color "$NODE_RISK_COLOR" "$NODE_RISK"), Google Captcha: $(color "$NODE_CAPTCHA_COLOR" "$NODE_CAPTCHA_STATUS")"
    echo -e " Сетевой стек:\tBBR: $(format_value "$NODE_BBR_STATUS") | UDP: $(format_value "$NODE_UDP_STATUS") | Port 25: $(format_value "$NODE_PORT25_STATUS")"
    echo -e " Path MTU (PMTU):\t$(bold "$NODE_PMTU") (Рек. для WG: $NODE_RECOMMENDED_MTU)"
    if [[ -n "$CHECK_SNI" ]]; then
      echo -e " SelfSteal SNI:\t$(color "$NODE_SNI_COLOR" "$NODE_SNI_STATUS")"
    fi
  } | format_table
  printf "\033[1;36m================================================================================\033[0m\n\n"
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

  printf "  Консенсус: \033[1;32m%s (%s)\033[0m — %s/%s (%s%%)\n\n" "$top_code" "$top_country" "$top_count" "$total" "$top_pct"

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

print_results() {
  calculate_verdict

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    build_json
    printf "%s\n" "$RESULT_JSON"
    return
  fi

  print_header

  # 1. GeoIP Consensus Table
  printf "\033[1;97m1. 🌐 Консенсус GeoIP баз данных (18 источников)\033[0m\n"
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

  # 2. Western Unblock Table
  printf "\033[1;97m2. 🔓 Обход блокировок в РФ (Western Services)\033[0m\n"
  {
    echo -e "  Сервис\tСтатус"
    echo -e "  ------------------------------------\t------"
    for row in "${ARR_RU_UNBLOCK[@]}"; do
      IFS=$'\t' read -r name val <<<"$row"
      echo -e "  $name\t$(format_value "$val")"
    done
  } | format_table
  printf "\n"

  # 3. Reverse Geoblocking Table
  printf "\033[1;97m3. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)\033[0m\n"
  {
    echo -e "  Сервис\tСтатус"
    echo -e "  ------------------------------------\t------"
    for row in "${ARR_RU_LOCAL[@]}"; do
      IFS=$'\t' read -r name val <<<"$row"
      echo -e "  $name\t$(format_value "$val")"
    done
  } | format_table
  printf "\n"

  # 4. Connectivity
  printf "\033[1;97m4. ⚡️ Связность и скорость по регионам РФ (Multi-Region Latency & Throughput)\033[0m\n"
  {
    echo -e "  Регион (Узел связи)\tЗадержка (RTT)\tСкорость (↓ DL / ↑ UL)"
    echo -e "  ------------------------------------\t--------------\t-----------------------"
    for row in "${ARR_CONNECTIVITY[@]}"; do
      IFS=$'\t' read -r name ping_val speed_val <<<"$row"
      echo -e "  $name\t$(format_value "$ping_val")\t$(format_value "$speed_val")"
    done
  } | format_table
  if ! is_command_available "iperf3"; then
    printf "  \033[0;90m* Для замера пропускной способности iPerf3: apt install -y iperf3\033[0m\n"
  fi
  printf "\n"

  # 5. White List Readiness Table
  printf "\033[1;97m5. ⚪ Готовность к режиму «Белых списков» (White List & RU CDN Readiness)\033[0m\n"
  {
    echo -e "  Параметр / Узел\tСтатус"
    echo -e "  ------------------------------------\t------"
    for row in "${ARR_WHITELIST[@]}"; do
      IFS=$'\t' read -r name val <<<"$row"
      echo -e "  $name\t$(format_value "$val")"
    done
  } | format_table
  printf "\n"

  # 6. Security & Zero-Probing Table
  printf "\033[1;97m6. 🛡 Безопасность периметра и Zero-Probing (Anti-Active Probing / SelfSteal)\033[0m\n"
  {
    echo -e "  Тест периметра\tРезультат"
    echo -e "  ------------------------------------\t------"
    echo -e "  Защита от зондов ТСПУ (80/443)\t$(color "$NODE_ZERO_PROBE_COLOR" "$NODE_ZERO_PROBE")"
    if [[ -n "$CHECK_SNI" ]]; then
      echo -e "  Сверка SNI ➔ DNS (nDPI)\t$(color "$NODE_SNI_COLOR" "$NODE_SNI_STATUS")"
    fi
  } | format_table
  printf "\n"

  # 7. Final Verdict
  print_verdict
}

calculate_verdict() {
  local score=100
  VERDICT_DEDUCTIONS=()

  # 1. Western Unblock (Обход блокировок зарубежных сервисов)
  local unblock_ok=0 total_unblock=${#ARR_RU_UNBLOCK[@]}
  for row in "${ARR_RU_UNBLOCK[@]}"; do
    IFS=$'\t' read -r _ val <<<"$row"
    if [[ "$val" != "No"* ]]; then
      unblock_ok=$((unblock_ok + 1))
    fi
  done
  VERDICT_UNBLOCK_OK="$unblock_ok"
  VERDICT_UNBLOCK_TOTAL="$total_unblock"

  local unblock_failed=$((total_unblock - unblock_ok))
  # 1 service failed (commonly Cloudflare Turnstile anti-bot challenge on curl) is tolerated
  if (( unblock_failed > 1 )); then
    local pen=$(( (unblock_failed - 1) * 5 ))
    score=$(( score - pen ))
    VERDICT_DEDUCTIONS+=("Заблокировано $unblock_failed зарубежных сервисов (-$((pen / 10)).$((pen % 10)))")
  fi

  # 2. Reverse Geoblocking (Доступность сервисов и банков РФ)
  local banks_blocked=()
  local other_ru_blocked=()
  local gos_blocked=false
  local avito_blocked=false

  for row in "${ARR_RU_LOCAL[@]}"; do
    IFS=$'\t' read -r name val <<<"$row"
    if [[ "$val" == *"Blocked"* || "$val" == *"Captcha"* || "$val" == *"No"* ]]; then
      local clean_name="${name%% (*}"
      case "$name" in
        *"Сбер"*|*"Т-Банк"*|*"ВТБ"*|*"Альфа"*)
          banks_blocked+=("$clean_name")
          ;;
        *"Госуслуги"*|*"ФНС"*|*"Мос.ру"*)
          gos_blocked=true
          ;;
        *"Авито"*|*"Wildberries"*)
          avito_blocked=true
          ;;
        *)
          other_ru_blocked+=("$clean_name")
          ;;
      esac
    fi
  done

  if [[ ${#banks_blocked[@]} -gt 0 ]]; then
    local pen=$(( ${#banks_blocked[@]} * 5 ))
    score=$(( score - pen ))
    local b_str
    b_str=$(printf ", %s" "${banks_blocked[@]}")
    b_str="${b_str:2}"
    VERDICT_DEDUCTIONS+=("Гео-блокировка банков РФ ($b_str: -$((pen / 10)).$((pen % 10)))")
  fi

  if [[ "$gos_blocked" == "true" ]]; then
    score=$(( score - 8 ))
    VERDICT_DEDUCTIONS+=("Госуслуги заблокированы (-0.8)")
  fi

  if [[ "$avito_blocked" == "true" ]]; then
    score=$(( score - 3 ))
    VERDICT_DEDUCTIONS+=("Авито выдает капчу/фильтр (-0.3)")
  fi

  if [[ ${#other_ru_blocked[@]} -gt 0 ]]; then
    local pen=$(( ${#other_ru_blocked[@]} * 2 ))
    score=$(( score - pen ))
    local o_str
    o_str=$(printf ", %s" "${other_ru_blocked[@]}")
    o_str="${o_str:2}"
    VERDICT_DEDUCTIONS+=("Сервисы РФ заблокированы ($o_str: -$((pen / 10)).$((pen % 10)))")
  fi

  # 3. Latency to Russia (минимальный RTT до ключевых узлов: СПб / Москва)
  local msk_val spb_val best_ping=999
  msk_val=$(grep -oE '^[0-9]+' <<<"${RU_PING_MSK:-}" || true)
  spb_val=$(grep -oE '^[0-9]+' <<<"${RU_PING_SPB:-}" || true)

  if [[ -n "$msk_val" && "$msk_val" =~ ^[0-9]+$ ]] && (( msk_val < best_ping )); then best_ping="$msk_val"; fi
  if [[ -n "$spb_val" && "$spb_val" =~ ^[0-9]+$ ]] && (( spb_val < best_ping )); then best_ping="$spb_val"; fi

  if (( best_ping < 35 )); then
    : # Premium sub-35ms routing (Finland, Baltic, direct peering)
  elif (( best_ping <= 55 )); then
    score=$(( score - 3 ))
    VERDICT_DEDUCTIONS+=("Задержка до РФ ${best_ping} ms (-0.3)")
  elif (( best_ping <= 90 )); then
    score=$(( score - 6 ))
    VERDICT_DEDUCTIONS+=("Повышенная задержка до РФ ${best_ping} ms (-0.6)")
  elif (( best_ping < 999 )); then
    score=$(( score - 12 ))
    VERDICT_DEDUCTIONS+=("Высокая задержка до РФ ${best_ping} ms (-1.2)")
  else
    score=$(( score - 15 ))
    VERDICT_DEDUCTIONS+=("Нет ответа ICMP пинга до РФ (-1.5)")
  fi

  # 4. Host stack, security & RKN
  if [[ "$NODE_RKN_STATUS" == *"BLOCKED"* ]]; then
    score=$(( score - 40 ))
    VERDICT_DEDUCTIONS+=("КРИТИЧНО: IP ноды занесен в реестр блокировок РКН (-4.0)")
  fi

  if [[ "$NODE_ZERO_PROBE" == *"Vulnerable"* ]]; then
    score=$(( score - 10 ))
    VERDICT_DEDUCTIONS+=("Утечка домена сканерам ТСПУ на портах 80/443 (-1.0)")
  fi

  if [[ "$NODE_SNI_STATUS" == *"Mismatch"* ]]; then
    score=$(( score - 10 ))
    VERDICT_DEDUCTIONS+=("Несоответствие SNI и DNS (риск NDPI_UNRESOLVED_HOSTNAME: -1.0)")
  fi

  if [[ "$WL_CASCADE_STATUS" == *"В зоне риска"* ]]; then
    score=$(( score - 5 ))
    VERDICT_DEDUCTIONS+=("Задержка каскада до Anycast РФ >120ms (риск таймаута CDN 504: -0.5)")
  fi

  if [[ "$NODE_BBR_STATUS" != *"Active"* ]]; then
    score=$(( score - 3 ))
    VERDICT_DEDUCTIONS+=("TCP BBR не включен (-0.3)")
  fi

  if [[ "$NODE_UDP_STATUS" == *"Blocked"* ]]; then
    score=$(( score - 15 ))
    VERDICT_DEDUCTIONS+=("UDP заблокирован хостером (-1.5)")
  fi

  if [[ "${NODE_RISK_SCORE:-}" =~ ^[0-9]+$ ]]; then
    local risk_num="$NODE_RISK_SCORE"
    if (( risk_num > 50 )); then
      score=$(( score - 15 ))
      VERDICT_DEDUCTIONS+=("Высокий Risk Score IP ($risk_num/100: -1.5)")
    elif (( risk_num > 25 )); then
      score=$(( score - 5 ))
      VERDICT_DEDUCTIONS+=("Повышенный Risk Score IP ($risk_num/100: -0.5)")
    fi
  fi

  # Bonus: YouTube Ad-Free
  if [[ "$YOUTUBE_AD_FREE" == "true" ]]; then
    score=$(( score + 2 ))
  fi

  if (( score > 100 )); then score=100; fi
  if (( score < 10 )); then score=10; fi

  VERDICT_SCORE="$((score / 10)).$((score % 10))"

  if (( score >= 90 )); then
    VERDICT_RATING="ОТЛИЧНО ДЛЯ VPN"
    VERDICT_COLOR="\033[1;32m"
  elif (( score >= 75 )); then
    VERDICT_RATING="ХОРОШО (ТРЕБУЕТСЯ SPLIT-TUNNELING ДЛЯ БАНКОВ)"
    VERDICT_COLOR="\033[1;33m"
  elif (( score >= 60 )); then
    VERDICT_RATING="УДОВЛЕТВОРИТЕЛЬНО"
    VERDICT_COLOR="\033[1;33m"
  else
    VERDICT_RATING="НЕ РЕКОМЕНДУЕТСЯ"
    VERDICT_COLOR="\033[1;31m"
  fi
}

print_verdict() {
  printf "\033[1;36m================================================================================\033[0m\n"
  printf " ⚖️  \033[1;97mВердикт пригодности ноды для РФ аудитории\033[0m\n"
  printf "\033[1;36m================================================================================\033[0m\n"

  printf " • %bОценка ноды: %s / 10 (%s)\033[0m\n" "$VERDICT_COLOR" "$VERDICT_SCORE" "$VERDICT_RATING"
  printf "   - Зарубежные сервисы: Обход блокировок функционирует (%s/%s сервисов доступно).\n" \
    "$VERDICT_UNBLOCK_OK" "$VERDICT_UNBLOCK_TOTAL"

  if [[ "$NODE_RKN_STATUS" == *"BLOCKED"* ]]; then
    printf "   - 🚫 \033[1;31mВНИМАНИЕ:\033[0m IP ноды занесен в реестр блокировок РКН! Соединение из РФ блокируется.\n"
  fi

  if [[ "$YOUTUBE_AD_FREE" == "true" ]]; then
    printf "   - \033[1;32mYouTube: Без рекламы 🎬 (Регион %s)\033[0m\n" "$YOUTUBE_DETECTED_CC"
  fi

  local blocked_ru=()
  local blocked_domains=()
  for row in "${ARR_RU_LOCAL[@]}"; do
    IFS=$'\t' read -r name val <<<"$row"
    if [[ "$val" == *"Blocked"* || "$val" == *"Captcha"* ]]; then
      blocked_ru+=("${name%% (*}")
      local dom
      dom=$(grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' <<<"$name" | head -n1)
      if [[ -n "$dom" ]]; then
        blocked_domains+=("$dom")
      fi
    fi
  done

  if [[ ${#blocked_ru[@]} -gt 0 ]]; then
    local blocked_str
    blocked_str=$(printf ", %s" "${blocked_ru[@]}")
    blocked_str="${blocked_str:2}"
    printf "   - ⚠️ \033[1;33mВнимание:\033[0m Зарубежный IP блокируется сервисами РФ: %s.\n" "$blocked_str"
    if [[ ${#blocked_domains[@]} -gt 0 ]]; then
      local dom_list
      dom_list=$(printf ", %s" "${blocked_domains[@]}")
      dom_list="${dom_list:2}"
      printf "   - Рекомендация Split-Tunneling (bypass): \033[1;36m%s\033[0m\n" "$dom_list"
    else
      printf "   - Рекомендация: настройте Split-Tunneling (прямой маршрут без VPN для этих доменов).\n"
    fi
  else
    printf "   - \033[1;32mСервисы РФ:\033[0m Все банки и сервисы РФ открываются напрямую без ограничений.\n"
  fi

  if [[ -n "$WL_NODE_ROLE" ]]; then
    if [[ "$WL_NODE_ROLE" == *"Origin"* ]]; then
      printf "   - ⚪ \033[1;32mБелые списки (WL):\033[0m Узел внутри РФ (Origin). Доступен для Anycast CDN-фронтинга.\n"
    else
      printf "   - ⚪ \033[1;36mБелые списки (WL):\033[0m Зарубежный Exit. Каскад VLESS XHTTP через CDN: %s (RTT %s).\n" "$WL_CASCADE_STATUS" "$WL_ANYCAST_RTT"
    fi
  fi

  printf "   - 🛡 \033[1;33mСетевой стек под VPN:\033[0m Path MTU %s (Рекомендуемый для WG/AWG: \033[1;97m%s\033[0m).\n" "$NODE_PMTU" "$NODE_RECOMMENDED_MTU"
  printf "   - ⚠️ \033[0;90mПримечание WL:\033[0m В режиме Белых Списков UDP полностью блокируется ТСПУ — WireGuard/AWG не работают, используйте VLESS XHTTP over TCP/TLS 443.\n"

  printf "   - Связность: Москва %s, СПб %s, Поволжье %s, Урал %s, Сибирь %s.\n" \
    "$RU_PING_MSK" "$RU_PING_SPB" "$RU_PING_KZN" "$RU_PING_EKAT" "$RU_PING_NSK"
  if [[ -n "$RU_IPERF_SPEED" && "$RU_IPERF_SPEED" != "—" ]]; then
    printf "   - Пропускная способность iPerf3 (Москва): %s.\n" "$RU_IPERF_SPEED"
  fi

  if [[ ${#VERDICT_DEDUCTIONS[@]} -gt 0 ]]; then
    local d_str
    d_str=$(printf "; %s" "${VERDICT_DEDUCTIONS[@]}")
    d_str="${d_str:2}"
    printf "   - \033[0;90mШтрафы оценки: %s\033[0m\n" "$d_str"
  fi

  if [[ "$NODE_BBR_STATUS" != *"Active"* ]]; then
    printf "   - 💡 \033[0;90mСовет: включите TCP BBR для ускорения канала при потерях пакетов:\033[0m\n"
    printf "     \033[0;90mecho 'net.core.default_qdisc=fq' >> /etc/sysctl.conf && echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf && sysctl -p\033[0m\n"
  fi
  printf "\033[1;36m================================================================================\033[0m\n\n"
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

  local whitelist_json="{}"
  for row in "${ARR_WHITELIST[@]}"; do
    IFS=$'\t' read -r name val <<<"$row"
    whitelist_json=$(jq --arg k "$name" --arg v "$val" '.[$k] = $v' <<<"$whitelist_json")
  done

  local deductions_json="[]"
  if [[ ${#VERDICT_DEDUCTIONS[@]} -gt 0 ]]; then
    deductions_json=$(jq -c -n '$ARGS.positional' --args "${VERDICT_DEDUCTIONS[@]}")
  fi

  RESULT_JSON=$(jq -n \
    --arg ip "${EXTERNAL_IPV4:-}" \
    --arg country "${NODE_COUNTRY_CODE:-}" \
    --arg city "${NODE_CITY:-}" \
    --arg asn "${NODE_ASN:-}" \
    --arg org "${NODE_ORG:-}" \
    --arg host_type "${NODE_TYPE:-}" \
    --arg risk "${NODE_RISK:-}" \
    --arg captcha "${NODE_CAPTCHA_STATUS:-}" \
    --arg rkn "${NODE_RKN_STATUS:-}" \
    --arg pmtu "${NODE_PMTU:-}" \
    --arg rec_mtu "${NODE_RECOMMENDED_MTU:-}" \
    --arg bbr "${NODE_BBR_STATUS:-}" \
    --arg udp "${NODE_UDP_STATUS:-}" \
    --arg port25 "${NODE_PORT25_STATUS:-}" \
    --arg zero_probe "${NODE_ZERO_PROBE:-}" \
    --arg sni_status "${NODE_SNI_STATUS:-}" \
    --arg yt_ad_free "$YOUTUBE_AD_FREE" \
    --arg yt_cc "$YOUTUBE_DETECTED_CC" \
    --arg verdict_score "$VERDICT_SCORE" \
    --arg verdict_rating "$VERDICT_RATING" \
    --arg verdict_ok "$VERDICT_UNBLOCK_OK" \
    --arg verdict_total "$VERDICT_UNBLOCK_TOTAL" \
    --argjson verdict_deductions "$deductions_json" \
    --argjson geoip "$geoip_json" \
    --argjson unblock "$unblock_json" \
    --argjson local "$local_json" \
    --argjson connectivity "$conn_json" \
    --argjson whitelist "$whitelist_json" \
    '{
      ip: $ip,
      location: { country: $country, city: $city, asn: $asn, org: $org },
      quality: { host_type: $host_type, risk: $risk, google_captcha: $captcha, rkn_registry: $rkn },
      network: { bbr: $bbr, udp: $udp, port25: $port25, pmtu: $pmtu, recommended_mtu: $rec_mtu },
      security: { zero_probe: $zero_probe, sni_status: $sni_status },
      youtube: { ad_free: ($yt_ad_free == "true"), country: $yt_cc },
      whitelist_readiness: $whitelist,
      verdict: {
        score: ($verdict_score | tonumber),
        rating: $verdict_rating,
        unblock_available: ($verdict_ok | tonumber),
        unblock_total: ($verdict_total | tonumber),
        deductions: $verdict_deductions
      },
      geoip_consensus: $geoip,
      ru_unblock: $unblock,
      ru_local_services: $local,
      connectivity: $connectivity
    }')
}

display_help() {
  cat <<EOF
Usage: nodecheck.sh [OPTIONS]

NodeCheck (RU Edition) - Comprehensive VPN Node Quality & Censorship Auditor

Options:
  -h, --help               Show this help message and exit
  -v, --verbose            Enable verbose logging
  -d, --debug              Enable debug mode (saves trace to $DEBUG_LOG_FILE)
  -j, --json               Output results in pure JSON format
  --no-iperf               Skip iPerf3 speedtest (latency ping only)
  --full-iperf             Run iPerf3 duplex speedtest on all 7 Russian regions
  --sni DOMAIN             Verify domain against node IP (protect against NDPI_UNRESOLVED_HOSTNAME)
  --cdn URL                Validate VLESS XHTTP CDN endpoint (Bodiless GET / Header Uplink check)
  -p, --proxy ADDR         Use SOCKS5/SOCKS5h proxy (format: host:port)
  -i, --interface IF       Bind requests to network interface (e.g. eth0, wg0)
  --no-doh                 Disable DNS-over-HTTPS (use system resolver)
  --doh PROVIDER           Select DoH provider: cloudflare, quad9, adguard

Examples:
  ./nodecheck.sh                         # Run full audit (GeoIP, Unblock, RU Geoblock, All-RU Ping, iPerf3)
  ./nodecheck.sh --full-iperf            # Test iPerf3 bandwidth on all 7 RU regions
  ./nodecheck.sh --sni mydomain.com      # Validate domain against IP for SelfSteal SNI
  ./nodecheck.sh --cdn https://cdn.x.com # Test VLESS XHTTP CDN endpoint
  ./nodecheck.sh --no-iperf              # Run audit without bandwidth speedtest
  ./nodecheck.sh -p 127.0.0.1:1080       # Audit VPN/Proxy node via SOCKS5
  ./nodecheck.sh -j                      # Output pure JSON for monitoring / bots

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
        shift
        ;;
      --sni)
        if [[ $# -lt 2 || "$2" == -* ]]; then
          error_exit "Option $1 requires a domain argument"
        fi
        CHECK_SNI="$2"
        shift 2
        ;;
      --cdn)
        if [[ $# -lt 2 || "$2" == -* ]]; then
          error_exit "Option $1 requires a URL argument"
        fi
        CUSTOM_CDN_ENDPOINT="$2"
        shift 2
        ;;
      -p|--proxy)
        if [[ $# -lt 2 || "$2" == -* ]]; then
          error_exit "Option $1 requires an argument (host:port)"
        fi
        PROXY_ADDR="$2"
        shift 2
        ;;
      -i|--interface)
        if [[ $# -lt 2 || "$2" == -* ]]; then
          error_exit "Option $1 requires an argument (interface name)"
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
          error_exit "Option $1 requires an argument (cloudflare|quad9|adguard)"
        fi
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

  TMP_WORK_DIR=$(mktemp -d "/tmp/nodecheck.XXXXXX" 2>/dev/null || mktemp -d)
  if [[ -z "$TMP_WORK_DIR" || ! -d "$TMP_WORK_DIR" ]]; then
    error_exit "Failed to create secure temporary directory"
  fi
  trap cleanup EXIT
  trap 'cleanup; exit 130' INT
  trap 'cleanup; exit 143' TERM

  install_dependencies
  check_doh

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 1/5:\033[0m Определение параметров ноды, MTU и реестра РКН...\n"
  fi
  discover_external_ips

  if [[ -z "$EXTERNAL_IPV4" && -z "$EXTERNAL_IPV6" ]]; then
    error_exit "No active internet connection or external IP detected."
  fi

  get_vpn_node_info

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "    \033[1;32m✓\033[0m Нода: \033[1;97m%s\033[0m (%s) | %s | BBR: %s | Port 25: %s\n" \
      "${EXTERNAL_IPV4:-$EXTERNAL_IPV6}" "${NODE_COUNTRY_CODE:-??}" "${NODE_ORG:-${NODE_ASN:-ISP}}" "$NODE_BBR_STATUS" "$NODE_PORT25_STATUS"
  fi

  # 1. 18 GeoIP Databases
  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 2/5:\033[0m Опрос 18 GeoIP баз данных (параллельно)...\n"
  fi
  run_geoip_consensus

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "    \033[1;32m✓\033[0m 18 GeoIP баз данных опрошены\n"
  fi

  # 2. Western Services & RU Local Services
  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 3/5:\033[0m Проверка 33 сервисов обхода цензуры и Рунета (параллельно)...\n"
  fi
  run_services_check

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    local unblock_ok=0
    for row in "${ARR_RU_UNBLOCK[@]}"; do
      IFS=$'\t' read -r _ val <<<"$row"
      if [[ "$val" != "No"* ]]; then unblock_ok=$((unblock_ok + 1)); fi
    done
    printf "    \033[1;32m✓\033[0m Сервисы: \033[1;97m%d/%d\033[0m зарубежных открыты | Рунет проверен\n" "$unblock_ok" "${#ARR_RU_UNBLOCK[@]}"
  fi

  # 3. Connectivity
  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 4/5:\033[0m Замер связности и скорости по 7 регионам РФ (в реальном времени):\n"
  fi
  measure_ru_connectivity

  # 4. White List & Cascade Readiness
  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 5/5:\033[0m Аудит готовности к Белым Спискам и каскаду VLESS XHTTP...\n"
  fi
  measure_whitelist_readiness

  printf "\n"
  print_results
}

main "$@"
