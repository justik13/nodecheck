#!/usr/bin/env bash

# ==============================================================================
# NodeCheck (RU Edition) v4.0.0-ru
# Comprehensive Node Hardware, Network Quality, Geolocation & Access Auditor
# Tailored for Russian Federation Network Realities (Reverse Geoblocking / Multi-Region)
#
# GitHub: https://github.com/justik13/nodecheck
# License: MIT
# ==============================================================================

set -o pipefail
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

SCRIPT_VERSION="4.0.0-ru"

CURL_TIMEOUT=4
CURL_RETRIES=0
VERBOSE=false
DEBUG=false
JSON_OUTPUT=false
IPV4_ONLY=false
IPV6_ONLY=false
USE_DOH=false
SELECTED_DOH_URL=""
PROXY_ADDR=""
INTERFACE_NAME=""
CUSTOM_DOH_PROVIDER=""
RUN_DNS_AUDIT=true
RUN_TG_AUDIT=true
RUN_DPI_AUDIT=true
RUN_GEOBLOCK_AUDIT=true
RUN_IPERF=true
RUN_IPERF_ALL=true
RUN_SPEEDTEST=true
RUN_FULL_IPERF=false
IPERF_TIME=3
IPERF_TIME_DL="$IPERF_TIME"
IPERF_TIME_UL="$IPERF_TIME"
IPERF_STREAMS=""
INSTALL_DEPS=false
SHOW_FULL_IP=false

EXTERNAL_IPV4=""
EXTERNAL_IPV6=""
IPV4_SUPPORTED=0
IPV6_SUPPORTED=0

NODE_ASN=""
NODE_ORG=""
NODE_CITY=""
NODE_COUNTRY_CODE=""
NODE_IP_NATIVE="Native (Geo-consistent)"
NODE_IP_NATIVE_COLOR="0;90"
NODE_RIR_REG_COUNTRY=""
CURRENT_DISK_TEST_FILE=""
NODE_TYPE=""
NODE_RISK=""
NODE_RISK_MAX_NUM=""
NODE_SCAM_SCORE=""
NODE_ABUSE_SCORE=""
NODE_ABUSE_REPORTS="0"
NODE_IPQUERY_SCORE=""
NODE_RISK_COLOR="0;90"
NODE_CAPTCHA_STATUS=""
NODE_CAPTCHA_COLOR="0;90"
NODE_RKN_STATUS="Checking..."
NODE_RKN_COLOR="0;90"
NODE_DNSBL_STATUS="Checking..."
NODE_DNSBL_COLOR="0;90"
NODE_DNSBL_TOTAL=0
NODE_DNSBL_LISTED=0
NODE_DNSBL_ZONES=""
NODE_BBR_STATUS=""
NODE_PORT25_STATUS=""
NODE_UDP_STATUS=""
NODE_UPLINK_STATUS=""
NODE_UPLINK_TARGET=""
NODE_UPLINK_HOST=""
NODE_UPLINK_PORTSPEC=""
NODE_UPLINK_PING="N/A"
NODE_UPLINK_PING_NUM="null"
NODE_UPLINK_DL="null"
NODE_UPLINK_UL="null"
SORTED_UPLINK_CANDIDATES=()
SAVED_STTY=""
INITIAL_STTY=""
IPERF_SKIPPED=false

NODE_CPU_MODEL=""
NODE_CPU_CORES=1
NODE_VIRT=""
NODE_UPTIME=""
NODE_OS=""
NODE_RAM=""
NODE_DISK=""
NODE_DISK_TYPE="SSD"
NODE_DISK_IO=""
NODE_DISK_IO_NUM="null"
NODE_DISK_IO_STATUS="pending"
NODE_DISK_IO_MSG=""
NODE_DISK_IO_4K="N/A"
NODE_DISK_IO_4K_NUM="null"
RUN_DISK_IO=true
DISK_IO_EXPLICIT=false
NODE_AES_HARDWARE=false
NODE_AES_TYPE="none"
NODE_AES_STATUS="Disabled (Soft)"
NODE_AES_COLOR="0;31"
NODE_CRYPTO_SPEED="N/A"
NODE_CRYPTO_SPEED_MB_S="null"
RUN_CRYPTO_BENCH=true
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
COLOR_ASN="1;36"
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
ARR_DNS_RESOLVERS=()
ARR_TG_DCS=()
ARR_DPI_DOMAINS=()
ARR_GEO_BLOCKED=()
DNS_HIJACKING_DETECTED=false
DNS_HIJACKING_MSG=""

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
      printf "  \033[%sm*\033[0m %s...\r" "$COLOR_WARN" "$1"
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
    ""|"null"|"$STATUS_NA"|*"N/A"*)
      color "$COLOR_NULL" "$val"
      ;;
    "NO"|"NO ("*)
      color "$COLOR_INFO" "$val"
      ;;
    *"Unavailable"*|"No"*|"BLOCKED"*|*"Blocked"*|*"Закрыт"*|*"Denied"*|*"High Risk"*|*"Leaks"*|*"Timeout"*|*"Captcha"*)
      color "$COLOR_DANGER" "$val"
      ;;
    "Yes"*|"YES"*|"OK"*|"Clean"*|"Active"*|"Open"*|"True"|"true"|*"Protected"*|*"Closed"*|*"Включен"*|*"Доступен"*)
      color "$COLOR_SUCCESS" "$val"
      ;;
    *"[Без рекламы"*|*"Без рекламы"*)
      color "$COLOR_SUCCESS" "$val"
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
        color "$COLOR_INFO" "$val"
      fi
      ;;
    *"Mbps"*)
      color "$COLOR_TABLE_VALUE" "$val"
      ;;
    *)
      if [[ "$val" =~ ^[A-Z]{2}$ ]] || [[ "$val" =~ ^[A-Z]{2}\ \([A-Z0-9-]+\)$ ]]; then
        color "$COLOR_INFO" "$val"
      else
        printf "%s" "$val"
      fi
      ;;
  esac
}

