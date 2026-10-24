#!/usr/bin/env bash

# ==============================================================================
# IPRegion (VPN Edition)
# Comprehensive Multi-Source Geolocation, Streaming & VPN Node Quality Auditor
#
# Synthesized & Enhanced from:
#   - vernette/ipregion (Upstream: Architecture, Docker, Gemini, Disney+, Tests)
#   - Davoyan/ipregion  (Fork: DoH, Country Stats, YouTube Music, Prime, Deezer, 2ip)
#
# Enhancements for VPN Node Testing:
#   - IP Node Type (Datacenter/Hosting vs Residential vs Mobile)
#   - Fraud / Abuse Risk Score (0-100)
#   - Google Search Captcha / Unusual Traffic detector
#   - Auto DoH (DNS-over-HTTPS) to prevent ISP DNS poisoning/leakage
#   - socks5h proxy support with remote DNS resolution
#   - Country percentage consensus & comprehensive streaming unblock assessment
# ==============================================================================

set -o pipefail

SCRIPT_VERSION="2.1.0-vpn"

CURL_TIMEOUT=5
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
GROUPS_TO_SHOW="all"
CUSTOM_DOH_PROVIDER=""

EXTERNAL_IPV4=""
EXTERNAL_IPV6=""
IPV4_SUPPORTED=0
IPV6_SUPPORTED=0

NODE_ASN=""
NODE_ORG=""
NODE_TYPE=""
NODE_RISK=""
NODE_RISK_SCORE=0
NODE_RISK_COLOR="NULL"
NODE_CAPTCHA_STATUS=""
NODE_CAPTCHA_COLOR="NULL"

SPOTIFY_API_KEY="142b583129b2df829de3656f9eb484e6"
SPOTIFY_CLIENT_ID="d8a5ed958d274c2e8ee717e6a4b0971d"
NETFLIX_API_KEY="YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm"
CHATGPT_STATSIG_API_KEY="client-zUdXdSTygXJdzoE0sWTkP8GKTVsUMF2IRM7ShVO2JAG"
REDDIT_BASIC_ACCESS_TOKEN="b2hYcG9xclpZdWIxa2c6"
DISNEY_PLUS_API_KEY="ZGlzbmV5JmFuZHJvaWQmMS4wLjA.bkeb0m230uUhv8qrAXuNu39tbE_mD5EEhM_NAcohjyA"
DISNEY_PLUS_JSON_BODY='{"query":"\n     mutation registerDevice($registerDevice: RegisterDeviceInput!) {\n       registerDevice(registerDevice: $registerDevice) {\n         grant {\n           grantType\n         }\n       }\n     }\n   ","variables":{"registerDevice":{"deviceFamily":"android","applicationRuntime":"android","deviceProfile":"tv","attributes":{"operatingSystem":"android","operatingSystemVersion":"9","model":"AFTMM","manufacturer":"Amazon"}}}}'
YOUTUBE_SOCS_COOKIE="CAISNQgDEitib3FfaWRlbnRpdHlmcm9udGVuZHVpc2VydmVyXzIwMjUwNzMwLjA1X3AwGgJlbiACGgYIgPC_xAY"
GEMINI_REGIONS_URL="https://ai.google.dev/gemini-api/docs/available-regions.md.txt"
CLDR_TERRITORIES_URL="https://cdn.jsdelivr.net/npm/cldr-localenames-full/main/en/territories.json"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"

SPINNER_PID=""
SPINNER_SERVICE_FILE=""
DEBUG_LOG_FILE="/tmp/ipregion_debug.log"

COLOR_HEADER="1;36"
COLOR_SERVICE="1;32"
COLOR_HEART="1;31"
COLOR_URL="1;90"
COLOR_ASN="1;33"
COLOR_TABLE_HEADER="1;97"
COLOR_TABLE_VALUE="1"
COLOR_NULL="0;90"
COLOR_ERROR="1;31"
COLOR_WARN="1;33"
COLOR_INFO="1;36"
COLOR_BOLD="1"
COLOR_RESET="0"

LOG_INFO="INFO"
LOG_WARN="WARNING"
LOG_ERROR="ERROR"

STATUS_NA="N/A"
STATUS_DENIED="Denied"
STATUS_RATE_LIMIT="Rate limited"
STATUS_SERVER_ERROR="Server error"

RESULT_JSON=""
ARR_PRIMARY=()
ARR_CUSTOM=()
ARR_CDN=()

# ISO 3166-1 alpha-2 dictionary
declare -A COUNTRY_NAMES=(
  [AF]="Afghanistan" [AX]="Aland Islands" [AL]="Albania" [DZ]="Algeria" [AS]="American Samoa"
  [AD]="Andorra" [AO]="Angola" [AI]="Anguilla" [AQ]="Antarctica" [AG]="Antigua and Barbuda"
  [AR]="Argentina" [AM]="Armenia" [AW]="Aruba" [AU]="Australia" [AT]="Austria"
  [AZ]="Azerbaijan" [BS]="Bahamas" [BH]="Bahrain" [BD]="Bangladesh" [BB]="Barbados"
  [BY]="Belarus" [BE]="Belgium" [BZ]="Belize" [BJ]="Benin" [BM]="Bermuda"
  [BT]="Bhutan" [BO]="Bolivia" [BQ]="Bonaire, Sint Eustatius and Saba" [BA]="Bosnia and Herzegovina" [BW]="Botswana"
  [BV]="Bouvet Island" [BR]="Brazil" [IO]="British Indian Ocean Territory" [BN]="Brunei Darussalam" [BG]="Bulgaria"
  [BF]="Burkina Faso" [BI]="Burundi" [CV]="Cabo Verde" [KH]="Cambodia" [CM]="Cameroon"
  [CA]="Canada" [KY]="Cayman Islands" [CF]="Central African Republic" [TD]="Chad" [CL]="Chile"
  [CN]="China" [CX]="Christmas Island" [CC]="Cocos (Keeling) Islands" [CO]="Colombia" [KM]="Comoros"
  [CG]="Congo" [CD]="Congo (DRC)" [CK]="Cook Islands" [CR]="Costa Rica" [CI]="Cote d'Ivoire"
  [HR]="Croatia" [CU]="Cuba" [CW]="Curacao" [CY]="Cyprus" [CZ]="Czech Republic"
  [DK]="Denmark" [DJ]="Djibouti" [DM]="Dominica" [DO]="Dominican Republic" [EC]="Ecuador"
  [EG]="Egypt" [SV]="El Salvador" [GQ]="Equatorial Guinea" [ER]="Eritrea" [EE]="Estonia"
  [SZ]="Eswatini" [ET]="Ethiopia" [FK]="Falkland Islands" [FO]="Faroe Islands" [FJ]="Fiji"
  [FI]="Finland" [FR]="France" [GF]="French Guiana" [PF]="French Polynesia" [TF]="French Southern Territories"
  [GA]="Gabon" [GM]="Gambia" [GE]="Georgia" [DE]="Germany" [GH]="Ghana"
  [GI]="Gibraltar" [GR]="Greece" [GL]="Greenland" [GD]="Grenada" [GP]="Guadeloupe"
  [GU]="Guam" [GT]="Guatemala" [GG]="Guernsey" [GN]="Guinea" [GW]="Guinea-Bissau"
  [GY]="Guyana" [HT]="Haiti" [HM]="Heard Island and McDonald Islands" [VA]="Vatican City" [HN]="Honduras"
  [HK]="Hong Kong" [HU]="Hungary" [IS]="Iceland" [IN]="India" [ID]="Indonesia"
  [IR]="Iran" [IQ]="Iraq" [IE]="Ireland" [IM]="Isle of Man" [IL]="Israel"
  [IT]="Italy" [JM]="Jamaica" [JP]="Japan" [JE]="Jersey" [JO]="Jordan"
  [KZ]="Kazakhstan" [KE]="Kenya" [KI]="Kiribati" [KP]="North Korea" [KR]="South Korea"
  [KW]="Kuwait" [KG]="Kyrgyzstan" [LA]="Laos" [LV]="Latvia" [LB]="Lebanon"
  [LS]="Lesotho" [LR]="Liberia" [LY]="Libya" [LI]="Liechtenstein" [LT]="Lithuania"
  [LU]="Luxembourg" [MO]="Macao" [MG]="Madagascar" [MW]="Malawi" [MY]="Malaysia"
  [MV]="Maldives" [ML]="Mali" [MT]="Malta" [MH]="Marshall Islands" [MQ]="Martinique"
  [MR]="Mauritania" [MU]="Mauritius" [YT]="Mayotte" [MX]="Mexico" [FM]="Micronesia"
  [MD]="Moldova" [MC]="Monaco" [MN]="Mongolia" [ME]="Montenegro" [MS]="Montserrat"
  [MA]="Morocco" [MZ]="Mozambique" [MM]="Myanmar" [NA]="Namibia" [NR]="Nauru"
  [NP]="Nepal" [NL]="Netherlands" [NC]="New Caledonia" [NZ]="New Zealand" [NI]="Nicaragua"
  [NE]="Niger" [NG]="Nigeria" [NU]="Niue" [NF]="Norfolk Island" [MK]="North Macedonia"
  [MP]="Northern Mariana Islands" [NO]="Norway" [OM]="Oman" [PK]="Pakistan" [PW]="Palau"
  [PS]="Palestine" [PA]="Panama" [PG]="Papua New Guinea" [PY]="Paraguay" [PE]="Peru"
  [PH]="Philippines" [PN]="Pitcairn" [PL]="Poland" [PT]="Portugal" [PR]="Puerto Rico"
  [QA]="Qatar" [RE]="Reunion" [RO]="Romania" [RU]="Russian Federation" [RW]="Rwanda"
  [BL]="Saint Barthelemy" [SH]="Saint Helena" [KN]="Saint Kitts and Nevis" [LC]="Saint Lucia" [MF]="Saint Martin"
  [PM]="Saint Pierre and Miquelon" [VC]="Saint Vincent and Grenadines" [WS]="Samoa" [SM]="San Marino" [ST]="Sao Tome and Principe"
  [SA]="Saudi Arabia" [SN]="Senegal" [RS]="Serbia" [SC]="Seychelles" [SL]="Sierra Leone"
  [SG]="Singapore" [SX]="Sint Maarten" [SK]="Slovakia" [SI]="Slovenia" [SB]="Solomon Islands"
  [SO]="Somalia" [ZA]="South Africa" [GS]="South Georgia" [SS]="South Sudan" [ES]="Spain"
  [LK]="Sri Lanka" [SD]="Sudan" [SR]="Suriname" [SJ]="Svalbard and Jan Mayen" [SE]="Sweden"
  [CH]="Switzerland" [SY]="Syria" [TW]="Taiwan" [TJ]="Tajikistan" [TZ]="Tanzania"
  [TH]="Thailand" [TL]="Timor-Leste" [TG]="Togo" [TK]="Tokelau" [TO]="Tonga"
  [TT]="Trinidad and Tobago" [TN]="Tunisia" [TR]="Turkey" [TM]="Turkmenistan" [TC]="Turks and Caicos Islands"
  [TV]="Tuvalu" [UG]="Uganda" [UA]="Ukraine" [AE]="United Arab Emirates" [GB]="United Kingdom"
  [US]="United States" [UM]="US Minor Outlying Islands" [UY]="Uruguay" [UZ]="Uzbekistan" [VU]="Vanuatu"
  [VE]="Venezuela" [VN]="Vietnam" [VG]="Virgin Islands (British)" [VI]="Virgin Islands (U.S.)" [WF]="Wallis and Futuna"
  [EH]="Western Sahara" [YE]="Yemen" [ZM]="Zambia" [ZW]="Zimbabwe" [XK]="Kosovo"
  [EU]="European Union" [WW]="Worldwide"
)

