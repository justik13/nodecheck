# 🌎 IPRegion (VPN Edition)

> **Multi-source IP geolocation, streaming availability & VPN node quality auditor.**  
> Комплексный скрипт для аудита VPN-нод, VPS, прокси и выходных узлов: определение типа IP (Residential vs Datacenter), оценка риска/фрода (Fraud Score), проверка Google Captcha, DoH-резолвер и проверка 45+ баз и сервисов.

Скрипт объединяет и развивает лучшие инженерные решения оригинального проекта [vernette/ipregion](https://github.com/vernette/ipregion) и форка [Davoyan/ipregion](https://github.com/Davoyan/ipregion), добавляя специализированный функционал для тестирования и оценки **VPN-нод**.

---

## 🚀 Быстрый запуск (Quick Start)

### Локально через `curl` / `wget`
```bash
# Прямой запуск без предварительного скачивания
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/ipregion/main/ipregion.sh)

# Или через wget:
bash <(wget -qO- https://raw.githubusercontent.com/justik13/ipregion/main/ipregion.sh)
```

### Аудит через SOCKS5 / Прокси (с разрешением DNS на стороне прокси)
```bash
./ipregion.sh -p 127.0.0.1:1080
```

### Аудит конкретного сетевого интерфейса (WireGuard / OpenVPN / VLESS)
```bash
./ipregion.sh -i wg0
# или
./ipregion.sh -i tun0
```

### В Docker
```bash
# С использованием хостовой сети (для одновременной проверки IPv4 и IPv6)
docker run --rm --network=host justik13/ipregion:latest

# Проверка через прокси внутри Docker
docker run --rm justik13/ipregion:latest -p 10.0.0.1:1080
```

---

## 🛡️ Что оценивается для VPN-ноды?

| Метрика | Описание | Зачем это для VPN? |
| :--- | :--- | :--- |
| **Node Type** | Классификация: `Residential / ISP`, `Datacenter / Hosting`, `Mobile` или `Proxy` | Стриминги и антифрод-системы (банковские приложения, Google, Amazon) блокируют `Datacenter`. Чистый `Residential` — признак идеальной ноды. |
| **Fraud / Risk Score** | Оценка чистоты IP по шкале `0-100` | Чем ниже оценка (0-25), тем меньше вероятность столкнуться с Cloudflare Challenge, капчами и блокировками. |
| **Google Captcha** | Проверка триггера "Unusual traffic from your computer network" | Показывает, заспамлена ли подсеть хостинга ботами/скрейперами. |
| **Country Consensus (%)** | Процентное совпадение геолокации по всем базам | Выявляет **Split Geo** (когда для RIPE IP в Германии, а Google и Netflix видят Финляндию). |
| **Streaming Unblock** | Проверка доступа: Netflix, Disney+, Amazon Prime, YouTube Premium, Spotify, Deezer | Полная проверка снятия гео-ограничений медиасервисов. |
| **AI Availability** | Доступ к OpenAI ChatGPT и Google Gemini | Проверка доступности современных AI-моделей из текущего региона. |
| **DNS-over-HTTPS (DoH)** | Автоматическое шифрование DNS через Cloudflare, Quad9, AdGuard | Исключает искажение результатов проверки провайдерскими DNS (DNS poisoning/заглушки в РФ/СНГ/Китае). |

---

## 📊 Пример вывода (Output Example)

```text
================================================================================
 🌎 IPRegion (VPN Edition) - Geolocation & Node Audit v2.1.0-vpn
================================================================================
 IPv4:            198.51.100.42
 IPv6:            2001:db8::42
 ASN & ISP:       AS13335 (Cloudflare, Inc.)
 Node Type:       Datacenter / Hosting
 Fraud / Risk:    12/100 (Low Risk / Clean)
 Google Captcha:  No (Clean)
 DNS Resolver:    Active DoH (Encrypted DNS-over-HTTPS)
================================================================================

GeoIP Databases (18 sources)

Service          IPv4   IPv6
MaxMind          US     US
RIPE NCC         US     US
IPinfo.io        US     US
Ipregistry       US     US
IP-API.co        US     US
Cloudflare       US     US
IP2Location.io   US     US
IPLocation.com   US     US
Country.is       US     US
Geoapify         US     US
GeoJS            US     US
IPAPI.is         US     US
ipbase.com       US     US
ipquery.io       US     US
ipwho.is         US     US
ip-api.com       US     US
2ip.io           US     US
ifconfig.co      US     US

Web, Streaming & AI Services (24 services)

Service                 IPv4   IPv6
Google                  US     US
Google Search Captcha   No     No
YouTube                 US     US
YouTube Premium         Yes    Yes
YouTube Music           Yes    Yes
ChatGPT                 US     US
Gemini Supported        Yes    Yes
Netflix                 US     US
Disney+                 US     US
Disney+ Access          Yes    Yes
Amazon Prime            US     US
Spotify                 US     US
Spotify Signup          Yes    Yes
Deezer                  US     US
Apple                   US     US
Microsoft Live          US     US
Steam                   US     US
PlayStation             US     US
TikTok                  US     US
Reddit                  US     US
Reddit Guest Access     Yes    Yes
Ookla Speedtest         US     US
JetBrains               US     US
Bing                    US     US

CDN Edge Nodes

Service          IPv4            IPv6
Cloudflare CDN   Dallas, US (DFW) Dallas, US (DFW)
YouTube CDN      Dallas, US (DFW) Dallas, US (DFW)
Netflix CDN      US              US

Country Consensus & Breakdown

Code  Country        % IPv4  % IPv6
US    United States  100%    100%

================================================================================
 🛡️  VPN Node Quality Assessment
================================================================================
 • Primary Geolocation:      United States [US] (100% agreement)
 • Host Classification:      Datacenter / Hosting
 • Risk & Captcha Status:    12/100 (Low Risk / Clean), Google Captcha: No
 • Streaming Unblock:        5/5 key platforms unlocked
 • AI Platforms:             ChatGPT: Yes | Gemini: Yes
================================================================================
```

---

## 📋 Поддерживаемые сервисы (45+)

### 1. Базы данных GeoIP (18 сервисов)
- **MaxMind** (GeoIP City)
- **RIPE NCC** (Официальный региональный регистратор)
- **IPinfo.io**
- **Ipregistry**
- **IP-API.co**
- **Cloudflare** (Speed Meta)
- **IP2Location.io**
- **IPLocation.com**
- **Country.is**
- **Geoapify**
- **GeoJS**
- **IPAPI.is**
- **ipbase.com**
- **ipquery.io** (включая скоринг рисков)
- **ipwho.is**
- **ip-api.com** (Pro демо)
- **2ip.io** (Популярный сервис проверки в СНГ)
- **ifconfig.co**

### 2. Веб-, AI- и стриминговые платформы (24 сервиса)
- **Google** (Определение региона + поддержка Google CN)
- **Google Search Captcha** (Детекция блокировки поиска и подозрительного трафика)
- **YouTube** (Регион выдачи)
- **YouTube Premium** (Доступность подписки в стране)
- **YouTube Music** (Доступность сервиса)
- **OpenAI ChatGPT** (Регион API Statsig)
- **Google Gemini** (Официальная проверка поддерживаемых регионов CLDR/Gemini)
- **Netflix** (Регион Fast.com)
- **Disney+** & **Disney+ Access** (Определение региона и доступности стриминга через Bamgrid GraphQL)
- **Amazon Prime Video** (Определение территории и блокировок `isServiceRestricted`)
- **Spotify** & **Spotify Signup** (Регион и возможность регистрации нового аккаунта)
- **Deezer** (Региональный прайсинг)
- **Apple** (Apple Maps GCC)
- **Microsoft Live** (`login.live.com`)
- **Steam Store** (Валюта и страна магазина)
- **PlayStation Network** (Cookie региона)
- **TikTok** (Cookie Privacy API)
- **Reddit** & **Reddit Guest Access** (OAuth локация и проверка сетевого бана)
- **Ookla Speedtest** (SDK config)
- **JetBrains** (Customer store location)
- **Bing Search** (Региональная выдача)

### 3. CDN и узлы доставки контента (3 сервиса)
- **Cloudflare CDN** (Код аэропорта IATA + город)
- **YouTube CDN** (Google Video redirector IATA)
- **Netflix CDN** (Fast.com target location)

---

## ⚙️ Опции командной строки (CLI Flags)

```text
Параметры:
  -h, --help               Показать справку и выйти
  -v, --verbose            Включить подробный вывод логов
  -d, --debug              Включить режим трассировки (лог в /tmp/ipregion_debug.log)
  -j, --json               Вывести результат в чистом JSON-формате
  -g, --group GROUP        Запустить определенную группу: 'primary', 'custom', 'cdn', 'all' (по умолчанию: all)
  -t, --timeout SEC        Таймаут запросов в секундах (по умолчанию: 5)
  -4, --ipv4               Проверять только IPv4
  -6, --ipv6               Проверять только IPv6
  -p, --proxy ADDR         SOCKS5/SOCKS5h прокси (формат: 127.0.0.1:1080)
  -i, --interface IF       Сетевой интерфейс для привязки (например: eth0, wg0, tun0)
  --no-doh                 Отключить DoH и использовать системный DNS
  --doh PROVIDER           Выбрать DoH-провайдер: cloudflare, quad9, adguard, opendns
```

---

## 🛠️ Зависимости

Скрипт автоматически определяет ОС и устанавливает недостающие пакеты при наличии `sudo`/`root`:
* `bash`
* `curl` (с поддержкой SSL)
* `jq` (обработка JSON)
* `util-linux` или `bsdmainutils` (утилита `column` для выравнивания таблиц; при отсутствии используется встроенный awk-форматтер)

Поддерживаемые дистрибутивы: **Debian/Ubuntu, CentOS/RHEL, Fedora, Alpine Linux, Arch Linux, macOS (Homebrew)**.

---

## 📜 Лицензия
MIT License. Разработано на базе наработок `vernette/ipregion` и `Davoyan/ipregion`.
