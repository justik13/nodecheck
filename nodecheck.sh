#!/usr/bin/env bash

# ==============================================================================
# NodeCheck (RU Edition) v3.6.1
# Comprehensive Node Hardware, Network Quality, Geolocation & Access Auditor
# Tailored for Russian Federation Network Realities (Reverse Geoblocking / Multi-Region)
#
# GitHub: https://github.com/justik13/nodecheck
# License: MIT
# ==============================================================================

set -o pipefail
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

SCRIPT_VERSION="3.8.0-ru"

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
RUN_IPERF_ALL=true
RUN_FULL_IPERF=false
IPERF_TIME=3
IPERF_TIME_DL="$IPERF_TIME"
IPERF_TIME_UL="$IPERF_TIME"
IPERF_STREAMS=""

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
NODE_UPLINK_STATUS=""
NODE_UPLINK_TARGET=""
NODE_UPLINK_HOST=""
NODE_UPLINK_PING="N/A"
NODE_UPLINK_PING_NUM="null"
NODE_UPLINK_DL="null"
NODE_UPLINK_UL="null"
SAVED_STTY=""
IPERF_SKIPPED=false

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

YOUTUBE_AD_FREE=false
YOUTUBE_DETECTED_CC=""

CHATGPT_STATSIG_API_KEY="client-zUdXdSTygXJdzoE0sWTkP8GKTVsUMF2IRM7ShVO2JAG"
YOUTUBE_SOCS_COOKIE="CAISNQgDEitib3FfaWRlbnRpdHlmcm9udGVuZHVpc2VydmVyXzIwMjUwNzMwLjA1X3AwGgJlbiACGgYIgPC_xAY"
GEMINI_REGIONS_URL="https://ai.google.dev/gemini-api/docs/available-regions.md.txt"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"

DEBUG_LOG_FILE=""
TMP_WORK_DIR=""
MAIN_PID=""
CPU_STAT_START=""

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

# ISO 3166-1 alpha-2 dictionary (249 countries/territories)
declare -A COUNTRY_NAMES=(
  [AF]="Afghanistan" [AX]="Åland Islands" [AL]="Albania" [DZ]="Algeria" [AS]="American Samoa"
  [AD]="Andorra" [AO]="Angola" [AI]="Anguilla" [AQ]="Antarctica" [AG]="Antigua and Barbuda"
  [AR]="Argentina" [AM]="Armenia" [AW]="Aruba" [AU]="Australia" [AT]="Austria"
  [AZ]="Azerbaijan" [BS]="Bahamas" [BH]="Bahrain" [BD]="Bangladesh" [BB]="Barbados"
  [BY]="Belarus" [BE]="Belgium" [BZ]="Belize" [BJ]="Benin" [BM]="Bermuda"
  [BT]="Bhutan" [BO]="Bolivia" [BQ]="Bonaire, Sint Eustatius and Saba" [BA]="Bosnia and Herzegovina" [BW]="Botswana"
  [BV]="Bouvet Island" [BR]="Brazil" [IO]="British Indian Ocean Territory" [BN]="Brunei Darussalam" [BG]="Bulgaria"
  [BF]="Burkina Faso" [BI]="Burundi" [CV]="Cabo Verde" [KH]="Cambodia" [CM]="Cameroon"
  [CA]="Canada" [KY]="Cayman Islands" [CF]="Central African Republic" [TD]="Chad" [CL]="Chile"
  [CN]="China" [CX]="Christmas Island" [CC]="Cocos (Keeling) Islands" [CO]="Colombia" [KM]="Comoros"
  [CG]="Congo" [CD]="Congo (Democratic Republic of the)" [CK]="Cook Islands" [CR]="Costa Rica" [CI]="Côte d'Ivoire"
  [HR]="Croatia" [CU]="Cuba" [CW]="Curaçao" [CY]="Cyprus" [CZ]="Czech Republic"
  [DK]="Denmark" [DJ]="Djibouti" [DM]="Dominica" [DO]="Dominican Republic" [EC]="Ecuador"
  [EG]="Egypt" [SV]="El Salvador" [GQ]="Equatorial Guinea" [ER]="Eritrea" [EE]="Estonia"
  [SZ]="Eswatini" [ET]="Ethiopia" [FK]="Falkland Islands (Malvinas)" [FO]="Faroe Islands" [FJ]="Fiji"
  [FI]="Finland" [FR]="France" [GF]="French Guiana" [PF]="French Polynesia" [TF]="French Southern Territories"
  [GA]="Gabon" [GM]="Gambia" [GE]="Georgia" [DE]="Germany" [GH]="Ghana"
  [GI]="Gibraltar" [GR]="Greece" [GL]="Greenland" [GD]="Grenada" [GP]="Guadeloupe"
  [GU]="Guam" [GT]="Guatemala" [GG]="Guernsey" [GN]="Guinea" [GW]="Guinea-Bissau"
  [GY]="Guyana" [HT]="Haiti" [HM]="Heard Island and McDonald Islands" [VA]="Holy See" [HN]="Honduras"
  [HK]="Hong Kong" [HU]="Hungary" [IS]="Iceland" [IN]="India" [ID]="Indonesia"
  [IR]="Iran" [IQ]="Iraq" [IE]="Ireland" [IM]="Isle of Man" [IL]="Israel"
  [IT]="Italy" [JM]="Jamaica" [JP]="Japan" [JE]="Jersey" [JO]="Jordan"
  [KZ]="Kazakhstan" [KE]="Kenya" [KI]="Kiribati" [KP]="Korea (Democratic People's Republic of)" [KR]="Korea (Republic of)"
  [KW]="Kuwait" [KG]="Kyrgyzstan" [LA]="Lao People's Democratic Republic" [LV]="Latvia" [LB]="Lebanon"
  [LS]="Lesotho" [LR]="Liberia" [LY]="Libya" [LI]="Liechtenstein" [LT]="Lithuania"
  [LU]="Luxembourg" [MO]="Macao" [MG]="Madagascar" [MW]="Malawi" [MY]="Malaysia"
  [MV]="Maldives" [ML]="Mali" [MT]="Malta" [MH]="Marshall Islands" [MQ]="Martinique"
  [MR]="Mauritania" [MU]="Mauritius" [YT]="Mayotte" [MX]="Mexico" [FM]="Micronesia (Federated States of)"
  [MD]="Moldova" [MC]="Monaco" [MN]="Mongolia" [ME]="Montenegro" [MS]="Montserrat"
  [MA]="Morocco" [MZ]="Mozambique" [MM]="Myanmar" [NA]="Namibia" [NR]="Nauru"
  [NP]="Nepal" [NL]="Netherlands" [NC]="New Caledonia" [NZ]="New Zealand" [NI]="Nicaragua"
  [NE]="Niger" [NG]="Nigeria" [NU]="Niue" [NF]="Norfolk Island" [MK]="North Macedonia"
  [MP]="Northern Mariana Islands" [NO]="Norway" [OM]="Oman" [PK]="Pakistan" [PW]="Palau"
  [PS]="Palestine" [PA]="Panama" [PG]="Papua New Guinea" [PY]="Paraguay" [PE]="Peru"
  [PH]="Philippines" [PN]="Pitcairn" [PL]="Poland" [PT]="Portugal" [PR]="Puerto Rico"
  [QA]="Qatar" [RE]="Réunion" [RO]="Romania" [RU]="Russia" [RW]="Rwanda"
  [BL]="Saint Barthélemy" [SH]="Saint Helena" [KN]="Saint Kitts and Nevis" [LC]="Saint Lucia" [MF]="Saint Martin (French part)"
  [PM]="Saint Pierre and Miquelon" [VC]="Saint Vincent and the Grenadines" [WS]="Samoa" [SM]="San Marino" [ST]="Sao Tome and Principe"
  [SA]="Saudi Arabia" [SN]="Senegal" [RS]="Serbia" [SC]="Seychelles" [SL]="Sierra Leone"
  [SG]="Singapore" [SX]="Sint Maarten (Dutch part)" [SK]="Slovakia" [SI]="Slovenia" [SB]="Solomon Islands"
  [SO]="Somalia" [ZA]="South Africa" [GS]="South Georgia and the South Sandwich Islands" [SS]="South Sudan" [ES]="Spain"
  [LK]="Sri Lanka" [SD]="Sudan" [SR]="Suriname" [SJ]="Svalbard and Jan Mayen" [SE]="Sweden"
  [CH]="Switzerland" [SY]="Syrian Arab Republic" [TW]="Taiwan" [TJ]="Tajikistan" [TZ]="Tanzania"
  [TH]="Thailand" [TL]="Timor-Leste" [TG]="Togo" [TK]="Tokelau" [TO]="Tonga"
  [TT]="Trinidad and Tobago" [TN]="Tunisia" [TR]="Turkey" [TM]="Turkmenistan" [TC]="Turks and Caicos Islands"
  [TV]="Tuvalu" [UG]="Uganda" [UA]="Ukraine" [AE]="United Arab Emirates" [GB]="United Kingdom"
  [US]="United States" [UM]="United States Minor Outlying Islands" [UY]="Uruguay" [UZ]="Uzbekistan" [VU]="Vanuatu"
  [VE]="Venezuela" [VN]="Vietnam" [VG]="Virgin Islands (British)" [VI]="Virgin Islands (U.S.)" [WF]="Wallis and Futuna"
  [EH]="Western Sahara" [YE]="Yemen" [ZM]="Zambia" [ZW]="Zimbabwe" [XK]="Kosovo"
  [EU]="European Union" [WW]="Worldwide"
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
    if [[ "$NO_COLOR_MODE" == "true" || -n "${NO_COLOR:-}" ]]; then
      printf "\r%80s\r" ""
    else
      printf "\r\033[2K\r"
    fi
  fi
}

read_val() {
  local file="$1"
  local def="${2:-N/A}"
  if [[ -s "$file" ]]; then
    cat "$file"
  else
    echo "$def"
  fi
}

pad_str() {
  local s="$1" w="$2"
  shopt -s extglob
  local clean="${s//$'\033'\[*([0-9;])[a-zA-Z]/}"
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
    ""|"null"|"$STATUS_NA"|*"N/A"*|*"Unavailable"*)
      color "$COLOR_NULL" "$val"
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
    *"Rate limited"*|*"Server error"*|*"Moderate"*|*"Warning"*|*"Inactive"*|*"Skipped"*)
      color "$COLOR_WARN" "$val"
      ;;
    *"ms")
      local num_ms="${val%%.*}"
      num_ms="${num_ms%%ms*}"
      num_ms="${num_ms//[^0-9]/}"
      num_ms="${num_ms:-999}"
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
  if [[ "$DEBUG" == "true" && -n "$DEBUG_LOG_FILE" ]]; then
    printf "[%s] %s\n" "$level" "$msg" >> "$DEBUG_LOG_FILE"
  fi
  if [[ "$VERBOSE" == "true" ]]; then
    if [[ -n "$COLOR_INFO" ]]; then
      printf "\033[%sm[%s]\033[0m %s\n" "$COLOR_INFO" "$level" "$msg" >&2
    else
      printf "[%s] %s\n" "$level" "$msg" >&2
    fi
  fi
}

error_exit() {
  if [[ -n "$COLOR_ERROR" ]]; then
    printf "\033[%smОшибка:\033[0m %s\n" "$COLOR_ERROR" "$1" >&2
  else
    printf "Ошибка: %s\n" "$1" >&2
  fi
  if [[ "$DEBUG" == "true" && -n "$DEBUG_LOG_FILE" && -f "$DEBUG_LOG_FILE" ]]; then
    printf "\n--- [DEBUG TRACE LOG] ---\n" >&2
    cat "$DEBUG_LOG_FILE" >&2
    printf "--- [END DEBUG LOG] ---\n\n" >&2
  fi
  cleanup
  exit 1
}

cleanup() {
  if [[ -n "${MAIN_PID:-}" && "$MAIN_PID" -ne "$BASHPID" ]]; then
    return 0
  fi
  if [[ "$$" -ne "$BASHPID" ]]; then
    return 0
  fi

  trap - EXIT INT TERM
  progress_clear
  if [[ -n "$SAVED_STTY" && -r /dev/tty ]]; then
    stty "$SAVED_STTY" < /dev/tty 2>/dev/null || true
    SAVED_STTY=""
  fi
  local pids
  pids=$(jobs -p 2>/dev/null)
  if [[ -n "$pids" ]]; then
    kill -TERM $pids 2>/dev/null || true
    sleep 0.05 2>/dev/null || true
    kill -KILL $pids 2>/dev/null || true
    wait $pids 2>/dev/null || true
  fi
  if [[ -n "$TMP_WORK_DIR" && -d "$TMP_WORK_DIR" ]]; then
    rm -rf "$TMP_WORK_DIR"
  fi
}