# 18 Primary GeoIP Databases
declare -A PRIMARY_SERVICES=(
  ["MAXMIND"]="MaxMind|geoip.maxmind.com|https://geoip.maxmind.com/geoip/v2.1/city/me|json"
  ["RIPE"]="RIPE NCC|stat.ripe.net|https://stat.ripe.net/data/whois/data.json?resource=|json"
  ["IPINFO_IO"]="IPinfo.io|ipinfo.io|https://ipinfo.io/json|json"
  ["IPREGISTRY"]="Ipregistry|api.ipregistry.co|https://api.ipregistry.co/?key=tryout|json"
  ["IPAPI_CO"]="IP-API.co|ipapi.co|https://ipapi.co/json|json"
  ["CLOUDFLARE"]="Cloudflare|speed.cloudflare.com|https://speed.cloudflare.com/meta|json"
  ["IP2LOCATION_IO"]="IP2Location.io|api.ip2location.io|https://api.ip2location.io/|json"
  ["IPLOCATION_COM"]="IPLocation.com|api.iplocation.com|https://api.iplocation.net/?ip=|json"
  ["COUNTRY_IS"]="Country.is|api.country.is|https://api.country.is|json"
  ["GEOAPIFY_COM"]="Geoapify|api.geoapify.com|https://api.geoapify.com/v1/ipinfo?apiKey=606555543c7b416ca214e21b777a83d6|json"
  ["GEOJS_IO"]="GeoJS|get.geojs.io|https://get.geojs.io/v1/ip/country.json|json"
  ["IPAPI_IS"]="IPAPI.is|api.ipapi.is|https://api.ipapi.is/?q=|json"
  ["IPBASE_COM"]="ipbase.com|api.ipbase.com|https://api.ipbase.com/v1/json/|json"
  ["IPQUERY_IO"]="ipquery.io|api.ipquery.io|https://api.ipquery.io/|json"
  ["IPWHO_IS"]="ipwho.is|ipwho.is|https://ipwho.is/|json"
  ["IPAPI_COM"]="ip-api.com|pro.ip-api.com|http://pro.ip-api.com/json/?key=free-demo|json"
  ["2IP"]="2ip.io|api.2ip.io|custom"
  ["IFCONFIG_CO"]="ifconfig.co|ifconfig.co|https://ifconfig.co/country-iso|text"
)

# 24 Custom & Web/Streaming Services
declare -A CUSTOM_SERVICES=(
  ["GOOGLE"]="Google"
  ["GOOGLE_SEARCH_CAPTCHA"]="Google Search Captcha"
  ["YOUTUBE"]="YouTube"
  ["YOUTUBE_PREMIUM"]="YouTube Premium"
  ["YOUTUBE_MUSIC"]="YouTube Music"
  ["CHATGPT"]="ChatGPT"
  ["GEMINI_SUPPORTED"]="Gemini Supported"
  ["NETFLIX"]="Netflix"
  ["DISNEY_PLUS"]="Disney+"
  ["DISNEY_PLUS_ACCESS"]="Disney+ Access"
  ["AMAZON_PRIME"]="Amazon Prime"
  ["SPOTIFY"]="Spotify"
  ["SPOTIFY_SIGNUP"]="Spotify Signup"
  ["DEEZER"]="Deezer"
  ["APPLE"]="Apple"
  ["MICROSOFT"]="Microsoft Live"
  ["STEAM"]="Steam"
  ["PLAYSTATION"]="PlayStation"
  ["TIKTOK"]="TikTok"
  ["REDDIT"]="Reddit"
  ["REDDIT_GUEST_ACCESS"]="Reddit Guest Access"
  ["OOKLA_SPEEDTEST"]="Ookla Speedtest"
  ["JETBRAINS"]="JetBrains"
  ["BING"]="Bing"
)

# 3 CDN Services
declare -A CDN_SERVICES=(
  ["CLOUDFLARE_CDN"]="Cloudflare CDN"
  ["YOUTUBE_CDN"]="YouTube CDN"
  ["NETFLIX_CDN"]="Netflix CDN"
)

# Order of services
PRIMARY_SERVICES_ORDER=(
  "MAXMIND" "RIPE" "IPINFO_IO" "IPREGISTRY" "IPAPI_CO" "CLOUDFLARE"
  "IP2LOCATION_IO" "IPLOCATION_COM" "COUNTRY_IS" "GEOJS_IO"
  "IPAPI_IS" "IPBASE_COM" "IPQUERY_IO" "IPWHO_IS" "IPAPI_COM" "2IP" "IFCONFIG_CO"
)

CUSTOM_SERVICES_ORDER=(
  "GOOGLE" "GOOGLE_SEARCH_CAPTCHA" "YOUTUBE" "YOUTUBE_PREMIUM" "YOUTUBE_MUSIC"
  "CHATGPT" "GEMINI_SUPPORTED" "NETFLIX" "DISNEY_PLUS" "DISNEY_PLUS_ACCESS"
  "AMAZON_PRIME" "SPOTIFY" "SPOTIFY_SIGNUP" "DEEZER" "APPLE" "MICROSOFT"
  "STEAM" "PLAYSTATION" "TIKTOK" "REDDIT" "REDDIT_GUEST_ACCESS"
  "OOKLA_SPEEDTEST" "JETBRAINS" "BING"
)

CDN_SERVICES_ORDER=(
  "CLOUDFLARE_CDN" "YOUTUBE_CDN" "NETFLIX_CDN"
)

IPV6_OVER_IPV4_SERVICES=(
  "IPINFO_IO" "IPAPI_IS" "IPLOCATION_COM" "IPWHO_IS" "IPAPI_COM" "2IP"
)

GEMINI_MATCH_FILTER=$(
  cat <<'EOF'
def stopwords: ["the", "of", "and", "republic", "island", "islands", "saint", "st"];
def words:
  ascii_downcase
  | [splits("[^\\p{L}]+")]
  | map(select(. != "" and (IN(stopwords[]) | not)))
  | unique;
def gemini_regions:
  $md | split("\n") | map(select(startswith("- ")) | .[2:] | words);
def cldr_names:
  $cldr_raw | try fromjson catch {}
  | .main.en.localeDisplayNames.territories // {}
  | to_entries | map(select(.key | startswith($code)) | .value);
gemini_regions as $supported
| cldr_names + [$api_name]
| map(words)
| any(IN($supported[]))
EOF
)

# Colors and formatting
color() {
  local color_name="$1" text="$2" code
  case "$color_name" in
    HEADER) code="$COLOR_HEADER" ;;
    SERVICE) code="$COLOR_SERVICE" ;;
    HEART) code="$COLOR_HEART" ;;
    URL) code="$COLOR_URL" ;;
    ASN) code="$COLOR_ASN" ;;
    TABLE_HEADER) code="$COLOR_TABLE_HEADER" ;;
    TABLE_VALUE) code="$COLOR_TABLE_VALUE" ;;
    NULL) code="$COLOR_NULL" ;;
    ERROR) code="$COLOR_ERROR" ;;
    WARN) code="$COLOR_WARN" ;;
    INFO) code="$COLOR_INFO" ;;
    BOLD) code="$COLOR_BOLD" ;;
    *) code="$COLOR_RESET" ;;
  esac
  printf "\033[%sm%s\033[%sm" "$code" "$text" "$COLOR_RESET"
}

bold() { printf "\033[%sm%s\033[%sm" "$COLOR_BOLD" "$1" "$COLOR_RESET"; }