render_speed_bar() {
  local num="$1" max="${2:-1000}" width="${3:-6}"
  [[ -z "$num" || "$num" == "null" || "$num" == "—" || "$num" == "N/A" ]] && return
  num="${num// /}"
  local int_num=0
  if [[ "$num" == *"G"* || "$num" == *"g"* ]]; then
    local g_val="${num%%[Gg]*}"
    local g_int="${g_val%%.*}"
    local g_dec="${g_val#*.}"
    [[ "$g_dec" == "$g_val" ]] && g_dec="0"
    g_dec="${g_dec:0:3}"
    while (( ${#g_dec} < 3 )); do g_dec+="0"; done
    int_num=$(( g_int * 1000 + 10#$g_dec ))
  else
    local m_val="${num%%[Mm]*}"
    m_val="${m_val%%.*}"
    m_val="${m_val//[^0-9]/}"
    [[ -n "$m_val" ]] && int_num="$m_val"
  fi
  [[ ! "$int_num" =~ ^[0-9]+$ ]] && return

  local filled=0
  if (( int_num > 0 )); then
    filled=$(( (int_num * width + (max / 2)) / max ))
    (( filled < 1 )) && filled=1
    (( filled > width )) && filled=$width
  fi
  local empty=$(( width - filled ))

  if [[ "$NO_COLOR_MODE" == "true" || -n "${NO_COLOR:-}" || -z "$COLOR_SUCCESS" ]]; then
    local bar="["
    for ((b=0; b<filled; b++)); do bar+="#"; done
    for ((b=0; b<empty; b++)); do bar+="-"; done
    bar+="]"
    printf "%s" "$bar"
  else
    local fill_color="$COLOR_SUCCESS"
    if (( int_num < 100 )); then
      fill_color="$COLOR_WARN"
    elif (( int_num < 300 )); then
      fill_color="$COLOR_INFO"
    fi
    local bar="["
    if (( filled > 0 )); then
      bar+="$(printf '\033[%sm' "$fill_color")"
      for ((b=0; b<filled; b++)); do bar+="█"; done
      bar+="$(printf '\033[0m')"
    fi
    if (( empty > 0 )); then
      bar+="$(printf '\033[%sm' "$COLOR_NULL")"
      for ((b=0; b<empty; b++)); do bar+="░"; done
      bar+="$(printf '\033[0m')"
    fi
    bar+="]"
    printf "%s" "$bar"
  fi
}

compact_mbps() {
  local val="$1" max_len="${2:-0}"
  [[ -z "$val" || "$val" == "null" || "$val" == "—" ]] && { printf "—"; return; }
  [[ "$val" == "Blocked" || "$val" == "Skipped" || "$val" == "Unavailable" ]] && { printf "%s" "$val"; return; }
  local num="${val%% Mbps*}"; num="${num%%M*}"; num="${num// /}"
  local int_part="${num%%.*}"
  if [[ "$int_part" =~ ^[0-9]+$ ]]; then
    if (( int_part >= 1000 )); then
      if (( int_part >= 10000 )) || (( max_len > 0 )); then
        local g_round=$(( (int_part + 500) / 1000 ))
        printf "%dG" "$g_round"
      else
        local g_val
        g_val=$(awk "BEGIN { printf \"%.1f\", $num / 1000 }")
        printf "%sG" "$g_val"
      fi
    elif (( int_part >= 100 )) || (( max_len > 0 )); then
      printf "%dM" "$int_part"
    else
      local dec_part="${num#*.}"
      if [[ "$num" == *"."* && -n "$dec_part" && "$dec_part" != "$num" ]]; then
        printf "%.1fM" "$num"
      else
        printf "%dM" "$int_part"
      fi
    fi
  else
    printf "%s" "$val"
  fi
}

format_speed_cell() {
  local dl_num="$1" ul_num="$2" raw_speed="$3"
  if [[ "$raw_speed" == "Unavailable" || "$raw_speed" == "Skipped" || "$raw_speed" == "—" || -z "$raw_speed" ]]; then
    format_value "$raw_speed"
    return
  fi

  local force_compact=0
  if [[ "$ul_num" == "Blocked" || "$ul_num" == "Skipped" || "$raw_speed" == *"↑ Blocked"* || "$raw_speed" == *"↑ Skipped"* ]]; then
    force_compact=1
  fi

  local dl_disp ul_disp bar dl_styled ul_styled
  dl_disp=$(compact_mbps "${dl_num:-$raw_speed}" "$force_compact")
  if [[ -n "$dl_num" && "$dl_num" != "null" && "$dl_num" != "—" ]]; then
    bar=$(render_speed_bar "$dl_num" 1000 6)
  fi

  if [[ -n "$COLOR_TABLE_VALUE" ]]; then
    dl_styled="$(color "$COLOR_TABLE_VALUE" "$dl_disp")"
  else
    dl_styled="$dl_disp"
  fi

  if [[ -n "$ul_num" && "$ul_num" != "null" && "$ul_num" != "—" && "$ul_num" != "Blocked" && "$ul_num" != "Skipped" ]]; then
    ul_disp=$(compact_mbps "$ul_num" 0)
    if [[ -n "$COLOR_TABLE_VALUE" ]]; then
      ul_styled="$(color "$COLOR_TABLE_VALUE" "$ul_disp")"
    else
      ul_styled="$ul_disp"
    fi
  elif [[ "$ul_num" == "Blocked" || "$raw_speed" == *"↑ Blocked"* ]]; then
    ul_styled="$(format_value "Blocked")"
  elif [[ "$ul_num" == "Skipped" || "$raw_speed" == *"↑ Skipped"* ]]; then
    ul_styled="$(format_value "Skipped")"
  elif [[ "$ul_num" == "—" || "$raw_speed" == *"↑ —"* ]]; then
    ul_styled="$(format_value "—")"
  else
    ul_styled=""
  fi

  if [[ -n "$ul_styled" ]]; then
    if [[ -n "$bar" ]]; then
      printf "↓ %s %s / ↑ %s" "$bar" "$dl_styled" "$ul_styled"
    else
      printf "↓ %s / ↑ %s" "$dl_styled" "$ul_styled"
    fi
  elif [[ -n "$bar" ]]; then
    printf "↓ %s %s" "$bar" "$dl_styled"
  else
    format_value "$raw_speed"
  fi
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

restore_terminal() {
  if [[ -t 0 && -t 1 ]] && is_command_available "stty"; then
    if [[ -n "${SAVED_STTY:-}" ]]; then
      stty "$SAVED_STTY" 2>/dev/null || true
      SAVED_STTY=""
    fi
    if [[ -n "${INITIAL_STTY:-}" ]]; then
      stty "$INITIAL_STTY" 2>/dev/null || true
    fi
    stty echo icanon 2>/dev/null || true
  fi
  if [[ -t 1 ]]; then
    printf "\033[?25h" 2>/dev/null || true
  fi
}

enable_raw_terminal() {
  if [[ "$JSON_OUTPUT" != "true" && -t 0 && -t 1 ]] && is_command_available "stty"; then
    if [[ -z "$SAVED_STTY" ]]; then
      SAVED_STTY=$(stty -g 2>/dev/null || echo "")
    fi
    stty -icanon -echo 2>/dev/null || true
  fi
}

cleanup() {
  # Always restore terminal mode unconditionally FIRST, even in subshells or on signal interruption
  restore_terminal

  if [[ -n "${MAIN_PID:-}" && "$MAIN_PID" -ne "$BASHPID" ]]; then
    return 0
  fi
  if [[ "$$" -ne "$BASHPID" ]]; then
    return 0
  fi

  trap - EXIT INT TERM HUP QUIT
  progress_clear
  local pids
  pids=$(jobs -p 2>/dev/null)
  if [[ -n "$pids" ]]; then
    kill -TERM $pids 2>/dev/null || true
    sleep 0.05 2>/dev/null || true
    kill -KILL $pids 2>/dev/null || true
    wait 2>/dev/null || true
  fi
  if [[ -n "$CURRENT_DISK_TEST_FILE" && -f "$CURRENT_DISK_TEST_FILE" ]]; then
    rm -f "$CURRENT_DISK_TEST_FILE" 2>/dev/null || true
  fi
  if [[ -n "$TMP_WORK_DIR" && -d "$TMP_WORK_DIR" && ( "$TMP_WORK_DIR" == *nodecheck* || "$TMP_WORK_DIR" == /tmp/* ) ]]; then
    rm -rf "$TMP_WORK_DIR" 2>/dev/null || true
  fi
}

is_command_available() { command -v "$1" >/dev/null 2>&1; }

install_dependencies() {
  local missing_required=()

  if ! is_command_available "curl"; then
    missing_required+=("curl")
  fi
  if ! is_command_available "jq"; then
    missing_required+=("jq")
  fi
  if ! is_command_available "awk"; then
    missing_required+=("gawk")
  fi

  if [[ ${#missing_required[@]} -eq 0 ]]; then
    return 0
  fi

  local sudo_prefix=""
  local is_root=false
  if [[ ${EUID:-$(id -u 2>/dev/null || echo 1)} -eq 0 ]]; then
    is_root=true
  elif is_command_available "sudo"; then
    sudo_prefix="sudo "
  fi

  local install_cmd="${sudo_prefix}apt-get update && ${sudo_prefix}apt-get install -y --no-install-recommends ${missing_required[*]}"

  if [[ "$INSTALL_DEPS" == "true" ]]; then
    progress_status "Установка недостающих пакетов (${missing_required[*]})"
    log "INFO" "Installing missing packages with user consent: ${missing_required[*]}"
    export DEBIAN_FRONTEND=noninteractive
    ${sudo_prefix}apt-get update -qq >/dev/null 2>&1 || true
    ${sudo_prefix}apt-get install -y -qq --no-install-recommends "${missing_required[@]}" >/dev/null 2>&1 || true
    ${sudo_prefix}apt-get clean >/dev/null 2>&1 || true
    progress_clear
  else
    # Zero-Mutation policy: Never modify production system state without explicit --install-deps flag
    log "ERROR" "Missing required packages: ${missing_required[*]}. Run: $install_cmd"
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "\n" >&2
      if [[ -n "$COLOR_DANGER" ]]; then
        printf "\033[%sm[!] Не найдены обязательные утилиты для аудита:\033[0m %s\n" "$COLOR_DANGER" "${missing_required[*]}" >&2
      else
        printf "[!] Не найдены обязательные утилиты для аудита: %s\n" "${missing_required[*]}" >&2
      fi
      printf "Для работы скрипта установите их вручную:\n  %s\n" "$install_cmd" >&2
      printf "Либо перезапустите скрипт с флагом --install-deps\n\n" >&2
    fi
    exit 1
  fi

  local critical
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

  local doh_candidates=()
  if [[ -n "$CUSTOM_DOH_PROVIDER" ]]; then
    case "$CUSTOM_DOH_PROVIDER" in
      quad9)      doh_candidates=("https://dns.quad9.net/dns-query") ;;
      adguard)    doh_candidates=("https://dns.adguard-dns.com/dns-query") ;;
      opendns)    doh_candidates=("https://doh.opendns.com/dns-query") ;;
      google)     doh_candidates=("https://dns.google/dns-query") ;;
      cloudflare) doh_candidates=("https://cloudflare-dns.com/dns-query") ;;
      *)          doh_candidates=("$CUSTOM_DOH_PROVIDER") ;;
    esac
  else
    doh_candidates=(
      "https://cloudflare-dns.com/dns-query"
      "https://dns.google/dns-query"
      "https://dns.quad9.net/dns-query"
      "https://dns.adguard-dns.com/dns-query"
    )
  fi

  # Verify DoH connectivity by resolving domain name
  local doh_base_cmd=(curl -s -m 3 --connect-timeout 2)
  if [[ "$IPV4_ONLY" == "true" ]]; then
    doh_base_cmd+=(-4)
  elif [[ "$IPV6_ONLY" == "true" ]]; then
    doh_base_cmd+=(-6)
  fi

  if [[ -n "$PROXY_ADDR" ]]; then
    doh_base_cmd+=(--proxy "socks5h://$PROXY_ADDR")
  fi

  if [[ -n "$INTERFACE_NAME" ]]; then
    doh_base_cmd+=(--interface "$INTERFACE_NAME")
  fi

  local test_urls=("https://connectivitycheck.gstatic.com/generate_204" "https://cp.cloudflare.com/generate_204")
  local found=false

  for doh_url in "${doh_candidates[@]}"; do
    for t_url in "${test_urls[@]}"; do
      if "${doh_base_cmd[@]}" --doh-url "$doh_url" -o /dev/null "$t_url" 2>/dev/null; then
        SELECTED_DOH_URL="$doh_url"
        found=true
        break 2
      fi
    done
  done

  if [[ "$found" != "true" ]]; then
    log "WARNING" "DoH provider unreachable; using standard resolver"
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
    "https://ipv4.icanhazip.com"
    "https://api.ipify.org"
    "https://ifconfig.me/ip"
  )
  local ipv6_endpoints=(
    "https://ipv6.icanhazip.com"
    "https://api64.ipify.org"
  )

  local ep
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

  local has_v6_route=false
  if [[ "$IPV4_ONLY" != "true" ]]; then
    if ip -6 route show default 2>/dev/null | grep -q default || ip -6 addr show scope global 2>/dev/null | grep -q inet6; then
      has_v6_route=true
    fi
  fi

  if [[ "$has_v6_route" == "true" ]]; then
    for ep in "${ipv6_endpoints[@]}"; do
      local ip
      ip=$(curl_wrapper GET "$ep" --ip-version "6" --timeout 3 2>/dev/null | tr -d '[:space:]')
      if [[ "$ip" =~ ^[0-9a-fA-F:]+$ && ( "$ip" =~ :: || "$ip" =~ [0-9a-fA-F]+:[0-9a-fA-F]+ ) ]]; then
        EXTERNAL_IPV6="$ip"
        IPV6_SUPPORTED=1
        break
      fi
    done
  fi
}

mask_ipv4() {
  local ip="$1"
  local a b c d
  local IFS=.
  read -r a b c d <<< "$ip"
  if [[ -n "$a" && -n "$b" && -n "$c" && -n "$d" ]]; then
    echo "${a}.${b}.*.*"
  else
    echo "$ip"
  fi
}

mask_ipv6() {
  local ip="$1"
  [[ -z "$ip" ]] && return 0
  if [[ "$ip" != *:* ]]; then
    echo "$ip"
    return 0
  fi
  local expanded="$ip"
  if [[ "$expanded" == *"::"* ]]; then
    local left="${expanded%%::*}"
    local right="${expanded#*::}"
    local left_count=0 right_count=0
    [[ -n "$left" ]] && { IFS=: read -r -a l_arr <<< "$left"; left_count=${#l_arr[@]}; }
    [[ -n "$right" ]] && { IFS=: read -r -a r_arr <<< "$right"; right_count=${#r_arr[@]}; }
    local missing=$(( 8 - left_count - right_count ))
    local mid="" i
    for (( i=0; i<missing; i++ )); do mid="${mid}0:"; done
    expanded="${left:+${left}:}${mid}${right}"
    expanded="${expanded%:}"
  fi
  local h1 h2 h3 rest
  IFS=: read -r h1 h2 h3 rest <<< "$expanded"
  echo "${h1:-0}:${h2:-0}:${h3:-0}:*:*:*:*:*"
}

query_single_dnsbl() {
  local rev_ip="$1" z="$2" n="$3" out_file="$4"
  local out
  out=$(dig +short +time=2 +tries=1 "${rev_ip}.${z}" A 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
  if [[ -z "$out" || "$out" == *";;"* || "$out" =~ ^127\.255\.255\. ]]; then
    echo "clean" > "$out_file"
  elif [[ "$out" =~ ^127\.0\. ]]; then
    echo "listed" > "$out_file"
  else
    echo "clean" > "$out_file"
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

  # Multi-database Anti-Fraud & Risk Consensus (Scamalytics, AbuseIPDB, IP-API, IPQuery, MaxMind/RIR, Captcha, RKN)
  local q_dir="$TMP_WORK_DIR/quality_bench"
  mkdir -p "$q_dir" 2>/dev/null || true
  local scam_file="$q_dir/scam.json"
  local abuse_file="$q_dir/abuse.json"
  local ipapi_file="$q_dir/ipapi.json"
  local ipq_file="$q_dir/ipq.json"
  local checkplace_file="$q_dir/checkplace.json"
  local captcha_file="$q_dir/captcha.html"
  local rkn_ip_file="$q_dir/rkn_ip.lst"
  local rkn_sum_file="$q_dir/rkn_sum.lst"

  if [[ -n "$primary_ip" ]]; then
    curl_wrapper GET "https://ipinfo.check.place/${primary_ip}?db=scamalytics" "${ip_ver_arg[@]}" -A "curl/8.5.0" --timeout 4 > "$scam_file" 2>/dev/null &
    curl_wrapper GET "https://ipinfo.check.place/${primary_ip}?db=abuseipdb" "${ip_ver_arg[@]}" -A "curl/8.5.0" --timeout 4 > "$abuse_file" 2>/dev/null &
    curl_wrapper GET "http://ip-api.com/json/${primary_ip}?fields=status,mobile,proxy,hosting" "${ip_ver_arg[@]}" --timeout 4 > "$ipapi_file" 2>/dev/null &
    curl_wrapper GET "https://api.ipquery.io/${primary_ip}" "${ip_ver_arg[@]}" --timeout 4 > "$ipq_file" 2>/dev/null &
    curl_wrapper GET "https://ipinfo.check.place/${primary_ip}?lang=en" "${ip_ver_arg[@]}" -A "curl/8.5.0" --timeout 4 > "$checkplace_file" 2>/dev/null &
    curl_wrapper GET "https://www.google.com/search?q=test" --timeout 3 > "$captcha_file" 2>/dev/null &
    if [[ -n "$EXTERNAL_IPV4" ]]; then
      curl_wrapper GET "https://antifilter.download/list/ip.lst" --timeout 4 > "$rkn_ip_file" 2>/dev/null &
      curl_wrapper GET "https://antifilter.network/download/ipsum.lst" --timeout 4 > "$rkn_sum_file" 2>/dev/null &
    fi
    wait
  fi

  # 1. Native IP vs Broadcast IP (Geo-consistent vs Geo-discrepant)
  local actual_cc="" reg_cc=""
  if [[ -s "$checkplace_file" ]] && jq -e . >/dev/null 2>&1 < "$checkplace_file"; then
    actual_cc=$(jq -r '.Country.IsoCode // empty' "$checkplace_file" 2>/dev/null)
    reg_cc=$(jq -r '.Country.RegisteredCountry.IsoCode // empty' "$checkplace_file" 2>/dev/null)
  fi
  # Fallback to RIR RDAP if checkplace did not return registered country
  if [[ -z "$reg_cc" || "$reg_cc" == "null" ]] && [[ -n "$primary_ip" ]]; then
    local rdap_raw
    rdap_raw=$(curl_wrapper GET "https://rdap.db.ripe.net/ip/${primary_ip}" "${ip_ver_arg[@]}" --timeout 3 2>/dev/null)
    reg_cc=$(jq -r '.country // empty' <<<"$rdap_raw" 2>/dev/null)
    if [[ -z "$reg_cc" ]]; then
      rdap_raw=$(curl_wrapper GET "https://rdap.arin.net/registry/ip/${primary_ip}" "${ip_ver_arg[@]}" --timeout 3 2>/dev/null)
      reg_cc=$(jq -r '.country // empty' <<<"$rdap_raw" 2>/dev/null)
    fi
  fi
  NODE_RIR_REG_COUNTRY="${reg_cc^^}"
  if [[ -n "$NODE_RIR_REG_COUNTRY" && "$NODE_RIR_REG_COUNTRY" != "NULL" && "$NODE_RIR_REG_COUNTRY" =~ ^[A-Z]{2}$ ]]; then
    if [[ "$NODE_RIR_REG_COUNTRY" == "${NODE_COUNTRY_CODE^^}" ]]; then
      NODE_IP_NATIVE="Native (Geo-consistent)"
      NODE_IP_NATIVE_COLOR="$COLOR_SUCCESS"
    else
      NODE_IP_NATIVE="Broadcast / Geodiscrepant (Reg: ${NODE_RIR_REG_COUNTRY})"
      NODE_IP_NATIVE_COLOR="$COLOR_WARN"
    fi
  else
    NODE_RIR_REG_COUNTRY=""
    NODE_IP_NATIVE="N/A (Unverified)"
    NODE_IP_NATIVE_COLOR="$COLOR_NULL"
  fi

  local scam_score="" scam_risk="" scam_vpn=false scam_dc=false scam_tor=false
  if [[ -s "$scam_file" ]] && jq -e . >/dev/null 2>&1 < "$scam_file"; then
    scam_score=$(jq -r '.scamalytics.scamalytics_score // empty' "$scam_file" 2>/dev/null)
    scam_risk=$(jq -r '.scamalytics.scamalytics_risk // empty' "$scam_file" 2>/dev/null)
    scam_vpn=$(jq -r '.scamalytics.scamalytics_proxy.is_vpn // false' "$scam_file" 2>/dev/null)
    scam_dc=$(jq -r '(.scamalytics.scamalytics_proxy.is_datacenter // false) or (.external_datasources.x4bnet.is_datacenter // false)' "$scam_file" 2>/dev/null)
    scam_tor=$(jq -r '(.external_datasources.x4bnet.is_tor // false)' "$scam_file" 2>/dev/null)
  fi

  local abuse_score="" abuse_reports="0" abuse_type="" abuse_tor=false
  if [[ -s "$abuse_file" ]] && jq -e . >/dev/null 2>&1 < "$abuse_file"; then
    abuse_score=$(jq -r '.data.abuseConfidenceScore // empty' "$abuse_file" 2>/dev/null)
    abuse_reports=$(jq -r '.data.totalReports // 0' "$abuse_file" 2>/dev/null)
    abuse_type=$(jq -r '.data.usageType // empty' "$abuse_file" 2>/dev/null)
    abuse_tor=$(jq -r '.data.isTor // false' "$abuse_file" 2>/dev/null)
  fi

  local ipapi_hosting=false ipapi_proxy=false ipapi_mobile=false
  if [[ -s "$ipapi_file" ]] && jq -e . >/dev/null 2>&1 < "$ipapi_file"; then
    ipapi_hosting=$(jq -r '.hosting // false' "$ipapi_file" 2>/dev/null)
    ipapi_proxy=$(jq -r '.proxy // false' "$ipapi_file" 2>/dev/null)
    ipapi_mobile=$(jq -r '.mobile // false' "$ipapi_file" 2>/dev/null)
  fi

  local ipq_score="" ipq_dc=false ipq_vpn=false ipq_tor=false ipq_mobile=false
  if [[ -s "$ipq_file" ]] && jq -e . >/dev/null 2>&1 < "$ipq_file"; then
    ipq_score=$(jq -r '.risk.risk_score // empty' "$ipq_file" 2>/dev/null)
    ipq_dc=$(jq -r '.risk.is_datacenter // false' "$ipq_file" 2>/dev/null)
    ipq_vpn=$(jq -r '.risk.is_vpn // false' "$ipq_file" 2>/dev/null)
    ipq_tor=$(jq -r '.risk.is_tor // false' "$ipq_file" 2>/dev/null)
    ipq_mobile=$(jq -r '.risk.is_mobile // false' "$ipq_file" 2>/dev/null)
  fi

  NODE_SCAM_SCORE="$scam_score"
  NODE_ABUSE_SCORE="$abuse_score"
  NODE_ABUSE_REPORTS="$abuse_reports"
  NODE_IPQUERY_SCORE="$ipq_score"

  # Consensus classification: Tor -> VPN -> Datacenter/Hosting -> Mobile -> Residential
  if [[ "$scam_tor" == "true" || "$abuse_tor" == "true" || "$ipq_tor" == "true" ]]; then
    NODE_TYPE="Tor Exit Node"
  elif [[ "$scam_vpn" == "true" || "$ipapi_proxy" == "true" || "$ipq_vpn" == "true" ]]; then
    NODE_TYPE="Commercial VPN / Proxy"
  elif [[ "$ipapi_hosting" == "true" || "$ipq_dc" == "true" || "$scam_dc" == "true" || "$abuse_type" =~ [Dd]ata[[:space:]]?[Cc]enter|[Hh]osting|[Tt]ransit ]]; then
    NODE_TYPE="Data Center / Hosting"
  elif [[ "$ipapi_mobile" == "true" || "$ipq_mobile" == "true" ]]; then
    NODE_TYPE="Mobile Cellular / ISP"
  elif [[ -n "$abuse_type" && "$abuse_type" =~ [Ff]ixed|[Rr]esidential|[Cc]onsumer|[Cc]able ]]; then
    NODE_TYPE="Residential / ISP"
  elif [[ -s "$ipq_file" || -s "$ipapi_file" || -s "$scam_file" ]]; then
    NODE_TYPE="Residential / ISP"
  else
    NODE_TYPE="Data Center / Hosting"
  fi

  # Multi-source Anti-Fraud & Risk score calculation
  local score_parts=()
  local max_score=0
  local has_score=false

  if [[ "$scam_score" =~ ^[0-9]+$ ]]; then
    has_score=true
    score_parts+=("Scam: ${scam_score}/100")
    (( scam_score > max_score )) && max_score=$scam_score
  fi
  if [[ "$abuse_score" =~ ^[0-9]+$ ]]; then
    has_score=true
    score_parts+=("Abuse: ${abuse_score}%")
    (( abuse_score > max_score )) && max_score=$abuse_score
  fi
  if [[ "$ipq_score" =~ ^[0-9]+$ ]]; then
    has_score=true
    score_parts+=("IPQ: ${ipq_score}/100")
    (( ipq_score > max_score )) && max_score=$ipq_score
  fi

  NODE_RISK_MAX_NUM="$max_score"

  local score_summary=""
  if (( ${#score_parts[@]} > 0 )); then
    local score_joined=""
    for sp in "${score_parts[@]}"; do
      [[ -n "$score_joined" ]] && score_joined+=" | "
      score_joined+="$sp"
    done
    score_summary=" ($score_joined)"
  fi

  if [[ "$has_score" == "true" ]]; then
    local abuse_num="${abuse_reports//[^0-9]/}"
    abuse_num="${abuse_num:-0}"
    if (( max_score > 60 || abuse_num > 10 )); then
      NODE_RISK="High Risk / Flagged${score_summary}"
      NODE_RISK_COLOR="$COLOR_DANGER"
    elif (( max_score > 25 || abuse_num > 0 )); then
      NODE_RISK="Moderate Risk${score_summary}"
      NODE_RISK_COLOR="$COLOR_WARN"
    else
      NODE_RISK="Clean / Low Risk${score_summary}"
      NODE_RISK_COLOR="$COLOR_SUCCESS"
    fi
  else
    NODE_RISK="N/A (APIs Unavailable)"
    NODE_RISK_COLOR="$COLOR_NULL"
  fi

  # Google Captcha Test result
  local g_search=""
  [[ -s "$captcha_file" ]] && g_search=$(<"$captcha_file")
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

  # TCP BBR status & module detection
  if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q "bbr"; then
    NODE_BBR_STATUS="Active"
  else
    if modinfo tcp_bbr >/dev/null 2>&1 || ls /lib/modules/"$(uname -r 2>/dev/null)"/kernel/net/ipv4/tcp_bbr* >/dev/null 2>&1; then
      NODE_BBR_STATUS="Inactive (Available)"
    else
      NODE_BBR_STATUS="Inactive"
    fi
  fi

  # Port 25 Outbound Consensus (multi-server SMTP check: Gmail, Outlook, Mail.ru)
  local p25_open=false
  local p25_hosts=("smtp.gmail.com" "smtp-mail.outlook.com" "mxs.mail.ru")
  for host in "${p25_hosts[@]}"; do
    if timeout 0.8 bash -c "true > /dev/tcp/$host/25" 2>/dev/null; then
      p25_open=true
      break
    elif is_command_available nc && nc -z -w 1 "$host" 25 2>/dev/null; then
      p25_open=true
      break
    fi
  done
  if [[ "$p25_open" == "true" ]]; then
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
    if dig +short +time=2 +tries=1 @"$udp_dns_ip" cloudflare.com 2>/dev/null | grep -qE '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[0-9a-fA-F:]+)$' || \
       dig +short +time=2 +tries=1 @"$udp_dns_fallback" cloudflare.com 2>/dev/null | grep -qE '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[0-9a-fA-F:]+)$' || \
       dig +short +time=2 +tries=1 @"$udp_dns_ip" google.com 2>/dev/null | grep -qE '^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[0-9a-fA-F:]+)$'; then
      NODE_UDP_STATUS="Open (DNS Bidirectional)"
    else
      NODE_UDP_STATUS="Blocked"
    fi
  elif is_command_available nslookup; then
    if nslookup -timeout=2 cloudflare.com "$udp_dns_ip" >/dev/null 2>&1 || \
       nslookup -timeout=2 cloudflare.com "$udp_dns_fallback" >/dev/null 2>&1 || \
       nslookup -timeout=2 google.com "$udp_dns_ip" >/dev/null 2>&1; then
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

    if [[ -s "$rkn_ip_file" ]]; then
      ip_list_ok=true
      if grep -Fxq "$EXTERNAL_IPV4" "$rkn_ip_file"; then
        rkn_hit=true
      fi
    fi

    if [[ "$rkn_hit" != "true" && -s "$rkn_sum_file" ]]; then
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
        END { exit (hit ? 0 : 1) }' "$rkn_sum_file"; then
        rkn_hit=true
      fi
    fi

    if [[ "$rkn_hit" == "true" ]]; then
      NODE_RKN_STATUS="BLOCKED in RU (Antifilter Registry)"
      NODE_RKN_COLOR="$COLOR_DANGER"
    elif [[ "$ip_list_ok" == "true" || "$ipsum_list_ok" == "true" ]]; then
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

  # DNSBL Spam Blacklist Check (12 premier active zones)
  NODE_DNSBL_TOTAL=0
  NODE_DNSBL_LISTED=0
  NODE_DNSBL_ZONES=""

  if [[ -n "$EXTERNAL_IPV4" ]]; then
    if is_command_available dig; then
      local d_dir="$TMP_WORK_DIR/dnsbl"
      mkdir -p "$d_dir" 2>/dev/null || true

      local a b c d
      local IFS=.
      read -r a b c d <<< "$EXTERNAL_IPV4"
      local rev_ip="$d.$c.$b.$a"

      local dnsbl_zones=(
        "b.barracudacentral.org:Barracuda"
        "bl.spamcop.net:SpamCop"
        "dnsbl.dronebl.org:DroneBL"
        "psbl.surriel.com:Surriel PSBL"
        "bl.mailspike.net:Mailspike"
        "dnsbl-1.uceprotect.net:UCEPROTECT-1"
        "truncate.gbudb.net:GBUdb Truncate"
        "bl.blocklist.de:Blocklist.de"
        "all.s5h.net:s5h.net"
        "rbl.interserver.net:InterServer"
        "0spam.fusionzero.com:0spam"
        "bl.nordspam.com:Nordspam"
      )

      for item in "${dnsbl_zones[@]}"; do
        query_single_dnsbl "$rev_ip" "${item%%:*}" "${item#*:}" "$d_dir/${item#*:}" &
      done
      wait

      local listed_arr=()
      for item in "${dnsbl_zones[@]}"; do
        local n="${item#*:}"
        ((NODE_DNSBL_TOTAL++))
        local st
        st=$(cat "$d_dir/$n" 2>/dev/null || echo "clean")
        if [[ "$st" == "listed" ]]; then
          ((NODE_DNSBL_LISTED++))
          listed_arr+=("$n")
        fi
      done

      if (( NODE_DNSBL_LISTED > 0 )); then
        local z_joined=""
        for lz in "${listed_arr[@]}"; do
          [[ -n "$z_joined" ]] && z_joined+=", "
          z_joined+="$lz"
        done
        NODE_DNSBL_ZONES="$z_joined"
        NODE_DNSBL_STATUS="Listed (${NODE_DNSBL_LISTED}/${NODE_DNSBL_TOTAL}: ${z_joined})"
        NODE_DNSBL_COLOR="$COLOR_DANGER"
      else
        NODE_DNSBL_STATUS="Clean (0/${NODE_DNSBL_TOTAL})"
        NODE_DNSBL_COLOR="$COLOR_SUCCESS"
      fi
    else
      NODE_DNSBL_STATUS="N/A (dig required)"
      NODE_DNSBL_COLOR="$COLOR_NULL"
    fi
  else
    NODE_DNSBL_STATUS="N/A (IPv6 only)"
    NODE_DNSBL_COLOR="$COLOR_NULL"
  fi
}

# ------------------------------------------------------------------------------
# 0. System Hardware & Virtualization Specs (CPU Steal, RAM, Disk, Uptime)
# ------------------------------------------------------------------------------

get_disk_type() {
  local root_dev
  root_dev=$(df -P / 2>/dev/null | awk 'END {print $1}')

  if [[ -z "$root_dev" || "$root_dev" == "overlay" || "$root_dev" == "tmpfs" ]]; then
    if [[ "$root_dev" == "overlay" ]]; then
      echo "Container OverlayFS"
    elif [[ "$root_dev" == "tmpfs" ]]; then
      echo "RAM Disk (tmpfs)"
    else
      echo "Unknown"
    fi
    return 0
  fi

  local dev_name
  dev_name=$(basename "$root_dev")

  if [[ "$dev_name" =~ ^nvme ]]; then
    echo "NVMe SSD"
    return 0
  fi

  local parent_dev=""
  if is_command_available "lsblk"; then
    parent_dev=$(lsblk -no PKNAME "$root_dev" 2>/dev/null | head -n 1 | tr -d '[:space:]')
  fi
  if [[ -z "$parent_dev" ]]; then
    if [[ "$dev_name" =~ ^(sd[a-z]|vd[a-z]|xvd[a-z]) ]]; then
      parent_dev="${BASH_REMATCH[1]}"
    elif [[ "$dev_name" =~ ^(mmcblk[0-9]+) ]]; then
      parent_dev="${BASH_REMATCH[1]}"
    elif [[ "$dev_name" =~ ^nvme[0-9]+n[0-9]+ ]]; then
      parent_dev="${BASH_REMATCH[0]}"
    else
      parent_dev="$dev_name"
    fi
  fi

  if [[ "$parent_dev" =~ ^nvme ]]; then
    echo "NVMe SSD"
    return 0
  fi

  local is_rota=""
  if is_command_available "lsblk"; then
    is_rota=$(lsblk -dno ROTA "/dev/$parent_dev" 2>/dev/null | head -n 1 | tr -d '[:space:]')
  fi
  if [[ -z "$is_rota" && -r "/sys/block/$parent_dev/queue/rotational" ]]; then
    is_rota=$(cat "/sys/block/$parent_dev/queue/rotational" 2>/dev/null | tr -d '[:space:]')
  fi

  if [[ "$is_rota" == "0" ]]; then
    echo "SSD"
  elif [[ "$is_rota" == "1" ]]; then
    if [[ "$parent_dev" =~ ^(vd|xvd) ]]; then
      echo "Virtual Disk"
    else
      echo "HDD"
    fi
  elif [[ "$parent_dev" =~ ^(vd|xvd) ]]; then
    echo "Virtual Disk"
  else
    echo "Unknown"
  fi
}

measure_disk_io() {
  if [[ "$RUN_DISK_IO" != "true" ]]; then
    NODE_DISK_IO="Skipped (--no-io)"
    NODE_DISK_IO_NUM="null"
    NODE_DISK_IO_STATUS="skipped"
    NODE_DISK_IO_MSG="Skipped (--no-io)"
    NODE_DISK_IO_4K="N/A"
    NODE_DISK_IO_4K_NUM="null"
    return 0
  fi

  if ! is_command_available "dd" || ! is_command_available "df"; then
    NODE_DISK_IO="N/A (no dd/df)"
    NODE_DISK_IO_NUM="null"
    NODE_DISK_IO_STATUS="error"
    NODE_DISK_IO_MSG="Missing coreutils (dd/df)"
    NODE_DISK_IO_4K="N/A"
    NODE_DISK_IO_4K_NUM="null"
    return 0
  fi

  # Determine target directory on persistent storage (avoiding tmpfs/ramfs)
  local target_dir=""
  local candidates=( "${TMP_WORK_DIR:-}" "/var/tmp" "$PWD" )
  for candidate in "${candidates[@]}"; do
    [[ -z "$candidate" || ! -d "$candidate" || ! -w "$candidate" ]] && continue
    local fs_type=""
    if is_command_available "stat"; then
      fs_type=$(stat -f -c %T "$candidate" 2>/dev/null || true)
    fi
    if [[ -z "$fs_type" ]]; then
      fs_type=$(df -T "$candidate" 2>/dev/null | awk 'END {print $2}')
    fi
    # Reject in-memory RAM filesystems for disk benchmarking
    if [[ "$fs_type" =~ ^(tmpfs|ramfs)$ ]]; then
      continue
    fi
    target_dir="$candidate"
    break
  done

  if [[ -z "$target_dir" ]]; then
    NODE_DISK_IO="Skipped (RAM/tmpfs storage)"
    NODE_DISK_IO_NUM="null"
    NODE_DISK_IO_STATUS="skipped"
    NODE_DISK_IO_MSG="In-memory or non-writable filesystem (tmpfs)"
    NODE_DISK_IO_4K="N/A"
    NODE_DISK_IO_4K_NUM="null"
    return 0
  fi

  # 1. Protection: Check free space in MB (abort if < 2 GB free)
  local freespace_mb
  freespace_mb=$(df -m -P "$target_dir" 2>/dev/null | awk 'END {print $4}')
  if [[ -z "$freespace_mb" || ! "$freespace_mb" =~ ^[0-9]+$ ]] || (( freespace_mb < 2048 )); then
    NODE_DISK_IO="Skipped (< 2 GB free)"
    NODE_DISK_IO_NUM="null"
    NODE_DISK_IO_STATUS="skipped"
    NODE_DISK_IO_MSG="Less than 2 GB free space available"
    NODE_DISK_IO_4K="N/A"
    NODE_DISK_IO_4K_NUM="null"
    return 0
  fi

  # 2. Protection: Check disk usage percentage (abort if >= 90% full)
  local used_pct
  used_pct=$(df -P "$target_dir" 2>/dev/null | awk 'END {sub(/%/, "", $5); print $5}')
  if [[ -z "$used_pct" || ! "$used_pct" =~ ^[0-9]+$ ]] || (( used_pct >= 90 )); then
    NODE_DISK_IO="Skipped (> 90% full)"
    NODE_DISK_IO_NUM="null"
    NODE_DISK_IO_STATUS="skipped"
    NODE_DISK_IO_MSG="Filesystem usage is >= 90%"
    NODE_DISK_IO_4K="N/A"
    NODE_DISK_IO_4K_NUM="null"
    return 0
  fi

  # 3. Adaptive 1 GB sequential write test (bench.sh standard with 10s ceiling)
  local test_file="$target_dir/nodecheck_io_$$.tmp"
  CURRENT_DISK_TEST_FILE="$test_file"
  local dd_out dd_exit=0
  local t_start_ns t_end_ns elapsed_sec="10.0"

  t_start_ns=$(date +%s%N 2>/dev/null || true)
  if [[ -z "$t_start_ns" || "$t_start_ns" == *N* ]]; then
    t_start_ns=$(date +%s 2>/dev/null || echo "0")
  fi

  dd_out=$(timeout 10 dd if=/dev/zero of="$test_file" bs=1M count=1024 conv=fdatasync 2>&1) || dd_exit=$?

  t_end_ns=$(date +%s%N 2>/dev/null || true)
  if [[ -z "$t_end_ns" || "$t_end_ns" == *N* ]]; then
    t_end_ns=$(date +%s 2>/dev/null || echo "0")
    local el_s=$(( t_end_ns - t_start_ns ))
    (( el_s <= 0 )) && el_s=1
    elapsed_sec="$el_s.0"
  else
    elapsed_sec=$(awk -v s="$t_start_ns" -v e="$t_end_ns" 'BEGIN { el = (e - s) / 1000000000; if (el <= 0) el = 0.1; printf "%.2f", el }')
  fi

  local written_bytes=0
  if [[ -f "$test_file" ]]; then
    written_bytes=$(stat -c %s "$test_file" 2>/dev/null || wc -c < "$test_file" 2>/dev/null || echo "0")
  fi
  rm -f "$test_file" 2>/dev/null || true
  CURRENT_DISK_TEST_FILE=""

  if [[ $dd_exit -eq 0 ]]; then
    local speed_str=""
    speed_str=$(awk -F '[,，]' '/copied|скопирован/ {print $NF}' <<<"$dd_out" | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' | head -n 1)
    if [[ -z "$speed_str" ]]; then
      speed_str=$(grep -E '/s' <<<"$dd_out" | awk '{print $(NF-1)" "$NF}' | tail -n 1)
    fi

    if [[ -n "$speed_str" && "$speed_str" == *"/s" ]]; then
      local num_part="${speed_str%% *}"
      local unit_part="${speed_str#* }"
      local speed_mbs=""
      if [[ "$unit_part" == *"GB/s"* || "$unit_part" == *"GiB/s"* ]]; then
        speed_mbs=$(awk -v n="$num_part" 'BEGIN { printf "%.1f", n * 1024 }')
      elif [[ "$unit_part" == *"kB/s"* || "$unit_part" == *"KiB/s"* || "$unit_part" == *"KB/s"* ]]; then
        speed_mbs=$(awk -v n="$num_part" 'BEGIN { printf "%.2f", n / 1024 }')
      else
        speed_mbs=$(awk -v n="$num_part" 'BEGIN { printf "%.1f", n }')
      fi
      NODE_DISK_IO="$speed_str"
      NODE_DISK_IO_NUM="$speed_mbs"
      NODE_DISK_IO_STATUS="success"
      NODE_DISK_IO_MSG=""
    else
      local speed_mbs
      speed_mbs=$(awk -v t="$elapsed_sec" 'BEGIN { if (t > 0) printf "%.1f", 1024 / t; else print "0" }')
      local mb_int="${speed_mbs%%.*}"
      if (( mb_int >= 1000 )); then
        NODE_DISK_IO="$(awk -v m="$speed_mbs" 'BEGIN { printf "%.2f GB/s", m / 1024 }')"
      else
        NODE_DISK_IO="${speed_mbs} MB/s"
      fi
      NODE_DISK_IO_NUM="$speed_mbs"
      NODE_DISK_IO_STATUS="success"
      NODE_DISK_IO_MSG=""
    fi
  elif [[ $dd_exit -eq 124 ]]; then
    if (( written_bytes >= 10485760 )); then
      local speed_mbs written_mb
      written_mb=$(awk -v b="$written_bytes" 'BEGIN { printf "%.0f", b / (1024 * 1024) }')
      speed_mbs=$(awk -v b="$written_bytes" -v t="$elapsed_sec" 'BEGIN { if (t > 0) printf "%.1f", (b / (1024 * 1024)) / t; else print "0" }')
      local mb_int="${speed_mbs%%.*}"
      if (( mb_int >= 1000 )); then
        NODE_DISK_IO="$(awk -v m="$speed_mbs" 'BEGIN { printf "%.2f GB/s", m / 1024 }')"
      else
        NODE_DISK_IO="${speed_mbs} MB/s"
      fi
      NODE_DISK_IO_NUM="$speed_mbs"
      NODE_DISK_IO_STATUS="success"
      NODE_DISK_IO_MSG="Adaptive 10s ceiling (${written_mb} MB written)"
    else
      NODE_DISK_IO="Timeout (> 10s)"
      NODE_DISK_IO_NUM="null"
      NODE_DISK_IO_STATUS="timeout"
      NODE_DISK_IO_MSG="I/O write benchmark timed out after 10s"
      NODE_DISK_IO_4K="N/A"
      NODE_DISK_IO_4K_NUM="null"
      return 0
    fi
  else
    NODE_DISK_IO="Failed (I/O error)"
    NODE_DISK_IO_NUM="null"
    NODE_DISK_IO_STATUS="error"
    NODE_DISK_IO_MSG="dd write returned error code $dd_exit"
    NODE_DISK_IO_4K="N/A"
    NODE_DISK_IO_4K_NUM="null"
    return 0
  fi

  # 4. Optional 4K IOPS via fio (strictly if locally installed, no external downloads)
  NODE_DISK_IO_4K="N/A"
  NODE_DISK_IO_4K_NUM="null"
  if [[ "$NODE_DISK_IO_STATUS" == "success" ]] && is_command_available "fio"; then
    local fio_file="$target_dir/nodecheck_fio_$$.tmp"
    CURRENT_DISK_TEST_FILE="$fio_file"
    local fio_out="" fio_exit=0
    fio_out=$(timeout 6 fio --name=bench_4k --filename="$fio_file" --rw=randwrite --bs=4k --size=64M --numjobs=1 --direct=1 --runtime=2 --time_based=0 --output-format=json 2>/dev/null) || fio_exit=$?
    rm -f "$fio_file" 2>/dev/null || true
    CURRENT_DISK_TEST_FILE=""

    if [[ $fio_exit -eq 0 && -n "$fio_out" ]]; then
      local raw_iops=""
      raw_iops=$(jq -r '.jobs[0].write.iops // empty' 2>/dev/null <<<"$fio_out")
      if [[ -n "$raw_iops" && "$raw_iops" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        local iops_int="${raw_iops%%.*}"
        if (( iops_int >= 1000 )); then
          NODE_DISK_IO_4K=$(awk -v i="$iops_int" 'BEGIN { printf "%.0fk IOPS", i / 1000 }')
        else
          NODE_DISK_IO_4K="${iops_int} IOPS"
        fi
        NODE_DISK_IO_4K_NUM="$iops_int"
      fi
    fi
  fi
}

measure_crypto_bench() {
  if [[ "$RUN_CRYPTO_BENCH" != "true" ]]; then
    NODE_CRYPTO_SPEED="Skipped (--no-crypto)"
    NODE_CRYPTO_SPEED_MB_S="null"
    return 0
  fi

  if ! is_command_available "openssl"; then
    NODE_CRYPTO_SPEED="N/A (no openssl)"
    NODE_CRYPTO_SPEED_MB_S="null"
    return 0
  fi

  local bench_out="" bench_exit=0
  bench_out=$(timeout 3 openssl speed -mr -elapsed -seconds 1 -bytes 1024 -evp aes-128-gcm 2>/dev/null) || bench_exit=$?

  if [[ $bench_exit -ne 0 || -z "$bench_out" ]]; then
    bench_out=$(timeout 3 openssl speed -mr -elapsed -seconds 1 -evp aes-128-gcm 2>/dev/null) || bench_exit=$?
  fi

  local raw_bytes=""
  if [[ $bench_exit -eq 0 && -n "$bench_out" ]]; then
    raw_bytes=$(awk -F: 'tolower($3) ~ /^aes-128-gcm/ {print $NF}' <<<"$bench_out" | tail -n 1)
  fi

  if [[ -n "$raw_bytes" && "$raw_bytes" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    local mb_s
    mb_s=$(awk -v b="$raw_bytes" 'BEGIN { printf "%.1f", b / 1000000 }')
    NODE_CRYPTO_SPEED_MB_S="$mb_s"
    local mb_int="${mb_s%%.*}"
    mb_int="${mb_int:-0}"
    if (( mb_int >= 1000 )); then
      NODE_CRYPTO_SPEED="$(awk -v m="$mb_s" 'BEGIN { printf "%.2f GB/s", m / 1000 }')"
    else
      NODE_CRYPTO_SPEED="${mb_s} MB/s"
    fi
  else
    NODE_CRYPTO_SPEED="N/A"
    NODE_CRYPTO_SPEED_MB_S="null"
  fi
}

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

  # Hardware Crypto / AES-NI / ARM Crypto Detection
  local cpu_flags=""
  if [[ -r /proc/cpuinfo ]]; then
    cpu_flags=$(grep -m1 -E '^(flags|Features)[[:space:]]*:' /proc/cpuinfo 2>/dev/null || true)
  fi
  if [[ -z "$cpu_flags" ]] && is_command_available "lscpu"; then
    cpu_flags=$(lscpu 2>/dev/null | grep -iE 'Flags|Features' | head -n 1 || true)
  fi

  if grep -qw -E 'aes|pmull' <<<"$cpu_flags"; then
    NODE_AES_HARDWARE=true
    if grep -qw 'pmull' <<<"$cpu_flags"; then
      NODE_AES_TYPE="ARM Crypto"
    elif grep -qw 'vaes' <<<"$cpu_flags"; then
      NODE_AES_TYPE="VAES"
    else
      NODE_AES_TYPE="AES-NI"
    fi
    NODE_AES_STATUS="$NODE_AES_TYPE"
    NODE_AES_COLOR="$COLOR_SUCCESS"
  else
    NODE_AES_HARDWARE=false
    NODE_AES_TYPE="none"
    NODE_AES_STATUS="Disabled (Soft)"
    NODE_AES_COLOR="$COLOR_DANGER"
  fi

  measure_crypto_bench

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
  local os_name="Linux"
  if [[ -f /etc/os-release ]]; then
    os_name=$(awk -F= '$1=="PRETTY_NAME" {gsub(/^["'\''"]+|["'\''"]+$/, "", $2); print $2}' /etc/os-release 2>/dev/null)
    os_name="${os_name:-Linux}"
  fi
  NODE_OS="${os_name} ($(uname -r) $(uname -m))"

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
  NODE_DISK_TYPE=$(get_disk_type)
  measure_disk_io

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

  [[ -z "$ip_val" ]] && return 0

  case "$db_name" in
    "IPinfo.io")
      local raw
      raw=$(curl_wrapper GET "https://ipinfo.io/${ip_val}/json" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw" 2>/dev/null)
      ;;
    "IP-API.com")
      local raw
      raw=$(curl_wrapper GET "http://ip-api.com/json/${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.countryCode // empty' <<<"$raw" 2>/dev/null)
      ;;
    "Cloudflare")
      local raw
      raw=$(curl_wrapper GET "https://cloudflare.com/cdn-cgi/trace" --ip-version "$ip_ver" --timeout 5 2>/dev/null)
      cc=$(grep "^loc=" <<<"$raw" 2>/dev/null | head -n1 | cut -d= -f2 | tr -d '[:space:]')
      ;;
    "IP.SB")
      local raw
      raw=$(curl_wrapper GET "https://api.ip.sb/geoip/${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw" 2>/dev/null)
      ;;
    "Ipregistry")
      local raw
      raw=$(curl_wrapper GET "https://api.ipregistry.co/${ip_val}?key=tryout" --header "Origin: https://ipregistry.co" --timeout 5 2>/dev/null)
      cc=$(jq -r '.location.country.code // empty' <<<"$raw" 2>/dev/null)
      ;;
    "IP-API.co")
      local raw
      raw=$(curl_wrapper GET "https://ipapi.co/${ip_val}/json/" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw" 2>/dev/null)
      ;;
    "IP2Location.io")
      local raw
      raw=$(curl_wrapper GET "https://api.ip2location.io/?ip=${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw" 2>/dev/null)
      ;;
    "Country.is")
      local raw
      raw=$(curl_wrapper GET "https://api.country.is/${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw" 2>/dev/null)
      ;;
    "GeoJS")
      local raw
      raw=$(curl_wrapper GET "https://get.geojs.io/v1/ip/country/${ip_val}.json" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw" 2>/dev/null)
      ;;
    "2ip.io")
      local raw
      raw=$(curl_wrapper GET "https://api.2ip.io/${ip_val}" --timeout 5 2>/dev/null)
      if [[ -n "$raw" && "$raw" =~ ^\{ ]]; then
        cc=$(jq -r '.code // empty' <<<"$raw" 2>/dev/null)
      fi
      ;;
    "ipwho.is")
      local raw
      raw=$(curl_wrapper GET "https://ipwho.is/${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw" 2>/dev/null)
      ;;
    "ifconfig.co")
      cc=$(curl_wrapper GET "https://ifconfig.co/country-iso?ip=${ip_val}" --timeout 5 2>/dev/null | tr -d '[:space:]')
      ;;
    "IPLocation.net")
      local raw
      raw=$(curl_wrapper GET "https://api.iplocation.net/?ip=${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country_code2 // empty' <<<"$raw" 2>/dev/null)
      ;;
    "ipbase.com")
      local raw
      raw=$(curl_wrapper GET "https://api.ipbase.com/v1/json/?ip=${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country_code // empty' <<<"$raw" 2>/dev/null)
      ;;
    "ipquery.io")
      local raw
      raw=$(curl_wrapper GET "https://api.ipquery.io/${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.location.country_code // empty' <<<"$raw" 2>/dev/null)
      ;;
    "IPAPI.is")
      local raw
      raw=$(curl_wrapper GET "https://api.ipapi.is/?q=${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country_code // .country // empty' <<<"$raw" 2>/dev/null)
      ;;
    "RIPE NCC")
      local raw
      raw=$(curl_wrapper GET "https://rdap.db.ripe.net/ip/${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.country // empty' <<<"$raw" 2>/dev/null)
      if [[ -z "$cc" && -n "$raw" ]]; then
        cc=$(jq -r '[.. | objects | .adr? | .label? | strings | split("\n")[] | select(length > 0)][-1] // empty' <<<"$raw" 2>/dev/null)
      fi
      if [[ -z "$cc" ]]; then
        raw=$(curl_wrapper GET "https://rdap.arin.net/registry/ip/${ip_val}" --timeout 5 2>/dev/null)
        cc=$(jq -r '.country // empty' <<<"$raw" 2>/dev/null)
        if [[ -z "$cc" && -n "$raw" ]]; then
          cc=$(jq -r '[.. | objects | .adr? | .label? | strings | split("\n")[] | select(length > 0)][-1] // empty' <<<"$raw" 2>/dev/null)
        fi
      fi
      if [[ -z "$cc" ]]; then
        raw=$(curl_wrapper GET "https://rdap.apnic.net/ip/${ip_val}" --timeout 5 2>/dev/null)
        cc=$(jq -r '.country // empty' <<<"$raw" 2>/dev/null)
        if [[ -z "$cc" && -n "$raw" ]]; then
          cc=$(jq -r '[.. | objects | .adr? | .label? | strings | split("\n")[] | select(length > 0)][-1] // empty' <<<"$raw" 2>/dev/null)
        fi
      fi
      ;;
    "IP.Guide")
      local raw
      raw=$(curl_wrapper GET "https://ip.guide/${ip_val}" --timeout 5 2>/dev/null)
      cc=$(jq -r '.location.country // .network.autonomous_system.country // empty' <<<"$raw" 2>/dev/null)
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
  local max_jobs=16
  local db

  # Launch parallel background queries in batches of max_jobs (network I/O bound)
  for db in "${geoip_dbs[@]}"; do
    if [[ $IPV4_SUPPORTED -eq 1 ]]; then
      query_single_geoip "$db" "4" "$v4_dir/$db" &
      running=$((running + 1))
      if (( running >= max_jobs )); then
        wait -n 2>/dev/null || true
        running=$((running - 1))
      fi
    fi
    if [[ $IPV6_SUPPORTED -eq 1 ]]; then
      query_single_geoip "$db" "6" "$v6_dir/$db" &
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

format_unblock_status() {
  local code="$1"
  if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then
    echo "Yes"
  elif [[ "$code" == "000" ]]; then
    echo "No (DPI Drop / Timeout)"
  elif [[ "$code" == "403" ]]; then
    echo "No (WAF / Geo-403)"
  elif [[ "$code" == "451" ]]; then
    echo "No (RKN Blockpage / 451)"
  elif [[ "$code" == "429" ]]; then
    echo "No (Captcha / Rate Limit)"
  else
    echo "No ($code)"
  fi
}

lookup_instagram() {
  local code
  code=$(curl_http_code "https://www.instagram.com")
  format_unblock_status "$code"
}

lookup_discord() {
  local resp
  resp=$(curl_wrapper GET "https://discord.com/api/v9/gateway" --timeout 3 2>/dev/null)
  if [[ "$resp" == *"gateway.discord"* ]]; then echo "Yes"; else echo "No"; fi
}

lookup_twitter_x() {
  local code
  code=$(curl_http_code "https://x.com")
  format_unblock_status "$code"
}

lookup_rutracker() {
  local code
  code=$(curl_http_code "https://rutracker.org")
  format_unblock_status "$code"
}

lookup_amnezia() {
  local code
  code=$(curl_http_code "https://amnezia.org")
  format_unblock_status "$code"
}

lookup_chatgpt() {
  local ip_ver_arg=()
  if [[ "$IPV6_ONLY" == "true" || ( -z "$EXTERNAL_IPV4" && "$IPV4_SUPPORTED" -eq 0 ) ]]; then
    ip_ver_arg=(--ip-version "6")
  elif [[ "$IPV4_ONLY" == "true" ]]; then
    ip_ver_arg=(--ip-version "4")
  fi

  local cc
  cc=$(curl_wrapper POST "https://ab.chatgpt.com/v1/initialize" "${ip_ver_arg[@]}" --timeout 5 \
    --header "Statsig-Api-Key: $CHATGPT_STATSIG_API_KEY" --header "Content-Type: application/json" --data '{}' 2>/dev/null | \
    ( jq -r '.derived_fields.country // empty' 2>/dev/null || grep -oE '"country":"[A-Z]{2}"' | head -n 1 | cut -d'"' -f4 ) )
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
    format_unblock_status "$code"
  fi
}

lookup_claude() {
  local code
  code=$(curl_http_code "https://claude.ai")
  format_unblock_status "$code"
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
    format_unblock_status "$code"
    return
  fi

  local raw code resp
  raw=$(curl_wrapper GET "$GEMINI_REGIONS_URL" --timeout 4 -w "\nHTTP_STATUS:%{http_code}" 2>/dev/null)
  code=$(tail -n 2 <<<"$raw" | grep -oE 'HTTP_STATUS:[0-9]{3}' | tail -n 1 | cut -d: -f2)
  code="${code:-000}"
  resp=$(sed -e '/HTTP_STATUS:[0-9]\{3\}$/d' <<<"$raw" | tr -d '\r')

  if [[ "$code" != "200" || -z "$resp" ]]; then
    local direct_code
    direct_code=$(curl_http_code "https://gemini.google.com")
    if [[ "$direct_code" =~ ^(200|301|302)$ ]]; then
      echo "Yes ($g_cc)"
    else
      format_unblock_status "$direct_code"
    fi
    return
  fi

  local country_name="${COUNTRY_NAMES[$g_cc]:-}"
  case "$g_cc" in
    TR) country_name="Türkiye" ;;
    CY) country_name="Republic of Cyprus" ;;
    BS) country_name="The Bahamas" ;;
    GM) country_name="The Gambia" ;;
    BN) country_name="Brunei" ;;
    CD) country_name="Democratic Republic of the Congo" ;;
    CG) country_name="Republic of the Congo" ;;
    KR) country_name="South Korea" ;;
    LA) country_name="Laos" ;;
    FM) country_name="Micronesia" ;;
    PN) country_name="Pitcairn Islands" ;;
    ST) country_name="São Tomé and Príncipe" ;;
    VN) country_name="Vietnam" ;;
  esac

  case "$country_name" in
    "Turkey") country_name="Türkiye" ;;
    "Cyprus") country_name="Republic of Cyprus" ;;
    "Bahamas") country_name="The Bahamas" ;;
    "Gambia") country_name="The Gambia" ;;
    "Brunei Darussalam") country_name="Brunei" ;;
    "Congo (Democratic Republic of the)") country_name="Democratic Republic of the Congo" ;;
    "Congo") country_name="Republic of the Congo" ;;
    "Korea (Republic of)") country_name="South Korea" ;;
    "Lao People's Democratic Republic") country_name="Laos" ;;
    "Micronesia (Federated States of)") country_name="Micronesia" ;;
    "Pitcairn") country_name="Pitcairn Islands" ;;
    "Sao Tome and Principe") country_name="São Tomé and Príncipe" ;;
    "Viet Nam") country_name="Vietnam" ;;
  esac

  if [[ -n "$country_name" ]] && grep -qi "^[*-] *${country_name}$" <<<"$resp"; then
    echo "Yes ($g_cc)"
  else
    echo "No ($g_cc - Region blocked)"
  fi
}

lookup_youtube() {
  local code resp cc=""
  code=$(curl_http_code "https://www.youtube.com")
  if [[ ! "$code" =~ ^(200|301|302)$ ]]; then
    format_unblock_status "$code"
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
      echo "${cc} [Без рекламы]"
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
  resp=$(sed -e '/HTTP_STATUS:[0-9]\{3\}$/d' <<<"$raw")
  if [[ -z "$resp" ]]; then
    echo "No (Empty)"
  elif grep -qi -E "YouTube Premium is( not|n't) available in your (country|area)" <<<"$resp"; then
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
  resp=$(sed -e '/HTTP_STATUS:[0-9]\{3\}$/d' <<<"$raw")
  if [[ -z "$resp" ]]; then
    echo "No (Empty)"
  elif grep -qi -E "YouTube Music is( not|n't) available in your (area|country)" <<<"$resp"; then
    echo "No"
  else
    echo "Yes"
  fi
}

lookup_spotify_signup() {
  local resp
  resp=$(curl_wrapper GET "https://spclient.wg.spotify.com/signup/public/v1/account/?validate=1&key=142b583129b2df829de3656f9eb484e6" \
    --header "User-Agent: Spotify/8.8.0 Android/33" \
    --header "X-Client-Id: 9a8d2f0ce77a4e248bb71fefcb557637" \
    --timeout 4 2>/dev/null)
  if jq -e '.status == 1 and .is_country_launched == true' >/dev/null 2>&1 <<<"$resp"; then
    local cc
    cc=$(jq -r '.country // empty' <<<"$resp" 2>/dev/null)
    if [[ -n "$cc" ]]; then
      echo "Yes ($cc)"
    else
      echo "Yes"
    fi
  else
    echo "No"
  fi
}

lookup_netflix() {
  local raw1 code1 cc="" url1
  raw1=$(curl_wrapper GET "https://www.netflix.com/title/81280792" \
    --timeout 4 \
    --header "Accept-Language: en-US,en;q=0.9" \
    -w "\nHTTP_STATUS:%{http_code}\nEFFECTIVE_URL:%{url_effective}" 2>/dev/null)
  code1=$(tail -n 3 <<<"$raw1" | grep -oE 'HTTP_STATUS:[0-9]{3}' | tail -n 1 | cut -d: -f2)
  code1="${code1:-000}"
  url1=$(tail -n 3 <<<"$raw1" | grep -oE 'EFFECTIVE_URL:[^\r\n]+' | tail -n 1 | cut -d: -f2-)

  if [[ "$code1" =~ ^(403|000)$ ]] || [[ "$url1" == *"80018499"* ]] || grep -qi -E "Oh no!|unblocker or proxy|title/80018499" <<<"$raw1"; then
    echo "No"
    return
  fi
  if [[ ! "$code1" =~ ^(200|301|302|307|308)$ ]]; then
    echo "No ($code1)"
    return
  fi

  if [[ "$url1" =~ netflix\.com/([a-z]{2})(-[a-z]{2})?/title/ ]]; then
    cc="${BASH_REMATCH[1]^^}"
  fi
  if [[ -z "$cc" ]]; then
    cc=$(sed -n 's/.*"geolocation_country":"\([^"]*\)".*/\1/p' <<<"$raw1" | head -n 1)
  fi

  local raw2 code2 url2
  raw2=$(curl_wrapper GET "https://www.netflix.com/title/70143836" \
    --timeout 4 \
    --header "Accept-Language: en-US,en;q=0.9" \
    -w "\nHTTP_STATUS:%{http_code}\nEFFECTIVE_URL:%{url_effective}" 2>/dev/null)
  code2=$(tail -n 3 <<<"$raw2" | grep -oE 'HTTP_STATUS:[0-9]{3}' | tail -n 1 | cut -d: -f2)
  code2="${code2:-000}"
  url2=$(tail -n 3 <<<"$raw2" | grep -oE 'EFFECTIVE_URL:[^\r\n]+' | tail -n 1 | cut -d: -f2-)

  if [[ "$code2" =~ ^(200|301|302|307|308)$ ]] && [[ "$url2" != *"80018499"* ]] && ! grep -qi -E "Oh no!|unblocker or proxy|title/80018499" <<<"$raw2"; then
    if [[ -n "$cc" ]]; then
      echo "Yes ($cc)"
    else
      echo "Yes"
    fi
  else
    if [[ -n "$cc" ]]; then
      echo "Yes ($cc - Originals)"
    else
      echo "Yes (Originals Only)"
    fi
  fi
}

lookup_apple() {
  local cc
  cc=$(curl_wrapper GET "https://gspe1-ssl.ls.apple.com/pep/gcc" --timeout 3 2>/dev/null | tr -d '[:space:]')
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  elif [[ -n "$cc" ]]; then
    echo "Yes"
  else
    echo "No (Timeout)"
  fi
}

lookup_steam() {
  local raw cc code
  raw=$(curl_wrapper GET "https://store.steampowered.com" --timeout 4 -c - 2>/dev/null)
  cc=$(grep -oE 'steamCountry=[A-Za-z0-9%]+' <<<"$raw" 2>/dev/null | head -n1 | cut -d= -f2 | cut -d% -f1)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    code=$(curl_http_code "https://store.steampowered.com")
    format_unblock_status "$code"
  fi
}

lookup_playstation() {
  local raw cc code
  raw=$(curl_wrapper GET "https://www.playstation.com" --timeout 4 -c - 2>/dev/null)
  cc=$(grep -oE 'country=[A-Za-z]{2}' <<<"$raw" 2>/dev/null | head -n1 | cut -d= -f2)
  if [[ -z "$cc" ]]; then
    cc=$(sed -n -E 's|.*playstation\.com/([a-z]{2})-[a-z]{2}/.*|\1|p' <<<"$raw" 2>/dev/null | head -n1)
  fi
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    code=$(curl_http_code "https://www.playstation.com")
    format_unblock_status "$code"
  fi
}

lookup_reddit() {
  local raw cc
  raw=$(curl_wrapper GET "https://www.reddit.com/api/v1/not-found" --timeout 4 2>/dev/null)
  cc=$(grep -oE 'country code: [A-Z]{2}' <<<"$raw" 2>/dev/null | awk '{print $3}')
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    echo "N/A"
  fi
}

lookup_reddit_guest() {
  local code
  code=$(curl_http_code "https://www.reddit.com")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "Yes"
  elif [[ "$code" == "403" ]]; then
    echo "Block (403)"
  else
    format_unblock_status "$code"
  fi
}

lookup_google_search_captcha() {
  local raw
  raw=$(curl_wrapper GET "https://www.google.com/search?q=test" --timeout 3 2>/dev/null)
  if [[ "$raw" == *"/sorry/"* || "$raw" == *"recaptcha"* || "$raw" == *"unusual traffic"* ]]; then
    echo "Triggered (Captcha)"
  elif [[ -n "$raw" ]]; then
    echo "No"
  else
    echo "No (Timeout)"
  fi
}

lookup_tiktok() {
  local raw cc
  raw=$(curl_wrapper GET "https://www.tiktok.com/api/v1/web-cookie-privacy/config?appId=1988" --timeout 4 2>/dev/null)
  cc=$(jq -r '.body.appProps.region // empty' <<<"$raw" 2>/dev/null)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    local code
    code=$(curl_http_code "https://www.tiktok.com")
    format_unblock_status "$code"
  fi
}

lookup_disney_plus() {
  local raw cc
  raw=$(curl_wrapper POST "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" \
    --header "Authorization: Bearer ZGlzbmV5JmFuZHJvaWQmMS4wLjA.bkeb0m230uUhv8qrAXuNu39tbE_mD5EEhM_NAcohjyA" \
    --header "Content-Type: application/json" \
    --data '{"query":"mutation registerDevice($registerDevice: RegisterDeviceInput!) { registerDevice(registerDevice: $registerDevice) { __typename } }","variables":{"registerDevice":{"applicationRuntime":"android","attributes":{"operatingSystem":"Android","operatingSystemVersion":"13"},"deviceFamily":"android","deviceLanguage":"en","deviceProfile":"phone","devicePlatformId":"android"}},"operationName":"registerDevice"}' \
    --timeout 4 2>/dev/null)
  cc=$(jq -r '.extensions.sdk.session.location.countryCode // empty' <<<"$raw" 2>/dev/null)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  elif grep -qi "Forbidden location" <<<"$raw" 2>/dev/null; then
    echo "Block"
  else
    local code
    code=$(curl_http_code "https://www.disneyplus.com")
    format_unblock_status "$code"
  fi
}

lookup_deezer() {
  local raw cc
  raw=$(curl_wrapper GET "https://api.deezer.com/infos" --timeout 4 2>/dev/null)
  cc=$(jq -r '.country_iso // empty' <<<"$raw" 2>/dev/null)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    local code
    code=$(curl_http_code "https://www.deezer.com")
    format_unblock_status "$code"
  fi
}

lookup_twitch() {
  local raw cc
  raw=$(curl_wrapper POST "https://gql.twitch.tv/gql" \
    --header "Client-Id: kimne78kx3ncx6brgo4mv6wki5h1ko" \
    --header "Content-Type: application/json" \
    --data '[{"operationName":"VerifyEmail_CurrentUser","variables":{},"extensions":{"persistedQuery":{"version":1,"sha256Hash":"f9e7dcdf7e99c314c82d8f7f725fab5f99d1df3d7359b53c9ae122deec590198"}}}]' \
    --timeout 4 2>/dev/null)
  cc=$(jq -r '.[0].data.requestInfo.countryCode // empty' <<<"$raw" 2>/dev/null)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    local code
    code=$(curl_http_code "https://www.twitch.tv")
    format_unblock_status "$code"
  fi
}

lookup_jetbrains() {
  local raw cc
  raw=$(curl_wrapper GET "https://data.services.jetbrains.com/geo" --timeout 4 2>/dev/null)
  cc=$(jq -r '.code // empty' <<<"$raw" 2>/dev/null)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    local code
    code=$(curl_http_code "https://www.jetbrains.com")
    format_unblock_status "$code"
  fi
}

lookup_ookla_speedtest() {
  local raw cc
  raw=$(curl_wrapper GET "https://www.speedtest.net/api/js/config-sdk" --timeout 4 2>/dev/null)
  cc=$(jq -r '.location.countryCode // empty' <<<"$raw" 2>/dev/null)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    local code
    code=$(curl_http_code "https://www.speedtest.net")
    format_unblock_status "$code"
  fi
}

lookup_microsoft() {
  local raw cc
  raw=$(curl_wrapper GET "https://login.live.com" --timeout 4 2>/dev/null)
  cc=$(grep -oE '"sRequestCountry":"[A-Za-z]{2}"' <<<"$raw" 2>/dev/null | head -n1 | cut -d'"' -f4)
  if [[ "$cc" =~ ^[A-Za-z]{2}$ ]]; then
    echo "${cc^^}"
  else
    local code
    code=$(curl_http_code "https://www.bing.com")
    format_unblock_status "$code"
  fi
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

run_ru_local_services_check() {
  local s_dir="$TMP_WORK_DIR/services_ru"
  mkdir -p "$s_dir" 2>/dev/null || true

  local check_pairs=(
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

  local i=0
  while (( i < ${#check_pairs[@]} )); do
    local fn="${check_pairs[i]}"
    local out="${check_pairs[i+1]}"
    "$fn" > "$out" &
    ((i += 2))
  done
  wait

  ARR_RU_LOCAL=(
    "Госуслуги (gosuslugi.ru)"$'\t'"$(read_val "$s_dir/gosuslugi" "Blocked")"
    "ФНС (nalog.gov.ru)"$'\t'"$(read_val "$s_dir/nalog" "Blocked")"
    "Мос.ру (mos.ru)"$'\t'"$(read_val "$s_dir/mosru" "Blocked")"
    "РЖД (ticket.rzd.ru)"$'\t'"$(read_val "$s_dir/rzd" "Blocked")"
    "Яндекс (ya.ru)"$'\t'"$(read_val "$s_dir/yandex" "Blocked")"
    "ВКонтакте (vk.com)"$'\t'"$(read_val "$s_dir/vk" "Blocked")"
    "СберБанк (sberbank.ru)"$'\t'"$(read_val "$s_dir/sberbank" "Blocked")"
    "Т-Банк (tbank.ru)"$'\t'"$(read_val "$s_dir/tbank" "Blocked")"
    "ВТБ (vtb.ru)"$'\t'"$(read_val "$s_dir/vtb" "Blocked")"
    "Альфа-Банк (alfabank.ru)"$'\t'"$(read_val "$s_dir/alfabank" "Blocked")"
    "Авито (avito.ru)"$'\t'"$(read_val "$s_dir/avito" "Blocked")"
    "Wildberries (wildberries.ru)"$'\t'"$(read_val "$s_dir/wildberries" "Blocked")"
    "Озон (ozon.ru)"$'\t'"$(read_val "$s_dir/ozon" "Blocked")"
    "Кинопоиск (kinopoisk.ru)"$'\t'"$(read_val "$s_dir/kinopoisk" "Blocked")"
  )
}

run_western_services_check() {
  local s_dir="$TMP_WORK_DIR/services_western"
  mkdir -p "$s_dir" 2>/dev/null || true

  local check_pairs=(
    "lookup_google" "$s_dir/google"
    "lookup_google_search_captcha" "$s_dir/google_captcha"
    "lookup_youtube" "$s_dir/youtube"
    "lookup_youtube_cdn" "$s_dir/youtube_cdn"
    "lookup_youtube_premium" "$s_dir/youtube_premium"
    "lookup_youtube_music" "$s_dir/youtube_music"
    "lookup_twitch" "$s_dir/twitch"
    "lookup_chatgpt" "$s_dir/chatgpt"
    "lookup_claude" "$s_dir/claude"
    "lookup_gemini" "$s_dir/gemini"
    "lookup_netflix" "$s_dir/netflix"
    "lookup_spotify_signup" "$s_dir/spotify"
    "lookup_deezer" "$s_dir/deezer"
    "lookup_reddit" "$s_dir/reddit"
    "lookup_reddit_guest" "$s_dir/reddit_guest"
    "lookup_disney_plus" "$s_dir/disney_plus"
    "lookup_tiktok" "$s_dir/tiktok"
    "lookup_apple" "$s_dir/apple"
    "lookup_steam" "$s_dir/steam"
    "lookup_playstation" "$s_dir/playstation"
    "lookup_ookla_speedtest" "$s_dir/ookla"
    "lookup_jetbrains" "$s_dir/jetbrains"
    "lookup_microsoft" "$s_dir/microsoft"
    "lookup_instagram" "$s_dir/instagram"
    "lookup_discord" "$s_dir/discord"
    "lookup_twitter_x" "$s_dir/twitter"
    "lookup_rutracker" "$s_dir/rutracker"
    "lookup_amnezia" "$s_dir/amnezia"
  )

  local i=0 running=0
  local max_jobs=16
  while (( i < ${#check_pairs[@]} )); do
    local fn="${check_pairs[i]}"
    local out="${check_pairs[i+1]}"
    "$fn" > "$out" &
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

  ARR_RU_UNBLOCK=(
    "Google"$'\t'"$(read_val "$s_dir/google" "N/A")"
    "Google Search Captcha"$'\t'"$(read_val "$s_dir/google_captcha" "No")"
    "YouTube"$'\t'"$yt_res"
    "YouTube CDN"$'\t'"$(read_val "$s_dir/youtube_cdn" "No")"
    "YouTube Premium"$'\t'"$(read_val "$s_dir/youtube_premium" "No")"
    "YouTube Music"$'\t'"$(read_val "$s_dir/youtube_music" "No")"
    "Twitch"$'\t'"$(read_val "$s_dir/twitch" "No")"
    "OpenAI ChatGPT"$'\t'"$(read_val "$s_dir/chatgpt" "No")"
    "Claude AI (Anthropic)"$'\t'"$(read_val "$s_dir/claude" "No")"
    "Google Gemini"$'\t'"$(read_val "$s_dir/gemini" "No")"
    "Netflix"$'\t'"$(read_val "$s_dir/netflix" "No")"
    "Spotify Signup"$'\t'"$(read_val "$s_dir/spotify" "No")"
    "Deezer"$'\t'"$(read_val "$s_dir/deezer" "No")"
    "Reddit"$'\t'"$(read_val "$s_dir/reddit" "N/A")"
    "Reddit (Guest Access)"$'\t'"$(read_val "$s_dir/reddit_guest" "No")"
    "Disney+"$'\t'"$(read_val "$s_dir/disney_plus" "No")"
    "TikTok"$'\t'"$(read_val "$s_dir/tiktok" "No")"
    "Apple Services"$'\t'"$(read_val "$s_dir/apple" "No")"
    "Steam Store (Игры)"$'\t'"$(read_val "$s_dir/steam" "No")"
    "PlayStation Network"$'\t'"$(read_val "$s_dir/playstation" "No")"
    "Ookla Speedtest"$'\t'"$(read_val "$s_dir/ookla" "No")"
    "JetBrains"$'\t'"$(read_val "$s_dir/jetbrains" "No")"
    "Microsoft (Bing)"$'\t'"$(read_val "$s_dir/microsoft" "No")"
    "Instagram (Meta)"$'\t'"$(read_val "$s_dir/instagram" "No")"
    "Discord (Voice/Gateway)"$'\t'"$(read_val "$s_dir/discord" "No")"
    "Twitter / X"$'\t'"$(read_val "$s_dir/twitter" "No")"
    "Rutracker"$'\t'"$(read_val "$s_dir/rutracker" "No")"
    "Amnezia VPN (amnezia.org)"$'\t'"$(read_val "$s_dir/amnezia" "No")"
  )
}

run_services_check() {
  run_ru_local_services_check
  run_western_services_check
}

# ------------------------------------------------------------------------------
# 4. Multi-Region RU Connectivity & Speed
# ------------------------------------------------------------------------------

resolve_target_ip() {
  local target_host="$1"
  [[ -z "$target_host" ]] && return 0
  if [[ "$target_host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$target_host" =~ : ]]; then
    echo "$target_host"
    return 0
  fi
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
  elif ! is_command_available "getent"; then
    echo "$target_host"
  fi
}

ping_host() {
  local host="$1" out_file="$2"
  local target_ip
  target_ip=$(resolve_target_ip "$host")
  if [[ -z "$target_ip" ]]; then
    printf "N/A" > "$out_file"
    return 0
  fi
  local ping_flags=()
  if [[ "$IPV4_ONLY" == "true" ]] || [[ "$IPV6_SUPPORTED" -eq 0 ]]; then
    ping_flags+=(-4)
  elif [[ "$IPV6_ONLY" == "true" ]] || [[ "$IPV4_SUPPORTED" -eq 0 && "$IPV6_SUPPORTED" -eq 1 ]]; then
    ping_flags+=(-6)
  fi
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
  local format_mode="${9:-TABLE}"
  local line

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
      if [[ "$format_mode" == "OOKLA" ]]; then
        if [[ "$mode" == "DL" ]]; then
          if [[ -n "$COLOR_TABLE_VALUE" ]]; then
            printf "\r\033[2K  • Загрузка (Down):  \033[%sm↓ ...\033[0m\r" "$COLOR_TABLE_VALUE"
          else
            printf "\r\033[2K  • Загрузка (Down):  ↓ ...\r"
          fi
        else
          if [[ -n "$COLOR_TABLE_VALUE" ]]; then
            printf "\r\033[2K  • Отдача (Up):      \033[%sm↑ ...\033[0m\r" "$COLOR_TABLE_VALUE"
          else
            printf "\r\033[2K  • Отдача (Up):      ↑ ...\r"
          fi
        fi
      else
        if [[ "$mode" == "DL" ]]; then
          if [[ -n "$COLOR_TABLE_VALUE" ]]; then
            printf "\r\033[2K  %s  %s  \033[%sm↓ ...\033[0m\r" \
              "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE"
          else
            printf "\r\033[2K  %s  %s  ↓ ...\r" \
              "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)"
          fi
        else
          local dl_comp dl_bar
          dl_comp=$(compact_mbps "$dl_speed_for_ul" 0)
          dl_bar=$(render_speed_bar "$dl_speed_for_ul" 1000 6)
          if [[ -n "$dl_bar" ]]; then
            if [[ -n "$COLOR_TABLE_VALUE" ]]; then
              printf "\r\033[2K  %s  %s  ↓ %s \033[%sm%s\033[0m / ↑ ...\r" \
                "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_bar" "$COLOR_TABLE_VALUE" "$dl_comp"
            else
              printf "\r\033[2K  %s  %s  ↓ %s %s / ↑ ...\r" \
                "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_bar" "$dl_comp"
            fi
          else
            if [[ -n "$COLOR_TABLE_VALUE" ]]; then
              printf "\r\033[2K  %s  %s  ↓ \033[%sm%s\033[0m / ↑ ...\r" \
                "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE" "$dl_comp"
            else
              printf "\r\033[2K  %s  %s  ↓ %s / ↑ ...\r" \
                "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_comp"
            fi
          fi
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

    while [[ -n "$iperf_pid" && "$iperf_pid" -gt 1 ]] && kill -0 "$iperf_pid" 2>/dev/null; do
      # 1. Non-blocking keypress check (<Enter>, Space, 's')
      if [[ "$JSON_OUTPUT" != "true" && -t 1 && -r /dev/tty ]]; then
        local user_key=""
        if read -t 0.15 -n 1 user_key < /dev/tty 2>/dev/null; then
          if [[ -z "$user_key" || "$user_key" == $'\n' || "$user_key" == $'\r' || "$user_key" == " " || "$user_key" == "s" || "$user_key" == "S" ]]; then
            IPERF_SKIPPED=true
            if [[ -n "$iperf_pid" && "$iperf_pid" -gt 1 ]]; then
              { kill -TERM "$iperf_pid" 2>/dev/null; sleep 0.05; kill -KILL "$iperf_pid" 2>/dev/null; wait "$iperf_pid" 2>/dev/null; } 2>/dev/null || true
            fi
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
                  local live_disp
                  live_disp=$(compact_mbps "$mbps" 0)
                  if [[ "$format_mode" == "OOKLA" ]]; then
                    local live_bar
                    live_bar=$(render_speed_bar "$mbps" 1000 6)
                    if [[ "$mode" == "DL" ]]; then
                      if [[ -n "$COLOR_TABLE_VALUE" ]]; then
                        printf "\r\033[2K  • Загрузка (Down):  \033[%sm↓ %s %s\033[0m\r" "$COLOR_TABLE_VALUE" "$live_bar" "$live_disp"
                      else
                        printf "\r\033[2K  • Загрузка (Down):  ↓ %s %s\r" "$live_bar" "$live_disp"
                      fi
                    else
                      if [[ -n "$COLOR_TABLE_VALUE" ]]; then
                        printf "\r\033[2K  • Отдача (Up):      \033[%sm↑ %s %s\033[0m\r" "$COLOR_TABLE_VALUE" "$live_bar" "$live_disp"
                      else
                        printf "\r\033[2K  • Отдача (Up):      ↑ %s %s\r" "$live_bar" "$live_disp"
                      fi
                    fi
                  else
                    if [[ "$mode" == "DL" ]]; then
                      local live_bar
                      live_bar=$(render_speed_bar "$mbps" 1000 6)
                      if [[ -n "$COLOR_TABLE_VALUE" ]]; then
                        printf "\r\033[2K  %s  %s  ↓ %s \033[%sm%s\033[0m\r" \
                          "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$live_bar" "$COLOR_TABLE_VALUE" "$live_disp"
                      else
                        printf "\r\033[2K  %s  %s  ↓ %s %s\r" \
                          "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$live_bar" "$live_disp"
                      fi
                    else
                      local dl_comp dl_bar
                      dl_comp=$(compact_mbps "$dl_speed_for_ul" 0)
                      dl_bar=$(render_speed_bar "$dl_speed_for_ul" 1000 6)
                      if [[ -n "$dl_bar" ]]; then
                        if [[ -n "$COLOR_TABLE_VALUE" ]]; then
                          printf "\r\033[2K  %s  %s  ↓ %s \033[%sm%s\033[0m / ↑ \033[%sm%s\033[0m\r" \
                            "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_bar" "$COLOR_TABLE_VALUE" "$dl_comp" "$COLOR_TABLE_VALUE" "$live_disp"
                        else
                          printf "\r\033[2K  %s  %s  ↓ %s %s / ↑ %s\r" \
                            "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_bar" "$dl_comp" "$live_disp"
                        fi
                      else
                        if [[ -n "$COLOR_TABLE_VALUE" ]]; then
                          printf "\r\033[2K  %s  %s  ↓ \033[%sm%s\033[0m / ↑ \033[%sm%s\033[0m\r" \
                            "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE" "$dl_comp" "$COLOR_TABLE_VALUE" "$live_disp"
                        else
                          printf "\r\033[2K  %s  %s  ↓ %s / ↑ %s\r" \
                            "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_comp" "$live_disp"
                        fi
                      fi
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
        if [[ -n "$iperf_pid" && "$iperf_pid" -gt 1 ]]; then
          { kill -TERM "$iperf_pid" 2>/dev/null; sleep 0.05; kill -KILL "$iperf_pid" 2>/dev/null; wait "$iperf_pid" 2>/dev/null; } 2>/dev/null || true
        fi
        break
      fi
    done

    if [[ -n "$iperf_pid" && "$iperf_pid" -gt 1 ]]; then
      wait "$iperf_pid" 2>/dev/null || true
    fi

    if [[ "$IPERF_SKIPPED" == "true" ]]; then
      IPERF_LAST_STR="Skipped"
      IPERF_LAST_NUM="null"
      IPERF_LAST_STATUS=2
      if [[ "$JSON_OUTPUT" != "true" && -t 1 && "$format_mode" == "OOKLA" ]]; then
        if [[ "$mode" == "DL" ]]; then
          printf "\r\033[2K  • Загрузка (Down):  %s\n" "$(format_value "Skipped")"
        else
          printf "\r\033[2K  • Отдача (Up):      %s\n" "$(format_value "Skipped")"
        fi
      fi
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
      if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
        local live_disp
        live_disp=$(compact_mbps "$res_mbps" 0)
        if [[ "$format_mode" == "OOKLA" ]]; then
          local live_bar
          live_bar=$(render_speed_bar "$res_mbps" 1000 6)
          if [[ "$mode" == "DL" ]]; then
            if [[ -n "$COLOR_TABLE_VALUE" ]]; then
              printf "\r\033[2K  • Загрузка (Down):  \033[%sm↓ %s %s\033[0m\n" "$COLOR_TABLE_VALUE" "$live_bar" "$live_disp"
            else
              printf "\r\033[2K  • Загрузка (Down):  ↓ %s %s\n" "$live_bar" "$live_disp"
            fi
          else
            if [[ -n "$COLOR_TABLE_VALUE" ]]; then
              printf "\r\033[2K  • Отдача (Up):      \033[%sm↑ %s %s\033[0m\n" "$COLOR_TABLE_VALUE" "$live_bar" "$live_disp"
            else
              printf "\r\033[2K  • Отдача (Up):      ↑ %s %s\n" "$live_bar" "$live_disp"
            fi
          fi
        else
          if [[ "$mode" == "DL" ]]; then
            local live_bar
            live_bar=$(render_speed_bar "$res_mbps" 1000 6)
            if [[ -n "$COLOR_TABLE_VALUE" ]]; then
              printf "\r\033[2K  %s  %s  ↓ %s \033[%sm%s\033[0m\r" \
                "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$live_bar" "$COLOR_TABLE_VALUE" "$live_disp"
            else
              printf "\r\033[2K  %s  %s  ↓ %s %s\r" \
                "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$live_bar" "$live_disp"
            fi
          else
            local dl_comp dl_bar
            dl_comp=$(compact_mbps "$dl_speed_for_ul" 0)
            dl_bar=$(render_speed_bar "$dl_speed_for_ul" 1000 6)
            if [[ -n "$dl_bar" ]]; then
              if [[ -n "$COLOR_TABLE_VALUE" ]]; then
                printf "\r\033[2K  %s  %s  ↓ %s \033[%sm%s\033[0m / ↑ \033[%sm%s\033[0m\r" \
                  "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_bar" "$COLOR_TABLE_VALUE" "$dl_comp" "$COLOR_TABLE_VALUE" "$live_disp"
              else
                printf "\r\033[2K  %s  %s  ↓ %s %s / ↑ %s\r" \
                  "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_bar" "$dl_comp" "$live_disp"
              fi
            else
              if [[ -n "$COLOR_TABLE_VALUE" ]]; then
                printf "\r\033[2K  %s  %s  ↓ \033[%sm%s\033[0m / ↑ \033[%sm%s\033[0m\r" \
                  "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$COLOR_TABLE_VALUE" "$dl_comp" "$COLOR_TABLE_VALUE" "$live_disp"
              else
                printf "\r\033[2K  %s  %s  ↓ %s / ↑ %s\r" \
                  "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_comp" "$live_disp"
              fi
            fi
          fi
        fi
      fi
    fi

    break
  done
}

# Regional test targets: Region | City | Provider | Host | PortRange
RU_REGIONAL_SERVERS=(
  "Центральный регион"$'\t'"Москва"$'\t'"Hostkey DataLine"$'\t'"spd-rudp.hostkey.ru"$'\t'"5201-5209"
  "Центральный регион"$'\t'"Москва"$'\t'"МТС"$'\t'"mskst.st.mtsws.net"$'\t'"3333"
  "Северо-Западный регион"$'\t'"Санкт-Петербург"$'\t'"ЭР-Телеком"$'\t'"st.spb.ertelecom.ru"$'\t'"5201-5209"
  "Приволжский регион"$'\t'"Казань"$'\t'"ЭР-Телеком"$'\t'"st.kzn.ertelecom.ru"$'\t'"5201-5209"
  "Приволжский регион"$'\t'"Казань"$'\t'"МТС"$'\t'"kazst.st.mtsws.net"$'\t'"3333"
  "Приволжский регион"$'\t'"Нижний Новгород"$'\t'"ТТК"$'\t'"speed-nn.vtt.net"$'\t'"5201"
  "Приволжский регион"$'\t'"Самара"$'\t'"ЭР-Телеком"$'\t'"st.samara.ertelecom.ru"$'\t'"5201-5209"
  "Южный регион"$'\t'"Ростов-на-Дону"$'\t'"ЭР-Телеком"$'\t'"st.rostov.ertelecom.ru"$'\t'"5201-5209"
  "Южный регион"$'\t'"Волгоград"$'\t'"ЭР-Телеком"$'\t'"st.volgograd.ertelecom.ru"$'\t'"5201-5209"
  "Южный регион"$'\t'"Волгоград"$'\t'"ТТК"$'\t'"speed-vgd.vtt.net"$'\t'"5201"
  "Южный регион"$'\t'"Астрахань"$'\t'"Билайн"$'\t'"astrakhan1.speedtest.corbina.net"$'\t'"5201"
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
  if [[ -z "$target_ip" ]]; then
    ARR_CONNECTIVITY+=( "$region"$'\t'"$city"$'\t'"$provider"$'\t'"$host"$'\t'"$base_port"$'\t'"$ping_val"$'\t'"$ping_num"$'\t—\tnull\tnull' )
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "  %s  %s  %s\n" \
        "$(pad_str "$label" 37)" \
        "$(pad_str "$(format_value "$ping_val")" 10)" \
        "$(format_value "—")"
    fi
    return
  fi

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
  elif [[ "$port_spec" == "5201-5210" ]]; then
    ports=(5201 5202 5203 5204 5205 5206 5207 5208 5209 5210)
  else
    ports=("$port_spec")
  fi

  local test_time="${IPERF_TIME:-3}"
  local best_dl="—" best_ul="—"
  local best_dl_num="null" best_ul_num="null"
  local actual_port="$base_port"
  local p s
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

    ((port_attempts++))
    if (( port_attempts > 3 )); then
      break
    fi

    # Fast TCP pre-check (0.8s) to skip closed or firewalled ports immediately without sending corrupting payload
    if ! timeout 0.8 bash -c "true > /dev/tcp/$target_ip/$p" 2>/dev/null; then
      continue
    fi

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
      continue
    fi

    best_dl="$IPERF_LAST_STR"
    best_dl_num="$IPERF_LAST_NUM"
    actual_port="$p"

    # Prepare terminal state for upload before socket-drain pause
    if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
      local dl_comp dl_bar
      dl_comp=$(compact_mbps "$best_dl" 0)
      dl_bar=$(render_speed_bar "$best_dl_num" 1000 6)
      if [[ -n "$COLOR_TABLE_VALUE" ]]; then
        printf "\r\033[2K  %s  %s  ↓ %s \033[%sm%s\033[0m / ↑ ...\r" \
          "$(pad_str "$label" 37)" "$(pad_str "$(format_value "$ping_val")" 10)" "$dl_bar" "$COLOR_TABLE_VALUE" "$dl_comp"
      else
        printf "\r\033[2K  %s  %s  ↓ %s %s / ↑ ...\r" \
          "$(pad_str "$label" 37)" "$(pad_str "$ping_val" 10)" "$dl_bar" "$dl_comp"
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
    local cell_speed
    cell_speed=$(format_speed_cell "$best_dl_num" "$best_ul_num" "$speed")
    if [[ -t 1 ]]; then
      printf "\r\033[2K  %s  %s  %s\n" \
        "$(pad_str "$label" 37)" \
        "$(pad_str "$(format_value "$ping_val")" 10)" \
        "$cell_speed"
    else
      printf "  %s  %s  %s\n" \
        "$(pad_str "$label" 37)" \
        "$(pad_str "$ping_val" 10)" \
        "$cell_speed"
    fi
  fi
}

measure_ru_pings() {
  local p_dir="$TMP_WORK_DIR/pings"
  local srv host
  mkdir -p "$p_dir"

  # Ping all unique regional hosts in parallel
  for srv in "${RU_REGIONAL_SERVERS[@]}"; do
    IFS=$'\t' read -r _ _ _ host _ <<<"$srv"
    if [[ ! -f "$p_dir/$host" ]]; then
      touch "$p_dir/$host"
      ping_host "$host" "$p_dir/$host" &
    fi
  done
  wait
}

measure_ru_iperf() {
  local p_dir="$TMP_WORK_DIR/pings"
  local current_region=""
  local srv_entry region city provider host port_spec

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    if is_command_available "iperf3" && [[ "$RUN_IPERF" == "true" ]]; then
      bold "7. ⚡ Связность с регионами РФ (Задержка RTT и скорость iPerf3)"; printf "\n\n"
    else
      bold "7. ⚡ Связность с регионами РФ (Задержка RTT до 7 округов)"; printf "\n\n"
    fi
  fi

  # Enable non-canonical mode if interactive terminal
  enable_raw_terminal

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
  restore_terminal

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



measure_ookla_speedtest() {
  local cc="${NODE_COUNTRY_CODE^^}"
  if [[ "$IPV6_ONLY" == "true" || ( -z "$EXTERNAL_IPV4" && "$IPV4_SUPPORTED" -eq 0 ) ]]; then
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      bold "6. 🚀 Тест скорости ноды (Speedtest by Ookla)"; printf "\n"
      printf "  • Замер канала:     %s\n\n" "$(format_value "Пропущено (Ookla Speedtest требует IPv4)")"
    fi
    NODE_UPLINK_STATUS="Skipped (IPv6-only host)"
    return 0
  fi

  # Для нод в РФ тест Ookla пропускается (Ookla заблокирована в РФ; замеры связности и скорости выполняются в Блоке 7)
  if [[ "$cc" == "RU" ]]; then
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      bold "6. 🚀 Тест скорости ноды (Speedtest by Ookla)"; printf "\n"
      printf "  • Замер канала:     %s\n\n" "$(format_value "Пропущено (для нод в РФ замер выполняется в Блоке 7)")"
    fi
    NODE_UPLINK_STATUS="Skipped for RU nodes (tested in section 7)"
    return 0
  fi

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    bold "6. 🚀 Тест скорости ноды (Speedtest by Ookla)"; printf "\n"
  fi

  if [[ "$RUN_SPEEDTEST" != "true" ]]; then
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "  • Скорость:         %s\n\n" "$(format_value "Пропущено (--no-speedtest)")"
    fi
    NODE_UPLINK_STATUS="Skipped (--no-speedtest)"
    return 0
  fi

  local st_bin=""
  if is_command_available "speedtest"; then
    local check_v
    check_v=$(HOME="$TMP_WORK_DIR" XDG_CONFIG_HOME="$TMP_WORK_DIR" speedtest --version 2>/dev/null || true)
    if [[ "$check_v" =~ "Speedtest by Ookla"|"Ookla" ]]; then
      st_bin="$(command -v speedtest)"
    fi
  fi

  if [[ -z "$st_bin" ]]; then
    local sysarch sys_bit=""
    sysarch="$(uname -m 2>/dev/null || arch 2>/dev/null || echo "x86_64")"
    case "$sysarch" in
      x86_64|amd64) sys_bit="x86_64" ;;
      aarch64|arm64|armv8*) sys_bit="aarch64" ;;
      armv7*) sys_bit="armhf" ;;
      i386|i686) sys_bit="i386" ;;
      *) sys_bit="" ;;
    esac

    if [[ -n "$sys_bit" ]]; then
      local st_dir="$TMP_WORK_DIR/speedtest_bin"
      mkdir -p "$st_dir" 2>/dev/null || true
      local st_tgz="$TMP_WORK_DIR/ookla_st.tgz"
      local url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
      local url2="https://dl.lamp.sh/files/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"

      progress_status "Инициализация движка Speedtest CLI ($sys_bit)"
      if curl -fsSL --connect-timeout 5 --max-time 15 "$url1" -o "$st_tgz" 2>/dev/null || \
         curl -fsSL --connect-timeout 5 --max-time 15 "$url2" -o "$st_tgz" 2>/dev/null; then
        tar -zxf "$st_tgz" -C "$st_dir" 2>/dev/null || true
        chmod +x "$st_dir/speedtest" 2>/dev/null || true
        rm -f "$st_tgz" 2>/dev/null || true
        if [[ -x "$st_dir/speedtest" ]]; then
          st_bin="$st_dir/speedtest"
        fi
      fi
      progress_clear
    fi
  fi

  if [[ -z "$st_bin" || ! -x "$st_bin" ]]; then
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "  • Скорость:         %s\n\n" "$(format_value "Speedtest CLI недоступен")"
    fi
    NODE_UPLINK_STATUS="Speedtest CLI unavailable"
    return 0
  fi

  local st_json="$TMP_WORK_DIR/speedtest_res.json"
  local st_err="$TMP_WORK_DIR/speedtest.err"
  : > "$st_json"
  : > "$st_err"

  if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
    if [[ -n "$COLOR_TABLE_VALUE" ]]; then
      printf "  • Замер канала:     \033[%smПодключение к ближайшему серверу Ookla...\033[0m\r" "$COLOR_TABLE_VALUE"
    else
      printf "  • Замер канала:     Подключение к ближайшему серверу Ookla...\r"
    fi
  fi

  timeout 45 env HOME="$TMP_WORK_DIR" XDG_CONFIG_HOME="$TMP_WORK_DIR" "$st_bin" --accept-license --accept-gdpr -p no -f json > "$st_json" 2> "$st_err" &
  local st_pid=$!

  local spinner=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
  local spin_idx=0
  while kill -0 "$st_pid" 2>/dev/null; do
    if [[ "$JSON_OUTPUT" != "true" && -t 1 ]]; then
      local char="${spinner[$spin_idx]}"
      if [[ -n "$COLOR_WARN" ]]; then
        printf "\r\033[2K  • Замер канала:     \033[%sm%s\033[0m Автовыбор сервера, замер задержки, Download и Upload...\r" "$COLOR_WARN" "$char"
      else
        printf "\r\033[2K  • Замер канала:     %s Автовыбор сервера, замер задержки, Download и Upload...\r" "$char"
      fi
      spin_idx=$(( (spin_idx + 1) % ${#spinner[@]} ))
    fi
    sleep 0.15
  done
  wait "$st_pid" 2>/dev/null || true
  progress_clear

  local s_location s_name s_country s_latency s_dl_bw s_ul_bw s_url is_ok=false
  if [[ -s "$st_json" ]] && jq -e '.download.bandwidth and .ping.latency' "$st_json" >/dev/null 2>&1; then
    s_location=$(jq -r '.server.location // ""' "$st_json" 2>/dev/null)
    s_name=$(jq -r '.server.name // ""' "$st_json" 2>/dev/null)
    s_country=$(jq -r '.server.country // ""' "$st_json" 2>/dev/null)
    s_latency=$(jq -r '.ping.latency // "null"' "$st_json" 2>/dev/null)
    s_dl_bw=$(jq -r '.download.bandwidth // "0"' "$st_json" 2>/dev/null)
    s_ul_bw=$(jq -r '.upload.bandwidth // "0"' "$st_json" 2>/dev/null)
    s_url=$(jq -r '.result.url // ""' "$st_json" 2>/dev/null)
    if [[ -n "$s_latency" && "$s_latency" != "null" && "$s_dl_bw" != "0" ]]; then
      is_ok=true
    fi
  fi

  if [[ "$is_ok" == "true" ]]; then
    local dl_mbps="0.0" ul_mbps="0.0" lat_val="N/A"
    dl_mbps=$(awk -v b="$s_dl_bw" 'BEGIN { printf "%.1f", (b * 8) / 1000000 }')
    ul_mbps=$(awk -v b="$s_ul_bw" 'BEGIN { printf "%.1f", (b * 8) / 1000000 }')
    if [[ "$s_latency" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      lat_val="$(awk -v l="$s_latency" 'BEGIN { printf "%.1f ms", l }')"
    fi

    local server_desc=""
    if [[ -n "$s_location" && -n "$s_name" && "$s_location" != "$s_name" ]]; then
      server_desc="$s_location ($s_name)"
    elif [[ -n "$s_location" ]]; then
      server_desc="$s_location"
    elif [[ -n "$s_name" ]]; then
      server_desc="$s_name"
    else
      server_desc="Speedtest Server"
    fi
    [[ -n "$s_country" ]] && server_desc="$server_desc, $s_country"

    local dl_bar ul_bar
    dl_bar=$(render_speed_bar "$dl_mbps" 1000 6)
    ul_bar=$(render_speed_bar "$ul_mbps" 1000 6)

    local dl_str="${dl_mbps} Mbps"
    local ul_str="${ul_mbps} Mbps"

    NODE_UPLINK_TARGET="$server_desc"
    NODE_UPLINK_PING="$lat_val"
    NODE_UPLINK_PING_NUM="$s_latency"
    NODE_UPLINK_DL="$dl_mbps"
    NODE_UPLINK_UL="$ul_mbps"
    NODE_UPLINK_STATUS="$lat_val | ↓ $dl_str / ↑ $ul_str ($server_desc)"

    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "  • Ближайший сервер: %s (автовыбор)\n" "$(bold "$server_desc")"
      printf "  • Задержка (Ping):  %s\n" "$(format_value "$lat_val")"
      if [[ -n "$COLOR_TABLE_VALUE" ]]; then
        printf "  • Загрузка (Down):  \033[%sm↓\033[0m %s %s\n" "$COLOR_TABLE_VALUE" "$dl_bar" "$(format_value "$dl_str")"
        printf "  • Отдача (Up):      \033[%sm↑\033[0m %s %s\n\n" "$COLOR_TABLE_VALUE" "$ul_bar" "$(format_value "$ul_str")"
      else
        printf "  • Загрузка (Down):  ↓ %s %s\n" "$dl_bar" "$dl_str"
        printf "  • Отдача (Up):      ↑ %s %s\n\n" "$ul_bar" "$ul_str"
      fi
    fi
  else
    local err_msg
    err_msg=$(jq -r '.message // empty' "$st_json" 2>/dev/null || cat "$st_err" 2>/dev/null | head -n 1)
    [[ -z "$err_msg" ]] && err_msg="Тест скорости не удался"
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      printf "  • Скорость:         %s\n\n" "$(format_value "$err_msg")"
    fi
    NODE_UPLINK_STATUS="$err_msg"
  fi
  return 0
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

# ==============================================================================
# Telegram MTProto Datacenter Audit (DC1-DC5 Port 443 Obfuscated Protocol)
# ==============================================================================

readonly TG_MTPROTO_HEADER_BYTES=64
readonly TG_MTPROTO_INTERMEDIATE_TAG="eeeeeeee"
readonly TG_MTPROTO_REQ_PQ_MULTI="f18e7ebe"
readonly TG_MTPROTO_RES_PQ="63241605"
readonly TG_MTPROTO_RES_PQ_BYTES=44

readonly TELEGRAM_DCS=(
  "DC1|149.154.175.50"
  "DC2|149.154.167.51"
  "DC2|95.161.76.100"
  "DC3|149.154.175.100"
  "DC4|149.154.167.91"
  "DC5|149.154.171.5"
  "DC5|91.108.56.130"
)

tg_bin_to_hex() {
  od -An -v -tx1 2>/dev/null | tr -d ' \n'
}

tg_hex_to_bin() {
  local bytes=()
  mapfile -t bytes < <(fold -w2 <<<"$1")
  printf "%b" "$(printf '\\x%s' "${bytes[@]}")"
}

tg_reverse_hex() {
  fold -w2 <<<"$1" | tac | tr -d '\n'
}

tg_le32_hex() {
  local val=$1
  printf "%02x%02x%02x%02x" $((val & 255)) $((val >> 8 & 255)) $((val >> 16 & 255)) $((val >> 24 & 255))
}

tg_aes_ctr() {
  openssl enc -aes-256-ctr -K "$1" -iv "$2" -nosalt 2>/dev/null
}

tg_random_obfuscated_header() {
  local hdr
  while true; do
    hdr=$(head -c "$TG_MTPROTO_HEADER_BYTES" /dev/urandom 2>/dev/null | tg_bin_to_hex)
    case "${hdr:0:8}" in
      ef*|48454144|504f5354|47455420|4f505449|dddddddd|eeeeeeee|16030102) continue ;;
    esac
    if [[ "${hdr:8:8}" == "00000000" ]]; then
      continue
    fi
    echo "$hdr"
    return
  done
}

mtproto_exchange() {
  local ip="$1" dc_id="$2"
  local hdr nonce req key iv rev dec_key dec_iv sealed reply plain

  hdr=$(tg_random_obfuscated_header)
  [[ -z "$hdr" ]] && return 1
  hdr="${hdr:0:112}${TG_MTPROTO_INTERMEDIATE_TAG}$(printf "%02x00" "$dc_id")${hdr:124:4}"
  nonce=$(head -c 16 /dev/urandom 2>/dev/null | tg_bin_to_hex)
  req="28000000""0000000000000000""00000000$(tg_le32_hex "$(date +%s)")""14000000""${TG_MTPROTO_REQ_PQ_MULTI}${nonce}"

  key=${hdr:16:64}
  iv=${hdr:80:32}
  rev=$(tg_reverse_hex "${hdr:16:96}")
  dec_key=${rev:0:64}
  dec_iv=${rev:64:32}
  sealed=$(tg_hex_to_bin "${hdr}${req}" | tg_aes_ctr "$key" "$iv" | tg_bin_to_hex)

  exec 3<>"/dev/tcp/$ip/443" || return 1
  tg_hex_to_bin "${hdr:0:112}${sealed:112}" >&3 2>/dev/null
  reply=$(head -c "$TG_MTPROTO_RES_PQ_BYTES" <&3 2>/dev/null | tg_bin_to_hex)
  exec 3>&- 3<&- 2>/dev/null || true

  if [[ ${#reply} -ne $((TG_MTPROTO_RES_PQ_BYTES * 2)) ]]; then
    return 1
  fi

  plain=$(tg_hex_to_bin "$reply" | tg_aes_ctr "$dec_key" "$dec_iv" | tg_bin_to_hex)
  [[ "${plain:48:8}" == "$TG_MTPROTO_RES_PQ" && "${plain:56:32}" == "$nonce" ]]
}

probe_single_telegram_dc() {
  local dc_name="$1" dc_ip="$2" dc_num="$3" out_file="$4"
  if ! is_command_available "openssl"; then
    if timeout 2 bash -c "true >/dev/tcp/$dc_ip/443" 2>/dev/null; then
      echo "Available (TCP)" > "$out_file"
    else
      echo "Blocked" > "$out_file"
    fi
    return
  fi

  local ex_script
  ex_script="$(declare -p TG_MTPROTO_HEADER_BYTES TG_MTPROTO_INTERMEDIATE_TAG TG_MTPROTO_REQ_PQ_MULTI TG_MTPROTO_RES_PQ TG_MTPROTO_RES_PQ_BYTES)
$(declare -f tg_bin_to_hex tg_hex_to_bin tg_reverse_hex tg_le32_hex tg_aes_ctr tg_random_obfuscated_header mtproto_exchange)
mtproto_exchange \"\$@\""

  if timeout 3 bash -c "$ex_script" _ "$dc_ip" "$dc_num" 2>/dev/null; then
    echo "Available" > "$out_file"
  else
    if timeout 1.5 bash -c "true >/dev/tcp/$dc_ip/443" 2>/dev/null; then
      echo "DPI Drop" > "$out_file"
    else
      echo "Blocked" > "$out_file"
    fi
  fi
}

run_telegram_dc_checks() {
  local tg_dir="$TMP_WORK_DIR/tg_dcs"
  mkdir -p "$tg_dir" 2>/dev/null || true

  local entry name ip num i
  for i in "${!TELEGRAM_DCS[@]}"; do
    entry="${TELEGRAM_DCS[$i]}"
    name="${entry%%|*}"
    ip="${entry##*|}"
    num="${name#DC}"
    probe_single_telegram_dc "$name" "$ip" "$num" "$tg_dir/$i" &
  done
  wait

  for i in "${!TELEGRAM_DCS[@]}"; do
    entry="${TELEGRAM_DCS[$i]}"
    name="${entry%%|*}"
    ip="${entry##*|}"
    local status="Blocked"
    if [[ -f "$tg_dir/$i" ]]; then
      status=$(<"$tg_dir/$i")
    fi
    ARR_TG_DCS+=( "$name"$'\t'"$ip"$'\t'"$status" )
  done
}

# ==============================================================================
# DNS Resolvers & Spoofing / Hijacking Detection
# ==============================================================================

readonly ENCRYPTED_DNS_SERVERS=(
  "Cloudflare|1.1.1.1"
  "Cloudflare|1.0.0.1"
  "Google|8.8.8.8"
  "Google|8.8.4.4"
  "Quad9|9.9.9.9"
  "Quad9|9.9.9.10"
  "AdGuard|94.140.14.14"
  "AdGuard|94.140.15.15"
  "NextDNS|45.90.28.65"
  "NextDNS|45.90.30.65"
  "Yandex|77.88.8.8"
  "Yandex|77.88.8.1"
)

probe_single_dns_resolver() {
  local name="$1" ip="$2" out_file="$3"
  local udp="Blocked" doh="Blocked" dot="Blocked" spoof="Clean"

  # 1. UDP DNS (Port 53)
  if is_command_available "dig"; then
    if dig +short +time=2 +tries=1 @"$ip" cloudflare.com A 2>/dev/null | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
      udp="Available"
    fi
  elif timeout 1.5 bash -c "true >/dev/udp/$ip/53" 2>/dev/null; then
    udp="Available"
  fi

  # 2. DoH (HTTPS)
  local doh_endpoint=""
  case "$ip" in
    1.1.1.1|1.0.0.1) doh_endpoint="https://cloudflare-dns.com/dns-query" ;;
    8.8.8.8|8.8.4.4) doh_endpoint="https://dns.google/dns-query" ;;
    9.9.9.9|9.9.9.10) doh_endpoint="https://dns.quad9.net/dns-query" ;;
    94.140.14.14|94.140.15.15) doh_endpoint="https://dns.adguard-dns.com/dns-query" ;;
    45.90.28.65|45.90.30.65) doh_endpoint="https://dns.nextdns.io" ;;
    77.88.8.8|77.88.8.1) doh_endpoint="https://common.dot.dns.yandex.net/dns-query" ;;
  esac
  if [[ -n "$doh_endpoint" ]]; then
    if curl -sS -m 2 --connect-timeout 1.5 -H "accept: application/dns-json" "${doh_endpoint}?name=cloudflare.com&type=A" 2>/dev/null | grep -q '"Status":0'; then
      doh="Available"
    fi
  fi

  # 3. DoT (Port 853)
  if is_command_available "dig" && dig -v 2>&1 | grep -q "+tls"; then
    if dig +short +tls +time=2 +tries=1 @"$ip" cloudflare.com A 2>/dev/null | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
      dot="Available"
    fi
  elif timeout 2 openssl s_client -connect "${ip}:853" </dev/null >/dev/null 2>&1; then
    dot="Available"
  elif timeout 1.5 bash -c "true >/dev/tcp/$ip/853" 2>/dev/null; then
    dot="Available"
  fi

  # 4. Spoofing test for blocked domain rutracker.org
  if is_command_available "dig" && [[ "$udp" == "Available" ]]; then
    local ans
    ans=$(dig +short +time=2 +tries=1 @"$ip" rutracker.org A 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)
    if [[ -z "$ans" ]]; then
      spoof="Blocked"
    elif [[ "$ans" =~ ^(127\.|0\.|195\.82\.146\.|10\.|192\.168\.) ]]; then
      spoof="Spoofed ($ans)"
    elif [[ "$ans" =~ ^(104\.21\.|172\.67\.|188\.114\.) ]]; then
      spoof="Clean"
    else
      spoof="Spoofed ($ans)"
    fi
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$name" "$ip" "$udp" "$doh" "$dot" "$spoof" > "$out_file"
}

run_dns_and_telegram_checks() {
  local dns_dir="$TMP_WORK_DIR/dns_checks"
  local tg_dir="$TMP_WORK_DIR/tg_dcs"
  mkdir -p "$dns_dir" "$tg_dir" 2>/dev/null || true

  if [[ "$RUN_DNS_AUDIT" == "true" ]]; then
    local i entry name ip
    for i in "${!ENCRYPTED_DNS_SERVERS[@]}"; do
      entry="${ENCRYPTED_DNS_SERVERS[$i]}"
      name="${entry%%|*}"
      ip="${entry##*|}"
      probe_single_dns_resolver "$name" "$ip" "$dns_dir/$i" &
    done
  fi

  if [[ "$RUN_TG_AUDIT" == "true" ]]; then
    local entry name ip num i
    for i in "${!TELEGRAM_DCS[@]}"; do
      entry="${TELEGRAM_DCS[$i]}"
      name="${entry%%|*}"
      ip="${entry##*|}"
      num="${name#DC}"
      probe_single_telegram_dc "$name" "$ip" "$num" "$tg_dir/$i" &
    done
  fi

  wait

  if [[ "$RUN_DNS_AUDIT" == "true" ]]; then
    local spoofed_count=0
    for i in "${!ENCRYPTED_DNS_SERVERS[@]}"; do
      if [[ -f "$dns_dir/$i" ]]; then
        local line
        line=$(<"$dns_dir/$i")
        ARR_DNS_RESOLVERS+=( "$line" )
        if [[ "$line" == *"Spoofed"* ]]; then
          ((spoofed_count++))
        fi
      fi
    done
    if (( spoofed_count > 0 )); then
      DNS_HIJACKING_DETECTED=true
      DNS_HIJACKING_MSG="DNS hijacking detected! ($spoofed_count resolvers returned spoofed IP)"
    else
      DNS_HIJACKING_DETECTED=false
      DNS_HIJACKING_MSG="Good news, no DNS hijacking detected! (reference: Cloudflare over HTTPS)"
    fi
  fi

  if [[ "$RUN_TG_AUDIT" == "true" ]]; then
    for i in "${!TELEGRAM_DCS[@]}"; do
      local entry name ip
      entry="${TELEGRAM_DCS[$i]}"
      name="${entry%%|*}"
      ip="${entry##*|}"
      local status="Blocked"
      if [[ -f "$tg_dir/$i" ]]; then
        status=$(<"$tg_dir/$i")
      fi
      ARR_TG_DCS+=( "$name"$'\t'"$ip"$'\t'"$status" )
    done
  fi
}

# ==============================================================================
# Censorcheck DPI & Sanctions Audits
# ==============================================================================

readonly DPI_TARGET_DOMAINS=(
  "youtube.com"
  "redirector.googlevideo.com"
  "discord.com"
  "instagram.com"
  "facebook.com"
  "x.com"
  "linkedin.com"
  "rutracker.org"
  "digitalocean.com"
  "amnezia.org"
  "getoutline.org"
  "mailfence.com"
  "flibusta.is"
  "rezka.ag"
  "api.telegram.org"
  "play.google.com"
  "github.com"
  "raw.githubusercontent.com"
)

readonly GEO_BLOCKED_SITES=(
  "spotify.com"
  "netflix.com"
  "patreon.com"
  "swagger.io"
  "snyk.io"
  "mongodb.com"
  "autodesk.com"
  "graylog.org"
  "redis.io"
  "copilot.microsoft.com"
)

probe_single_dpi_site() {
  local domain="$1" out_file="$2"
  local resolved_ip=""
  if is_command_available "getent"; then
    resolved_ip=$(getent ahosts "$domain" 2>/dev/null | awk '{print $1; exit}')
  fi
  resolved_ip="${resolved_ip:-N/A}"

  # HTTP check
  local http_raw http_code http_res
  http_code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 3 "http://${domain}" 2>/dev/null)
  http_code="${http_code:-000}"
  [[ "$http_code" =~ ^0+$ ]] && http_code="000"
  if [[ "$http_code" =~ ^(301|302|307|308)$ ]]; then
    http_res="Redirected ($http_code)"
  elif [[ "$http_code" == "200" ]]; then
    http_res="Available (200)"
  elif [[ "$http_code" == "000" ]]; then
    http_res="Timeout"
  else
    http_res="HTTP $http_code"
  fi

  # HTTPS check
  local https_code https_res
  https_code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 4 -k "https://${domain}" 2>/dev/null)
  https_code="${https_code:-000}"
  [[ "$https_code" =~ ^0+$ ]] && https_code="000"
  if [[ "$https_code" =~ ^(200|301|302|307|308)$ ]]; then
    https_res="Available ($https_code)"
  elif [[ "$https_code" == "000" ]]; then
    https_res="DPI Drop / Timeout"
  elif [[ "$https_code" == "403" ]]; then
    https_res="Blocked (403)"
  elif [[ "$https_code" == "451" ]]; then
    https_res="RKN Blockpage (451)"
  else
    https_res="Blocked ($https_code)"
  fi

  printf "%s\t%s\t%s\t%s\n" "$domain" "$resolved_ip" "$http_res" "$https_res" > "$out_file"
}

probe_single_geoblocked_site() {
  local domain="$1" out_file="$2"
  local code
  code=$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 4 "https://${domain}" 2>/dev/null)
  code="${code:-000}"
  [[ "$code" =~ ^0+$ ]] && code="000"
  code="${code:-000}"
  if [[ "$code" =~ ^(200|301|302|307|308)$ ]]; then
    echo "Available ($code)" > "$out_file"
  elif [[ "$code" == "403" ]]; then
    echo "Blocked (Geo-403)" > "$out_file"
  elif [[ "$code" == "451" ]]; then
    echo "Blocked (Sanctions 451)" > "$out_file"
  elif [[ "$code" == "000" ]]; then
    echo "Timeout" > "$out_file"
  else
    echo "Status $code" > "$out_file"
  fi
}

run_censorcheck_dpi_and_geoblock() {
  local dpi_dir="$TMP_WORK_DIR/dpi"
  local geo_dir="$TMP_WORK_DIR/geoblocked"
  mkdir -p "$dpi_dir" "$geo_dir" 2>/dev/null || true

  if [[ "$RUN_DPI_AUDIT" == "true" ]]; then
    local dom i
    for i in "${!DPI_TARGET_DOMAINS[@]}"; do
      dom="${DPI_TARGET_DOMAINS[$i]}"
      probe_single_dpi_site "$dom" "$dpi_dir/$i" &
    done
  fi

  if [[ "$RUN_GEOBLOCK_AUDIT" == "true" ]]; then
    local dom i
    for i in "${!GEO_BLOCKED_SITES[@]}"; do
      dom="${GEO_BLOCKED_SITES[$i]}"
      probe_single_geoblocked_site "$dom" "$geo_dir/$i" &
    done
  fi

  wait

  if [[ "$RUN_DPI_AUDIT" == "true" ]]; then
    for i in "${!DPI_TARGET_DOMAINS[@]}"; do
      if [[ -f "$dpi_dir/$i" ]]; then
        ARR_DPI_DOMAINS+=( "$(<"$dpi_dir/$i")" )
      fi
    done
  fi

  if [[ "$RUN_GEOBLOCK_AUDIT" == "true" ]]; then
    for i in "${!GEO_BLOCKED_SITES[@]}"; do
      local dom="${GEO_BLOCKED_SITES[$i]}"
      local st="Blocked"
      if [[ -f "$geo_dir/$i" ]]; then
        st=$(<"$geo_dir/$i")
      fi
      ARR_GEO_BLOCKED+=( "$dom"$'\t'"$st" )
    done
  fi
}

print_dns_and_telegram_tables() {
  if [[ ( "$RUN_DNS_AUDIT" == "true" && ${#ARR_DNS_RESOLVERS[@]} -gt 0 ) || ( "$RUN_TG_AUDIT" == "true" && ${#ARR_TG_DCS[@]} -gt 0 ) ]]; then
    bold "2. 🛡️ DNS-резолверы, спуфинг и дата-центры Telegram (MTProto)"; printf "\n"
  fi

  if [[ "$RUN_DNS_AUDIT" == "true" && ${#ARR_DNS_RESOLVERS[@]} -gt 0 ]]; then
    printf "  [ DNS-резолверы и детекция спуфинга ]\n"
    {
      echo -e "  Resolver\tIP\tUDP\tDoH\tDoT\tSpoofing"
      echo -e "  ----------------\t----------------\t---------\t---------\t---------\t---------"
      for line in "${ARR_DNS_RESOLVERS[@]}"; do
        IFS=$'\t' read -r r_name r_ip r_udp r_doh r_dot r_spoof <<<"$line"
        echo -e "  $r_name\t$r_ip\t$(format_value "$r_udp")\t$(format_value "$r_doh")\t$(format_value "$r_dot")\t$(format_value "$r_spoof")"
      done
    } | format_table
    if [[ -n "$DNS_HIJACKING_MSG" ]]; then
      if [[ "$DNS_HIJACKING_DETECTED" == "true" ]]; then
        printf "  \033[%sm%s\033[0m\n\n" "$COLOR_DANGER" "$DNS_HIJACKING_MSG"
      else
        printf "  \033[%sm%s\033[0m\n\n" "$COLOR_SUCCESS" "$DNS_HIJACKING_MSG"
      fi
    else
      printf "\n"
    fi
  fi

  if [[ "$RUN_TG_AUDIT" == "true" && ${#ARR_TG_DCS[@]} -gt 0 ]]; then
    printf "  [ Дата-центры Telegram MTProto (порт 443) ]\n"
    {
      echo -e "  DC\tIP Address\tMTProto (Port 443)"
      echo -e "  ----\t----------------\t-------------------"
      for line in "${ARR_TG_DCS[@]}"; do
        IFS=$'\t' read -r dc_name dc_ip dc_status <<<"$line"
        echo -e "  $dc_name\t$dc_ip\t$(format_value "$dc_status")"
      done
    } | format_table
    printf "\n"
  fi
}

print_censorcheck_dpi_table() {
  if [[ "$RUN_DPI_AUDIT" != "true" || ${#ARR_DPI_DOMAINS[@]} -eq 0 ]]; then
    return 0
  fi

  local blocked_count=0
  for row in "${ARR_DPI_DOMAINS[@]}"; do
    IFS=$'\t' read -r d ip h s <<<"$row"
    if [[ "$s" == *"Drop"* || "$s" == *"Block"* || "$s" == *"Timeout"* ]]; then
      ((blocked_count++))
    fi
  done

  bold "4. 🚫 Фильтрация ТСПУ (Censorcheck DPI) и санкционные ресурсы"; printf "\n"
  printf "  [ Censorcheck DPI: 18 сайтов ] "
  if (( blocked_count == 0 )); then
    printf "\033[%sm[0 блоков / %d доступны без DPI-блокировок]\033[0m\n" "$COLOR_SUCCESS" "${#ARR_DPI_DOMAINS[@]}"
  else
    printf "\033[%sm[%d блоков из %d ресурсов под фильтрацией ТСПУ]\033[0m\n" "$COLOR_DANGER" "$blocked_count" "${#ARR_DPI_DOMAINS[@]}"
  fi

  {
    echo -e "  Домен\tIP-адрес\tHTTP (Port 80)\tHTTPS (Port 443 / TLS)"
    echo -e "  ----------------------------\t----------------\t--------------------\t----------------------"
    for row in "${ARR_DPI_DOMAINS[@]}"; do
      IFS=$'\t' read -r d ip h s <<<"$row"
      echo -e "  $d\t$ip\t$(format_value "$h")\t$(format_value "$s")"
    done
  } | format_table
  printf "\n"
}

print_geoblocked_table() {
  if [[ "$RUN_GEOBLOCK_AUDIT" != "true" || ${#ARR_GEO_BLOCKED[@]} -eq 0 ]]; then
    return 0
  fi

  local allowed_count=0
  for row in "${ARR_GEO_BLOCKED[@]}"; do
    IFS=$'\t' read -r d s <<<"$row"
    if [[ "$s" == *"Available"* ]]; then
      ((allowed_count++))
    fi
  done

  printf "  [ Санкционные зарубежные сервисы ] "
  if (( allowed_count == ${#ARR_GEO_BLOCKED[@]} )); then
    printf "\033[%sm[%d / %d пускают IP этого сервера]\033[0m\n" "$COLOR_SUCCESS" "$allowed_count" "${#ARR_GEO_BLOCKED[@]}"
  else
    printf "\033[%sm[%d / %d открываются с этого IP]\033[0m\n" "$COLOR_WARN" "$allowed_count" "${#ARR_GEO_BLOCKED[@]}"
  fi

  {
    echo -e "  Сервис\tСтатус доступа"
    echo -e "  ----------------------------\t----------------------"
    for row in "${ARR_GEO_BLOCKED[@]}"; do
      IFS=$'\t' read -r d s <<<"$row"
      echo -e "  $d\t$(format_value "$s")"
    done
  } | format_table
  printf "\n"
}

print_header() {
  local title="NodeCheck (RU Edition) - Node & Network Quality Auditor v${SCRIPT_VERSION}"
  local title_len=${#title}
  local pad=$(( 76 - title_len ))
  (( pad < 0 )) && pad=0

  if [[ -n "$COLOR_INFO" ]]; then
    printf "\033[%sm┌%s┐\033[0m\n" "$COLOR_INFO" "$(printf '%0.s─' {1..78})"
    printf "\033[%sm│\033[0m \033[%sm%s\033[0m%*s \033[%sm│\033[0m\n" "$COLOR_INFO" "$COLOR_BOLD" "$title" "$pad" "" "$COLOR_INFO"
    printf "\033[%sm└%s┘\033[0m\n" "$COLOR_INFO" "$(printf '%0.s─' {1..78})"
  elif [[ "$NO_COLOR_MODE" == "true" || -n "${NO_COLOR:-}" ]]; then
    printf "+%s+\n" "$(printf '%0.s-' {1..78})"
    printf "| %s%*s |\n" "$title" "$pad" ""
    printf "+%s+\n" "$(printf '%0.s-' {1..78})"
  else
    printf "┌%s┐\n" "$(printf '%0.s─' {1..78})"
    printf "│ %s%*s │\n" "$title" "$pad" ""
    printf "└%s┘\n" "$(printf '%0.s─' {1..78})"
  fi
  {
    local display_v4="$EXTERNAL_IPV4"
    local display_v6="$EXTERNAL_IPV6"
    if [[ "$SHOW_FULL_IP" != "true" ]]; then
      [[ -n "$display_v4" ]] && display_v4="$(mask_ipv4 "$display_v4")"
      [[ -n "$display_v6" ]] && display_v6="$(mask_ipv6 "$display_v6")"
    fi

    if [[ -n "$display_v4" ]]; then
      echo -e " IPv4:\t$(bold "$display_v4")"
    else
      echo -e " IPv4:\t$(color "$COLOR_NULL" "None (Not configured)")"
    fi
    if [[ -n "$display_v6" ]]; then
      echo -e " IPv6:\t$(bold "$display_v6")"
    else
      echo -e " IPv6:\t$(color "$COLOR_NULL" "None (Not configured)")"
    fi
    echo -e " Локация / ASN:\t$(color "$COLOR_ASN" "$NODE_COUNTRY_CODE ($NODE_CITY)") — $NODE_ASN ($NODE_ORG)"
    echo -e " ОС и ядро:\t$(bold "$NODE_OS")"
    echo -e " Платформа:\t$(bold "${NODE_VIRT^^}") | Аптайм: $(bold "$NODE_UPTIME")"
    local cpu_desc
    cpu_desc="$(bold "$NODE_CPU_MODEL") (${NODE_CPU_CORES} vCPU)"
    local crypto_parts=()
    if [[ -n "$NODE_AES_STATUS" && "$NODE_AES_STATUS" != "N/A" ]]; then
      crypto_parts+=("$(color "$NODE_AES_COLOR" "$NODE_AES_STATUS")")
    fi
    if [[ -n "$NODE_CRYPTO_SPEED" && "$NODE_CRYPTO_SPEED" != "N/A" && "$NODE_CRYPTO_SPEED" != *"Skipped"* ]]; then
      crypto_parts+=("$(bold "$NODE_CRYPTO_SPEED")")
    fi
    if (( ${#crypto_parts[@]} > 0 )); then
      local crypto_joined=""
      for p in "${crypto_parts[@]}"; do
        [[ -n "$crypto_joined" ]] && crypto_joined+=", "
        crypto_joined+="$p"
      done
      cpu_desc="$cpu_desc [$crypto_joined]"
    fi
    echo -e " Процессор (CPU):\t$cpu_desc"
    echo -e " CPU Steal:\t$(color "$NODE_CPU_STEAL_COLOR" "$NODE_CPU_STEAL")"
    local disk_info="$NODE_DISK"
    local disk_extra=()
    [[ -n "$NODE_DISK_TYPE" && "$NODE_DISK_TYPE" != "N/A" ]] && disk_extra+=("$NODE_DISK_TYPE")
    if [[ -n "$NODE_DISK_IO" && "$NODE_DISK_IO" != "N/A" ]]; then
      if [[ "$NODE_DISK_IO" == *"Skipped"* ]]; then
        disk_extra+=("$NODE_DISK_IO")
      else
        local io_label="I/O: $NODE_DISK_IO"
        if [[ -n "$NODE_DISK_IO_4K" && "$NODE_DISK_IO_4K" != "N/A" ]]; then
          io_label="$io_label, 4K: $NODE_DISK_IO_4K"
        fi
        disk_extra+=("$io_label")
      fi
    fi
    if (( ${#disk_extra[@]} > 0 )); then
      local disk_extra_joined=""
      for d_item in "${disk_extra[@]}"; do
        [[ -n "$disk_extra_joined" ]] && disk_extra_joined+=", "
        disk_extra_joined+="$d_item"
      done
      disk_info="$disk_info [$disk_extra_joined]"
    fi
    echo -e " Память / Диск:\tRAM: $(bold "$NODE_RAM") | Диск: $(bold "$disk_info")"
    echo -e " Тип хоста:\t$(bold "$NODE_TYPE") | Тип IP: $(color "$NODE_IP_NATIVE_COLOR" "$NODE_IP_NATIVE")"
    echo -e " Репутация / Базы:\tРКН: $(color "$NODE_RKN_COLOR" "$NODE_RKN_STATUS") | DNSBL: $(color "$NODE_DNSBL_COLOR" "$NODE_DNSBL_STATUS")"
    echo -e " Антифрод / Риск:\t$(color "$NODE_RISK_COLOR" "$NODE_RISK"), Google Captcha: $(color "$NODE_CAPTCHA_COLOR" "$NODE_CAPTCHA_STATUS")"
    echo -e " Сетевой стек:\tBBR: $(format_value "$NODE_BBR_STATUS") | UDP: $(format_value "$NODE_UDP_STATUS") | Port 25: $(format_value "$NODE_PORT25_STATUS")"
  } | format_table

  local line_sep
  if [[ "$NO_COLOR_MODE" == "true" || -n "${NO_COLOR:-}" ]]; then
    line_sep=$(printf '%0.s-' {1..80})
    printf "%s\n\n" "$line_sep"
  else
    line_sep=$(printf '%0.s─' {1..80})
    if [[ -n "$COLOR_INFO" ]]; then
      printf "\033[%sm%s\033[0m\n\n" "$COLOR_INFO" "$line_sep"
    else
      printf "%s\n\n" "$line_sep"
    fi
  fi
}

calculate_geoip_stats() {
  local protos=()
  if [[ $IPV4_SUPPORTED -eq 1 ]]; then
    protos+=("v4:IPv4")
  fi
  if [[ $IPV6_SUPPORTED -eq 1 ]]; then
    protos+=("v6:IPv6")
  fi

  local proto_entry
  for proto_entry in "${protos[@]}"; do
    local target_col="${proto_entry%%:*}"
    local col_label="${proto_entry##*:}"

    local top_code="" top_count=0 total=0 row c
    unset counts
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
      continue
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
    if [[ ${#protos[@]} -gt 1 ]]; then
      printf "  Консенсус (%s): %s — %s/%s (%s%%)\n\n" "$col_label" "$(color "$consensus_color" "$consensus_val")" "$top_count" "$total" "$top_pct"
    else
      printf "  Консенсус: %s — %s/%s (%s%%)\n\n" "$(color "$consensus_color" "$consensus_val")" "$top_count" "$total" "$top_pct"
    fi

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
  done
}

print_geoip_table() {
  local row name v4 v6
  bold "1. 🌐 Консенсус баз GeoIP (18 источников)"; printf "\n"
  if [[ $IPV4_SUPPORTED -eq 1 && $IPV6_SUPPORTED -eq 1 ]]; then
    {
      echo -e "  База данных\tIPv4\tIPv6"
      echo -e "  ------------------------\t------------\t------------"
      for row in "${ARR_GEOIP[@]}"; do
        IFS=$'\t' read -r name v4 v6 <<<"$row"
        echo -e "  $name\t$(format_value "$v4")\t$(format_value "$v6")"
      done
    } | format_table
  elif [[ $IPV6_SUPPORTED -eq 1 ]]; then
    {
      echo -e "  База данных\tСтрана (IPv6)"
      echo -e "  ----------------------------\t-------------"
      for row in "${ARR_GEOIP[@]}"; do
        IFS=$'\t' read -r name _ v6 <<<"$row"
        echo -e "  $name\t$(format_value "$v6")"
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
  local row name val
  bold "5. 🎬 Стриминги, медиа и AI-сервисы (Western Services & Geolocation)"; printf "\n"
  {
    echo -e "  Сервис\tРегион / Статус"
    echo -e "  ------------------------------------\t----------------------"
    for row in "${ARR_RU_UNBLOCK[@]}"; do
      IFS=$'\t' read -r name val <<<"$row"
      echo -e "  $name\t$(format_value "$val")"
    done
  } | format_table
  printf "\n"

  # Print Country Distribution Consensus Legend
  local all_countries=()
  for row in "${ARR_RU_UNBLOCK[@]}"; do
    IFS=$'\t' read -r _ val <<<"$row"
    local c
    c=$(grep -oE '\b[A-Z]{2}\b' <<<"$val" 2>/dev/null | head -n1)
    if [[ -n "$c" && -n "${COUNTRY_NAMES[$c]:-}" ]]; then
      all_countries+=("$c")
    fi
  done
  for row in "${ARR_GEOIP[@]}"; do
    IFS=$'\t' read -r _ v4 v6 <<<"$row"
    for item in "$v4" "$v6"; do
      local c
      c=$(grep -oE '\b[A-Z]{2}\b' <<<"$item" 2>/dev/null | head -n1)
      if [[ -n "$c" && -n "${COUNTRY_NAMES[$c]:-}" ]]; then
        all_countries+=("$c")
      fi
    done
  done

  if (( ${#all_countries[@]} > 0 )); then
    bold "  [ Распределение стран (Legend %) ]"; printf "\n"
    local summary
    summary=$(printf "%s\n" "${all_countries[@]}" | sort | uniq -c | sort -nr)
    local total=${#all_countries[@]}
    {
      echo -e "    Код\tСтрана\tДоля"
      echo -e "    ---\t--------------------\t------"
      while read -r count code; do
        [[ -z "$code" ]] && continue
        local c_name="${COUNTRY_NAMES[$code]:-$code}"
        local pct
        pct=$(awk -v c="$count" -v t="$total" 'BEGIN { printf "%.1f%%", (c / t) * 100 }')
        echo -e "    $(color "$COLOR_ASN" "$code")\t$c_name\t$pct"
      done <<<"$summary"
    } | format_table
    printf "\n"
  fi
}

print_ru_local_table() {
  local row name val
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
  local geoip_lines unblock_lines local_lines conn_lines dns_lines tg_lines dpi_lines geoblock_lines
  geoip_lines=$(printf "%s\n" "${ARR_GEOIP[@]}")
  unblock_lines=$(printf "%s\n" "${ARR_RU_UNBLOCK[@]}")
  local_lines=$(printf "%s\n" "${ARR_RU_LOCAL[@]}")
  conn_lines=$(printf "%s\n" "${ARR_CONNECTIVITY[@]}")
  dns_lines=$(printf "%s\n" "${ARR_DNS_RESOLVERS[@]}")
  tg_lines=$(printf "%s\n" "${ARR_TG_DCS[@]}")
  dpi_lines=$(printf "%s\n" "${ARR_DPI_DOMAINS[@]}")
  geoblock_lines=$(printf "%s\n" "${ARR_GEO_BLOCKED[@]}")

  local json_v4="$EXTERNAL_IPV4"
  local json_v6="$EXTERNAL_IPV6"
  if [[ "$SHOW_FULL_IP" != "true" ]]; then
    [[ -n "$json_v4" ]] && json_v4="$(mask_ipv4 "$json_v4")"
    [[ -n "$json_v6" ]] && json_v6="$(mask_ipv6 "$json_v6")"
  fi

  RESULT_JSON=$(jq -n \
    --arg ip "${json_v4:-}" \
    --arg ipv6 "${json_v6:-}" \
    --arg os "${NODE_OS:-}" \
    --arg virt "${NODE_VIRT:-}" \
    --arg uptime "${NODE_UPTIME:-}" \
    --arg cpu_model "${NODE_CPU_MODEL:-}" \
    --arg cpu_cores "${NODE_CPU_CORES:-1}" \
    --arg cpu_aes_hw "${NODE_AES_HARDWARE:-false}" \
    --arg cpu_aes_type "${NODE_AES_TYPE:-none}" \
    --arg cpu_crypto_speed "${NODE_CRYPTO_SPEED:-}" \
    --arg cpu_crypto_num "${NODE_CRYPTO_SPEED_MB_S:-null}" \
    --arg cpu_steal "${NODE_CPU_STEAL_NUM:-0.0}" \
    --arg cpu_steal_alltime "${NODE_CPU_STEAL_ALLTIME:-0.00}" \
    --arg ram "${NODE_RAM:-}" \
    --arg disk "${NODE_DISK:-}" \
    --arg disk_type "${NODE_DISK_TYPE:-}" \
    --arg disk_io "${NODE_DISK_IO:-}" \
    --arg disk_io_num "${NODE_DISK_IO_NUM:-null}" \
    --arg disk_io_status "${NODE_DISK_IO_STATUS:-pending}" \
    --arg disk_io_msg "${NODE_DISK_IO_MSG:-}" \
    --arg disk_io_4k "${NODE_DISK_IO_4K:-}" \
    --arg disk_io_4k_num "${NODE_DISK_IO_4K_NUM:-null}" \
    --arg country "${NODE_COUNTRY_CODE:-}" \
    --arg city "${NODE_CITY:-}" \
    --arg asn "${NODE_ASN:-}" \
    --arg org "${NODE_ORG:-}" \
    --arg host_type "${NODE_TYPE:-}" \
    --arg ip_type "${NODE_IP_NATIVE:-}" \
    --arg reg_country "${NODE_RIR_REG_COUNTRY:-}" \
    --arg risk "${NODE_RISK:-}" \
    --arg risk_max "${NODE_RISK_MAX_NUM:-}" \
    --arg scam_score "${NODE_SCAM_SCORE:-}" \
    --arg abuse_score "${NODE_ABUSE_SCORE:-}" \
    --arg abuse_reports "${NODE_ABUSE_REPORTS:-0}" \
    --arg ipq_score "${NODE_IPQUERY_SCORE:-}" \
    --arg captcha "${NODE_CAPTCHA_STATUS:-}" \
    --arg rkn "${NODE_RKN_STATUS:-}" \
    --arg dnsbl_status "${NODE_DNSBL_STATUS:-}" \
    --arg dnsbl_total "${NODE_DNSBL_TOTAL:-0}" \
    --arg dnsbl_listed "${NODE_DNSBL_LISTED:-0}" \
    --arg dnsbl_zones "${NODE_DNSBL_ZONES:-}" \
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
    --arg dns_raw "$dns_lines" \
    --arg tg_raw "$tg_lines" \
    --arg dpi_raw "$dpi_lines" \
    --arg geoblock_raw "$geoblock_lines" \
    --arg dns_hijack "$DNS_HIJACKING_DETECTED" \
    --arg dns_hijack_msg "$DNS_HIJACKING_MSG" \
    '{
      ip: (if $ip != "" then $ip else null end),
      ipv6: (if $ipv6 != "" then $ipv6 else null end),
      system: {
        os: $os,
        virt: $virt,
        uptime: $uptime,
        cpu_model: $cpu_model,
        cpu_cores: ($cpu_cores | try tonumber catch 1),
        cpu_aes_hardware: ($cpu_aes_hw == "true"),
        cpu_aes_type: (if $cpu_aes_type != "" and $cpu_aes_type != "none" then $cpu_aes_type else null end),
        cpu_crypto_speed: (if $cpu_crypto_speed != "" and $cpu_crypto_speed != "N/A" and ($cpu_crypto_speed | test("Skipped") | not) then $cpu_crypto_speed else null end),
        cpu_crypto_speed_mb_s: (if $cpu_crypto_num != "" and $cpu_crypto_num != "null" and $cpu_crypto_num != "N/A" then ($cpu_crypto_num | try tonumber catch null) else null end),
        cpu_steal_pct: ($cpu_steal | try tonumber catch 0.0),
        cpu_steal_all_time_pct: ($cpu_steal_alltime | try tonumber catch 0.00),
        ram: $ram,
        disk: $disk,
        disk_type: (if $disk_type != "" then $disk_type else null end),
        disk_io_status: (if $disk_io_status != "" then $disk_io_status else null end),
        disk_io_message: (if $disk_io_msg != "" then $disk_io_msg else null end),
        disk_io_write_speed: (if $disk_io_status == "success" and $disk_io != "" then $disk_io else null end),
        disk_io_write_mb_s: (if $disk_io_status == "success" and $disk_io_num != "" and $disk_io_num != "null" and $disk_io_num != "N/A" then ($disk_io_num | try tonumber catch null) else null end),
        disk_io_4k_speed: (if $disk_io_4k != "" and $disk_io_4k != "N/A" then $disk_io_4k else null end),
        disk_io_4k_iops: (if $disk_io_4k_num != "" and $disk_io_4k_num != "null" and $disk_io_4k_num != "N/A" then ($disk_io_4k_num | try tonumber catch null) else null end)
      },
      location: { country: $country, city: $city, asn: $asn, org: $org },
      quality: {
        host_type: $host_type,
        ip_type: (if $ip_type != "" then $ip_type else null end),
        registered_country: (if $reg_country != "" and $reg_country != "null" and $reg_country != "NULL" and $reg_country != "N/A" then $reg_country else null end),
        risk: $risk,
        risk_score_max: (if $risk_max != "" and $risk_max != "null" then ($risk_max | try tonumber catch null) else null end),
        scamalytics_score: (if $scam_score != "" and $scam_score != "null" then ($scam_score | try tonumber catch null) else null end),
        abuseipdb_score: (if $abuse_score != "" and $abuse_score != "null" then ($abuse_score | try tonumber catch null) else null end),
        abuseipdb_reports: (if $abuse_reports != "" and $abuse_reports != "null" then ($abuse_reports | try tonumber catch 0) else 0 end),
        ipquery_score: (if $ipq_score != "" and $ipq_score != "null" then ($ipq_score | try tonumber catch null) else null end),
        google_captcha: $captcha,
        rkn_registry: $rkn,
        dnsbl: {
          status: $dnsbl_status,
          total: ($dnsbl_total | try tonumber catch 0),
          blacklisted: ($dnsbl_listed | try tonumber catch 0),
          listed_zones: (if $dnsbl_zones != "" then ($dnsbl_zones | split(", ")) else [] end)
        }
      },
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
      dns_audit: {
        hijacking_detected: ($dns_hijack == "true"),
        hijacking_message: $dns_hijack_msg,
        resolvers: (
          [$dns_raw | split("\n")[] | select(length > 0) | split("\t")]
          | map(select(.[0] != null and .[0] != "") | {
              name: .[0],
              ip: .[1],
              udp: .[2],
              doh: .[3],
              dot: .[4],
              spoofing: .[5]
            })
        )
      },
      telegram_dcs: (
        [$tg_raw | split("\n")[] | select(length > 0) | split("\t")]
        | map(select(.[0] != null and .[0] != "") | {
            dc: .[0],
            ip: .[1],
            mtproto: .[2]
          })
      ),
      censorcheck_dpi: (
        [$dpi_raw | split("\n")[] | select(length > 0) | split("\t")]
        | map(select(.[0] != null and .[0] != "") | {
            domain: .[0],
            ip: .[1],
            http: .[2],
            https: .[3]
          })
      ),
      geoblocked_sanctions: (
        [$geoblock_raw | split("\n")[] | select(length > 0) | split("\t")]
        | map(select(.[0] != null and .[0] != "") | {
            domain: .[0],
            status: .[1]
          })
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
  -f, --full-ip            Отображать полный IP без маскирования (по умолч.: скрыт *.*)
  -4, --ipv4               Принудительно использовать только IPv4
  -6, --ipv6               Принудительно использовать только IPv6
  -j, --json               Вывод результатов в чистом формате JSON
  -s, --streams ЧИСЛО      Число параллельных потоков iPerf3 (по умолч.: 2 для 1 vCPU, 4 для 2+ vCPU)
  --no-iperf               Пропустить замер скорости iPerf3 (только пинг)
  --no-speedtest           Пропустить замер скорости ноды Ookla Speedtest
  --no-crypto              Пропустить замер скорости криптографии (AES)
  --io, --disk-bench       Запустить замер скорости диска (I/O) (по умолч. включен в TUI, выключен в -j)
  --no-io, --no-disk-bench Пропустить замер скорости диска (I/O)
  --iperf-all              Замер скорости iPerf3 по всем 7 регионам РФ (по умолчанию включен)
  --full-iperf             Расширенный тест iPerf3 (по 10с на прием и отдачу)
  --iperf-time СЕК         Время замера iPerf3 на прием и отдачу (по умолч.: 3с)
  --no-color               Отключить цветовое форматирование ANSI
  -p, --proxy АДРЕС        Использовать SOCKS5/SOCKS5h прокси (хост:порт)
  -i, --interface ИНТЕРФЕЙС Привязать запросы к сетевому интерфейсу (eth0, ens3)
  --no-dns                 Пропустить проверку DNS-резолверов (UDP/DoH/DoT и Spoofing)
  --no-tg                  Пропустить аудит дата-центров Telegram (MTProto)
  --no-dpi                 Пропустить тест DPI-блокировок ТСПУ
  --no-geoblock            Пропустить тест санкционных сервисов
  --no-doh                 Отключить DNS-over-HTTPS (системный резолвер)
  --doh ПРОВАЙДЕР          Выбор DoH: cloudflare, quad9, adguard
  --install-deps           Автоматически установить недостающие базовые утилиты через apt
  -v, --verbose            Подробное логирование сетевых запросов
  -d, --debug              Режим отладки (сохранение трассировки в сессионный log-файл)

Примеры:
  ./nodecheck.sh                         # Комплексный аудит (железо, GeoIP, сервисы, пинг и iPerf3 по всем 7 регионам РФ)
  ./nodecheck.sh -f                      # Аудит с отображением полного нескрытого IP
  ./nodecheck.sh -s 8                    # Аудит с 8 параллельными потоками iPerf3
  ./nodecheck.sh --no-iperf              # Быстрый экспресс-аудит без замера скорости (~10-15 секунд)
  ./nodecheck.sh --no-speedtest          # Экспресс-аудит без замера скорости Ookla Speedtest
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
      --*=?*)
        local opt="${1%%=*}"
        local val="${1#*=}"
        shift
        set -- "$opt" "$val" "$@"
        ;;
      --*=)
        local opt="${1%%=*}"
        shift
        set -- "$opt" "" "$@"
        ;;
      -h|--help)
        display_help
        exit 0
        ;;
      -f|--full-ip)
        SHOW_FULL_IP=true
        shift
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
      --no-speedtest)
        RUN_SPEEDTEST=false
        shift
        ;;
      --no-crypto)
        RUN_CRYPTO_BENCH=false
        shift
        ;;
      --io|--disk-bench)
        RUN_DISK_IO=true
        DISK_IO_EXPLICIT=true
        shift
        ;;
      --no-io|--no-disk-bench)
        RUN_DISK_IO=false
        DISK_IO_EXPLICIT=true
        shift
        ;;
      --install-deps)
        INSTALL_DEPS=true
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
      --no-dns)
        RUN_DNS_AUDIT=false
        shift
        ;;
      --no-tg)
        RUN_TG_AUDIT=false
        shift
        ;;
      --no-dpi)
        RUN_DPI_AUDIT=false
        shift
        ;;
      --no-geoblock)
        RUN_GEOBLOCK_AUDIT=false
        shift
        ;;
      *)
        error_exit "Неизвестная опция: $1 (используйте --help для справки)"
        ;;
    esac
  done

  if [[ "$JSON_OUTPUT" == "true" && "$DISK_IO_EXPLICIT" != "true" ]]; then
    RUN_DISK_IO=false
  fi
}

main() {
  MAIN_PID=$$
  export MAIN_PID
  if [[ -t 0 && -t 1 ]] && is_command_available "stty"; then
    INITIAL_STTY=$(stty -g 2>/dev/null || echo "")
  fi
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
  trap 'cleanup; exit 129' HUP
  trap 'cleanup; exit 131' QUIT

  install_dependencies
  check_doh

  # 1. External IP & Node Parameters
  progress_status "Определение внешнего IP"
  discover_external_ips

  if [[ -z "$EXTERNAL_IPV4" && -z "$EXTERNAL_IPV6" ]]; then
    progress_clear
    error_exit "Нет активного подключения к сети или внешний IP не определен."
  fi

  progress_status "Анализ ASN, антифрода и спам-баз (DNSBL / РКН)"
  get_vpn_node_info
  progress_status "Анализ CPU, криптографии, памяти и диска"
  get_system_specs
  progress_clear

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    print_header
  fi

  # 1. 18 GeoIP Databases
  progress_status "Опрос 18 баз GeoIP (параллельно)"
  run_geoip_consensus
  progress_clear

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    print_geoip_table
  fi

  # 2. DNS Resolvers & Telegram MTProto DCs
  if [[ "$RUN_DNS_AUDIT" == "true" || "$RUN_TG_AUDIT" == "true" ]]; then
    progress_status "Аудит DNS-резолверов и дата-центров Telegram (MTProto)"
    run_dns_and_telegram_checks
    progress_clear
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      print_dns_and_telegram_tables
    fi
  fi

  # 3. RU Local Services
  progress_status "Проверка доступности сервисов РФ (Reverse Geoblocking)"
  run_ru_local_services_check
  progress_clear

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    print_ru_local_table
  fi

  # 4. Censorcheck DPI & Sanctioned services
  if [[ "$RUN_DPI_AUDIT" == "true" || "$RUN_GEOBLOCK_AUDIT" == "true" ]]; then
    progress_status "Аудит DPI-фильтрации ТСПУ и санкционных сервисов"
    run_censorcheck_dpi_and_geoblock
    progress_clear
    if [[ "$JSON_OUTPUT" != "true" ]]; then
      print_censorcheck_dpi_table
      print_geoblocked_table
    fi
  fi

  # 5. Western Services & Geolocation
  progress_status "Аудит стримингов и сервисов (определение стран и доступа)"
  run_western_services_check
  progress_clear

  if [[ "$JSON_OUTPUT" != "true" ]]; then
    print_western_unblock_table
  fi

  # 6. Ookla Speedtest (Node Uplink)
  measure_ookla_speedtest

  # 7. Multi-Region Pings & Speedtest (Russian Federation)
  progress_status "Замер задержки RTT (регионы РФ)"
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