is_command_available() { command -v "$1" >/dev/null 2>&1; }

install_dependencies() {
  local required_pkgs=()

  if ! is_command_available "curl"; then
    required_pkgs+=("curl")
  fi
  if ! is_command_available "jq"; then
    required_pkgs+=("jq")
  fi
  if ! is_command_available "awk"; then
    required_pkgs+=("gawk")
  fi
  if ! is_command_available "ping"; then
    required_pkgs+=("iputils-ping")
  fi
  if ! is_command_available "dig"; then
    required_pkgs+=("bind9-dnsutils")
  fi
  if [[ "$RUN_IPERF" == "true" ]] && ! is_command_available "iperf3"; then
    required_pkgs+=("iperf3")
  fi

  if [[ ${#required_pkgs[@]} -eq 0 ]]; then
    return 0
  fi

  local sudo_prefix=""
  local is_root=false
  if [[ ${EUID:-$(id -u 2>/dev/null || echo 1)} -eq 0 ]]; then
    is_root=true
  elif is_command_available "sudo"; then
    sudo_prefix="sudo "
  fi

  local install_cmd="${sudo_prefix}apt-get update && ${sudo_prefix}apt-get install -y --no-install-recommends ${required_pkgs[*]}"
  local should_install=false

  if [[ "$is_root" == "true" && ! -t 0 ]]; then
    # Automatic installation in non-interactive pipeline under root (e.g. curl ... | bash)
    should_install=true
  elif [[ -t 0 && -t 1 ]]; then
    printf "\n"
    if [[ -n "$COLOR_WARN" ]]; then
      printf "\033[%sm[!] Не найдены компоненты:\033[0m %s\n" "$COLOR_WARN" "${required_pkgs[*]}"
    else
      printf "[!] Не найдены компоненты: %s\n" "${required_pkgs[*]}"
    fi
    printf "Установить недостающие пакеты автоматически? [y/N]: "
    local user_confirmed="n"
    read -r -t 15 user_confirmed || user_confirmed="n"
    printf "\n"
    if [[ "$user_confirmed" =~ ^[Yy]$ ]]; then
      should_install=true
    fi
  fi

  if [[ "$should_install" == "true" ]]; then
    progress_status "Установка недостающих пакетов (${required_pkgs[*]})"
    log "INFO" "Installing missing packages: ${required_pkgs[*]}"
    export DEBIAN_FRONTEND=noninteractive
    ${sudo_prefix}apt-get update -qq >/dev/null 2>&1 || true
    ${sudo_prefix}apt-get install -y -qq --no-install-recommends "${required_pkgs[@]}" >/dev/null 2>&1 || true
    progress_clear
  else
    log "WARNING" "Missing packages: ${required_pkgs[*]}. Run: $install_cmd"
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "Примечание: отсутствуют утилиты (%s). Установите: %s\n\n" "${required_pkgs[*]}" "$install_cmd" >&2
    fi
  fi

  for critical in curl jq awk; do
    if ! is_command_available "$critical"; then
      error_exit "Критическая утилита '$critical' не найдена. Установите: $install_cmd"
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

  # Verify DoH connectivity by resolving domain name
  local doh_cmd=(curl -s -m 3)
  if [[ "$IPV4_ONLY" == "true" ]]; then
    doh_cmd+=(-4)
  elif [[ "$IPV6_ONLY" == "true" ]]; then
    doh_cmd+=(-6)
  fi

  if [[ -n "$PROXY_ADDR" ]]; then
    doh_cmd+=(--proxy "socks5h://$PROXY_ADDR")
  fi

  if [[ -n "$INTERFACE_NAME" ]]; then
    doh_cmd+=(--interface "$INTERFACE_NAME")
  fi

  doh_cmd+=(--doh-url "$SELECTED_DOH_URL" -o /dev/null "https://cloudflare.com")

  if ! "${doh_cmd[@]}" 2>/dev/null; then
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

  if [[ -z "$ip_version" ]]; then
    if [[ "$IPV4_ONLY" == "true" ]]; then
      ip_version="4"
    elif [[ "$IPV6_ONLY" == "true" ]]; then
      ip_version="6"
    fi
  fi

  local curl_cmd=(curl -sS -L -b "" --connect-timeout 2 --max-time "$timeout" --retry "$CURL_RETRIES" --retry-delay 0)
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
  local primary_ip="${EXTERNAL_IPV4:-$EXTERNAL_IPV6}"
  local ip_ver_arg=()
  if [[ -n "$EXTERNAL_IPV4" && "$IPV6_ONLY" != "true" ]]; then
    ip_ver_arg=(--ip-version "4")
  elif [[ -n "$EXTERNAL_IPV6" ]]; then
    ip_ver_arg=(--ip-version "6")
  fi

  local info_raw
  if [[ -n "$primary_ip" ]]; then
    info_raw=$(curl_wrapper GET "https://ipinfo.io/${primary_ip}/json" "${ip_ver_arg[@]}" --timeout 4 2>/dev/null)
  else
    info_raw=$(curl_wrapper GET "https://ipinfo.io/json" "${ip_ver_arg[@]}" --timeout 4 2>/dev/null)
  fi

  if [[ -n "$info_raw" ]] && jq -e . >/dev/null 2>&1 <<<"$info_raw"; then
    NODE_ASN=$(jq -r '.org // ""' <<<"$info_raw" | grep -oE "AS[0-9]+" || echo "AS0")
    NODE_ORG=$(jq -r '.org // ""' <<<"$info_raw" | sed -E 's/^AS[0-9]+ //')
    NODE_CITY=$(jq -r '.city // ""' <<<"$info_raw")
    NODE_COUNTRY_CODE=$(jq -r '.country // ""' <<<"$info_raw")
  fi

  # Fallback 1: ip-api.com if ipinfo failed, rate limited (429), or empty
  if [[ -z "$NODE_ASN" || "$NODE_ASN" == "AS0" || -z "$NODE_COUNTRY_CODE" || -z "$NODE_CITY" || "$NODE_CITY" == "Unknown City" ]]; then
    local fallback_raw
    if [[ -n "$primary_ip" ]]; then
      fallback_raw=$(curl_wrapper GET "http://ip-api.com/json/${primary_ip}" "${ip_ver_arg[@]}" --timeout 4 2>/dev/null)
    else
      fallback_raw=$(curl_wrapper GET "http://ip-api.com/json/" "${ip_ver_arg[@]}" --timeout 4 2>/dev/null)
    fi
    if [[ -n "$fallback_raw" ]] && jq -e '.status == "success"' >/dev/null 2>&1 <<<"$fallback_raw"; then
      [[ -z "$NODE_ASN" || "$NODE_ASN" == "AS0" ]] && NODE_ASN=$(jq -r '.as // ""' <<<"$fallback_raw" | grep -oE "AS[0-9]+" || echo "AS0")
      [[ -z "$NODE_ORG" || "$NODE_ORG" == "Unknown Org" ]] && NODE_ORG=$(jq -r '.org // .as // ""' <<<"$fallback_raw" | sed -E 's/^AS[0-9]+ //')
      [[ -z "$NODE_CITY" || "$NODE_CITY" == "Unknown City" ]] && NODE_CITY=$(jq -r '.city // ""' <<<"$fallback_raw")
      [[ -z "$NODE_COUNTRY_CODE" || "$NODE_COUNTRY_CODE" == "XX" ]] && NODE_COUNTRY_CODE=$(jq -r '.countryCode // ""' <<<"$fallback_raw")
    fi
  fi

  # Fallback 2: ip.guide
  if [[ -z "$NODE_ASN" || "$NODE_ASN" == "AS0" || -z "$NODE_COUNTRY_CODE" || -z "$NODE_CITY" || "$NODE_CITY" == "Unknown City" ]]; then
    local guide_raw
    if [[ -n "$primary_ip" ]]; then
      guide_raw=$(curl_wrapper GET "https://ip.guide/${primary_ip}" "${ip_ver_arg[@]}" --timeout 4 2>/dev/null)
    else
      guide_raw=$(curl_wrapper GET "https://ip.guide/" "${ip_ver_arg[@]}" --timeout 4 2>/dev/null)
    fi
    if [[ -n "$guide_raw" ]] && jq -e . >/dev/null 2>&1 <<<"$guide_raw"; then
      local guide_asn
      guide_asn=$(jq -r '.network.autonomous_system.asn // empty' <<<"$guide_raw")
      [[ -n "$guide_asn" && ( -z "$NODE_ASN" || "$NODE_ASN" == "AS0" ) ]] && NODE_ASN="AS${guide_asn}"
      local guide_org
      guide_org=$(jq -r '.network.autonomous_system.organization // empty' <<<"$guide_raw")
      [[ -n "$guide_org" && ( -z "$NODE_ORG" || "$NODE_ORG" == "Unknown Org" ) ]] && NODE_ORG="$guide_org"
      [[ -z "$NODE_CITY" || "$NODE_CITY" == "Unknown City" ]] && NODE_CITY=$(jq -r '.location.city // empty' <<<"$guide_raw")
      [[ -z "$NODE_COUNTRY_CODE" || "$NODE_COUNTRY_CODE" == "XX" ]] && NODE_COUNTRY_CODE=$(jq -r '.location.country // empty' <<<"$guide_raw")
    fi
  fi

  NODE_ASN="${NODE_ASN:-AS0}"
  NODE_ORG="${NODE_ORG:-Unknown Org}"
  NODE_CITY="${NODE_CITY:-Unknown City}"
  NODE_COUNTRY_CODE="${NODE_COUNTRY_CODE:-XX}"

  # Classification & Anti-fraud via ipquery.io
  local query_raw=""
  if [[ -n "$primary_ip" ]]; then
    query_raw=$(curl_wrapper GET "https://api.ipquery.io/${primary_ip}" "${ip_ver_arg[@]}" --timeout 4 2>/dev/null)
  fi
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

  # Prioritize Tor -> VPN -> Datacenter -> Residential
  if [[ "$is_tor" == "true" ]]; then
    NODE_TYPE="Tor Exit Node"
  elif [[ "$is_vpn" == "true" ]]; then
    NODE_TYPE="Commercial VPN / Proxy"
  elif [[ "$is_datacenter" == "true" ]]; then
    NODE_TYPE="Data Center / Hosting"
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
  local tcp25_exit=0
  timeout 2 bash -c 'echo > /dev/tcp/smtp.gmail.com/25' 2>/dev/null
  tcp25_exit=$?
  if [[ $tcp25_exit -eq 0 ]]; then
    NODE_PORT25_STATUS="Open"
  elif [[ $tcp25_exit -eq 124 ]]; then
    # Timed out - connection dropped by firewall, do not waste 2 more seconds on nc
    NODE_PORT25_STATUS="Blocked"
  elif is_command_available nc && nc -z -w 2 smtp.gmail.com 25 2>/dev/null; then
    NODE_PORT25_STATUS="Open"
  else
    NODE_PORT25_STATUS="Blocked"
  fi

  # UDP Connectivity (verify DNS resolution via 1.1.1.1 and fallback 8.8.8.8)
  local udp_dns_ip="1.1.1.1"
  local udp_dns_fallback="8.8.8.8"
  if [[ "$IPV6_ONLY" == "true" ]] || [[ -z "$EXTERNAL_IPV4" && -n "$EXTERNAL_IPV6" ]]; then
    udp_dns_ip="2606:4700:4700::1111"
    udp_dns_fallback="2001:4860:4860::8888"
  fi

  if is_command_available dig; then
    if dig +short +time=2 +tries=1 @"$udp_dns_ip" cloudflare.com 2>/dev/null | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[0-9a-fA-F:]+' || \
       dig +short +time=2 +tries=1 @"$udp_dns_fallback" cloudflare.com 2>/dev/null | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[0-9a-fA-F:]+'; then
      NODE_UDP_STATUS="Open (DNS Bidirectional)"
    else
      NODE_UDP_STATUS="Blocked"
    fi
  elif is_command_available nslookup; then
    if nslookup -timeout=2 cloudflare.com "$udp_dns_ip" >/dev/null 2>&1 || \
       nslookup -timeout=2 cloudflare.com "$udp_dns_fallback" >/dev/null 2>&1; then
      NODE_UDP_STATUS="Open (DNS Bidirectional)"
    else
      NODE_UDP_STATUS="Blocked"
    fi
  else
    NODE_UDP_STATUS="N/A (No DNS tools)"
  fi

  # RKN / Antifilter IP Registry Check
  if [[ -n "$EXTERNAL_IPV4" ]]; then
    local rkn_hit=false
    local ip_list_ok=false
    local ipsum_list_ok=false

    local rkn_list
    rkn_list=$(curl_wrapper GET "https://antifilter.download/list/ip.lst" --timeout 4 2>/dev/null || echo "")
    if [[ -n "$rkn_list" ]]; then
      ip_list_ok=true
      if grep -Fxq "$EXTERNAL_IPV4" <<<"$rkn_list"; then
        rkn_hit=true
      fi
    fi

    if [[ "$rkn_hit" != "true" ]]; then
      local ipsum_list
      ipsum_list=$(curl_wrapper GET "https://antifilter.network/download/ipsum.lst" --timeout 4 2>/dev/null || echo "")
      if [[ -n "$ipsum_list" ]]; then
        ipsum_list_ok=true
        if awk -v ip="$EXTERNAL_IPV4" '
          function ip2int(s, oct, n) {
            n = split(s, oct, ".")
            if (n != 4) return -1
            return ((oct[1] * 256 + oct[2]) * 256 + oct[3]) * 256 + oct[4]
          }
          BEGIN { target = ip2int(ip); hit = 0 }
          {
            line = $1
            if (!line || line ~ /^#/) next
            p = index(line, "/")
            if (p > 0) {
              cidr_ip = substr(line, 1, p - 1)
              prefix = substr(line, p + 1) + 0
              net = ip2int(cidr_ip)
              if (net >= 0 && prefix >= 0 && prefix <= 32) {
                size = 2 ^ (32 - prefix)
                net_base = net - (net % size)
                if (target >= net_base && target < net_base + size) { hit = 1; exit }
              }
            } else {
              if (ip2int(line) == target) { hit = 1; exit }
            }
          }
          END { exit (hit ? 0 : 1) }' <<<"$ipsum_list"; then
          rkn_hit=true
        fi
      fi
    fi

    if [[ "$rkn_hit" == "true" ]]; then
      NODE_RKN_STATUS="BLOCKED in RU (Antifilter Registry)"
      NODE_RKN_COLOR="$COLOR_DANGER"
    elif [[ "$ip_list_ok" == "true" && "$ipsum_list_ok" == "true" ]]; then
      NODE_RKN_STATUS="Clean (Not in Registry)"
      NODE_RKN_COLOR="$COLOR_SUCCESS"
    else
      NODE_RKN_STATUS="N/A (Unreachable)"
      NODE_RKN_COLOR="$COLOR_NULL"
    fi
  else
    NODE_RKN_STATUS="N/A (IPv6 only)"
    NODE_RKN_COLOR="$COLOR_NULL"
  fi
}

# ------------------------------------------------------------------------------
# 0. System Hardware & Virtualization Specs (CPU Steal, RAM, Disk, Uptime)
# ------------------------------------------------------------------------------

get_system_specs() {
  # 1. CPU Model & Cores (x86_64, aarch64 / ARM fallback)
  local cpu_model=""
  if is_command_available "lscpu"; then
    cpu_model=$(lscpu 2>/dev/null | awk -F: '/Model name/ {print $2; exit}' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')
  fi
  if [[ -z "$cpu_model" ]]; then
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | awk -F: '{print $2}' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')
  fi
  if [[ -z "$cpu_model" ]]; then
    cpu_model=$(grep -m1 -E "Hardware|Processor" /proc/cpuinfo 2>/dev/null | awk -F: '{print $2}' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')
  fi
  if [[ -z "$cpu_model" ]]; then
    cpu_model=$(uname -m 2>/dev/null || echo "Generic CPU")
  fi
  NODE_CPU_MODEL="$cpu_model"
  NODE_CPU_CORES=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1")
  if [[ ! "$NODE_CPU_CORES" =~ ^[1-9][0-9]*$ ]]; then
    NODE_CPU_CORES=1
  fi

  # 2. Virtualization & Uptime
  if [[ -f /.dockerenv ]]; then
    NODE_VIRT="docker"
  elif [[ -f /run/.containerenv ]]; then
    NODE_VIRT="container"
  elif is_command_available "systemd-detect-virt"; then
    local virt_out
    if virt_out=$(systemd-detect-virt 2>/dev/null); then
      if [[ "$virt_out" == "none" || -z "$virt_out" ]]; then
        NODE_VIRT="Bare-Metal"
      else
        NODE_VIRT="$virt_out"
      fi
    else
      NODE_VIRT="Bare-Metal"
    fi
  else
    NODE_VIRT="Bare-Metal"
  fi

  if [[ -r /proc/uptime ]]; then
    local up_sec up_int d h m
    read -r up_sec _ < /proc/uptime
    up_int="${up_sec%%.*}"
    up_int="${up_int//[^0-9]/}"
    up_int="${up_int:-0}"
    d=$(( up_int / 86400 ))
    h=$(( (up_int % 86400) / 3600 ))
    m=$(( (up_int % 3600) / 60 ))
    if (( d > 0 )); then
      NODE_UPTIME="${d}d ${h}h ${m}m"
    elif (( h > 0 )); then
      NODE_UPTIME="${h}h ${m}m"
    else
      NODE_UPTIME="${m}m"
    fi
  else
    NODE_UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //' || uptime 2>/dev/null | awk -F'( |,|:)+' '{print $6"h "$7"m"}' || echo "N/A")
  fi

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
    NODE_RAM=$(free -m 2>/dev/null | awk '/Mem:/ {if ($2 > 0) printf "%d MB / %d MB (%.1f%%)", $3, $2, ($3/$2)*100; else printf "%d MB", $3}')
  else
    NODE_RAM="N/A"
  fi
  if is_command_available "df"; then
    NODE_DISK=$(df -h -P / 2>/dev/null | awk 'END {printf "%s / %s (%s)", $3, $2, $5}')
  else
    NODE_DISK="N/A"
  fi

  # 5. CPU Steal measurement (Zero-sleep delta from start + all-time uptime ticks)
  # Exclude double counting of guest and guest_nice (already part of user and nice)
  local u1 n1 s1 i1 w1 x1 q1 st1 u2 n2 s2 i2 w2 x2 q2 st2
  if [[ -r /proc/stat ]]; then
    read -r _ u2 n2 s2 i2 w2 x2 q2 st2 _ < /proc/stat
    local total_boot=$(( ${u2:-0} + ${n2:-0} + ${s2:-0} + ${i2:-0} + ${w2:-0} + ${x2:-0} + ${q2:-0} + ${st2:-0} ))
    if (( total_boot > 0 )); then
      NODE_CPU_STEAL_ALLTIME=$(awk -v s="${st2:-0}" -v t="$total_boot" 'BEGIN { printf "%.2f", (s/t)*100 }')
    else
      NODE_CPU_STEAL_ALLTIME="0.00"
    fi

    if [[ -n "${CPU_STAT_START:-}" ]]; then
      read -r _ u1 n1 s1 i1 w1 x1 q1 st1 _ <<<"$CPU_STAT_START"
      local total1=$(( ${u1:-0} + ${n1:-0} + ${s1:-0} + ${i1:-0} + ${w1:-0} + ${x1:-0} + ${q1:-0} + ${st1:-0} ))
      local diff_total=$((total_boot - total1))
      local diff_steal=$(( ${st2:-0} - ${st1:-0} ))
      if (( diff_steal < 0 )); then diff_steal=0; fi
      if (( diff_total >= 50 )); then
        NODE_CPU_STEAL_NUM=$(awk -v s="$diff_steal" -v t="$diff_total" 'BEGIN { printf "%.1f", (s/t)*100 }')
      else
        NODE_CPU_STEAL_NUM="$NODE_CPU_STEAL_ALLTIME"
      fi
    else
      NODE_CPU_STEAL_NUM="$NODE_CPU_STEAL_ALLTIME"
    fi
  else
    NODE_CPU_STEAL_NUM="0.0"
    NODE_CPU_STEAL_ALLTIME="0.00"
  fi

  local steal_int="${NODE_CPU_STEAL_NUM%%.*}"
  steal_int="${steal_int//[^0-9]/}"
  steal_int="${steal_int:-0}"
  local alltime_int="${NODE_CPU_STEAL_ALLTIME%%.*}"
  alltime_int="${alltime_int//[^0-9]/}"
  alltime_int="${alltime_int:-0}"

  if (( steal_int > 10 || alltime_int > 5 )); then
    NODE_CPU_STEAL_COLOR="$COLOR_DANGER"
    NODE_CPU_STEAL="${NODE_CPU_STEAL_NUM}% (High Steal / Оверселл!) | ${NODE_CPU_STEAL_ALLTIME}% (за аптайм)"
  elif (( steal_int > 3 || alltime_int > 2 )); then
    NODE_CPU_STEAL_COLOR="$COLOR_WARN"
    NODE_CPU_STEAL="${NODE_CPU_STEAL_NUM}% (Moderate) | ${NODE_CPU_STEAL_ALLTIME}% (за аптайм)"
  else
    NODE_CPU_STEAL_COLOR="$COLOR_SUCCESS"
    NODE_CPU_STEAL="${NODE_CPU_STEAL_NUM}% (Clean) | ${NODE_CPU_STEAL_ALLTIME}% (за аптайм)"
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
      raw=$(curl_wrapper GET "https://api.ipregistry.co/${ip_val}?key=tryout" --ip-version "$ip_ver" --header "Origin: https://ipregistry.co" --timeout 3 2>/dev/null)
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
      raw=$(curl_wrapper GET "https://api.iplocation.net/?ip=${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code2 // empty' <<<"$raw")
      ;;
    "ipbase.com")
      local raw
      raw=$(curl_wrapper GET "https://api.ipbase.com/v1/json/?ip=${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw")
      ;;
    "ipquery.io")
      local raw
      raw=$(curl_wrapper GET "https://api.ipquery.io/${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.location.country_code // empty' <<<"$raw")
      ;;
    "IPAPI.is")
      local raw
      raw=$(curl_wrapper GET "https://api.ipapi.is/?q=${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country_code // .country // empty' <<<"$raw")
      ;;
    "RIPE NCC")
      local raw
      raw=$(curl_wrapper GET "https://rdap.db.ripe.net/ip/${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw")
      if [[ -z "$cc" && -n "$raw" ]]; then
        cc=$(jq -r '[.. | objects | .adr? | .label? | strings | split("\n")[] | select(length > 0)][-1] // empty' <<<"$raw" 2>/dev/null)
      fi
      ;;
    "IP.Guide")
      local raw
      raw=$(curl_wrapper GET "https://ip.guide/${ip_val}" --ip-version "$ip_ver" --timeout 3 2>/dev/null)
      cc=$(jq -r '.location.country // .network.autonomous_system.country // empty' <<<"$raw")
      ;;
  esac

  # Normalize 2-letter uppercase or N/A
  local country_name_regex='^[A-Za-z ]{3,}$'
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    cc="${cc^^}"
  elif [[ "$cc" =~ $country_name_regex ]]; then
    # Common aliases check
    case "${cc,,}" in
      "russian federation"|"russia") cc="RU" ;;
      "united states"|"united states of america"|"usa") cc="US" ;;
      "united kingdom"|"great britain"|"uk") cc="GB" ;;
      "south korea"|"korea, republic of"|"republic of korea") cc="KR" ;;
      "north korea"|"democratic people's republic of korea") cc="KP" ;;
      "viet nam") cc="VN" ;;
      "czechia") cc="CZ" ;;
      *)
        for code in "${!COUNTRY_NAMES[@]}"; do
          if [[ "${COUNTRY_NAMES[$code],,}" == "${cc,,}" ]]; then
            cc="$code"
            break
          fi
        done
        ;;
    esac
  fi

  if [[ ! "$cc" =~ ^[A-Z]{2}$ ]]; then
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

  local running=0
  local max_jobs=8

  # Launch parallel background queries in batches of max_jobs
  for db in "${geoip_dbs[@]}"; do
    if [[ $IPV4_SUPPORTED -eq 1 ]]; then
      ( query_single_geoip "$db" "4" "$v4_dir/$db" ) &
      running=$((running + 1))
      if (( running >= max_jobs )); then
        wait -n 2>/dev/null || true
        running=$((running - 1))
      fi
    fi
    if [[ $IPV6_SUPPORTED -eq 1 ]]; then
      ( query_single_geoip "$db" "6" "$v6_dir/$db" ) &
      running=$((running + 1))
      if (( running >= max_jobs )); then
        wait -n 2>/dev/null || true
        running=$((running - 1))
      fi
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