format_value() {
  local value="$1"
  case "$value" in
    Yes) color SERVICE "$value" ;;
    No) color HEART "$value" ;;
    "$STATUS_NA" | "null") color NULL "N/A" ;;
    "$STATUS_DENIED" | "$STATUS_SERVER_ERROR" | "$STATUS_RATE_LIMIT") color ERROR "$value" ;;
    *) color TABLE_VALUE "$value" ;;
  esac
}

print_value_or_colored() {
  local value="$1" color_name="$2"
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    printf "%s" "$value"
  else
    color "$color_name" "$value"
  fi
}

log() {
  local level="$1" msg="$2"
  if [[ "$VERBOSE" == "true" || "$DEBUG" == "true" ]]; then
    printf "[%s] %s\n" "$level" "$msg" >&2
  fi
}

error_exit() {
  printf "\033[%sm%s: %s\033[%sm\n" "$COLOR_ERROR" "Error" "$1" "$COLOR_RESET" >&2
  spinner_cleanup
  exit 1
}

process_json() {
  local json="$1" query="$2"
  jq -r "$query // empty" 2>/dev/null <<<"$json"
}

is_valid_json() {
  jq empty 2>/dev/null <<<"$1"
}

is_status_string() {
  case "$1" in
    "$STATUS_DENIED" | "$STATUS_SERVER_ERROR" | "$STATUS_RATE_LIMIT" | "$STATUS_NA") return 0 ;;
    *) return 1 ;;
  esac
}

status_from_http_code() {
  case "$1" in
    403) printf "%s" "$STATUS_DENIED" ;;
    429) printf "%s" "$STATUS_RATE_LIMIT" ;;
    5*)  printf "%s" "$STATUS_SERVER_ERROR" ;;
    *)   printf "%s" "$STATUS_NA" ;;
  esac
}

grep_wrapper() {
  local grep_args=()
  if [[ "$1" == "--perl" ]]; then
    grep_args+=("-oP")
    shift
  fi
  grep "${grep_args[@]}" "$@"
}

# ------------------------------------------------------------------------------
# DNS & DoH Resolution Setup
# ------------------------------------------------------------------------------
check_doh() {
  if [[ "$USE_DOH" != "true" || -n "$PROXY_ADDR" ]]; then
    SELECTED_DOH_URL=""
    return 0
  fi

  local test_domain="www.google.com"
  local resolvers=(
    "Cloudflare|https://1.1.1.1/dns-query"
    "Quad9|https://9.9.9.9/dns-query"
    "AdGuard|https://94.140.14.140/dns-query"
    "OpenDNS|https://208.67.222.222/dns-query"
  )

  if [[ -n "$CUSTOM_DOH_PROVIDER" ]]; then
    case "${CUSTOM_DOH_PROVIDER,,}" in
      cloudflare) resolvers=("Cloudflare|https://1.1.1.1/dns-query") ;;
      quad9)      resolvers=("Quad9|https://9.9.9.9/dns-query") ;;
      adguard)    resolvers=("AdGuard|https://94.140.14.140/dns-query") ;;
      opendns)    resolvers=("OpenDNS|https://208.67.222.222/dns-query") ;;
      http*)      resolvers=("Custom|$CUSTOM_DOH_PROVIDER") ;;
    esac
  fi

  local curl_opts=(-s --max-time 4 --connect-timeout 2 -o /dev/null)
  local entry name doh_url

  for entry in "${resolvers[@]}"; do
    IFS="|" read -r name doh_url <<<"$entry"
    if curl "${curl_opts[@]}" --doh-url "$doh_url" "https://$test_domain/" 2>/dev/null; then
      SELECTED_DOH_URL="--doh-url ${doh_url}"
      log "$LOG_INFO" "Selected DoH resolver: $name ($doh_url)"
      return 0
    fi
  done

  log "$LOG_WARN" "DoH checks failed; falling back to system DNS"
  SELECTED_DOH_URL=""
  return 1
}

# ------------------------------------------------------------------------------
# Unified Curl Request Wrapper
# ------------------------------------------------------------------------------
curl_wrapper() {
  local method="$1" url="$2"
  shift 2

  local ip_version="" user_agent="" json="" data="" file=""
  local forms=() headers=() response_with_code response http_code
  local custom_timeout="$CURL_TIMEOUT"

  local curl_args=(
    --silent
    --compressed
    --location
    --retry-connrefused
    --retry "$CURL_RETRIES"
    -w '\n%{http_code}'
  )

  case "$method" in
    HEAD) curl_args+=(--head) ;;
    *)    curl_args+=(--request "$method") ;;
  esac

  while (($#)); do
    case "$1" in
      --ip-version)  ip_version="$2"; shift 2 ;;
      --user-agent)  user_agent="$2"; shift 2 ;;
      --header)      headers+=("$2"); shift 2 ;;
      --json)        json="$2"; shift 2 ;;
      --data)        data="$2"; shift 2 ;;
      --file)        file="$2"; shift 2 ;;
      --form)        forms+=("$2"); shift 2 ;;
      --timeout)     custom_timeout="$2"; shift 2 ;;
      *)             shift ;;
    esac
  done

  curl_args+=(--max-time "$custom_timeout")

  if [[ "$ip_version" == "4" ]]; then
    curl_args+=(-4)
  elif [[ "$ip_version" == "6" ]]; then
    curl_args+=(-6)
  fi

  for h in "${headers[@]}"; do
    curl_args+=(-H "$h")
  done

  if [[ -n "$user_agent" ]]; then
    curl_args+=(-A "$user_agent")
  fi

  if [[ -n "$json" ]]; then
    curl_args+=(--json "$json")
  fi

  if [[ -n "$data" ]]; then
    curl_args+=(--data "$data")
  fi

  if [[ -n "$file" ]]; then
    curl_args+=(--upload-file "$file")
  fi

  for f in "${forms[@]}"; do
    curl_args+=(-F "$f")
  done

  if [[ -n "$PROXY_ADDR" ]]; then
    # socks5h resolves DNS on proxy server side
    curl_args+=(--proxy "socks5h://$PROXY_ADDR")
  elif [[ -n "$SELECTED_DOH_URL" ]]; then
    # Inject DoH when direct connection
    curl_args+=($SELECTED_DOH_URL)
  fi

  if [[ -n "$INTERFACE_NAME" ]]; then
    curl_args+=(--interface "$INTERFACE_NAME")
  fi

  curl_args+=("$url")

  response_with_code=$(curl "${curl_args[@]}" 2>/dev/null)
  http_code=$(tail -n1 <<<"$response_with_code")
  response=$(head -n -1 <<<"$response_with_code")

  if [[ "$http_code" == 4* || "$http_code" == 5* ]]; then
    status_from_http_code "$http_code"
    return 0
  fi

  echo "$response"
}

# ------------------------------------------------------------------------------
# Dependency Management
# ------------------------------------------------------------------------------
is_command_available() { command -v "$1" >/dev/null 2>&1; }

detect_distro() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="$ID"
    DISTRO_LIKE="$ID_LIKE"
  elif is_command_available sw_vers; then
    DISTRO_ID="macos"
  else
    DISTRO_ID="unknown"
  fi
}

detect_package_manager() {
  local managers=("apt-get" "apt" "dnf" "yum" "pacman" "apk" "zypper" "brew")
  for pm in "${managers[@]}"; do
    if is_command_available "$pm"; then
      PACKAGE_MANAGER="$pm"
      return 0
    fi
  done
  PACKAGE_MANAGER=""
}

get_missing_commands() {
  local required=("curl" "jq")
  local missing=()
  for cmd in "${required[@]}"; do
    if ! is_command_available "$cmd"; then
      missing+=("$cmd")
    fi
  done
  if ! is_command_available column; then
    missing+=("column")
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf "%s\n" "${missing[@]}"
  fi
}

install_dependencies() {
  local missing_cmds=()
  while IFS= read -r cmd; do
    [[ -n "$cmd" ]] && missing_cmds+=("$cmd")
  done < <(get_missing_commands)

  if [[ ${#missing_cmds[@]} -eq 0 ]]; then
    return 0
  fi

  detect_distro
  detect_package_manager

  if [[ -z "$PACKAGE_MANAGER" ]]; then
    error_exit "Missing dependencies: ${missing_cmds[*]}. Please install them manually."
  fi

  log "$LOG_INFO" "Installing missing dependencies: ${missing_cmds[*]}"
  local sudo_cmd=""
  if [[ $EUID -ne 0 ]] && is_command_available sudo; then
    sudo_cmd="sudo"
  fi

  case "$PACKAGE_MANAGER" in
    apt-get|apt)
      export DEBIAN_FRONTEND=noninteractive
      $sudo_cmd "$PACKAGE_MANAGER" update -y -qq >/dev/null 2>&1
      local pkgs=()
      for c in "${missing_cmds[@]}"; do
        case "$c" in
          column)
            # Ubuntu 24.04 (Noble) uses bsdextrautils, older releases use bsdmainutils
            if ! $sudo_cmd "$PACKAGE_MANAGER" install -y -qq bsdextrautils >/dev/null 2>&1; then
              $sudo_cmd "$PACKAGE_MANAGER" install -y -qq bsdmainutils >/dev/null 2>&1 || true
            fi
            ;;
          *) pkgs+=("$c") ;;
        esac
      done
      if [[ ${#pkgs[@]} -gt 0 ]]; then
        $sudo_cmd "$PACKAGE_MANAGER" install -y -qq --no-install-recommends "${pkgs[@]}" >/dev/null 2>&1
      fi
      ;;
    dnf|yum)
      $sudo_cmd "$PACKAGE_MANAGER" install -y -q "${missing_cmds[@]}" util-linux >/dev/null 2>&1
      ;;
    pacman)
      $sudo_cmd pacman -Sy --noconfirm "${missing_cmds[@]}" util-linux >/dev/null 2>&1
      ;;
    apk)
      $sudo_cmd apk add --no-cache "${missing_cmds[@]}" util-linux >/dev/null 2>&1
      ;;
    brew)
      brew install "${missing_cmds[@]}" >/dev/null 2>&1
      ;;
  esac
}

