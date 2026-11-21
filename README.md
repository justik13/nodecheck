# NodeCheck (RU Edition)

Скрипт аудита VPS/VDS и выделенных серверов под аудиторию РФ: железо, сетевой стек, репутация IP, геолокация, блокировки и скорость.

[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Traces](https://img.shields.io/badge/Storage-Zero%20Traces%20(Safe)-brightgreen)](#-без-следов-на-диске)

---

## Быстрый запуск

Запуск одной строкой на сервере (чистый Bash, без компиляции и автоустановки пакетов):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Через `wget`:
```bash
bash <(wget -qO- https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

---

## Что проверяет скрипт

1. **Железо, CPU Steal и шифрование:**
   * Модель CPU, количество vCPU, объём RAM, аптайм и виртуализацию (KVM/LXC/Bare-Metal).
   * CPU Steal %: текущую выборку и среднее значение за весь аптайм.
   * Скорость аппаратного шифрования (AES-NI / VAES / ARM CE) через OpenSSL в GB/s за 1 секунду.

2. **Диск:**
   * Реальный тип накопителя (NVMe SSD, SSD, Virtual Disk, HDD, Container OverlayFS, RAM Disk) через `lsblk PKNAME` и `rotational`.
   * Последовательную запись через `dd` с `conv=fdatasync` (256 МБ, либо 512 МБ при RAM ≥ 2 ГБ, лимит 10с). При таймауте считает скорость по фактически записанным байтам, пропускает `tmpfs`/`ramfs` и не запускается, если свободно меньше 2 ГБ или диск заполнен более чем на 90%.

3. **Сетевой стек и BBR:**
   * Статус TCP BBR и наличие модуля ядра `tcp_bbr.ko` (`Inactive (Available)`).
   * Исходящий Port 25 (SMTP: Gmail, Outlook, Mail.ru).
   * Двунаправленный UDP (DNS-запросы к 1.1.1.1 / 8.8.8.8).

4. **Антифрод и тип IP (стандарт xykt/IPQuality):**
   * Параллельный опрос 4 баз (Scamalytics, AbuseIPDB, IP-API, IPQuery) за ~350 мс.
   * Тип IP: Native IP или Broadcast IP по совпадению физической геолокации и RIR (RIPE/ARIN/APNIC).
   * Классификация хоста: `Tor Exit Node` -> `Commercial VPN / Proxy` -> `Data Center / Hosting` -> `Mobile` -> `Residential`.
   * Проверка IP по реестру РКН (базы Antifilter `ip.lst` и CIDR `ipsum.lst`).
   * Прямой тест триггера Google Captcha («Необычный трафик»).

5. **DNSBL-сканер (12 спам-баз):**
   * Параллельный опрос 12 почтовых чёрных списков (Barracuda, SpamCop, DroneBL, Surriel PSBL, Mailspike, UCEPROTECT-1, GBUdb, Blocklist.de, s5h, InterServer, 0spam, Nordspam) за ~210 мс.
   * Отсеивает служебные ответы публичных DNS (`127.255.255.*`) и закрытые списки вроде SORBS.

6. **Консенсус 18 баз GeoIP:**
   * Параллельный опрос 18 провайдеров (IPinfo, Cloudflare, IP-API, IP2Location, 2ip, ipwho.is, ifconfig.co, IPLocation, ipbase, ipquery, IPAPI.is, RIPE NCC, IP.Guide и др.) с долей голосов за страну.

7. **DNS-резолверы и спуфинг (12 резолверов):**
   * Проверка Cloudflare, Google, Quad9, AdGuard, NextDNS и Yandex по UDP (53), DoH (HTTPS) и DoT (TLS 853).
   * Поиск DNS Hijacking / Spoofing по эталонным IP для `rutracker.org`.

8. **Дата-центры Telegram MTProto (DC1–DC5):**
   * Обмен пакетами MTProto (`req_pq_multi` / `resPQ`) с шифрованием AES-CTR по порту 443 для всех 5 DC.

9. **Сервисы РФ (Reverse Geoblocking):**
   * Госуслуги, ФНС, Мос.ру, РЖД, Почта России (Anti-VPN 417), ФССП, КонсультантПлюс, Яндекс, VK.
   * Банки: СберБанк, Т-Банк, ВТБ, Альфа-Банк.
   * Маркетплейсы и медиа: Авито (Qrator Browser PoW), Wildberries, Озон, Кинопоиск.

10. **Фильтрация ТСПУ (Censorcheck DPI) и санкционные ресурсы:**
    * DPI ТСПУ (18 доменов): раздельный тест HTTP 80 (редиректы) и HTTPS 443 (DPI Drop, TLS-сбросы, заглушка РКН 451) — YouTube, Discord, Instagram, Facebook, X/Twitter, Rutracker, Amnezia, Outline, Telegram API, Google Play и др.
    * Санкционные западные сервисы (10 доменов): Spotify, Netflix, Patreon, Swagger, Snyk, MongoDB, Autodesk, Graylog, Redis, MS Copilot.

11. **Стриминги, медиа и AI-сервисы (IP Region 28 + Legend %):**
    * Определение страны для Claude AI, OpenAI ChatGPT, Google Gemini, YouTube (включая YouTube Ad-Free), TikTok, Disney+, Twitch, JetBrains, Ookla, Microsoft/Bing, Deezer, Steam, PlayStation, Reddit, Apple Services.
    * Таблица Legend % с долей стран по всем сервисам.

12. **Скорость и связность:**
    * Зарубежные ноды: Speedtest by Ookla CLI (до 10 Gbps).
    * Ноды в РФ и связность с Россией: дуплексный iPerf3 и пинг по 7 макро-регионам (21 узел в Москве, СПб, Казани, Нижнем Новгороде, Самаре, Ростове-на-Дону, Волгограде, Астрахани, Екатеринбурге/Урале, Новосибирске и Иркутске/Якутске).

---

## Пример вывода

```text
+------------------------------------------------------------------------------+
| NodeCheck (RU Edition) - Node & Network Quality Auditor v4.1.0-ru            |
+------------------------------------------------------------------------------+
 IPv4:              185.96.*.*
 IPv6:              2a14:a084:1a77:*:*:*:*:*
 Локация / ASN:     RU (Moscow) — AS216246 (Aeza Group LLC)
 ОС и ядро:         Ubuntu 24.04.1 LTS (6.8.0-48-generic x86_64)
 Платформа:         KVM | Аптайм: 53m
 Процессор (CPU):   AMD Ryzen 9 9950X 16-Core Processor (1 vCPU) [VAES, 10.69 GB/s]
 CPU Steal:         0.0% (Clean) | 0.00% (за аптайм)
 Память / Диск:     RAM: 262 MB / 1968 MB (13.3%) | Диск: 2.6G / 30G (9%) [Virtual Disk, I/O: 113 MB/s]
 Тип хоста:         Data Center / Hosting | Тип IP: Native (Geo-consistent)
 Репутация / Базы:  РКН: Clean (Not in Registry) | DNSBL: Clean (0/12)
 Антифрод / Риск:   High Risk / Flagged (Scam: 0/100 | Abuse: 0% | IPQ: 85/100), Google Captcha: Clean (No Captcha)
 Сетевой стек:      BBR: Active | UDP: Open (DNS Bidirectional) | Port 25: Blocked
--------------------------------------------------------------------------------

1. 🌐 Консенсус баз GeoIP (18 источников)
  База данных               IPv4          IPv6
  ------------------------  ------------  ------------
  IPinfo.io                 RU            RU
  IP-API.com                RU            LV
  Cloudflare                RU            RU
  IP.SB                     RU            LV
  Ipregistry                RU            LV
  IP-API.co                 N/A           N/A
  IP2Location.io            RU            LV
  Country.is                RU            LV
  GeoJS                     RU            LV
  2ip.io                    RU            LV
  ipwho.is                  RU            LV
  ifconfig.co               MX            N/A
  IPLocation.net            RU            LV
  ipbase.com                RU            LV
  ipquery.io                RU            LV
  IPAPI.is                  RU            LV
  RIPE NCC                  RU            RU
  IP.Guide                  RU            LV

  Консенсус (IPv4): RU (Russia) — 15/16 (93.8%)

  Код  Страна  Доля (IPv4)
  ---  ------  -----------
  RU   Russia  93.8% (15/16)
  MX   Mexico  6.2% (1/16)

  Консенсус (IPv6): LV (Latvia) — 12/15 (80.0%)

  Код  Страна  Доля (IPv6)
  ---  ------  -----------
  LV   Latvia  80.0% (12/15)
  RU   Russia  20.0% (3/15)

2. 🛡️ DNS-резолверы, спуфинг и дата-центры Telegram (MTProto)
  [ DNS-резолверы и детекция спуфинга ]
  Resolver          IP                UDP        DoH        DoT        Spoofing
  ----------------  ----------------  ---------  ---------  ---------  ---------
  Cloudflare        1.1.1.1           Available  Available  Available  Clean
  Cloudflare        1.0.0.1           Available  Available  Available  Clean
  Google            8.8.8.8           Available  Blocked    Available  Clean
  Google            8.8.4.4           Available  Blocked    Available  Clean
  Quad9             9.9.9.9           Available  Blocked    Available  Clean
  Quad9             9.9.9.10          Available  Blocked    Available  Clean
  AdGuard           94.140.14.14      Available  Blocked    Available  Clean
  AdGuard           94.140.15.15      Available  Blocked    Available  Clean
  NextDNS           45.90.28.65       Available  Available  Available  Clean
  NextDNS           45.90.30.65       Available  Available  Available  Clean
  Yandex            77.88.8.8         Available  Blocked    Available  Clean
  Yandex            77.88.8.1         Available  Blocked    Available  Clean
  Good news, no DNS hijacking detected! (reference: Cloudflare over HTTPS)

  [ Дата-центры Telegram MTProto (порт 443) ]
  DC    IP Address        MTProto (Port 443)
  ----  ----------------  -------------------
  DC1   149.154.175.50    Blocked
  DC2   149.154.167.51    Blocked
  DC2   95.161.76.100     Blocked
  DC3   149.154.175.100   Blocked
  DC4   149.154.167.91    Blocked
  DC5   149.154.171.5     Blocked
  DC5   91.108.56.130     Blocked

3. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)
  Сервис                                Статус
  ------------------------------------  ------
  Госуслуги (gosuslugi.ru)              OK
  ФНС (nalog.gov.ru)                    OK
  Мос.ру (mos.ru)                       OK
  РЖД (ticket.rzd.ru)                   OK
  Почта России (pochta.ru)              OK
  ФССП (fssp.gov.ru)                    OK
  КонсультантПлюс (consultant.ru)       OK
  Яндекс (ya.ru)                        OK
  ВКонтакте (vk.com)                    OK
  СберБанк (sberbank.ru)                OK
  Т-Банк (tbank.ru)                     OK
  ВТБ (vtb.ru)                          OK
  Альфа-Банк (alfabank.ru)              OK
  Авито (avito.ru)                      Yes (Browser / PoW)
  Wildberries (wildberries.ru)          Yes
  Озон (ozon.ru)                        Yes
  Кинопоиск (kinopoisk.ru)              Yes