lookup_rutracker() {
  local code
  code=$(curl_http_code "https://rutracker.org")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then echo "Yes"; else echo "No ($code)"; fi
}

lookup_chatgpt() {
  local ip_ver_arg=()
  if [[ "$IPV6_ONLY" == "true" ]]; then
    ip_ver_arg=(--ip-version "6")
  elif [[ "$IPV4_ONLY" == "true" ]]; then
    ip_ver_arg=(--ip-version "4")
  fi

  local resp
  resp=$(curl_wrapper POST "https://ab.chatgpt.com/v1/initialize" "${ip_ver_arg[@]}" \
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

parse_youtube_cdn_iata() {
  local node="$1"
  local google_node_regex='^([a-z]{3})[0-9]'
  local isp_iata_regex='^[a-z]+-([a-z]{3})[0-9]'
  local ggc_dash_regex='^[a-z]{2}-([a-z]{3})-'
  local ggc_node_regex='^[a-z]{2}([a-z]{3})[a-z]-[a-z0-9]+$'

  if [[ "$node" =~ $google_node_regex || "$node" =~ $isp_iata_regex || "$node" =~ $ggc_dash_regex || "$node" =~ $ggc_node_regex ]]; then
    echo "${BASH_REMATCH[1]^^}"
  fi
}

lookup_youtube_cdn() {
  local raw resp code
  raw=$(curl_wrapper GET "https://redirector.googlevideo.com/report_mapping?di=no" --timeout 3 -w "\nHTTP_STATUS:%{http_code}" 2>/dev/null)
  code=$(tail -n 2 <<<"$raw" | grep -oE 'HTTP_STATUS:[0-9]{3}' | tail -n 1 | cut -d: -f2)
  code="${code:-000}"
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi
  resp=$(head -n 1 <<<"$raw")
  local node_id
  node_id=$(awk '{print $3}' <<<"$resp")
  local iata
  iata=$(parse_youtube_cdn_iata "$node_id")
  if [[ -z "$iata" ]]; then
    iata=$(sed -n -E 's/.*=> *(tz)?([a-zA-Z]{3}).*/\2/p' <<<"$resp" | head -n 1 | tr '[:lower:]' '[:upper:]')
  fi
  if [[ -n "$iata" ]]; then echo "Yes ($iata)"; else echo "Yes"; fi
}

lookup_youtube_premium() {
  local raw resp code
  raw=$(curl_wrapper GET "https://www.youtube.com/premium" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9" \
    --timeout 4 \
    -w "\nHTTP_STATUS:%{http_code}" 2>/dev/null)
  code=$(tail -n 2 <<<"$raw" | grep -oE 'HTTP_STATUS:[0-9]{3}' | tail -n 1 | cut -d: -f2)
  code="${code:-000}"
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi
  resp=$(head -c 16384 <<<"$raw" | sed -e '/HTTP_STATUS:[0-9]\{3\}$/d')
  if [[ -z "$resp" ]]; then
    echo "No (Empty)"
  elif grep -qi "YouTube Premium is not available in your country" <<<"$resp"; then
    echo "No"
  else
    echo "Yes"
  fi
}

lookup_youtube_music() {
  local raw resp code
  raw=$(curl_wrapper GET "https://music.youtube.com/" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9" \
    --timeout 4 \
    -w "\nHTTP_STATUS:%{http_code}" 2>/dev/null)
  code=$(tail -n 2 <<<"$raw" | grep -oE 'HTTP_STATUS:[0-9]{3}' | tail -n 1 | cut -d: -f2)
  code="${code:-000}"
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi
  resp=$(head -c 16384 <<<"$raw" | sed -e '/HTTP_STATUS:[0-9]\{3\}$/d')
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
  local raw resp code cc=""
  raw=$(curl_wrapper GET "https://www.netflix.com" --timeout 4 -w "\nHTTP_STATUS:%{http_code}" 2>/dev/null)
  code=$(tail -n 2 <<<"$raw" | grep -oE 'HTTP_STATUS:[0-9]{3}' | tail -n 1 | cut -d: -f2)
  code="${code:-000}"
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    echo "No ($code)"
    return
  fi
  resp=$(head -c 16384 <<<"$raw" | sed -e '/HTTP_STATUS:[0-9]\{3\}$/d')
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

check_ru_site() {
  local url="$1" timeout="${2:-4}"
  local resp code body
  resp=$(curl_wrapper GET "$url" -k -L --max-redirs 5 --timeout "$timeout" -w "\nHTTP_STATUS:%{http_code}" 2>/dev/null)
  code=$(tail -n 2 <<<"$resp" | grep -oE 'HTTP_STATUS:[0-9]{3}' | tail -n 1 | cut -d: -f2)
  code="${code:-000}"
  body=$(head -c 8192 <<<"$resp" | sed -e '/HTTP_STATUS:[0-9]\{3\}$/d')

  if [[ "$code" == "000" ]]; then
    echo "Blocked (Timeout / Geo-Drop)"
    return
  elif [[ "$code" =~ ^(403|429|439|498)$ ]]; then
    echo "Blocked (WAF $code)"
    return
  elif ! [[ "$code" =~ ^(200|301|302|307)$ ]]; then
    echo "Blocked ($code)"
    return
  fi

  # Inspect response body for WAF / Captcha / Geo-drop stubs returning 200 OK
  if LC_ALL=C.UTF-8 grep -qi -E "ddos-guard|ddos protection" <<<"$body"; then
    echo "Blocked (DDoS-Guard)"
  elif LC_ALL=C.UTF-8 grep -qi -E "qrator|firewallcaptcha|pow_challenge" <<<"$body"; then
    echo "Blocked (Qrator)"
  elif LC_ALL=C.UTF-8 grep -qi -E "smartcaptcha|showcaptcha|recaptcha|abt-challenge" <<<"$body"; then
    echo "Blocked (Captcha)"
  elif LC_ALL=C.UTF-8 grep -qi -E "доступ ограничен|за пределами рф|выключите vpn|access denied|доступ запрещен|нет соединения" <<<"$body"; then
    echo "Blocked (Geo-restricted)"
  else
    echo "OK"
  fi
}

lookup_gosuslugi() {
  check_ru_site "https://www.gosuslugi.ru" 4
}

lookup_nalog() {
  check_ru_site "https://nalog.gov.ru" 4
}

lookup_mosru() {
  check_ru_site "https://www.mos.ru" 4
}

lookup_rzd() {
  check_ru_site "https://ticket.rzd.ru" 4
}

lookup_yandex() {
  check_ru_site "https://ya.ru" 3
}

lookup_vk() {
  check_ru_site "https://vk.com" 4
}

lookup_sberbank() {
  check_ru_site "https://www.sberbank.ru" 4
}

lookup_tbank() {
  check_ru_site "https://tbank.ru" 4
}

lookup_vtb() {
  check_ru_site "https://www.vtb.ru" 4
}

lookup_alfabank() {
  check_ru_site "https://alfabank.ru" 4
}

lookup_avito() {
  local res
  res=$(check_ru_site "https://www.avito.ru" 4)
  if [[ "$res" == *"Qrator"* || "$res" == *"439"* ]]; then
    echo "Blocked (439 Qrator Captcha)"
  else
    echo "$res"
  fi
}

lookup_wildberries() {
  check_ru_site "https://www.wildberries.ru" 4
}

lookup_ozon() {
  local res
  res=$(check_ru_site "https://www.ozon.ru" 4)
  if [[ "$res" == *"Captcha"* || "$res" == *"Geo-restricted"* ]]; then
    echo "Blocked (Anti-VPN)"
  else
    echo "$res"
  fi
}

lookup_kinopoisk() {
  check_ru_site "https://www.kinopoisk.ru" 4
}

run_services_check() {
  local s_dir="$TMP_WORK_DIR/services"
  mkdir -p "$s_dir"

  local check_pairs=(
    "lookup_instagram" "$s_dir/instagram"
    "lookup_discord" "$s_dir/discord"
    "lookup_twitter_x" "$s_dir/twitter"
    "lookup_chatgpt" "$s_dir/chatgpt"
    "lookup_google" "$s_dir/google"
    "lookup_gemini" "$s_dir/gemini"
    "lookup_youtube" "$s_dir/youtube"
    "lookup_youtube_cdn" "$s_dir/youtube_cdn"
    "lookup_youtube_premium" "$s_dir/youtube_premium"
    "lookup_youtube_music" "$s_dir/youtube_music"
    "lookup_rutracker" "$s_dir/rutracker"
    "lookup_spotify_signup" "$s_dir/spotify"
    "lookup_netflix" "$s_dir/netflix"
    "lookup_steam" "$s_dir/steam"
    "lookup_playstation" "$s_dir/playstation"
    "lookup_reddit" "$s_dir/reddit"
    "lookup_apple" "$s_dir/apple"
    "lookup_gosuslugi" "$s_dir/gosuslugi"
    "lookup_nalog" "$s_dir/nalog"
    "lookup_mosru" "$s_dir/mosru"
    "lookup_rzd" "$s_dir/rzd"
    "lookup_yandex" "$s_dir/yandex"
    "lookup_vk" "$s_dir/vk"
    "lookup_sberbank" "$s_dir/sberbank"
    "lookup_tbank" "$s_dir/tbank"
    "lookup_vtb" "$s_dir/vtb"
    "lookup_alfabank" "$s_dir/alfabank"
    "lookup_avito" "$s_dir/avito"
    "lookup_wildberries" "$s_dir/wildberries"
    "lookup_ozon" "$s_dir/ozon"
    "lookup_kinopoisk" "$s_dir/kinopoisk"
  )

  local i=0 running=0 max_jobs=8
  while (( i < ${#check_pairs[@]} )); do
    local fn="${check_pairs[i]}"
    local out="${check_pairs[i+1]}"
    ( "$fn" > "$out" ) &
    running=$((running + 1))
    if (( running >= max_jobs )); then
      wait -n 2>/dev/null || true
      running=$((running - 1))
    fi
    ((i += 2))
  done
  wait

  local yt_res
  yt_res=$(read_val "$s_dir/youtube" "No")
  YOUTUBE_DETECTED_CC=$(awk '{print $1}' <<<"$yt_res")
  if [[ "$yt_res" == *"Без рекламы"* ]]; then
    YOUTUBE_AD_FREE=true
  fi

  ARR_RU_UNBLOCK+=( "Instagram (Meta)"$'\t'"$(read_val "$s_dir/instagram" "No")" )
  ARR_RU_UNBLOCK+=( "Discord (Voice/Gateway)"$'\t'"$(read_val "$s_dir/discord" "No")" )
  ARR_RU_UNBLOCK+=( "Twitter / X"$'\t'"$(read_val "$s_dir/twitter" "No")" )
  ARR_RU_UNBLOCK+=( "OpenAI ChatGPT"$'\t'"$(read_val "$s_dir/chatgpt" "No")" )
  ARR_RU_UNBLOCK+=( "Google (Регион)"$'\t'"$(read_val "$s_dir/google" "N/A")" )
  ARR_RU_UNBLOCK+=( "Google Gemini"$'\t'"$(read_val "$s_dir/gemini" "No")" )
  ARR_RU_UNBLOCK+=( "YouTube"$'\t'"$yt_res" )
  ARR_RU_UNBLOCK+=( "YouTube CDN"$'\t'"$(read_val "$s_dir/youtube_cdn" "No")" )
  ARR_RU_UNBLOCK+=( "YouTube Premium"$'\t'"$(read_val "$s_dir/youtube_premium" "No")" )
  ARR_RU_UNBLOCK+=( "YouTube Music"$'\t'"$(read_val "$s_dir/youtube_music" "No")" )
  ARR_RU_UNBLOCK+=( "Rutracker"$'\t'"$(read_val "$s_dir/rutracker" "No")" )
  ARR_RU_UNBLOCK+=( "Spotify Signup"$'\t'"$(read_val "$s_dir/spotify" "No")" )
  ARR_RU_UNBLOCK+=( "Netflix"$'\t'"$(read_val "$s_dir/netflix" "No")" )
  ARR_RU_UNBLOCK+=( "Steam Store (Игры)"$'\t'"$(read_val "$s_dir/steam" "No")" )
  ARR_RU_UNBLOCK+=( "PlayStation Network"$'\t'"$(read_val "$s_dir/playstation" "No")" )
  ARR_RU_UNBLOCK+=( "Reddit"$'\t'"$(read_val "$s_dir/reddit" "No")" )
  ARR_RU_UNBLOCK+=( "Apple Services"$'\t'"$(read_val "$s_dir/apple" "No")" )

  ARR_RU_LOCAL+=( "Госуслуги (gosuslugi.ru)"$'\t'"$(read_val "$s_dir/gosuslugi" "Blocked")" )
  ARR_RU_LOCAL+=( "ФНС (nalog.gov.ru)"$'\t'"$(read_val "$s_dir/nalog" "Blocked")" )
  ARR_RU_LOCAL+=( "Мос.ру (mos.ru)"$'\t'"$(read_val "$s_dir/mosru" "Blocked")" )
  ARR_RU_LOCAL+=( "РЖД (ticket.rzd.ru)"$'\t'"$(read_val "$s_dir/rzd" "Blocked")" )
  ARR_RU_LOCAL+=( "Яндекс (ya.ru)"$'\t'"$(read_val "$s_dir/yandex" "Blocked")" )
  ARR_RU_LOCAL+=( "ВКонтакте (vk.com)"$'\t'"$(read_val "$s_dir/vk" "Blocked")" )
  ARR_RU_LOCAL+=( "СберБанк (sberbank.ru)"$'\t'"$(read_val "$s_dir/sberbank" "Blocked")" )
  ARR_RU_LOCAL+=( "Т-Банк (tbank.ru)"$'\t'"$(read_val "$s_dir/tbank" "Blocked")" )
  ARR_RU_LOCAL+=( "ВТБ (vtb.ru)"$'\t'"$(read_val "$s_dir/vtb" "Blocked")" )
  ARR_RU_LOCAL+=( "Альфа-Банк (alfabank.ru)"$'\t'"$(read_val "$s_dir/alfabank" "Blocked")" )
  ARR_RU_LOCAL+=( "Авито (avito.ru)"$'\t'"$(read_val "$s_dir/avito" "Blocked")" )
  ARR_RU_LOCAL+=( "Wildberries (wildberries.ru)"$'\t'"$(read_val "$s_dir/wildberries" "Blocked")" )
  ARR_RU_LOCAL+=( "Озон (ozon.ru)"$'\t'"$(read_val "$s_dir/ozon" "Blocked")" )
  ARR_RU_LOCAL+=( "Кинопоиск (kinopoisk.ru)"$'\t'"$(read_val "$s_dir/kinopoisk" "Blocked")" )
}

# ------------------------------------------------------------------------------
# 4. Multi-Region RU Connectivity & Speed
# ------------------------------------------------------------------------------

resolve_target_ip() {
  local target_host="$1"
  local resolved_ip=""
  if [[ "$IPV6_ONLY" == "true" ]] || [[ "$IPV4_SUPPORTED" -ne 1 && "$IPV6_SUPPORTED" -eq 1 ]]; then
    if is_command_available "getent"; then
      resolved_ip=$(getent ahostsv6 "$target_host" 2>/dev/null | awk '{print $1; exit}')
    fi
  else
    if is_command_available "getent"; then
      resolved_ip=$(getent ahostsv4 "$target_host" 2>/dev/null | awk '{print $1; exit}')
    fi
  fi
  if [[ -n "$resolved_ip" ]]; then
    echo "$resolved_ip"
  else
    echo "$target_host"
  fi
}

ping_host() {
  local host="$1" out_file="$2"
  local ping_flags=()
  if [[ "$IPV4_ONLY" == "true" ]] || [[ "$IPV6_SUPPORTED" -eq 0 ]]; then
    ping_flags+=(-4)
  elif [[ "$IPV6_ONLY" == "true" ]] || [[ "$IPV4_SUPPORTED" -eq 0 && "$IPV6_SUPPORTED" -eq 1 ]]; then
    ping_flags+=(-6)
  fi
  local target_ip
  target_ip=$(resolve_target_ip "$host")
  local p
  p=$(LC_ALL=C ping "${ping_flags[@]}" -c 2 -W 2 "$target_ip" 2>/dev/null | tail -n 1 | awk -F '/' '{print $5}')
  if [[ -n "$p" && "$p" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    printf "%.1f ms" "$p" > "$out_file"
  else
    printf "N/A" > "$out_file"
  fi
}

convert_to_mbps() {
  local val="$1" unit="$2"
  awk -v val="$val" -v unit="$unit" 'BEGIN {
    mbps = 0;
    if (unit ~ /^[Gg]bits/) mbps = val * 1000;
    else if (unit ~ /^[Mm]bits/) mbps = val;
    else if (unit ~ /^[Kk]bits/) mbps = val / 1000;
    else if (unit ~ /^bits/) mbps = val / 1000000;
    else if (unit ~ /^[Gg]Bytes/) mbps = val * 8000;
    else if (unit ~ /^[Mm]Bytes/) mbps = val * 8;
    else if (unit ~ /^[Kk]Bytes/) mbps = val * 8 / 1000;
    else if (unit ~ /^Bytes/) mbps = val * 8 / 1000000;

    if (mbps >= 10) printf "%d", mbps + 0.5;
    else if (mbps >= 0.05) printf "%.1f", mbps;
    else if (mbps > 0) printf "0.1";
    else printf "null";
  }'
}

iperf_stream_test() {
  local target_host="$1"
  local target_port="$2"
  local mode="$3"          # "DL" or "UL"
  local test_time="$4"
  local streams="$5"
  local label="$6"
  local ping_val="$7"
  local dl_speed_for_ul="${8:-}"

  IPERF_LAST_NUM="null"
  IPERF_LAST_STR="—"
  IPERF_LAST_STATUS=1
  IPERF_SERVER_BUSY=false

  local stdbuf_cmd=()
  if is_command_available "stdbuf"; then
    stdbuf_cmd=("stdbuf" "-oL" "-eL")
  fi

  local mode_args=()
  if [[ "$mode" == "DL" ]]; then
    mode_args+=("-R")
  fi

  local active_streams="$streams"

  while :; do
    local final_recv="" final_send="" last_interval=""
    local has_stream_error=false has_server_busy=false has_conn_error=false

    # Show initial live indicator before data begins streaming
    if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
      if [[ -n "$COLOR_TABLE_VALUE" ]]; then
        if [[ "$mode" == "DL" ]]; then
          printf "\r\033[2K  %s  %s  \033[%sm↓ ...\033[0m\r" \
            "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE"
        else
          printf "\r\033[2K  %s  %s  \033[%sm↓ %s / ↑ ...\033[0m\r" \
            "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE" "$dl_speed_for_ul"
        fi
      else
        if [[ "$mode" == "DL" ]]; then
          printf "\r\033[2K  %s  %s  ↓ ...\r" \
            "$(pad_str "$label" 37)" "$(pad_str "$ping_val" 10)"
        else
          printf "\r\033[2K  %s  %s  ↓ %s / ↑ ...\r" \
            "$(pad_str "$label" 37)" "$(pad_str "$ping_val" 10)" "$dl_speed_for_ul"
        fi
      fi
    fi

    local stream_args=()
    if (( active_streams > 1 )); then
      stream_args+=("-P" "$active_streams")
    fi

    local iperf_ver_flag=()
    if [[ "$IPV6_ONLY" == "true" ]] || [[ "$IPV4_SUPPORTED" -ne 1 && "$IPV6_SUPPORTED" -eq 1 ]]; then
      iperf_ver_flag+=(-6)
    elif [[ "$IPV4_ONLY" == "true" ]] || [[ "$IPV6_SUPPORTED" -eq 0 ]]; then
      iperf_ver_flag+=(-4)
    fi

    local raw_out="$TMP_WORK_DIR/iperf_raw.log"
    : > "$raw_out"

    timeout $((test_time + 4)) "${stdbuf_cmd[@]}" iperf3 "${iperf_ver_flag[@]}" -c "$target_host" -p "$target_port" "${mode_args[@]}" -t "$test_time" "${stream_args[@]}" -i 1 > "$raw_out" 2>&1 &
    local iperf_pid=$!
    local start_sec=$SECONDS
    local last_line=0

    while kill -0 "$iperf_pid" 2>/dev/null; do
      # 1. Non-blocking keypress check (<Enter>, Space, 's')
      if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]]; then
        local user_key=""
        if read -t 0.15 -n 1 user_key < /dev/tty 2>/dev/null; then
          if [[ -z "$user_key" || "$user_key" == $'\n' || "$user_key" == $'\r' || "$user_key" == " " || "$user_key" == "s" || "$user_key" == "S" ]]; then
            IPERF_SKIPPED=true
            { kill -TERM "$iperf_pid" 2>/dev/null; sleep 0.05; kill -KILL "$iperf_pid" 2>/dev/null; wait "$iperf_pid" 2>/dev/null; } 2>/dev/null || true
            break
          fi
        fi
      else
        sleep 0.15
      fi

      # 2. Check for new output lines without subshell process substitution
      local total_lines=0
      total_lines=$(wc -l < "$raw_out" 2>/dev/null || echo 0)
      if (( total_lines > last_line )); then
        local chunk=""
        chunk=$(sed -n "$((last_line + 1)),${total_lines}p" "$raw_out" 2>/dev/null || true)
        if [[ -n "$chunk" ]]; then
          while IFS= read -r line; do
            if [[ "$line" == *"unable to create a new stream"* || "$line" == *"parallel"* ]]; then
              has_stream_error=true
            fi
            if [[ "$line" == *"busy running a test"* ]]; then
              has_server_busy=true
            fi
            if [[ "$line" == *"Connection refused"* || "$line" == *"unable to connect"* ]]; then
              has_conn_error=true
            fi

            if (( active_streams > 1 )); then
              [[ "$line" =~ ^[[:space:]]*\[SUM\] ]] || continue
            else
              [[ "$line" =~ ^[[:space:]]*\[[[:space:]]*[0-9]+\] || "$line" =~ ^[[:space:]]*\[SUM\] ]] || continue
            fi

            if [[ "$line" =~ ([0-9]+(\.[0-9]+)?)[[:space:]]+([a-zA-Z]+bits/sec|[a-zA-Z]+Bytes/sec) ]]; then
              local val="${BASH_REMATCH[1]}"
              local unit="${BASH_REMATCH[3]}"
              local mbps
              mbps=$(convert_to_mbps "$val" "$unit")
              [[ "$mbps" == "null" || -z "$mbps" ]] && continue

              if [[ "$line" == *"receiver"* ]]; then
                final_recv="$mbps"
              elif [[ "$line" == *"sender"* ]]; then
                final_send="$mbps"
              else
                last_interval="$mbps"
                if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
                  if [[ -n "$COLOR_TABLE_VALUE" ]]; then
                    if [[ "$mode" == "DL" ]]; then
                      printf "\r\033[2K  %s  %s  \033[%sm↓ %s Mbps...\033[0m\r" \
                        "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE" "$mbps"
                    else
                      printf "\r\033[2K  %s  %s  \033[%sm↓ %s / ↑ %s Mbps...\033[0m\r" \
                        "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE" "$dl_speed_for_ul" "$mbps"
                    fi
                  else
                    if [[ "$mode" == "DL" ]]; then
                      printf "\r\033[2K  %s  %s  ↓ %s Mbps...\r" \
                        "$(pad_str "$label" 37)" "$(pad_str "$ping_val" 10)" "$mbps"
                    else
                      printf "\r\033[2K  %s  %s  ↓ %s / ↑ %s Mbps...\r" \
                        "$(pad_str "$label" 37)" "$(pad_str "$ping_val" 10)" "$dl_speed_for_ul" "$mbps"
                    fi
                  fi
                fi
              fi
            fi
          done <<< "$chunk"
        fi
        last_line=$total_lines
      fi

      # 3. Watchdog timeout
      if (( SECONDS - start_sec > test_time + 4 )); then
        { kill -TERM "$iperf_pid" 2>/dev/null; sleep 0.05; kill -KILL "$iperf_pid" 2>/dev/null; wait "$iperf_pid" 2>/dev/null; } 2>/dev/null || true
        break
      fi
    done

    wait "$iperf_pid" 2>/dev/null || true

    if [[ "$IPERF_SKIPPED" == "true" ]]; then
      IPERF_LAST_STR="Skipped"
      IPERF_LAST_NUM="null"
      IPERF_LAST_STATUS=2
      break
    fi

    local final_total=0
    final_total=$(wc -l < "$raw_out" 2>/dev/null || echo 0)
    if (( final_total > last_line )); then
      local final_chunk=""
      final_chunk=$(sed -n "$((last_line + 1)),${final_total}p" "$raw_out" 2>/dev/null || true)
      if [[ -n "$final_chunk" ]]; then
        while IFS= read -r line; do
          if [[ "$line" == *"unable to create a new stream"* || "$line" == *"parallel"* ]]; then
            has_stream_error=true
          fi
          if [[ "$line" == *"busy running a test"* ]]; then
            has_server_busy=true
          fi
          if [[ "$line" == *"Connection refused"* || "$line" == *"unable to connect"* ]]; then
            has_conn_error=true
          fi

          if (( active_streams > 1 )); then
            [[ "$line" =~ ^[[:space:]]*\[SUM\] ]] || continue
          else
            [[ "$line" =~ ^[[:space:]]*\[[[:space:]]*[0-9]+\] || "$line" =~ ^[[:space:]]*\[SUM\] ]] || continue
          fi

          if [[ "$line" =~ ([0-9]+(\.[0-9]+)?)[[:space:]]+([a-zA-Z]+bits/sec|[a-zA-Z]+Bytes/sec) ]]; then
            local val="${BASH_REMATCH[1]}"
            local unit="${BASH_REMATCH[3]}"
            local mbps
            mbps=$(convert_to_mbps "$val" "$unit")
            [[ "$mbps" == "null" || -z "$mbps" ]] && continue
            if [[ "$line" == *"receiver"* ]]; then
              final_recv="$mbps"
            elif [[ "$line" == *"sender"* ]]; then
              final_send="$mbps"
            else
              last_interval="$mbps"
            fi
          fi
        done <<< "$final_chunk"
      fi
    fi

    local res_mbps="${final_recv:-${final_send:-$last_interval}}"

    if (( active_streams > 1 )) && [[ "$has_stream_error" == "true" || ( -z "$res_mbps" && "$has_server_busy" != "true" && "$has_conn_error" != "true" ) ]]; then
      active_streams=1
      continue
    fi

    if [[ "$has_server_busy" == "true" ]]; then
      IPERF_SERVER_BUSY=true
    fi

    if [[ -n "$res_mbps" && "$res_mbps" != "null" ]]; then
      IPERF_LAST_NUM="$res_mbps"
      IPERF_LAST_STR="${res_mbps} Mbps"
      IPERF_LAST_STATUS=0
    fi

    break
  done
}

# Regional test targets: Region | City | Provider | Host | PortRange
RU_REGIONAL_SERVERS=(
  "Центральный регион"$'\t'"Москва"$'\t'"Hostkey DataLine"$'\t'"spd-rudp.hostkey.ru"$'\t'"5201-5209"
  "Центральный регион"$'\t'"Москва"$'\t'"ЭР-Телеком / Дом.ру"$'\t'"st.msk.ertelecom.ru"$'\t'"5201-5209"
  "Центральный регион"$'\t'"Москва"$'\t'"МТС"$'\t'"mskst.st.mtsws.net"$'\t'"3333"
  "Северо-Западный регион"$'\t'"Санкт-Петербург"$'\t'"ЭР-Телеком"$'\t'"st.spb.ertelecom.ru"$'\t'"5201-5209"
  "Приволжский регион"$'\t'"Казань"$'\t'"ЭР-Телеком"$'\t'"st.kzn.ertelecom.ru"$'\t'"5201-5209"
  "Приволжский регион"$'\t'"Казань"$'\t'"МТС"$'\t'"kazst.st.mtsws.net"$'\t'"3333"
  "Приволжский регион"$'\t'"Нижний Новгород"$'\t'"ЭР-Телеком"$'\t'"st.nn.ertelecom.ru"$'\t'"5201-5209"
  "Приволжский регион"$'\t'"Нижний Новгород"$'\t'"ТТК"$'\t'"speed-nn.vtt.net"$'\t'"5201"
  "Приволжский регион"$'\t'"Самара"$'\t'"ЭР-Телеком"$'\t'"st.samara.ertelecom.ru"$'\t'"5201-5209"
  "Южный регион"$'\t'"Ростов-на-Дону"$'\t'"ЭР-Телеком"$'\t'"st.rostov.ertelecom.ru"$'\t'"5201-5209"
  "Южный регион"$'\t'"Волгоград"$'\t'"ЭР-Телеком"$'\t'"st.volgograd.ertelecom.ru"$'\t'"5201-5209"
  "Южный регион"$'\t'"Волгоград"$'\t'"ТТК"$'\t'"speed-vgd.vtt.net"$'\t'"5201"
  "Южный регион"$'\t'"Астрахань"$'\t'"Билайн"$'\t'"astrakhan1.speedtest.corbina.net"$'\t'"5201"
  "Уральский регион"$'\t'"Екатеринбург"$'\t'"ЭР-Телеком"$'\t'"st.ekat.ertelecom.ru"$'\t'"5201-5209"
  "Уральский регион"$'\t'"Тюмень"$'\t'"ЭР-Телеком"$'\t'"st.tmn.ertelecom.ru"$'\t'"5201-5209"
  "Уральский регион"$'\t'"Тюмень"$'\t'"МТС"$'\t'"tumst.st.mtsws.net"$'\t'"3333"
  "Уральский регион"$'\t'"Челябинск"$'\t'"ЭР-Телеком"$'\t'"st.chel.ertelecom.ru"$'\t'"5201-5209"
  "Уральский регион"$'\t'"Пермь"$'\t'"ЭР-Телеком"$'\t'"st.perm.ertelecom.ru"$'\t'"5201-5209"
  "Уральский регион"$'\t'"Уфа"$'\t'"ЭР-Телеком"$'\t'"st.ufa.ertelecom.ru"$'\t'"5201-5209"
  "Сибирский регион"$'\t'"Новосибирск"$'\t'"ЭР-Телеком"$'\t'"st.nsk.ertelecom.ru"$'\t'"5201-5209"
  "Сибирский регион"$'\t'"Красноярск"$'\t'"ЭР-Телеком"$'\t'"st.krsk.ertelecom.ru"$'\t'"5201-5209"
  "Сибирский регион"$'\t'"Омск"$'\t'"ЭР-Телеком"$'\t'"st.omsk.ertelecom.ru"$'\t'"5201-5209"
  "Дальневосточный регион"$'\t'"Иркутск"$'\t'"ЭР-Телеком"$'\t'"st.irkutsk.ertelecom.ru"$'\t'"5201-5209"
  "Дальневосточный регион"$'\t'"Якутск"$'\t'"МТС"$'\t'"yktst.st.mtsws.net"$'\t'"3333"
)

run_region_speed_test() {
  local region="$1" city="$2" provider="$3" host="$4" port_spec="$5" ping_val="$6"
  local label="• ${city} (${provider})"
  local speed="—"

  local ping_num="${ping_val%% ms*}"
  if [[ ! "$ping_num" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    ping_num="null"
  fi

  local base_port="${port_spec%%-*}"
  if [[ "$RUN_IPERF" != "true" || -z "$host" ]] || ! is_command_available "iperf3"; then
    ARR_CONNECTIVITY+=( "$region"$'\t'"$city"$'\t'"$provider"$'\t'"$host"$'\t'"$base_port"$'\t'"$ping_val"$'\t'"$ping_num"$'\t—\tnull\tnull' )
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "  %s  %s  %s\n" \
        "$(pad_str "$label" 37)" \
        "$(pad_str "$(format_value "$ping_val")" 10)" \
        "$(format_value "—")"
    fi
    return
  fi

  # Drain pending keystrokes before starting this server test
  if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]]; then
    while read -t 0.01 -n 1000 _ < /dev/tty 2>/dev/null; do :; done
  fi

  local target_ip
  target_ip=$(resolve_target_ip "$host")

  local streams="$IPERF_STREAMS"
  if [[ -z "$streams" ]]; then
    if (( NODE_CPU_CORES >= 2 )); then
      streams=4
    else
      streams=2
    fi
  fi

  local ports=()
  if [[ "$port_spec" == "5200-5209" ]]; then
    ports=(5200 5201 5202 5203 5204 5205 5206 5207 5208 5209)
  elif [[ "$port_spec" == "5201-5209" ]]; then
    ports=(5201 5202 5203 5204 5205 5206 5207 5208 5209)
  else
    ports=("$port_spec")
  fi

  local test_time="${IPERF_TIME:-3}"
  local best_dl="—" best_ul="—"
  local best_dl_num="null" best_ul_num="null"
  local actual_port="$base_port"
  IPERF_SKIPPED=false

  # Initial live state before port scanning
  if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
    if [[ -n "$COLOR_TABLE_VALUE" ]]; then
      printf "\r\033[2K  %s  %s  \033[%sm↓ ...\033[0m\r" \
        "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE"
    else
      printf "\r\033[2K  %s  %s  ↓ ...\r" \
        "$(pad_str "$label" 37)" "$(pad_str "$ping_val" 10)"
    fi
  fi

  local port_attempts=0
  for p in "${ports[@]}"; do
    # Check if user pressed skip before TCP probe
    if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]]; then
      local user_key=""
      if read -t 0.05 -n 1 user_key < /dev/tty 2>/dev/null; then
        if [[ -z "$user_key" || "$user_key" == $'\n' || "$user_key" == $'\r' || "$user_key" == " " || "$user_key" == "s" || "$user_key" == "S" ]]; then
          IPERF_SKIPPED=true
          break
        fi
      fi
    fi

    # Fast TCP pre-check (2.0s) to skip closed or firewalled ports immediately without sending corrupting payload
    if ! timeout 2.0 bash -c "true > /dev/tcp/$target_ip/$p" 2>/dev/null; then
      continue
    fi

    ((port_attempts++))

    # 1. Download (Server -> Client, Reverse mode -R)
    iperf_stream_test "$target_ip" "$p" "DL" "$test_time" "$streams" "$label" "$ping_val" ""
    if [[ "$IPERF_SKIPPED" == "true" ]]; then
      break
    fi

    # If single-port host was busy running another test, wait 1.5s and retry once
    if [[ "$IPERF_LAST_STATUS" -ne 0 && "$IPERF_SERVER_BUSY" == "true" && ${#ports[@]} -eq 1 ]]; then
      sleep 1.5
      iperf_stream_test "$target_ip" "$p" "DL" "$test_time" "$streams" "$label" "$ping_val" ""
      if [[ "$IPERF_SKIPPED" == "true" ]]; then
        break
      fi
    fi

    if [[ "$IPERF_LAST_STATUS" -ne 0 ]]; then
      # If multi-port host has failed 4 active ports, stop scanning further ports
      if (( port_attempts >= 4 )); then
        break
      fi
      continue
    fi

    best_dl="$IPERF_LAST_STR"
    best_dl_num="$IPERF_LAST_NUM"
    actual_port="$p"

    # Prepare terminal state for upload before socket-drain pause
    if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
      if [[ -n "$COLOR_TABLE_VALUE" ]]; then
        printf "\r\033[2K  %s  %s  \033[%sm↓ %s / ↑ ...\033[0m\r" \
          "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE" "$best_dl"
      else
        printf "\r\033[2K  %s  %s  ↓ %s / ↑ ...\r" \
          "$(pad_str "$label" 37)" "$(pad_str "$ping_val" 10)" "$best_dl"
      fi
    fi

    # Delay 1s with interactive keypress monitoring before Upload
    for ((s=0; s<10; s++)); do
      if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]]; then
        local user_key=""
        if read -t 0.1 -n 1 user_key < /dev/tty 2>/dev/null; then
          if [[ -z "$user_key" || "$user_key" == $'\n' || "$user_key" == $'\r' || "$user_key" == " " || "$user_key" == "s" || "$user_key" == "S" ]]; then
            IPERF_SKIPPED=true
            break
          fi
        fi
      else
        sleep 0.1
      fi
    done
    if [[ "$IPERF_SKIPPED" == "true" ]]; then
      best_ul="Skipped"
      break
    fi

    # 2. Upload (Client -> Server, Normal mode)
    iperf_stream_test "$target_ip" "$p" "UL" "$test_time" "$streams" "$label" "$ping_val" "$best_dl"
    if [[ "$IPERF_SKIPPED" == "true" ]]; then
      best_ul="Skipped"
      break
    fi

    if [[ "$IPERF_LAST_STATUS" -ne 0 && "$IPERF_SERVER_BUSY" == "true" ]]; then
      sleep 1.5
      iperf_stream_test "$target_ip" "$p" "UL" "$test_time" "$streams" "$label" "$ping_val" "$best_dl"
      if [[ "$IPERF_SKIPPED" == "true" ]]; then
        best_ul="Skipped"
        break
      fi
    fi

    if [[ "$IPERF_LAST_STATUS" -eq 0 ]]; then
      best_ul="$IPERF_LAST_STR"
      best_ul_num="$IPERF_LAST_NUM"
    else
      best_ul="Blocked"
      best_ul_num="null"
    fi

    # Download succeeded; test completed
    break
  done

  if [[ "$IPERF_SKIPPED" == "true" ]]; then
    if [[ "$best_dl" != "—" && "$best_dl" != "Skipped" ]]; then
      speed="↓ $best_dl / ↑ Skipped"
    else
      speed="Skipped"
    fi
  elif [[ "$best_dl" != "—" || "$best_ul" != "—" ]]; then
    if [[ "$best_ul" == "Blocked" ]]; then
      speed="↓ $best_dl / ↑ Blocked"
    elif [[ "$best_dl" != "—" && "$best_ul" != "—" ]]; then
      speed="↓ $best_dl / ↑ $best_ul"
    elif [[ "$best_dl" != "—" ]]; then
      speed="↓ $best_dl / ↑ —"
    else
      speed="↓ — / ↑ $best_ul"
    fi
  else
    speed="Unavailable"
  fi

  local port_num="${actual_port:-$base_port}"
  ARR_CONNECTIVITY+=( "$region"$'\t'"$city"$'\t'"$provider"$'\t'"$host"$'\t'"$port_num"$'\t'"$ping_val"$'\t'"$ping_num"$'\t'"$speed"$'\t'"$best_dl_num"$'\t'"$best_ul_num" )

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    if [[ -t 1 ]]; then
      printf "\r\033[2K  %s  %s  %s\n" \
        "$(pad_str "$label" 37)" \
        "$(pad_str "$(format_value "$ping_val")" 10)" \
        "$(format_value "$speed")"
    else
      printf "  %s  %s  %s\n" \
        "$(pad_str "$label" 37)" \
        "$(pad_str "$ping_val" 10)" \
        "$speed"
    fi
  fi
}

measure_ru_pings() {
  local p_dir="$TMP_WORK_DIR/pings"
  mkdir -p "$p_dir"

  # Ping all unique regional hosts in parallel
  for srv in "${RU_REGIONAL_SERVERS[@]}"; do
    IFS=$'\t' read -r _ _ _ host _ <<<"$srv"
    if [[ ! -f "$p_dir/$host" ]]; then
      touch "$p_dir/$host"
      ( ping_host "$host" "$p_dir/$host" ) &
    fi
  done
  wait
}

measure_ru_iperf() {
  local p_dir="$TMP_WORK_DIR/pings"
  local current_region=""

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    bold "4. ⚡️ Связность и скорость каналов связи (Enter — пропустить узел)"; printf "\n\n"
  fi

  # Enable non-canonical mode if interactive terminal
  if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]] && is_command_available "stty"; then
    SAVED_STTY=$(stty -g < /dev/tty 2>/dev/null || echo "")
    stty -icanon -echo < /dev/tty 2>/dev/null || true
  fi

  for srv_entry in "${RU_REGIONAL_SERVERS[@]}"; do
    IFS=$'\t' read -r region city provider host port_spec <<<"$srv_entry"

    if [[ "$JSON_OUTPUT" != "true" && "$region" != "$current_region" ]]; then
      if [[ -n "$current_region" ]]; then
        printf "\n"
      fi
      if [[ -n "$COLOR_BOLD" ]]; then
        printf "  \033[%sm[%s]\033[0m\n" "$COLOR_BOLD" "$region"
      else
        printf "  [%s]\n" "$region"
      fi
      current_region="$region"
    fi

    local ping_val="N/A"
    if [[ -f "$p_dir/$host" ]]; then
      ping_val=$(read_val "$p_dir/$host" "N/A")
    fi

    run_region_speed_test "$region" "$city" "$provider" "$host" "$port_spec" "$ping_val"
  done

  # Restore terminal stty settings
  if [[ -n "$SAVED_STTY" && -r /dev/tty ]]; then
    stty "$SAVED_STTY" < /dev/tty 2>/dev/null || true
    SAVED_STTY=""
  fi

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    if ! is_command_available "iperf3"; then
      printf "\n"
      if [[ -n "$COLOR_NULL" ]]; then
        printf "  \033[%sm* Для замера пропускной способности iPerf3: apt install -y iperf3\033[0m\n" "$COLOR_NULL"
      else
        printf "  * Для замера пропускной способности iPerf3: apt install -y iperf3\n"
      fi
    fi
    printf "\n"
  fi
}

get_local_datacenter_target() {
  local cc="${NODE_COUNTRY_CODE^^}"
  case "$cc" in
    "DE")
      echo "Frankfurt, Clouvider 10G"$'\t'"fra.speedtest.clouvider.net"$'\t'"5200-5209"
      ;;
    "NL")
      echo "Amsterdam, Clouvider 10G"$'\t'"ams.speedtest.clouvider.net"$'\t'"5200-5209"
      ;;
    "GB"|"UK")
      echo "London, Clouvider 10G"$'\t'"lon.speedtest.clouvider.net"$'\t'"5200-5209"
      ;;
    "RU")
      echo "Moscow, Hostkey 10G"$'\t'"spd-rudp.hostkey.ru"$'\t'"5201-5209"
      ;;
    "US")
      echo "New York, Clouvider 10G"$'\t'"nyc.speedtest.clouvider.net"$'\t'"5200-5209"
      ;;
    "FR")
      echo "Paris, Testdebit 10G"$'\t'"paris.testdebit.info"$'\t'"5200-5209"
      ;;
    "FI"|"SE"|"NO"|"DK"|"EE"|"LV"|"LT"|"PL"|"AT"|"CH"|"CZ"|"BE")
      echo "Frankfurt, Clouvider 10G"$'\t'"fra.speedtest.clouvider.net"$'\t'"5200-5209"
      ;;
    *)
      echo "Frankfurt, Clouvider 10G"$'\t'"fra.speedtest.clouvider.net"$'\t'"5200-5209"
      ;;
  esac
}