# ------------------------------------------------------------------------------
# IP Connectivity & Node Detection
# ------------------------------------------------------------------------------
fetch_ip_from_service() {
  local ip_version="$1" service="$2"
  local url="https://$service"
  curl_wrapper GET "$url" --ip-version "$ip_version" --timeout 4 2>/dev/null
}

discover_external_ips() {
  local services=(
    "api64.ipify.org"
    "icanhazip.com"
    "ifconfig.me"
    "ipinfo.io/ip"
  )

  if [[ "$IPV6_ONLY" != "true" ]]; then
    for s in "${services[@]}"; do
      EXTERNAL_IPV4=$(fetch_ip_from_service 4 "$s")
      if [[ "$EXTERNAL_IPV4" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        IPV4_SUPPORTED=0
        break
      fi
    done
  fi

  if [[ "$IPV4_ONLY" != "true" ]]; then
    for s in "${services[@]}"; do
      EXTERNAL_IPV6=$(fetch_ip_from_service 6 "$s")
      if [[ "$EXTERNAL_IPV6" =~ : ]]; then
        IPV6_SUPPORTED=0
        break
      fi
    done
  fi
}

can_use_ipv4() {
  [[ "$IPV6_ONLY" != "true" && -n "$EXTERNAL_IPV4" ]]
}

can_use_ipv6() {
  [[ "$IPV4_ONLY" != "true" && -n "$EXTERNAL_IPV6" ]]
}

# ------------------------------------------------------------------------------
# VPN Node Audit & Fraud Score Extraction
# ------------------------------------------------------------------------------
get_vpn_node_info() {
  local ip ip_version response
  if can_use_ipv4; then
    ip="$EXTERNAL_IPV4"
    ip_version=4
  elif can_use_ipv6; then
    ip="$EXTERNAL_IPV6"
    ip_version=6
  else
    return 1
  fi

  spinner_update "Auditing VPN Node & Risk..."

  # Query ipquery.io for ISP & Risk
  response=$(curl_wrapper GET "https://api.ipquery.io/$ip" --ip-version "$ip_version" --timeout 5 2>/dev/null)
  
  NODE_ASN=$(process_json "$response" ".isp.asn")
  NODE_ORG=$(process_json "$response" ".isp.org")
  local is_datacenter is_vpn is_proxy is_mobile risk_score
  is_datacenter=$(process_json "$response" ".risk.is_datacenter")
  is_vpn=$(process_json "$response" ".risk.is_vpn")
  is_proxy=$(process_json "$response" ".risk.is_proxy")
  is_mobile=$(process_json "$response" ".risk.is_mobile")
  risk_score=$(process_json "$response" ".risk.risk_score")

  # Fallback 1: ipinfo.io
  if [[ -z "$NODE_ASN" || "$NODE_ASN" == "null" ]]; then
    response=$(curl_wrapper GET "https://ipinfo.io/$ip/json" --ip-version "$ip_version" --timeout 4 2>/dev/null)
    local org=$(process_json "$response" ".org")
    NODE_ASN=$(echo "$org" | awk '{print $1}')
    NODE_ORG=$(echo "$org" | cut -d' ' -f2-)
  fi

  # Fallback 2: ipwho.is
  if [[ -z "$NODE_ASN" || "$NODE_ASN" == "null" ]]; then
    response=$(curl_wrapper GET "https://ipwho.is/$ip" --ip-version "$ip_version" --timeout 4 2>/dev/null)
    NODE_ASN=$(process_json "$response" ".connection.asn")
    [[ -n "$NODE_ASN" && "$NODE_ASN" != "null" ]] && NODE_ASN="AS$NODE_ASN"
    NODE_ORG=$(process_json "$response" ".connection.org")
  fi

  # Fallback 3: 2ip.io
  if [[ -z "$NODE_ASN" || "$NODE_ASN" == "null" ]]; then
    response=$(curl_wrapper GET "https://api.2ip.io" --ip-version "$ip_version" --data "ip=$ip" --timeout 4 2>/dev/null)
    local as_id=$(process_json "$response" ".asn.id")
    [[ -n "$as_id" && "$as_id" != "null" ]] && NODE_ASN="AS$as_id"
    NODE_ORG=$(process_json "$response" ".asn.name")
    local is_hosting=$(process_json "$response" ".asn.hosting")
    if [[ "$is_hosting" == "true" ]]; then is_datacenter="true"; fi
  fi

  # Node classification
  if [[ "$is_datacenter" == "true" ]]; then
    NODE_TYPE="Datacenter / Hosting"
  elif [[ "$is_mobile" == "true" ]]; then
    NODE_TYPE="Mobile / Cellular"
  elif [[ "$is_vpn" == "true" || "$is_proxy" == "true" ]]; then
    NODE_TYPE="Proxy / VPN Exit"
  elif [[ -n "$risk_score" && "$risk_score" != "null" ]]; then
    NODE_TYPE="Residential / ISP"
  else
    NODE_TYPE="Hosting / Transit"
  fi

  # Risk / Fraud score
  if [[ -n "$risk_score" && "$risk_score" != "null" && "$risk_score" =~ ^[0-9]+$ ]]; then
    NODE_RISK_SCORE="$risk_score"
    if [[ "$risk_score" -le 25 ]]; then
      NODE_RISK="$risk_score/100 (Low Risk / Clean)"
      NODE_RISK_COLOR="SERVICE"
    elif [[ "$risk_score" -le 60 ]]; then
      NODE_RISK="$risk_score/100 (Moderate Risk)"
      NODE_RISK_COLOR="WARN"
    else
      NODE_RISK="$risk_score/100 (High Risk / Flagged)"
      NODE_RISK_COLOR="HEART"
    fi
  else
    NODE_RISK="N/A"
    NODE_RISK_COLOR="NULL"
  fi
}

# ------------------------------------------------------------------------------
# Airport IATA Resolver
# ------------------------------------------------------------------------------
get_iata_location() {
  local iata_code="$1"
  local url="https://www.air-port-codes.com/api/v1/single"
  local payload="iata=$iata_code"
  local apc_auth="96dc04b3fb"
  local referer="https://www.air-port-codes.com/"
  local response

  response=$(curl_wrapper POST "$url" \
    --header "APC-Auth: $apc_auth" \
    --header "Referer: $referer" \
    --data "$payload" \
    --ip-version "4" --timeout 4 2>/dev/null)

  process_json "$response" ".airport.country.iso"
}

# ------------------------------------------------------------------------------
# Primary GeoIP Lookups
# ------------------------------------------------------------------------------
is_ipv6_over_ipv4_service() {
  local service="$1"
  for s in "${IPV6_OVER_IPV4_SERVICES[@]}"; do
    if [[ "$s" == "$service" ]]; then return 0; fi
  done
  return 1
}

service_build_request() {
  local service="$1" ip="$2" ip_version="$3"
  local cfg="${PRIMARY_SERVICES[$service]}"
  local display_name domain url_template response_format url headers_str

  IFS='|' read -r display_name domain url_template response_format <<<"$cfg"
  display_name="${display_name:-$service}"

  case "$service" in
    RIPE)
      url="${url_template}${ip}"
      ;;
    MAXMIND)
      url="$url_template"
      headers_str="Referer: https://www.maxmind.com"
      ;;
    CLOUDFLARE)
      url="$url_template"
      headers_str="Referer: https://speed.cloudflare.com"
      ;;
    IPLOCATION_COM)
      url="${url_template}${ip}"
      ;;
    IPAPI_IS|IPQUERY_IO)
      url="${url_template}${ip}"
      ;;
    2IP)
      url="https://api.2ip.io"
      ;;
    *)
      url="$url_template"
      ;;
  esac

  printf "%s\n%s\n%s\n%s" "$display_name" "$url" "${response_format:-json}" "$headers_str"
}

normalize_country_code() {
  local val="$1"
  if [[ ${#val} -eq 2 ]]; then
    echo "${val^^}"
    return
  fi
  for code in "${!COUNTRY_NAMES[@]}"; do
    if [[ "${COUNTRY_NAMES[$code],,}" == "${val,,}" ]]; then
      echo "$code"
      return
    fi
  done
  echo "$val"
}

process_response() {
  local service="$1" response="$2" display_name="$3" response_format="$4"

  if [[ -z "$response" ]]; then
    printf ""
    return
  fi

  if is_status_string "$response"; then
    printf "%s" "$response"
    return
  fi

  if [[ "$response_format" == "json" ]]; then
    if ! is_valid_json "$response"; then
      printf ""
      return
    fi
  fi

  case "$service" in
    MAXMIND)        process_json "$response" ".country.iso_code" ;;
    RIPE)           process_json "$response" "[(.data.records[][] | select(.key | ascii_downcase == \"country\") | .value)][0]" ;;
    IPINFO_IO)      process_json "$response" ".country" ;;
    IPREGISTRY)     process_json "$response" ".location.country.code" ;;
    IPAPI_CO)       process_json "$response" ".country_code" ;;
    CLOUDFLARE)     process_json "$response" ".country" ;;
    IP2LOCATION_IO) process_json "$response" ".country_code" ;;
    IPLOCATION_COM) process_json "$response" ".country_code2" ;;
    COUNTRY_IS)     process_json "$response" ".country" ;;
    GEOAPIFY_COM)   process_json "$response" ".country.iso_code" ;;
    GEOJS_IO)       process_json "$response" ".country" ;;
    IPAPI_IS)       local c=$(process_json "$response" ".country_code // .country"); normalize_country_code "$c" ;;
    IPBASE_COM)     process_json "$response" ".country_code" ;;
    IPQUERY_IO)     process_json "$response" ".location.country_code" ;;
    IPWHO_IS)       process_json "$response" ".country_code" ;;
    IPAPI_COM)      process_json "$response" ".countryCode" ;;
    2IP)            process_json "$response" ".code" ;;
    IFCONFIG_CO)    tr -d ' \n\r' <<<"$response" ;;
    *)              printf "%s" "$response" ;;
  esac
}