4. 🚫 Фильтрация ТСПУ (Censorcheck DPI) и санкционные ресурсы
  [ Censorcheck DPI: 18 сайтов ] [12 блоков из 18 ресурсов под фильтрацией ТСПУ]
  Домен                         IP-адрес          HTTP (Port 80)        HTTPS (Port 443 / TLS)
  ----------------------------  ----------------  --------------------  ----------------------
  youtube.com                   172.217.19.238    Redirected (301)      DPI Drop / Timeout
  redirector.googlevideo.com    N/A               HTTP 404              DPI Drop / Timeout
  discord.com                   162.159.135.232   Redirected (301)      DPI Drop / Timeout
  instagram.com                 31.13.72.174      Redirected (301)      Available (301)
  facebook.com                  31.13.72.36       Timeout               DPI Drop / Timeout
  x.com                         172.66.0.227      Redirected (301)      Available (200)
  linkedin.com                  130.211.32.14     Timeout               DPI Drop / Timeout
  rutracker.org                 172.67.182.196    Timeout               DPI Drop / Timeout
  digitalocean.com              104.19.173.68     Redirected (301)      Available (301)
  amnezia.org                   65.9.62.27        Timeout               DPI Drop / Timeout
  getoutline.org                104.21.5.212      Timeout               DPI Drop / Timeout
  mailfence.com                 217.182.28.160    Timeout               DPI Drop / Timeout
  flibusta.is                   179.43.150.83     Timeout               DPI Drop / Timeout
  rezka.ag                      179.43.189.162    Timeout               DPI Drop / Timeout
  api.telegram.org              149.154.166.110   Redirected (301)      Available (302)
  play.google.com               142.251.154.7     Redirected (302)      DPI Drop / Timeout
  github.com                    140.82.121.4      Redirected (301)      Available (200)
  raw.githubusercontent.com     185.199.111.133   Redirected (301)      Available (301)

  [ Санкционные зарубежные сервисы ] [3 / 10 открываются с этого IP]
  Сервис                        Статус доступа
  ----------------------------  ----------------------
  spotify.com                   Available (301)
  netflix.com                   Blocked (Geo-403)
  patreon.com                   Blocked (Geo-403)
  swagger.io                    Blocked (Geo-403)
  snyk.io                       Blocked (Geo-403)
  mongodb.com                   Available (301)
  autodesk.com                  Available (301)
  graylog.org                   Blocked (Geo-403)
  redis.io                      Blocked (Geo-403)
  copilot.microsoft.com         Blocked (Geo-403)