measure_local_uplink() {
  local target_info
  target_info=$(get_local_datacenter_target)
  local dc_name dc_host dc_port_spec
  IFS=$'\t' read -r dc_name dc_host dc_port_spec <<<"$target_info"

  NODE_UPLINK_TARGET="$dc_name"
  NODE_UPLINK_HOST="$dc_host"
  NODE_UPLINK_PING="N/A"
  NODE_UPLINK_PING_NUM="null"
  NODE_UPLINK_DL="null"
  NODE_UPLINK_UL="null"
  NODE_UPLINK_STATUS=""

  local p_file="$TMP_WORK_DIR/local_uplink_ping.txt"
  ping_host "$dc_host" "$p_file"
  local ping_val="N/A"
  if [[ -f "$p_file" ]]; then
    ping_val=$(read_val "$p_file" "N/A")
  fi
  NODE_UPLINK_PING="$ping_val"
  local ping_num="${ping_val%% ms*}"
  if [[ "$ping_num" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    NODE_UPLINK_PING_NUM="$ping_num"
  fi

  if [[ "$RUN_IPERF" != "true" ]] || ! is_command_available "iperf3"; then
    NODE_UPLINK_STATUS="$ping_val ($dc_name)"
    return
  fi

  if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]] && is_command_available "stty"; then
    SAVED_STTY=$(stty -g < /dev/tty 2>/dev/null || echo "")
    stty -icanon -echo < /dev/tty 2>/dev/null || true
  fi

  if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]]; then
    while read -t 0.01 -n 1000 _ < /dev/tty 2>/dev/null; do :; done
  fi

  local ports=()
  if [[ "$dc_port_spec" == "5200-5209" ]]; then
    ports=(5200 5201 5202 5203 5204 5205 5206 5207 5208 5209)
  elif [[ "$dc_port_spec" == "5201-5209" ]]; then
    ports=(5201 5202 5203 5204 5205 5206 5207 5208 5209)
  else
    ports=("$dc_port_spec")
  fi

  local test_time=2
  local streams="$IPERF_STREAMS"
  if [[ -z "$streams" ]]; then
    if (( NODE_CPU_CORES >= 2 )); then
      streams=4
    else
      streams=2
    fi
  fi

  local best_dl="—" best_ul="—"
  local best_dl_num="null" best_ul_num="null"
  IPERF_SKIPPED=false
  local label="• Local Uplink (${dc_name})"

  local dc_ip
  dc_ip=$(resolve_target_ip "$dc_host")

  for p in "${ports[@]}"; do
    if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]]; then
      local user_key=""
      if read -t 0.05 -n 1 user_key < /dev/tty 2>/dev/null; then
        if [[ -z "$user_key" || "$user_key" == $'\n' || "$user_key" == $'\r' || "$user_key" == " " || "$user_key" == "s" || "$user_key" == "S" ]]; then
          IPERF_SKIPPED=true
          break
        fi
      fi
    fi

    # Fast TCP pre-check (2.0s) to skip closed or firewalled ports immediately without sending corrupting payload
    if ! timeout 2.0 bash -c "true > /dev/tcp/$dc_ip/$p" 2>/dev/null; then
      continue
    fi

    # 1. Download
    iperf_stream_test "$dc_ip" "$p" "DL" "$test_time" "$streams" "$label" "$ping_val" ""
    if [[ "$IPERF_SKIPPED" == "true" ]]; then
      break
    fi

    if [[ "$IPERF_LAST_STATUS" -ne 0 ]]; then
      continue
    fi

    best_dl="$IPERF_LAST_STR"
    best_dl_num="$IPERF_LAST_NUM"

    for ((s=0; s<5; s++)); do
      if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]]; then
        local user_key=""
        if read -t 0.1 -n 1 user_key < /dev/tty 2>/dev/null; then
          if [[ -z "$user_key" || "$user_key" == $'\n' || "$user_key" == $'\r' || "$user_key" == " " || "$user_key" == "s" || "$user_key" == "S" ]]; then
            IPERF_SKIPPED=true
            break
          fi
        fi
      else
        sleep 0.1
      fi
    done
    if [[ "$IPERF_SKIPPED" == "true" ]]; then
      best_ul="Skipped"
      break
    fi

    # 2. Upload
    iperf_stream_test "$dc_ip" "$p" "UL" "$test_time" "$streams" "$label" "$ping_val" "$best_dl"
    if [[ "$IPERF_SKIPPED" == "true" ]]; then
      best_ul="Skipped"
      break
    fi

    if [[ "$IPERF_LAST_STATUS" -eq 0 ]]; then
      best_ul="$IPERF_LAST_STR"
      best_ul_num="$IPERF_LAST_NUM"
    fi
    break
  done

  # Clear live streaming indicator before printing header
  if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
    printf "\r\033[2K\r"
  fi

  if [[ -n "$SAVED_STTY" && -r /dev/tty ]]; then
    stty "$SAVED_STTY" < /dev/tty 2>/dev/null || true
    SAVED_STTY=""
  fi

  if [[ "$IPERF_SKIPPED" == "true" ]]; then
    if [[ "$best_dl" != "—" && "$best_dl" != "Skipped" ]]; then
      NODE_UPLINK_STATUS="$ping_val | ↓ $best_dl / ↑ Skipped ($dc_name)"
    else
      NODE_UPLINK_STATUS="$ping_val | Skipped ($dc_name)"
    fi
  elif [[ "$best_dl" != "—" && "$best_ul" != "—" ]]; then
    NODE_UPLINK_STATUS="$ping_val | ↓ $best_dl / ↑ $best_ul ($dc_name)"
  elif [[ "$best_dl" != "—" ]]; then
    NODE_UPLINK_STATUS="$ping_val | ↓ $best_dl ($dc_name)"
  else
    NODE_UPLINK_STATUS="$ping_val ($dc_name)"
  fi

  NODE_UPLINK_DL="$best_dl_num"
  NODE_UPLINK_UL="$best_ul_num"
}