lookup_2ip() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://api.2ip.io" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  process_json "$response" ".code"
}

# ------------------------------------------------------------------------------
# Web & Streaming Lookup Implementations
# ------------------------------------------------------------------------------
lookup_google() {
  local ip_version="$1" response result
  response=$(curl_wrapper GET "https://accounts.google.com/v3/signin/identifier?flowName=GlifSetupAndroid" \
    --user-agent "$USER_AGENT" --ip-version "$ip_version" 2>/dev/null)

  result=$(sed -n 's/.*name="region" value="\([^"]*\)".*/\1/p' <<<"$response" | head -n1)

  # Fallback 1: www.google.com
  if [[ -z "$result" ]]; then
    response=$(curl_wrapper GET "https://www.google.com" --user-agent "$USER_AGENT" --ip-version "$ip_version" 2>/dev/null)
    result=$(sed -n 's/.*"[a-z]\{2\}_\([A-Z]\{2\}\)".*/\1/p' <<<"$response" | head -n1)
    if [[ -z "$result" ]]; then
      result=$(sed -n 's/.*"[a-z]\{2\}-\([A-Z]\{2\}\)".*/\1/p' <<<"$response" | tail -n1)
    fi
  fi

  echo "$result"
}

lookup_google_search_captcha() {
  local ip_version="$1" response is_captcha color_name

  response=$(curl_wrapper GET "https://www.google.com/search?q=cats" --ip-version "$ip_version" \
    --user-agent "$USER_AGENT" --header "Accept-Language: en-US,en;q=0.9" 2>/dev/null)

  if [[ -z "$response" ]]; then
    echo ""
    return
  fi

  is_captcha=$(grep_wrapper -iE "unusual traffic from|is blocked|unaddressed abuse|systems have detected unusual traffic" <<<"$response")

  if [[ -z "$is_captcha" ]]; then
    is_captcha="No"
    color_name="SERVICE"
    NODE_CAPTCHA_STATUS="No"
    NODE_CAPTCHA_COLOR="SERVICE"
  else
    is_captcha="Yes"
    color_name="HEART"
    NODE_CAPTCHA_STATUS="Yes"
    NODE_CAPTCHA_COLOR="HEART"
  fi

  print_value_or_colored "$is_captcha" "$color_name"
}

lookup_youtube() {
  local ip_version="$1" response json_result result

  # Method 1: sw.js_data
  response=$(curl_wrapper GET "https://www.youtube.com/sw.js_data" --ip-version "$ip_version" 2>/dev/null)
  json_result=$(tail -n +3 <<<"$response")
  result=$(process_json "$json_result" ".[0][2][0][0][1]")

  # Method 2: youtube.com page
  if [[ -z "$result" || "$result" == "null" ]]; then
    response=$(curl_wrapper GET "https://www.youtube.com" --user-agent "$USER_AGENT" --ip-version "$ip_version" 2>/dev/null)
    result=$(sed -n 's/.*"countryCode":"\([^"]*\)".*/\1/p' <<<"$response" | head -n1)
  fi

  echo "$result"
}

lookup_youtube_premium() {
  local ip_version="$1" response is_not_avail available color_name

  response=$(curl_wrapper GET "https://www.youtube.com/premium" \
    --ip-version "$ip_version" \
    --user-agent "$USER_AGENT" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9" 2>/dev/null)

  if [[ -z "$response" ]]; then
    echo ""
    return
  fi

  is_not_avail=$(grep_wrapper -io "YouTube Premium is not available in your country" <<<"$response")

  if [[ -z "$is_not_avail" ]]; then
    available="Yes"
    color_name="SERVICE"
  else
    available="No"
    color_name="HEART"
  fi

  print_value_or_colored "$available" "$color_name"
}

lookup_youtube_music() {
  local ip_version="$1" response is_not_avail available color_name

  response=$(curl_wrapper GET "https://music.youtube.com/" \
    --ip-version "$ip_version" \
    --user-agent "$USER_AGENT" \
    --header "Cookie: SOCS=$YOUTUBE_SOCS_COOKIE" \
    --header "Accept-Language: en-US,en;q=0.9" 2>/dev/null)

  if [[ -z "$response" ]]; then
    echo ""
    return
  fi

  is_not_avail=$(grep_wrapper -io "YouTube Music is not available in your area" <<<"$response")

  if [[ -z "$is_not_avail" ]]; then
    available="Yes"
    color_name="SERVICE"
  else
    available="No"
    color_name="HEART"
  fi

  print_value_or_colored "$available" "$color_name"
}

lookup_chatgpt() {
  local ip_version="$1" response
  response=$(curl_wrapper POST "https://ab.chatgpt.com/v1/initialize" --ip-version "$ip_version" \
    --header "Statsig-Api-Key: $CHATGPT_STATSIG_API_KEY" --header "Content-Type: application/json" --data '{}' 2>/dev/null)
  process_json "$response" ".derived_fields.country"
}

lookup_gemini_supported() {
  local ip_version="$1" country_code api_name territories regions_md available color_name

  country_code=$(lookup_google "$ip_version")
  if [[ -z "$country_code" ]]; then
    echo ""
    return
  fi

  regions_md=$(curl_wrapper GET "$GEMINI_REGIONS_URL" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  if [[ -z "$regions_md" ]] || is_status_string "$regions_md"; then
    echo ""
    return
  fi

  territories=$(curl_wrapper GET "$CLDR_TERRITORIES_URL" --ip-version "4" --timeout 4 2>/dev/null)
  api_name=$(curl_wrapper GET "https://restcountries.com/v3.1/alpha/${country_code}" --ip-version "4" --timeout 4 2>/dev/null)
  api_name=$(process_json "$api_name" ".[0].name.common" 2>/dev/null)

  if jq -en \
    --arg code "$country_code" \
    --arg md "$regions_md" \
    --arg cldr_raw "$territories" \
    --arg api_name "$api_name" \
    "$GEMINI_MATCH_FILTER" >/dev/null 2>&1; then
    available="Yes"
    color_name="SERVICE"
  else
    available="No"
    color_name="HEART"
  fi

  print_value_or_colored "$available" "$color_name"
}

lookup_netflix() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://api.fast.com/netflix/speedtest/v2?https=true&token=$NETFLIX_API_KEY&urlCount=1" \
    --ip-version "$ip_version" --timeout 5 2>/dev/null)

  if is_valid_json "$response"; then
    process_json "$response" ".client.location.country"
  else
    echo ""
  fi
}

lookup_disney_plus() {
  local ip_version="$1" response
  response=$(curl_wrapper POST "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" \
    --header "Authorization: Bearer $DISNEY_PLUS_API_KEY" \
    --header "Content-Type: application/json" \
    --data "$DISNEY_PLUS_JSON_BODY" \
    --ip-version "$ip_version" --timeout 5 2>/dev/null)

  process_json "$response" ".extensions.sdk.session.location.countryCode"
}

lookup_disney_plus_access() {
  local ip_version="$1" response errors_count in_supported_location available color_name
  response=$(curl_wrapper POST "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" \
    --header "Authorization: Bearer $DISNEY_PLUS_API_KEY" \
    --header "Content-Type: application/json" \
    --data "$DISNEY_PLUS_JSON_BODY" \
    --ip-version "$ip_version" --timeout 5 2>/dev/null)

  errors_count=$(process_json "$response" ".errors | length")
  in_supported_location=$(process_json "$response" ".extensions.sdk.session.inSupportedLocation")

  if [[ "$errors_count" == "0" && "$in_supported_location" == "true" ]]; then
    available="Yes"
    color_name="SERVICE"
  else
    available="No"
    color_name="HEART"
  fi

  print_value_or_colored "$available" "$color_name"
}

lookup_amazon_prime() {
  local ip_version="$1" response region is_blocked
  response=$(curl_wrapper GET "https://www.primevideo.com" \
    --user-agent "$USER_AGENT" --header "Accept-Language: en-US,en;q=0.9" \
    --ip-version "$ip_version" --timeout 5 2>/dev/null)

  is_blocked=$(grep_wrapper -i "isServiceRestricted" <<<"$response")
  region=$(sed -n 's/.*"currentTerritory":"\([^"]*\)".*/\1/p' <<<"$response" | head -n1)

  if [[ -n "$is_blocked" ]]; then
    print_value_or_colored "No" "HEART"
  elif [[ -n "$region" ]]; then
    echo "${region:0:2}"
  else
    echo ""
  fi
}

lookup_spotify() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://spclient.wg.spotify.com/signup/public/v1/account/?validate=1&key=$SPOTIFY_API_KEY" \
    --header "X-Client-Id: $SPOTIFY_CLIENT_ID" --ip-version "$ip_version" --timeout 4 2>/dev/null)

  local cc=$(process_json "$response" ".country")
  if [[ -z "$cc" || "$cc" == "null" ]]; then
    response=$(curl_wrapper GET "https://accounts.spotify.com/status" --ip-version "$ip_version" --timeout 4 2>/dev/null)
    cc=$(sed -n 's/.*"geoLocationCountryCode":"\([^"]*\)".*/\1/p' <<<"$response")
  fi

  echo "$cc"
}