5. 🎬 Стриминги, медиа и AI-сервисы (Western Services & Geolocation)
  Сервис                                Регион / Статус
  ------------------------------------  ----------------------
  Google                                RU
  Google Search Captcha                 No
  YouTube                               No (DPI Drop / Timeout)
  YouTube CDN                           No (000)
  YouTube Premium                       No (000)
  YouTube Music                         No (000)
  Twitch                                RU
  OpenAI ChatGPT                        NL
  Claude AI (Anthropic)                 Yes
  Google Gemini                         No (RU - Region blocked)
  Netflix                               No
  Spotify Signup                        No
  Deezer                                RU
  Reddit                                RU
  Reddit (Guest Access)                 Yes
  Disney+                               RU
  TikTok                                RU
  Apple Services                        RU
  Steam Store (Игры)                    Yes
  PlayStation Network                   EN
  Ookla Speedtest                       RU
  JetBrains                             MX
  Microsoft (Bing)                      RU
  Instagram (Meta)                      Yes
  Discord (Voice/Gateway)               Yes
  Twitter / X                           No (DPI Drop / Timeout)
  Rutracker                             No (DPI Drop / Timeout)
  Amnezia VPN (amnezia.org)             No (DPI Drop / Timeout)

  [ Распределение стран (Legend %) ]
    Код  Страна                Доля
    ---  --------------------  ------
    RU   Russia                65.1%
    LV   Latvia                27.9%
    MX   Mexico                4.7%
    NL   Netherlands           2.3%