# ------------------------------------------------------------------------------
# Output Formatting
# ------------------------------------------------------------------------------

format_table() {
  awk -F '\t' '{
    for (i=1; i<=NF; i++) {
      clean = $i; gsub(/\033\[[0-9;]*[a-zA-Z]/, "", clean)
      if (length(clean) > w[i]) w[i] = length(clean)
    }
    rows[NR] = $0
  }
  END {
    for (r=1; r<=NR; r++) {
      n = split(rows[r], cols, "\t")
      line = ""
      for (i=1; i<=n; i++) {
        clean = cols[i]; gsub(/\033\[[0-9;]*[a-zA-Z]/, "", clean)
        pad = w[i] - length(clean) + 2
        line = line cols[i] sprintf("%*s", (i==n ? 0 : pad), "")
      }
      print line
    }
  }'
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
    if [[ -n "$EXTERNAL_IPV4" ]]; then
      echo -e " IPv4:\t$(bold "$EXTERNAL_IPV4")"
    else
      echo -e " IPv4:\t$(color "$COLOR_NULL" "None (Not configured)")"
    fi
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
    if [[ -n "$NODE_UPLINK_STATUS" ]]; then
      echo -e " Аплинк (Local DC):\t$(format_value "$NODE_UPLINK_STATUS")"
    fi
  } | format_table
  if [[ -n "$COLOR_INFO" ]]; then
    printf "\033[%sm%s\033[0m\n\n" "$COLOR_INFO" "$line_sep"
  else
    printf "%s\n\n" "$line_sep"
  fi
}