lookup_spotify_signup() {
  local ip_version="$1" response status is_launched available color_name
  response=$(curl_wrapper GET "https://spclient.wg.spotify.com/signup/public/v1/account/?validate=1&key=$SPOTIFY_API_KEY" \
    --header "X-Client-Id: $SPOTIFY_CLIENT_ID" --ip-version "$ip_version" --timeout 4 2>/dev/null)

  status=$(process_json "$response" ".status")
  is_launched=$(process_json "$response" ".is_country_launched")

  if [[ "$status" == "120" || "$status" == "320" || "$is_launched" == "false" ]]; then
    available="No"
    color_name="HEART"
  else
    available="Yes"
    color_name="SERVICE"
  fi

  print_value_or_colored "$available" "$color_name"
}

lookup_deezer() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://www.deezer.com/en/offers" --user-agent "$USER_AGENT" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  sed -n "s/.*'country': '\(.*\)'.*/\1/p" <<<"$response"
}

lookup_apple() {
  local ip_version="$1"
  curl_wrapper GET "https://gspe1-ssl.ls.apple.com/pep/gcc" --ip-version "$ip_version" --timeout 4 2>/dev/null
}

lookup_microsoft() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://login.live.com" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  sed -n 's/.*"sRequestCountry":"\([^"]*\)".*/\1/p' <<<"$response" | head -n1
}

