#!/usr/bin/env bash

# ==============================================================================
# VPNCheck (RU Edition) v3.1.0
# Comprehensive VPN Node Quality, Geolocation & Censorship Auditor
# Tailored for Russian Federation Network Realities (TSPU / Reverse Geoblocking)
#
# GitHub: https://github.com/justik13/vpncheck
# License: MIT
# ==============================================================================

set -o pipefail

SCRIPT_VERSION="3.1.0-ru"

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
RU_PING_ROSTOV=""
RU_PING_KZN=""
RU_PING_EKAT=""
RU_PING_NSK=""
RU_PING_IRK=""
RU_IPERF_SPEED=""

YOUTUBE_AD_FREE=false
YOUTUBE_DETECTED_CC=""

CHATGPT_STATSIG_API_KEY="client-zUdXdSTygXJdzoE0sWTkP8GKTVsUMF2IRM7ShVO2JAG"
YOUTUBE_SOCS_COOKIE="CAISNQgDEitib3FfaWRlbnRpdHlmcm9udGVuZHVpc2VydmVyXzIwMjUwNzMwLjA1X3AwGgJlbiACGgYIgPC_xAY"
GEMINI_REGIONS_URL="https://ai.google.dev/gemini-api/docs/available-regions.md.txt"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"

DEBUG_LOG_FILE="/tmp/vpncheck_debug.log"
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
    ""|"null"|"$STATUS_NA")
      color "$COLOR_NULL" "$STATUS_NA"
      ;;
    "Yes"*|"OK"*|"Clean"*|"Active"|"Open"|"True"|"true"|*"Protected"*)
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
        required_cmds+=("iputils-ping")
      else
        required_cmds+=("$cmd")
      fi
    fi
  done

  if ! is_command_available "column"; then
    required_cmds+=("bsdextrautils")
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
  local is_vpn=false is_tor=false is_datacenter=false risk_score=0

  if [[ -n "$query_raw" ]] && jq -e . >/dev/null 2>&1 <<<"$query_raw"; then
    is_vpn=$(jq -r '.risk.is_vpn // false' <<<"$query_raw")
    is_tor=$(jq -r '.risk.is_tor // false' <<<"$query_raw")
    is_datacenter=$(jq -r '.risk.is_datacenter // false' <<<"$query_raw")
    risk_score=$(jq -r '.risk.risk_score // 0' <<<"$query_raw")
  fi

  if [[ "$is_datacenter" == "true" ]]; then
    NODE_TYPE="Data Center / Hosting"
  elif [[ "$is_vpn" == "true" ]]; then
    NODE_TYPE="Commercial VPN / Proxy"
  elif [[ "$is_tor" == "true" ]]; then
    NODE_TYPE="Tor Exit Node"
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

  # Port 25 Outbound (native bash /dev/tcp with nc fallback)
  if timeout 2 bash -c 'echo > /dev/tcp/smtp.gmail.com/25' 2>/dev/null; then
    NODE_PORT25_STATUS="Open"
  elif is_command_available nc && nc -z -w 2 smtp.gmail.com 25 2>/dev/null; then
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
      raw=$(curl_wrapper GET "https://ipinfo.io/json" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw")
      ;;
    "IP-API.com")
      local raw
      raw=$(curl_wrapper GET "http://ip-api.com/json/" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.countryCode // empty' <<<"$raw")
      ;;
    "Cloudflare")
      local raw
      raw=$(curl_wrapper GET "https://cloudflare.com/cdn-cgi/trace" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(grep "^loc=" <<<"$raw" | head -n1 | cut -d= -f2 | tr -d '[:space:]')
      ;;
    "IP.SB")
      local raw
      raw=$(curl_wrapper GET "https://api.ip.sb/geoip" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "Ipregistry")
      local raw
      raw=$(curl_wrapper GET "https://api.ipregistry.co/?key=tryout" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.location.country.code // empty' <<<"$raw")
      ;;
    "IP-API.co")
      local raw
      raw=$(curl_wrapper GET "https://ipapi.co/json" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "IP2Location.io")
      local raw
      raw=$(curl_wrapper GET "https://api.ip2location.io/" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "Country.is")
      local raw
      raw=$(curl_wrapper GET "https://api.country.is" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw")
      ;;
    "GeoJS")
      local raw
      raw=$(curl_wrapper GET "https://get.geojs.io/v1/ip/country.json" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw")
      ;;
    "2ip.io")
      local raw
      raw=$(curl_wrapper GET "https://api.2ip.io" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.code // empty' <<<"$raw")
      ;;
    "ipwho.is")
      local raw
      raw=$(curl_wrapper GET "https://ipwho.is/" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
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
      raw=$(curl_wrapper GET "https://api.ipbase.com/v1/json/" --timeout 3 2>/dev/null)
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
      cc=$(jq -r '.location.country // empty' <<<"$raw")
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
  iata=$(grep -oE "[a-z]{3}[0-9]+s[0-9]+" <<<"$resp" | head -n 1 | cut -c 1-3 | tr '[:lower:]' '[:upper:]')
  if [[ -z "$iata" ]]; then
    iata=$(sed -n 's/.*=> [a-z]*\([a-z]\{3\}\)[a-z0-9_-]*.*/\1/p' <<<"$resp" | head -n 1 | tr '[:lower:]' '[:upper:]')
  fi
  if [[ -n "$iata" ]]; then echo "Yes ($iata)"; else echo "Yes"; fi
}