calculate_geoip_stats() {
  local target_col="v4"
  local col_label="IPv4"
  if [[ $IPV4_SUPPORTED -ne 1 && $IPV6_SUPPORTED -eq 1 ]]; then
    target_col="v6"
    col_label="IPv6"
  fi

  local top_code="" top_count=0 total=0
  declare -A counts=()

  for row in "${ARR_GEOIP[@]}"; do
    local db_name v4 v6
    IFS=$'\t' read -r db_name v4 v6 <<<"$row"
    local check_val="$v4"
    if [[ "$target_col" == "v6" ]]; then
      check_val="$v6"
    fi
    if [[ "$check_val" =~ ^[A-Z]{2}$ ]]; then
      counts["$check_val"]=$(( counts["$check_val"] + 1 ))
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

  local consensus_val="${top_code} (${top_country})"
  printf "  Консенсус: %s — %s/%s (%s%%)\n\n" "$(color "$consensus_color" "$consensus_val")" "$top_count" "$total" "$top_pct"

  {
    echo -e "  Код\tСтрана\tДоля (${col_label})"
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
  bold "1. 📍 Консенсус GeoIP баз данных (18 источников)"; printf "\n"
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
  bold "2. 🌍 Доступность зарубежных сервисов (Western Services)"; printf "\n"
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
  bold "3. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)"; printf "\n"
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

build_json() {
  local geoip_lines unblock_lines local_lines conn_lines
  geoip_lines=$(printf "%s\n" "${ARR_GEOIP[@]}")
  unblock_lines=$(printf "%s\n" "${ARR_RU_UNBLOCK[@]}")
  local_lines=$(printf "%s\n" "${ARR_RU_LOCAL[@]}")
  conn_lines=$(printf "%s\n" "${ARR_CONNECTIVITY[@]}")

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
    --arg uplink_target "${NODE_UPLINK_TARGET:-}" \
    --arg uplink_ping "${NODE_UPLINK_PING_NUM:-null}" \
    --arg uplink_dl "${NODE_UPLINK_DL:-null}" \
    --arg uplink_ul "${NODE_UPLINK_UL:-null}" \
    --arg yt_ad_free "$YOUTUBE_AD_FREE" \
    --arg yt_cc "$YOUTUBE_DETECTED_CC" \
    --arg geoip_raw "$geoip_lines" \
    --arg unblock_raw "$unblock_lines" \
    --arg local_raw "$local_lines" \
    --arg conn_raw "$conn_lines" \
    '{
      ip: (if $ip != "" then $ip else null end),
      ipv6: (if $ipv6 != "" then $ipv6 else null end),
      system: {
        os: $os,
        virt: $virt,
        uptime: $uptime,
        cpu_model: $cpu_model,
        cpu_cores: ($cpu_cores | try tonumber catch 1),
        cpu_steal_pct: ($cpu_steal | try tonumber catch 0.0),
        cpu_steal_all_time_pct: ($cpu_steal_alltime | try tonumber catch 0.00),
        ram: $ram,
        disk: $disk
      },
      location: { country: $country, city: $city, asn: $asn, org: $org },
      quality: { host_type: $host_type, risk: $risk, google_captcha: $captcha, rkn_registry: $rkn },
      network: {
        bbr: $bbr,
        udp: $udp,
        port25: $port25,
        local_uplink: {
          target: (if $uplink_target != "" then $uplink_target else null end),
          latency_ms: (if $uplink_ping != "" and $uplink_ping != "null" and $uplink_ping != "N/A" then ($uplink_ping | try tonumber catch null) else null end),
          download_mbps: (if $uplink_dl != "" and $uplink_dl != "null" then ($uplink_dl | try tonumber catch null) else null end),
          upload_mbps: (if $uplink_ul != "" and $uplink_ul != "null" then ($uplink_ul | try tonumber catch null) else null end)
        }
      },
      youtube: { ad_free: ($yt_ad_free == "true"), country: $yt_cc },
      geoip_consensus: (
        [$geoip_raw | split("\n")[] | select(length > 0) | split("\t")]
        | map(select(.[0] != null and .[0] != "") | {key: .[0], value: {ipv4: (.[1] // "N/A"), ipv6: (.[2] // "N/A")}})
        | from_entries
      ),
      ru_unblock: (
        [$unblock_raw | split("\n")[] | select(length > 0) | split("\t")]
        | map(select(.[0] != null and .[0] != "") | {key: .[0], value: (.[1] // "N/A")})
        | from_entries
      ),
      ru_local_services: (
        [$local_raw | split("\n")[] | select(length > 0) | split("\t")]
        | map(select(.[0] != null and .[0] != "") | {key: .[0], value: (.[1] // "N/A")})
        | from_entries
      ),
      connectivity: (
        [$conn_raw | split("\n")[] | select(length > 0) | split("\t")]
        | map(select(.[0] != null and .[0] != "") | {
            region: .[0],
            city: .[1],
            provider: .[2],
            host: .[3],
            port: (.[4] | try tonumber catch 5201),
            latency: (.[5] // "—"),
            latency_ms: (if .[6] != null and .[6] != "" and .[6] != "null" then (.[6] | try tonumber catch null) else null end),
            speed: (.[7] // "—"),
            download_mbps: (if .[8] != null and .[8] != "" and .[8] != "null" then (.[8] | try tonumber catch null) else null end),
            upload_mbps: (if .[9] != null and .[9] != "" and .[9] != "null" then (.[9] | try tonumber catch null) else null end)
          })
      )
    }')
}

display_help() {
  cat <<EOF
Использование: nodecheck.sh [ОПЦИИ]

NodeCheck (RU Edition) v${SCRIPT_VERSION} — комплексный аудит серверных нод и сетевого стека под РФ
(Аплинк ноды и 7 регионов РФ)

Управление:
  <Enter> / Пробел         Мгновенно пропустить текущий узел при замере скорости iPerf3

Опции:
  -h, --help               Показать эту справку и выйти
  -4, --ipv4               Принудительно использовать только IPv4
  -6, --ipv6               Принудительно использовать только IPv6
  -j, --json               Вывод результатов в чистом формате JSON
  -s, --streams ЧИСЛО      Число параллельных потоков iPerf3 (по умолч.: 2 для 1 vCPU, 4 для 2+ vCPU)
  --no-iperf               Пропустить замер скорости iPerf3 (только пинг)
  --iperf-all              Замер скорости iPerf3 по всем 7 регионам РФ (по умолчанию включен)
  --full-iperf             Расширенный тест iPerf3 (по 10с на прием и отдачу)
  --iperf-time СЕК         Время замера iPerf3 на прием и отдачу (по умолч.: 3с)
  --no-color               Отключить цветовое форматирование ANSI
  -p, --proxy АДРЕС        Использовать SOCKS5/SOCKS5h прокси (хост:порт)
  -i, --interface ИНТЕРФЕЙС Привязать запросы к сетевому интерфейсу (eth0, ens3)
  --no-doh                 Отключить DNS-over-HTTPS (системный резолвер)
  --doh ПРОВАЙДЕР          Выбор DoH: cloudflare, quad9, adguard
  -v, --verbose            Подробное логирование сетевых запросов
  -d, --debug              Режим отладки (сохранение трассировки в сессионный log-файл)

Примеры:
  ./nodecheck.sh                         # Комплексный аудит (железо, GeoIP, сервисы, пинг и iPerf3 по всем 7 регионам РФ)
  ./nodecheck.sh -s 8                    # Аудит с 8 параллельными потоками iPerf3
  ./nodecheck.sh --no-iperf              # Быстрый экспресс-аудит без замера скорости (~10-15 секунд)
  ./nodecheck.sh --full-iperf            # Расширенный замер скорости (по 10с на каждый регион)
  ./nodecheck.sh -4                      # Аудит только по IPv4
  ./nodecheck.sh -6                      # Аудит только по IPv6
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
      -4|--ipv4)
        IPV4_ONLY=true
        IPV6_ONLY=false
        shift
        ;;
      -6|--ipv6)
        IPV6_ONLY=true
        IPV4_ONLY=false
        shift
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
      -s|--streams)
        if [[ $# -lt 2 || -z "$2" || ! "$2" =~ ^[1-9][0-9]*$ ]]; then
          error_exit "Для опции $1 требуется положительное целое число (например, -s 4)"
        fi
        IPERF_STREAMS="$2"
        shift 2
        ;;
      --no-iperf)
        RUN_IPERF=false
        shift
        ;;
      --iperf-all)
        RUN_IPERF_ALL=true
        shift
        ;;
      --full-iperf)
        RUN_FULL_IPERF=true
        IPERF_TIME=10
        IPERF_TIME_DL=10
        IPERF_TIME_UL=10
        shift
        ;;
      --iperf-time)
        if [[ $# -lt 2 || -z "$2" || ! "$2" =~ ^[1-9][0-9]*$ ]]; then
          error_exit "Для опции $1 требуется положительное целое число секунд (например, --iperf-time 3)"
        fi
        IPERF_TIME="$2"
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
  MAIN_PID=$$
  export MAIN_PID
  CPU_STAT_START=$(head -n 1 /proc/stat 2>/dev/null || echo "")

  parse_arguments "$@"
  init_colors

  TMP_WORK_DIR=$(mktemp -d "/tmp/nodecheck.XXXXXX" 2>/dev/null || mktemp -d)
  if [[ -z "$TMP_WORK_DIR" || ! -d "$TMP_WORK_DIR" ]]; then
    error_exit "Не удалось создать защищенный временный каталог в /tmp"
  fi
  chmod 700 "$TMP_WORK_DIR" 2>/dev/null || true
  DEBUG_LOG_FILE="$TMP_WORK_DIR/debug.log"

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

  # Local Datacenter Uplink capacity check
  progress_status "Замер аплинк-канала ноды (Local Datacenter)"
  measure_local_uplink
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
  progress_status "Замер задержки RTT (Европа и регионы РФ)"
  measure_ru_pings
  progress_clear

  measure_ru_iperf

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    build_json
    printf "%s\n" "$RESULT_JSON"
  fi

  if [[ "$DEBUG" == "true" && -n "$DEBUG_LOG_FILE" && -f "$DEBUG_LOG_FILE" ]]; then
    printf "\n--- [DEBUG TRACE LOG] ---\n" >&2
    cat "$DEBUG_LOG_FILE" >&2
    printf "--- [END DEBUG LOG] ---\n\n" >&2
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" || -z "${BASH_SOURCE[0]}" ]]; then
  main "$@"
fi