lookup_steam() {
  local ip_version="$1" response
  response=$(curl_wrapper HEAD "https://store.steampowered.com" --user-agent "$USER_AGENT" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  sed -n 's/.*steamCountry=\([^%;]*\).*/\1/p' <<<"$response" | head -n1
}

lookup_playstation() {
  local ip_version="$1" response
  response=$(curl_wrapper HEAD "https://www.playstation.com" --user-agent "$USER_AGENT" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  sed -n 's/.*country=\([^;]*\).*/\1/p' <<<"$response" | head -n1
}

lookup_tiktok() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://www.tiktok.com/api/v1/web-cookie-privacy/config?appId=1988" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  process_json "$response" ".body.appProps.region"
}

lookup_reddit() {
  local ip_version="$1" user_agent="Reddit/Version 2025.29.0/Build 2529021/Android 13"
  local response access_token

  response=$(curl_wrapper POST "https://www.reddit.com/auth/v2/oauth/access-token/loid" \
    --ip-version "$ip_version" \
    --user-agent "$user_agent" \
    --header "Authorization: Basic $REDDIT_BASIC_ACCESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{"scopes":["email"]}' --timeout 4 2>/dev/null)

  access_token=$(process_json "$response" ".access_token")
  if [[ -z "$access_token" || "$access_token" == "null" ]]; then
    echo ""
    return
  fi

  response=$(curl_wrapper POST "https://gql-fed.reddit.com" \
    --ip-version "$ip_version" \
    --user-agent "$user_agent" \
    --header "Authorization: Bearer $access_token" \
    --header "Content-Type: application/json" \
    --data '{"operationName":"UserLocation","variables":{},"extensions":{"persistedQuery":{"version":1,"sha256Hash":"f07de258c54537e24d7856080f662c1b1268210251e5789c8c08f20d76cc8ab2"}}}' \
    --timeout 4 2>/dev/null)

  process_json "$response" ".data.userLocation.countryCode"
}

lookup_reddit_guest_access() {
  local ip_version="$1" response is_blocked available color_name
  response=$(curl_wrapper GET "https://www.reddit.com" --user-agent "$USER_AGENT" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  is_blocked=$(grep_wrapper -iE "blocked by network security|unusual traffic" <<<"$response")

  if [[ -n "$is_blocked" ]]; then
    available="No"
    color_name="HEART"
  else
    available="Yes"
    color_name="SERVICE"
  fi

  print_value_or_colored "$available" "$color_name"
}

lookup_ookla_speedtest() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://www.speedtest.net/api/js/config-sdk" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  process_json "$response" ".customer.country"
}

lookup_jetbrains() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://www.jetbrains.com/shop/customer/location" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  process_json "$response" ".countryCode"
}

lookup_bing() {
  local ip_version="$1" response is_cn region
  response=$(curl_wrapper GET "https://www.bing.com/search?q=cats" --user-agent "$USER_AGENT" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  is_cn=$(grep -i 'cn.bing.com' <<<"$response")
  region=$(sed -n 's/.*Region:"\([^"]*\)".*/\1/p' <<<"$response" | head -n1)

  if [[ -n "$is_cn" ]]; then
    echo "CN"
  elif [[ -n "$region" ]]; then
    echo "$region"
  else
    echo ""
  fi
}

# ------------------------------------------------------------------------------
# CDN Lookups
# ------------------------------------------------------------------------------
lookup_cloudflare_cdn() {
  local ip_version="$1" response iata location
  response=$(curl_wrapper GET "https://speed.cloudflare.com/meta" \
    --header "Referer: https://speed.cloudflare.com" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  iata=$(process_json "$response" ".colo.iata")
  if [[ -n "$iata" && "$iata" != "null" ]]; then
    location=$(get_iata_location "$iata")
    echo "$location ($iata)"
  fi
}

lookup_youtube_cdn() {
  local ip_version="$1" response iata location
  response=$(curl_wrapper GET "https://redirector.googlevideo.com/report_mapping?di=no" --ip-version "$ip_version" --timeout 4 2>/dev/null)
  iata=$(echo "$response" | awk '{print $3}' | cut -f2 -d'-' | cut -c1-3)
  iata=${iata^^}
  if [[ -n "$iata" && ${#iata} -eq 3 ]]; then
    location=$(get_iata_location "$iata")
    echo "$location ($iata)"
  fi
}

lookup_netflix_cdn() {
  local ip_version="$1" response
  response=$(curl_wrapper GET "https://api.fast.com/netflix/speedtest/v2?https=true&token=$NETFLIX_API_KEY&urlCount=1" \
    --ip-version "$ip_version" --timeout 4 2>/dev/null)
  if is_valid_json "$response"; then
    process_json "$response" ".targets[0].location.country"
  fi
}

# ------------------------------------------------------------------------------
# Dispatcher & Test Orchestration
# ------------------------------------------------------------------------------
add_result() {
  local group="$1" service="$2" ipv4="$3" ipv6="$4"
  ipv4=${ipv4//$'\n'/}
  ipv4=${ipv4//$'\t'/ }
  ipv6=${ipv6//$'\n'/}
  ipv6=${ipv6//$'\t'/ }

  case "$group" in
    primary) ARR_PRIMARY+=("$service|||$ipv4|||$ipv6") ;;
    custom)  ARR_CUSTOM+=("$service|||$ipv4|||$ipv6") ;;
    cdn)     ARR_CDN+=("$service|||$ipv4|||$ipv6") ;;
  esac
}

process_primary_service() {
  local service="$1"
  local ipv4_result="" ipv6_result=""

  local req_data display_name url response_format headers_str
  req_data=$(service_build_request "$service" "$EXTERNAL_IPV4" 4)
  mapfile -t parts <<<"$req_data"
  display_name="${parts[0]}"
  url="${parts[1]}"
  response_format="${parts[2]}"
  headers_str="${parts[3]}"

  spinner_update "$display_name"

  if can_use_ipv4; then
    if [[ "$service" == "2IP" ]]; then
      ipv4_result=$(lookup_2ip 4)
    else
      local headers=()
      if [[ -n "$headers_str" ]]; then headers+=(--header "$headers_str"); fi
      local resp
      resp=$(curl_wrapper GET "$url" "${headers[@]}" --ip-version 4 2>/dev/null)
      ipv4_result=$(process_response "$service" "$resp" "$display_name" "$response_format")
    fi
  fi

  if can_use_ipv6; then
    if [[ "$service" == "2IP" ]]; then
      ipv6_result=$(lookup_2ip 6)
    elif is_ipv6_over_ipv4_service "$service" && can_use_ipv4; then
      # Query via IPv4 transport with IPv6 payload
      local req_v6
      req_v6=$(service_build_request "$service" "$EXTERNAL_IPV6" 6)
      mapfile -t parts_v6 <<<"$req_v6"
      local url_v6="${parts_v6[1]}"
      local resp_v6
      resp_v6=$(curl_wrapper GET "$url_v6" --ip-version 4 2>/dev/null)
      ipv6_result=$(process_response "$service" "$resp_v6" "$display_name" "$response_format")
    else
      local headers=()
      if [[ -n "$headers_str" ]]; then headers+=(--header "$headers_str"); fi
      local resp
      resp=$(curl_wrapper GET "$url" "${headers[@]}" --ip-version 6 2>/dev/null)
      ipv6_result=$(process_response "$service" "$resp" "$display_name" "$response_format")
    fi
  fi

  add_result "primary" "$display_name" "$ipv4_result" "$ipv6_result"
}

process_custom_service() {
  local service="$1"
  local display_name="${CUSTOM_SERVICES[$service]:-$service}"
  local func_name="lookup_${service,,}"
  local ipv4_result="" ipv6_result=""

  spinner_update "$display_name"

  if declare -f "$func_name" >/dev/null; then
    if can_use_ipv4; then
      ipv4_result=$("$func_name" 4)
    fi
    if can_use_ipv6; then
      ipv6_result=$("$func_name" 6)
    fi
  fi

  add_result "custom" "$display_name" "$ipv4_result" "$ipv6_result"
}

process_cdn_service() {
  local service="$1"
  local display_name="${CDN_SERVICES[$service]:-$service}"
  local func_name="lookup_${service,,}"
  local ipv4_result="" ipv6_result=""

  spinner_update "$display_name"

  if declare -f "$func_name" >/dev/null; then
    if can_use_ipv4; then
      ipv4_result=$("$func_name" 4)
    fi
    if can_use_ipv6; then
      ipv6_result=$("$func_name" 6)
    fi
  fi

  add_result "cdn" "$display_name" "$ipv4_result" "$ipv6_result"
}

# ------------------------------------------------------------------------------
# Spinner & Process Control
# ------------------------------------------------------------------------------
spinner_start() {
  SPINNER_SERVICE_FILE=$(mktemp)
  (
    local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local idx=0
    tput civis 2>/dev/null
    while true; do
      local cur_service=""
      if [[ -f "$SPINNER_SERVICE_FILE" ]]; then
        cur_service=$(<"$SPINNER_SERVICE_FILE")
      fi
      printf "\r\033[K\033[1;36m%s\033[0m Checking: \033[1;37m%s\033[0m" "${spin[idx]}" "$cur_service"
      idx=$(( (idx + 1) % ${#spin[@]} ))
      sleep 0.1
    done
  ) &
  SPINNER_PID=$!
}

spinner_update() {
  if [[ -n "$SPINNER_SERVICE_FILE" && -f "$SPINNER_SERVICE_FILE" ]]; then
    printf "%s" "$1" >"$SPINNER_SERVICE_FILE"
  fi
}

spinner_stop() {
  if [[ -n "$SPINNER_PID" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
    kill "$SPINNER_PID" 2>/dev/null
    wait "$SPINNER_PID" 2>/dev/null
    printf "\r\033[K"
    tput cnorm 2>/dev/null
    SPINNER_PID=""
  fi
  if [[ -n "$SPINNER_SERVICE_FILE" && -f "$SPINNER_SERVICE_FILE" ]]; then
    rm -f "$SPINNER_SERVICE_FILE"
  fi
}

spinner_cleanup() {
  spinner_stop
  tput cnorm 2>/dev/null
}

# ------------------------------------------------------------------------------
# JSON Generation
# ------------------------------------------------------------------------------
build_json() {
  local t_primary t_custom t_cdn
  t_primary=$(printf "%s\n" "${ARR_PRIMARY[@]}" | sed 's/|||/	/g')
  t_custom=$(printf "%s\n" "${ARR_CUSTOM[@]}" | sed 's/|||/	/g')
  t_cdn=$(printf "%s\n" "${ARR_CDN[@]}" | sed 's/|||/	/g')

  RESULT_JSON=$(
    jq -n \
      --arg p "$t_primary" \
      --arg c "$t_custom" \
      --arg d "$t_cdn" \
      --arg ipv4 "$EXTERNAL_IPV4" \
      --arg ipv6 "$EXTERNAL_IPV6" \
      --arg asn "$NODE_ASN" \
      --arg org "$NODE_ORG" \
      --arg node_type "$NODE_TYPE" \
      --arg risk_score "$NODE_RISK_SCORE" \
      --arg captcha "$NODE_CAPTCHA_STATUS" \
      --arg version "$SCRIPT_VERSION" '
        def lines_to_array($raw):
          if ($raw | length) == 0 then [] else
          ($raw | split("\n"))
          | map(select(length > 0))
          | map(
              (split("\t")) as $f
              | {
                  service: $f[0],
                  ipv4: ( ($f[1] // "") | if length>0 then . else null end ),
                  ipv6: ( ($f[2] // "") | if length>0 then . else null end )
                }
            )
          end;

        {
          version: $version,
          ipv4: ($ipv4 | select(length > 0) // null),
          ipv6: ($ipv6 | select(length > 0) // null),
          node_audit: {
            asn: ($asn | select(length > 0) // null),
            organization: ($org | select(length > 0) // null),
            type: ($node_type | select(length > 0) // null),
            risk_score: ($risk_score | tonumber? // 0),
            google_captcha: ($captcha | select(length > 0) // "Unknown")
          },
          results: {
            primary: lines_to_array($p),
            custom: lines_to_array($c),
            cdn: lines_to_array($d)
          }
        }
      '
  )
}

# ------------------------------------------------------------------------------
# Output Presentation: Tables, Legends, and VPN Node Audit
# ------------------------------------------------------------------------------
print_header() {
  printf "\033[1;36m================================================================================\033[0m\n"
  printf " 🌎 \033[1;97mIPRegion (VPN Edition)\033[0m - Geolocation & Node Audit v%s\n" "$SCRIPT_VERSION"
  printf "\033[1;36m================================================================================\033[0m\n"

  if [[ -n "$EXTERNAL_IPV4" ]]; then
    printf " \033[1;37m%-16s\033[0m %s\n" "IPv4:" "$(bold "$EXTERNAL_IPV4")"
  fi
  if [[ -n "$EXTERNAL_IPV6" ]]; then
    printf " \033[1;37m%-16s\033[0m %s\n" "IPv6:" "$(bold "$EXTERNAL_IPV6")"
  fi

  if [[ -n "$NODE_ASN" ]]; then
    printf " \033[1;37m%-16s\033[0m %s (%s)\n" "ASN & ISP:" "$(color ASN "$NODE_ASN")" "$NODE_ORG"
  fi

  if [[ -n "$NODE_TYPE" ]]; then
    printf " \033[1;37m%-16s\033[0m %s\n" "Node Type:" "$(bold "$NODE_TYPE")"
  fi

  if [[ -n "$NODE_RISK" ]]; then
    printf " \033[1;37m%-16s\033[0m %s\n" "Fraud / Risk:" "$(color "$NODE_RISK_COLOR" "$NODE_RISK")"
  fi

  if [[ -n "$NODE_CAPTCHA_STATUS" ]]; then
    local capt_desc="Clean"
    if [[ "$NODE_CAPTCHA_STATUS" == "Yes" ]]; then capt_desc="Blocked / Captcha Triggered"; fi
    printf " \033[1;37m%-16s\033[0m %s\n" "Google Captcha:" "$(color "$NODE_CAPTCHA_COLOR" "$NODE_CAPTCHA_STATUS ($capt_desc)")"
  fi

  if [[ -n "$PROXY_ADDR" ]]; then
    printf " \033[1;37m%-16s\033[0m %s (Remote DNS)\n" "Proxy Mode:" "socks5h://$PROXY_ADDR"
  elif [[ -n "$SELECTED_DOH_URL" ]]; then
    printf " \033[1;37m%-16s\033[0m %s\n" "DNS Resolver:" "Active DoH (Encrypted DNS-over-HTTPS)"
  fi

  printf "\033[1;36m================================================================================\033[0m\n\n"
}

print_table_group() {
  local group="$1" group_title="$2"
  local separator="|||"
  local show_ipv4=false show_ipv6=false

  if can_use_ipv4; then show_ipv4=true; fi
  if can_use_ipv6; then show_ipv6=true; fi

  printf "%s\n\n" "$(color HEADER "$group_title")"

  {
    local header_parts=()
    header_parts+=("$(color TABLE_HEADER 'Service')")
    $show_ipv4 && header_parts+=("$(color TABLE_HEADER 'IPv4')")
    $show_ipv6 && header_parts+=("$(color TABLE_HEADER 'IPv6')")

    local header="${header_parts[0]}"
    for ((i=1; i<${#header_parts[@]}; i++)); do
      header+="$separator${header_parts[i]}"
    done
    echo "$header"

    jq -r --arg group "$group" '
      (.results // {}) as $r
      | ($r[$group] // [])
      | .[]
      | [ .service, (.ipv4 // "N/A"), (.ipv6 // "N/A") ]
      | @tsv
    ' <<<"$RESULT_JSON" | while IFS=$'\t' read -r s v4 v6; do

      local row="$(color SERVICE "$s")"
      if $show_ipv4; then
        row+="$separator$(format_value "$v4")"
      fi
      if $show_ipv6; then
        row+="$separator$(format_value "$v6")"
      fi
      echo "$row"
    done
  } | if is_command_available column; then
      column -t -s "$separator"
    else
      awk -F "$separator" '{
        for (i=1; i<=NF; i++) { if (length($i) > w[i]) w[i] = length($i) }
        rows[NR] = $0
      }
      END {
        for (r=1; r<=NR; r++) {
          n = split(rows[r], cols, FS)
          line = ""
          for (i=1; i<=n; i++) {
            fmt = sprintf("%%-%ds  ", w[i])
            line = line sprintf(fmt, cols[i])
          }
          print line
        }
      }'
    fi

  echo
}

print_legend() {
  local separator="|||"
  printf "%s\n\n" "$(color HEADER 'Country Consensus & Breakdown')"

  local stats
  stats=$(jq -r '
    def clean:
      tostring
      | gsub("\u001b\\[[0-9;]*m"; "")
      | select(test("^(No|Yes|N/A|null|Denied|Rate limited|Server error)$") | not);

    def counts(stream):
      [stream | select(. != null) | clean] as $arr
      | reduce ($arr[]) as $c ({}; .[$c] += 1)
      | {total: ($arr | length), counts: .};

    {
      ipv4: counts(
        (.results.primary[].ipv4?, .results.custom[].ipv4?)
      ),
      ipv6: counts(
        (.results.primary[].ipv6?, .results.custom[].ipv6?)
      )
    }
  ' <<<"$RESULT_JSON")

  local codes
  codes=$(jq -r '
    [
      (.ipv4.counts | keys[]?),
      (.ipv6.counts | keys[]?)
    ] | unique[]
  ' <<<"$stats")

  if [[ -z "$codes" ]]; then
    return 0
  fi

  local show_ipv4=false show_ipv6=false
  if can_use_ipv4; then show_ipv4=true; fi
  if can_use_ipv6; then show_ipv6=true; fi

  {
    local header_parts=()
    header_parts+=("$(color TABLE_HEADER 'Code')")
    header_parts+=("$(color TABLE_HEADER 'Country')")
    $show_ipv4 && header_parts+=("$(color TABLE_HEADER '% IPv4')")
    $show_ipv6 && header_parts+=("$(color TABLE_HEADER '% IPv6')")

    local header="${header_parts[0]}"
    for ((i=1; i<${#header_parts[@]}; i++)); do
      header+="$separator${header_parts[i]}"
    done
    echo "$header"

    while read -r code; do
      [[ -z "$code" ]] && continue
      local country ipv4_num ipv6_num ipv4_str="" ipv6_str=""
      country="${COUNTRY_NAMES[$code]:-Unknown}"

      ipv4_num=$(jq -r --arg c "$code" '
        if (.ipv4.total == 0) then 0
        else ((.ipv4.counts[$c] // 0) / .ipv4.total * 100 | round)
        end
      ' <<<"$stats")

      ipv6_num=$(jq -r --arg c "$code" '
        if (.ipv6.total == 0) then 0
        else ((.ipv6.counts[$c] // 0) / .ipv6.total * 100 | round)
        end
      ' <<<"$stats")

      [[ "$ipv4_num" -ne 0 ]] && ipv4_str="${ipv4_num}%"
      [[ "$ipv6_num" -ne 0 ]] && ipv6_str="${ipv6_num}%"

      printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$ipv4_num" "$ipv6_num" "$(color SERVICE "$code")" "$(format_value "$country")" "$ipv4_str" "$ipv6_str"
    done <<< "$codes" \
      | sort -t$'\t' -k1,1nr -k2,2nr \
      | awk -F $'\t' -v OFS="$separator" \
        "$(
          if $show_ipv4 && $show_ipv6; then
            echo '{print $3,$4,$5,$6}'
          elif $show_ipv4; then
            echo '{print $3,$4,$5}'
          elif $show_ipv6; then
            echo '{print $3,$4,$6}'
          else
            echo '{print $3,$4,$5,$6}'
          fi
        )"

  } | if is_command_available column; then
      column -t -s "$separator"
    else
      awk -F "$separator" '{
        for (i=1; i<=NF; i++) { if (length($i) > w[i]) w[i] = length($i) }
        rows[NR] = $0
      }
      END {
        for (r=1; r<=NR; r++) {
          n = split(rows[r], cols, FS)
          line = ""
          for (i=1; i<=n; i++) {
            fmt = sprintf("%%-%ds  ", w[i])
            line = line sprintf(fmt, cols[i])
          }
          print line
        }
      }'
    fi

  echo
}

print_vpn_assessment() {
  printf "\033[1;36m================================================================================\033[0m\n"
  printf " 🛡️  \033[1;97mVPN Node Quality Assessment\033[0m\n"
  printf "\033[1;36m================================================================================\033[0m\n"

  # 1. Geolocation consensus
  local top_code top_pct top_country
  top_code=$(jq -r '
    def clean: tostring | gsub("\u001b\\[[0-9;]*m"; "") | select(test("^(No|Yes|N/A|null|Denied|Rate limited|Server error)$") | not);
    [(.results.primary[].ipv4?, .results.custom[].ipv4?) | select(. != null) | clean] as $arr
    | reduce ($arr[]) as $c ({}; .[$c] += 1)
    | to_entries | sort_by(.value) | reverse | .[0].key // empty
  ' <<<"$RESULT_JSON")

  if [[ -n "$top_code" ]]; then
    top_country="${COUNTRY_NAMES[$top_code]:-Unknown}"
    top_pct=$(jq -r --arg c "$top_code" '
      def clean: tostring | gsub("\u001b\\[[0-9;]*m"; "") | select(test("^(No|Yes|N/A|null|Denied|Rate limited|Server error)$") | not);
      [(.results.primary[].ipv4?, .results.custom[].ipv4?) | select(. != null) | clean] as $arr
      | reduce ($arr[]) as $c ({}; .[$c] += 1)
      | if ($arr|length) > 0 then (.[$c] / ($arr|length) * 100 | round) else 0 end
    ' <<<"$RESULT_JSON")
    printf " • %-25s %s (%s%% agreement)\n" "Primary Geolocation:" "$(bold "$top_country [$top_code]")" "$top_pct"
  fi

  # 2. Node Classification
  printf " • %-25s %s\n" "Host Classification:" "$(bold "$NODE_TYPE")"

  # 3. Fraud / Captcha
  printf " • %-25s %s\n" "Risk & Captcha Status:" "$(color "$NODE_RISK_COLOR" "$NODE_RISK"), Google Captcha: $(color "$NODE_CAPTCHA_COLOR" "$NODE_CAPTCHA_STATUS")"

  # 4. Streaming Availability
  local stream_services=("Netflix" "Disney+ Access" "Amazon Prime" "YouTube Premium" "Spotify Signup")
  local ok_count=0 total_count=0
  for s in "${stream_services[@]}"; do
    total_count=$((total_count + 1))
    local val
    val=$(jq -r --arg s "$s" '
      .results.custom[] | select(.service == $s) | .ipv4 // .ipv6 // "No"
    ' <<<"$RESULT_JSON")
    if [[ "$val" =~ (Yes|[A-Z]{2}) ]]; then
      ok_count=$((ok_count + 1))
    fi
  done
  printf " • %-25s %s\n" "Streaming Unblock:" "$ok_count/$total_count key platforms unlocked"

  # 5. AI Access
  local gpt_ok gemini_ok
  gpt_ok=$(jq -r '.results.custom[] | select(.service == "ChatGPT") | .ipv4 // .ipv6 // "No"' <<<"$RESULT_JSON")
  gemini_ok=$(jq -r '.results.custom[] | select(.service == "Gemini Supported") | .ipv4 // .ipv6 // "No"' <<<"$RESULT_JSON")
  printf " • %-25s ChatGPT: %s | Gemini: %s\n" "AI Platforms:" "$(format_value "$gpt_ok")" "$(format_value "$gemini_ok")"

  printf "\033[1;36m================================================================================\033[0m\n\n"
}

print_results() {
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    printf "%s\n" "$RESULT_JSON"
    return
  fi

  print_header

  case "$GROUPS_TO_SHOW" in
    primary)
      print_table_group "primary" "GeoIP Databases (18 sources)"
      ;;
    custom)
      print_table_group "custom" "Web, Streaming & AI Services (24 services)"
      ;;
    cdn)
      print_table_group "cdn" "CDN Edge Nodes"
      ;;
    all|*)
      print_table_group "primary" "GeoIP Databases (18 sources)"
      print_table_group "custom" "Web, Streaming & AI Services (24 services)"
      print_table_group "cdn" "CDN Edge Nodes"
      print_legend
      print_vpn_assessment
      ;;
  esac
}

# ------------------------------------------------------------------------------
# CLI Argument Parsing
# ------------------------------------------------------------------------------
display_help() {
  cat <<EOF
Usage: ipregion.sh [OPTIONS]

IPRegion (VPN Edition) - Multi-Source Geolocation, Streaming & VPN Node Auditor

Options:
  -h, --help               Show this help message and exit
  -v, --verbose            Enable verbose logging
  -d, --debug              Enable debug mode (saves trace to $DEBUG_LOG_FILE)
  -j, --json               Output results in pure JSON format
  -g, --group GROUP        Run specific group: 'primary', 'custom', 'cdn', 'all' (default: all)
  -t, --timeout SEC        Set request timeout in seconds (default: 5)
  -4, --ipv4               Test only IPv4
  -6, --ipv6               Test only IPv6
  -p, --proxy ADDR         Use SOCKS5/SOCKS5h proxy (format: host:port)
  -i, --interface IF       Bind requests to network interface (e.g. eth0, wg0, tun0)
  --no-doh                 Disable DNS-over-HTTPS (use system resolver)
  --doh PROVIDER           Select DoH provider: cloudflare, quad9, adguard, opendns

Examples:
  ./ipregion.sh                         # Run full audit
  ./ipregion.sh -p 127.0.0.1:1080       # Audit VPN/Proxy node via SOCKS5
  ./ipregion.sh -i wg0                  # Audit WireGuard interface
  ./ipregion.sh -g custom               # Check only streaming & web services
  ./ipregion.sh -j                      # Output JSON for automation / monitoring

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
      -g|--group)
        GROUPS_TO_SHOW="${2:-all}"
        shift 2
        ;;
      -t|--timeout)
        if [[ "$2" =~ ^[0-9]+$ ]]; then
          CURL_TIMEOUT="$2"
        fi
        shift 2
        ;;
      -4|--ipv4)
        IPV4_ONLY=true
        shift
        ;;
      -6|--ipv6)
        IPV6_ONLY=true
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

# ------------------------------------------------------------------------------
# Main Flow
# ------------------------------------------------------------------------------
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

  if ! can_use_ipv4 && ! can_use_ipv6; then
    spinner_cleanup
    error_exit "No active internet connection or external IP detected."
  fi

  get_vpn_node_info

  # Primary services
  if [[ "$GROUPS_TO_SHOW" == "all" || "$GROUPS_TO_SHOW" == "primary" ]]; then
    for s in "${PRIMARY_SERVICES_ORDER[@]}"; do
      process_primary_service "$s"
    done
  fi

  # Custom services
  if [[ "$GROUPS_TO_SHOW" == "all" || "$GROUPS_TO_SHOW" == "custom" ]]; then
    for s in "${CUSTOM_SERVICES_ORDER[@]}"; do
      process_custom_service "$s"
    done
  fi

  # CDN services
  if [[ "$GROUPS_TO_SHOW" == "all" || "$GROUPS_TO_SHOW" == "cdn" ]]; then
    for s in "${CDN_SERVICES_ORDER[@]}"; do
      process_cdn_service "$s"
    done
  fi

  spinner_stop
  build_json
  print_results
}

main "$@"