lookup_youtube_premium() {
  local resp
  resp=$(curl_wrapper GET "https://www.youtube.com/premium" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9" 2>/dev/null)
  if grep -qi "YouTube Premium is not available in your country" <<<"$resp"; then
    echo "No"
  else
    echo "Yes"
  fi
}

lookup_youtube_music() {
  local resp
  resp=$(curl_wrapper GET "https://music.youtube.com/" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9" 2>/dev/null)
  if grep -qi "YouTube Music is not available in your area" <<<"$resp"; then
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

# ------------------------------------------------------------------------------
# 3. RU Reverse Geoblocking Lookups
# ------------------------------------------------------------------------------

# Uses -k to validate reachability even when Russian Минцифры CA is not in system trust store
curl_ru_code() {
  local url="$1" timeout="${2:-4}"
  local code
  code=$(curl -sk -L --max-time "$timeout" -A "$USER_AGENT" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  code="${code: -3}"
  echo "${code:-000}"
}

lookup_gosuslugi() {
  local code
  code=$(curl_ru_code "https://www.gosuslugi.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked ($code)"; fi
}

lookup_yandex() {
  local resp
  resp=$(curl -sk -L --max-time 3 -A "$USER_AGENT" "https://ya.ru" 2>/dev/null)
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

lookup_avito() {
  local code resp
  resp=$(curl -sk -L --max-time 3 -A "$USER_AGENT" "https://www.avito.ru" 2>/dev/null)
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

lookup_kinopoisk() {
  local code
  code=$(curl_ru_code "https://www.kinopoisk.ru")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "OK"; else echo "Blocked ($code)"; fi
}

# ------------------------------------------------------------------------------
# 4. Multi-Region RU Connectivity & Speed
# ------------------------------------------------------------------------------

ping_host() {
  local host="$1" out_file="$2"
  local p
  p=$(ping -c 2 -W 2 "$host" 2>/dev/null | tail -n 1 | awk -F '/' '{print $5}')
  if [[ -n "$p" ]]; then
    printf "%.1f ms" "$p" > "$out_file"
  else
    printf "N/A" > "$out_file"
  fi
}

iperf_speed_test() {
  local host="$1"
  shift
  local ports=("$@")
  if [[ ${#ports[@]} -eq 0 ]]; then ports=(5201); fi
  local res=""
  for p in "${ports[@]}"; do
    res=$(timeout 3 iperf3 -c "$host" -p "$p" -t 1.5 -P 2 -J 2>/dev/null || echo "")
    if [[ -n "$res" ]] && jq -e '.end.sum_received.bits_per_second // .end.sum_sent.bits_per_second' >/dev/null 2>&1 <<<"$res"; then
      jq -r '((.end.sum_received.bits_per_second // .end.sum_sent.bits_per_second // 0) / 1000000 | round | tostring) + " Mbps"' <<<"$res"
      return
    fi
  done
  echo "—"
}

measure_ru_connectivity() {
  local p_dir="$TMP_WORK_DIR/pings"
  mkdir -p "$p_dir"

  # Ping 7 macro-regions across Russia in parallel
  ( ping_host "spd-rudp.hostkey.ru" "$p_dir/msk" ) &
  ( ping_host "st.spb.ertelecom.ru" "$p_dir/spb" ) &
  ( ping_host "st.rostov.ertelecom.ru" "$p_dir/rostov" ) &
  ( ping_host "st.kzn.ertelecom.ru" "$p_dir/kzn" ) &
  ( ping_host "st.ekat.ertelecom.ru" "$p_dir/ekat" ) &
  ( ping_host "st.nsk.ertelecom.ru" "$p_dir/nsk" ) &
  ( ping_host "st.irkutsk.ertelecom.ru" "$p_dir/irk" ) &
  wait

  RU_PING_MSK=$(<"$p_dir/msk")
  RU_PING_SPB=$(<"$p_dir/spb")
  RU_PING_ROSTOV=$(<"$p_dir/rostov")
  RU_PING_KZN=$(<"$p_dir/kzn")
  RU_PING_EKAT=$(<"$p_dir/ekat")
  RU_PING_NSK=$(<"$p_dir/nsk")
  RU_PING_IRK=$(<"$p_dir/irk")

  local s_msk="—" s_spb="—" s_ekat="—" s_nsk="—"
  if [[ "$RUN_IPERF" == "true" ]] && is_command_available "iperf3"; then
    s_msk=$(iperf_speed_test "spd-rudp.hostkey.ru" 5201 5202 5203 5204 5205)
    s_spb=$(iperf_speed_test "st.spb.ertelecom.ru" 5201 5202 5203)
    s_ekat=$(iperf_speed_test "st.ekat.ertelecom.ru" 5201 5202 5204)
    s_nsk=$(iperf_speed_test "st.nsk.ertelecom.ru" 5201 5202 5203)
  fi

  RU_IPERF_SPEED="$s_msk"

  ARR_CONNECTIVITY+=( "Москва (Центр, Hostkey / MSK-IX)"$'\t'"$RU_PING_MSK"$'\t'"$s_msk" )
  ARR_CONNECTIVITY+=( "Санкт-Петербург (Северо-Запад, SPB)"$'\t'"$RU_PING_SPB"$'\t'"$s_spb" )
  ARR_CONNECTIVITY+=( "Екатеринбург (Урал, ER-Telecom)"$'\t'"$RU_PING_EKAT"$'\t'"$s_ekat" )
  ARR_CONNECTIVITY+=( "Новосибирск (Сибирь, ER-Telecom)"$'\t'"$RU_PING_NSK"$'\t'"$s_nsk" )
  ARR_CONNECTIVITY+=( "Ростов-на-Дону (Юг)"$'\t'"$RU_PING_ROSTOV"$'\t'"—" )
  ARR_CONNECTIVITY+=( "Казань (Поволжье)"$'\t'"$RU_PING_KZN"$'\t'"—" )
  ARR_CONNECTIVITY+=( "Иркутск (Восточная Сибирь)"$'\t'"$RU_PING_IRK"$'\t'"—" )
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
  printf " 🇷🇺 \033[1;97mVPNCheck (RU Edition) - VPN Node & Quality Auditor v%s\033[0m\n" "$SCRIPT_VERSION"
  printf "\033[1;36m================================================================================\033[0m\n"
  {
    echo -e " IPv4:\t$(bold "${EXTERNAL_IPV4:-N/A}")"
    if [[ -n "$EXTERNAL_IPV6" ]]; then
      echo -e " IPv6:\t$(bold "$EXTERNAL_IPV6")"
    fi
    echo -e " Локация / ASN:\t$(color "$COLOR_ASN" "$NODE_COUNTRY_CODE ($NODE_CITY)") — $NODE_ASN ($NODE_ORG)"
    echo -e " Тип хоста:\t$(bold "$NODE_TYPE")"
    echo -e " Антифрод / Риск:\t$(color "$NODE_RISK_COLOR" "$NODE_RISK"), Google Captcha: $(color "$NODE_CAPTCHA_COLOR" "$NODE_CAPTCHA_STATUS")"
    echo -e " Сетевой стек:\tBBR: $(format_value "$NODE_BBR_STATUS") | UDP: $(format_value "$NODE_UDP_STATUS") | Port 25: $(format_value "$NODE_PORT25_STATUS")"
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
  printf "\033[1;97m4. ⚡️ Связность и скорость по регионам РФ (Multi-Region Latency & Speed)\033[0m\n"
  {
    echo -e "  Регион (Узел связи)\tЗадержка (RTT)\tСкорость (iPerf3)"
    echo -e "  ------------------------------------\t--------------\t-----------------"
    for row in "${ARR_CONNECTIVITY[@]}"; do
      IFS=$'\t' read -r name ping_val speed_val <<<"$row"
      echo -e "  $name\t$(format_value "$ping_val")\t$(format_value "$speed_val")"
    done
  } | format_table
  printf "\n"

  # 5. Security
  printf "\033[1;97m5. 🛡 Безопасность периметра (Zero-Probing Check)\033[0m\n"
  {
    echo -e "  Порт 80/443 IP-Probe\t$(format_value "$NODE_ZERO_PROBE")"
  } | format_table
  printf "\n"

  # 6. Final Verdict
  print_verdict
}

print_verdict() {
  printf "\033[1;36m================================================================================\033[0m\n"
  printf " ⚖️  \033[1;97mВердикт пригодности ноды для РФ аудитории\033[0m\n"
  printf "\033[1;36m================================================================================\033[0m\n"

  local unblock_ok=0 total_unblock=${#ARR_RU_UNBLOCK[@]}
  for row in "${ARR_RU_UNBLOCK[@]}"; do
    IFS=$'\t' read -r _ val <<<"$row"
    if [[ "$val" != "No"* ]]; then
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
    printf " • \033[1;32mОценка ноды: 9.3 / 10 (ОТЛИЧНО ДЛЯ VPN)\033[0m\n"
    printf "   - Зарубежные сервисы: Обход блокировок функционирует (%s/%s сервисов доступно).\n" "$unblock_ok" "$total_unblock"
  else
    printf " • \033[1;33mОценка ноды: 7.8 / 10 (ХОРОШО / С ОГРАНИЧЕНИЯМИ)\033[0m\n"
  fi

  if [[ "$YOUTUBE_AD_FREE" == "true" ]]; then
    printf "   - \033[1;32mYouTube: Без рекламы 🎬 (Регион %s)\033[0m\n" "$YOUTUBE_DETECTED_CC"
  fi

  if [[ ${#blocked_ru[@]} -gt 0 ]]; then
    local blocked_str
    blocked_str=$(printf ", %s" "${blocked_ru[@]}")
    blocked_str="${blocked_str:2}"
    printf "   - ⚠️ \033[1;33mВнимание:\033[0m Зарубежный IP блокируется сервисами РФ: %s.\n" "$blocked_str"
    printf "   - Рекомендация: настройте Split-Tunneling (прямой маршрут без VPN для этих доменов).\n"
  else
    printf "   - Сервисы РФ открываются без ограничений.\n"
  fi

  printf "   - Связность: Москва %s, СПб %s, Поволжье %s, Урал %s, Сибирь %s.\n" \
    "$RU_PING_MSK" "$RU_PING_SPB" "$RU_PING_KZN" "$RU_PING_EKAT" "$RU_PING_NSK"
  if [[ -n "$RU_IPERF_SPEED" ]]; then
    printf "   - Пропускная способность iPerf3: %s.\n" "$RU_IPERF_SPEED"
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
    --arg zero_probe "${NODE_ZERO_PROBE:-}" \
    --arg yt_ad_free "$YOUTUBE_AD_FREE" \
    --arg yt_cc "$YOUTUBE_DETECTED_CC" \
    --argjson geoip "$geoip_json" \
    --argjson unblock "$unblock_json" \
    --argjson local "$local_json" \
    --argjson connectivity "$conn_json" \
    '{
      ip: $ip,
      location: { country: $country, city: $city, asn: $asn, org: $org },
      quality: { host_type: $host_type, risk: $risk, google_captcha: $captcha },
      network: { bbr: $bbr, udp: $udp, port25: $port25 },
      security: { zero_probe: $zero_probe },
      youtube: { ad_free: ($yt_ad_free == "true"), country: $yt_cc },
      geoip_consensus: $geoip,
      ru_unblock: $unblock,
      ru_local_services: $local,
      connectivity: $connectivity
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
  --no-iperf               Skip 3-second iPerf3 speedtest
  -p, --proxy ADDR         Use SOCKS5/SOCKS5h proxy (format: host:port)
  -i, --interface IF       Bind requests to network interface (e.g. eth0, wg0)
  --no-doh                 Disable DNS-over-HTTPS (use system resolver)
  --doh PROVIDER           Select DoH provider: cloudflare, quad9, adguard

Examples:
  ./vpncheck.sh                         # Run full audit (GeoIP, Unblock, RU Geoblock, All-RU Ping, iPerf3)
  ./vpncheck.sh --no-iperf              # Run audit without bandwidth speedtest
  ./vpncheck.sh -p 127.0.0.1:1080       # Audit VPN/Proxy node via SOCKS5
  ./vpncheck.sh -j                      # Output pure JSON for monitoring / bots

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

  TMP_WORK_DIR=$(mktemp -d "/tmp/vpncheck.XXXXXX")
  trap cleanup EXIT INT TERM

  install_dependencies
  check_doh

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 1/4: Определение внешних IP и параметров ноды...\033[0m\n" >&2
  fi
  discover_external_ips

  if [[ -z "$EXTERNAL_IPV4" && -z "$EXTERNAL_IPV6" ]]; then
    error_exit "No active internet connection or external IP detected."
  fi

  get_vpn_node_info

  # 1. 18 GeoIP Databases
  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 2/4: Опрос 18 GeoIP баз данных (параллельно)...\033[0m\n" >&2
  fi
  run_geoip_consensus

  # 2. Western Services & RU Local Services
  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 3/4: Проверка обхода цензуры и доступности сервисов РФ...\033[0m\n" >&2
  fi
  ARR_RU_UNBLOCK+=( "Instagram (Meta)"$'\t'"$(lookup_instagram)" )
  ARR_RU_UNBLOCK+=( "Discord (Voice/Gateway)"$'\t'"$(lookup_discord)" )
  ARR_RU_UNBLOCK+=( "Twitter / X"$'\t'"$(lookup_twitter_x)" )
  ARR_RU_UNBLOCK+=( "OpenAI ChatGPT"$'\t'"$(lookup_chatgpt)" )
  ARR_RU_UNBLOCK+=( "Anthropic Claude AI"$'\t'"$(lookup_claude_ai)" )
  ARR_RU_UNBLOCK+=( "Google (Регион)"$'\t'"$(lookup_google)" )
  ARR_RU_UNBLOCK+=( "Google Gemini"$'\t'"$(lookup_gemini)" )
  local yt_res
  yt_res=$(lookup_youtube)
  YOUTUBE_DETECTED_CC=$(awk '{print $1}' <<<"$yt_res")
  if [[ "$yt_res" == *"Без рекламы"* ]]; then
    YOUTUBE_AD_FREE=true
  fi
  ARR_RU_UNBLOCK+=( "YouTube"$'\t'"$yt_res" )
  ARR_RU_UNBLOCK+=( "YouTube CDN"$'\t'"$(lookup_youtube_cdn)" )
  ARR_RU_UNBLOCK+=( "YouTube Premium"$'\t'"$(lookup_youtube_premium)" )
  ARR_RU_UNBLOCK+=( "YouTube Music"$'\t'"$(lookup_youtube_music)" )
  ARR_RU_UNBLOCK+=( "Rutracker"$'\t'"$(lookup_rutracker)" )
  ARR_RU_UNBLOCK+=( "Spotify Signup"$'\t'"$(lookup_spotify_signup)" )
  ARR_RU_UNBLOCK+=( "Netflix"$'\t'"$(lookup_netflix)" )
  ARR_RU_UNBLOCK+=( "Steam Store (Игры)"$'\t'"$(lookup_steam)" )
  ARR_RU_UNBLOCK+=( "PlayStation Network"$'\t'"$(lookup_playstation)" )
  ARR_RU_UNBLOCK+=( "Reddit"$'\t'"$(lookup_reddit)" )
  ARR_RU_UNBLOCK+=( "Apple Services"$'\t'"$(lookup_apple)" )

  ARR_RU_LOCAL+=( "Госуслуги (gosuslugi.ru)"$'\t'"$(lookup_gosuslugi)" )
  ARR_RU_LOCAL+=( "Яндекс (ya.ru)"$'\t'"$(lookup_yandex)" )
  ARR_RU_LOCAL+=( "ВКонтакте (vk.com)"$'\t'"$(lookup_vk)" )
  ARR_RU_LOCAL+=( "СберБанк (sberbank.ru)"$'\t'"$(lookup_sberbank)" )
  ARR_RU_LOCAL+=( "Т-Банк (tbank.ru)"$'\t'"$(lookup_tbank)" )
  ARR_RU_LOCAL+=( "ВТБ (vtb.ru)"$'\t'"$(lookup_vtb)" )
  ARR_RU_LOCAL+=( "Авито (avito.ru)"$'\t'"$(lookup_avito)" )
  ARR_RU_LOCAL+=( "Кинопоиск (kinopoisk.ru)"$'\t'"$(lookup_kinopoisk)" )

  # 3. Connectivity
  if [[ "$JSON_OUTPUT" != "true" ]]; then
    printf "\033[1;36m[*] Шаг 4/4: Проверка связности по регионам РФ и iPerf3...\033[0m\n\n" >&2
  fi
  measure_ru_connectivity

  print_results
}

main "$@"