6. 🚀 Тест скорости ноды (Speedtest by Ookla)
  • Замер канала:     Пропущено (для нод в РФ замер выполняется в Блоке 7)

7. ⚡ Связность с регионами РФ (Задержка RTT до 7 округов)

  [Центральный регион]
  • Москва (Hostkey DataLine)            1.4 ms      —
  • Москва (МТС)                         1.7 ms      —

  [Северо-Западный регион]
  • Санкт-Петербург (ЭР-Телеком)         13.0 ms     —

  [Приволжский регион]
  • Казань (ЭР-Телеком)                  64.4 ms     —
  • Казань (МТС)                         13.1 ms     —
  • Нижний Новгород (ТТК)                18.0 ms     —
  • Самара (ЭР-Телеком)                  19.9 ms     —

  [Южный регион]
  • Ростов-на-Дону (ЭР-Телеком)          18.2 ms     —
  • Волгоград (ЭР-Телеком)               28.0 ms     —
  • Волгоград (ТТК)                      30.3 ms     —
  • Астрахань (Билайн)                   49.2 ms     —

  [Уральский регион]
  • Тюмень (ЭР-Телеком)                  67.0 ms     —
  • Тюмень (МТС)                         37.3 ms     —
  • Челябинск (ЭР-Телеком)               29.7 ms     —
  • Пермь (ЭР-Телеком)                   75.3 ms     —
  • Уфа (ЭР-Телеком)                     43.2 ms     —

  [Сибирский регион]
  • Новосибирск (ЭР-Телеком)             48.9 ms     —
  • Красноярск (ЭР-Телеком)              73.9 ms     —
  • Омск (ЭР-Телеком)                    46.3 ms     —

  [Дальневосточный регион]
  • Иркутск (ЭР-Телеком)                 78.3 ms     —
  • Якутск (МТС)                         97.2 ms     —
```

---

## Управление и требования

Скрипт рассчитан на Ubuntu 24.04 LTS и запускается без CLI-флагов.

* Если не хватает `curl`, `jq` или `awk`, скрипт выводит команду `apt-get install -y ...` и завершается, ничего не устанавливая сам.
* Для отключения ANSI-цветов поддерживается переменная окружения `NO_COLOR=1`.
* Замер iPerf3 по регионам РФ можно пропустить нажатием `Enter`, `Space` или `s`.
* Внешние IPv4 и IPv6 в шапке отчёта автоматически маскируются (`*.*`).

---

## Без следов на диске

* Временные файлы хранятся в `/tmp/nodecheck.$PID.*` с правами `700`.
* Для Speedtest CLI задаётся `XDG_CONFIG_HOME="$TMP_WORK_DIR"`, чтобы он не создавал `~/.config/ookla`.
* Обработчик `trap cleanup` удаляет `/tmp/nodecheck.*` и тестовый файл `dd` при обычном выходе, ошибке или `Ctrl+C`.
* Скрипт не меняет системные и сетевые настройки и читает `/etc/os-release` без `source`.

---

Лицензия: [MIT](LICENSE).
