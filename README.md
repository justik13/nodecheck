# 🇷🇺 NodeCheck (RU Edition) — Комплексный аудит нод и сетевого стека под РФ

Скрипт для глубокого аудита серверных нод (VPS/VDS/Dedicated), сетевого стека, репутации IP, геолокации, скорости и доступности сервисов под аудиторию РФ.

[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Traces](https://img.shields.io/badge/Storage-Zero%20Traces%20(Safe)-brightgreen)](#-безопасность-и-чистота-zero-traces)

---

## ⚡️ Быстрый запуск

Запуск одной строкой на сервере (чистый Bash, установка сторонних пакетов и компиляция не требуются):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Через `wget`:
```bash
bash <(wget -qO- https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

### Экспресс-режимы:
* **Без iPerf3 по регионам РФ** (только пинг, аппаратный тест, репутация, сервисы и Ookla Speedtest, ~10–12 секунд):
  ```bash
  bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) --no-iperf
  ```
* **Чистый JSON** (для Telegram-ботов, мониторинга и автоматизации):
  ```bash
  bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) -j
  ```
* **Только IPv4 / IPv6:**
  ```bash
  bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) -4
  bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) -6
  ```

---

## 🔍 Ключевые возможности

1. **Железо, CPU Steal и аппаратное шифрование:**
   * Определение модели процессора, vCPU, RAM, аптайма и виртуализации (KVM/LXC/Bare-Metal).
   * Замер **CPU Steal %** (выборка в реальном времени + накопленное среднее за весь аптайм ноды).
   * Тест аппаратного ускорения криптографии (**AES-NI / VAES / ARM CE**) через OpenSSL в GB/s за 1.0 секунду.

2. **Безопасный бенчмарк и классификатор диска:**
   * Определение реального типа накопителя (**NVMe SSD, SSD, Virtual Disk, HDD, Container OverlayFS, RAM Disk**) через `lsblk PKNAME` и `rotational`.
   * Однопроходный безопасный замер последовательной записи (64 МБ с `fdatasync`, таймаут 5с) с защитой от записи в `tmpfs`/`ramfs`, контролем кода завершения `dd` и проверкой наличия свободного места (не менее 2 ГБ и не более 90% заполнения).

3. **Сетевой стек и BBR:**
   * Диагностика TCP BBR: статус активности + проверка наличия скомпилированного модуля ядра `tcp_bbr.ko` (`Inactive (Available)`).
   * Мультисерверная проверка Outbound Port 25 (SMTP пул: Gmail, Outlook, Mail.ru) без ложных срабатываний из-за единичного троттлинга.
   * Двунаправленный UDP (проверка DNS-резолвинга 1.1.1.1 / 8.8.8.8).

4. **Многоисточниковый консенсус антифрода и определение типа IP (стандарт xykt/IPQuality):**
   * Параллельный опрос 4 независимых баз (**Scamalytics, AbuseIPDB, IP-API, IPQuery**) за ~350 мс.
   * Определение типа IP: **Native IP (Локальный)** vs **Broadcast IP (Маршрутизированный)** через сопоставление физической геолокации и RIR (RIPE/ARIN/APNIC).
   * Консенсусная классификация хоста: `Tor Exit Node` -> `Commercial VPN / Proxy` -> `Data Center / Hosting` -> `Mobile` -> `Residential`.
   * Проверка на нахождение IP в реестре блокировок Роскомнадзора (**базы Antifilter `ip.lst` и CIDR `ipsum.lst`**).
   * Прямая проверка триггера **Google Captcha** («Необычный трафик»).

5. **Параллельный DNSBL-сканер (12 спам-баз):**
   * Быстрый (~210 мс) параллельный опрос 12 проверенных мировых почтовых черных списков (Barracuda, SpamCop, DroneBL, Surriel PSBL, Mailspike, UCEPROTECT-1, GBUdb, Blocklist.de, s5h, InterServer, 0spam, Nordspam).
   * Встроенная фильтрация служебных кодов отказа публичных DNS (`127.255.255.*`) и исключение закрытых сервисов (вроде SORBS).

6. **Консенсус 18 баз GeoIP:**
   * Одновременный параллельный опрос 18 провайдеров геолокации (IPinfo, Cloudflare, IP-API, IP2Location, 2ip, ipwho.is, ifconfig.co, IPLocation, ipbase, ipquery, IPAPI.is, RIPE NCC, IP.Guide и др.) с подсчетом процента голосов за страну.

7. **Аудит DNS-резолверов и детекция спуфинга (12 резолверов):**
   * Проверка Cloudflare, Google, Quad9, AdGuard, NextDNS, Yandex по 3 протоколам: **UDP (53)**, **DoH (HTTPS)** и **DoT (TLS 853)**.
   * Детекция **DNS Hijacking / Spoofing** через сверку эталонных IP для `rutracker.org`.

8. **Аудит дата-центров Telegram MTProto (DC1–DC5):**
   * Нативный обмен пакетами MTProto (`req_pq_multi` / `resPQ`) с шифрованием AES-CTR по порту 443 для всех 5 дата-центров Telegram.

9. **Сервисы РФ (Reverse Geoblocking):**
   * Проверка доступности через Geo-WAF и Anti-VPN фильтры с ноды: Госуслуги, ФНС, Мос.ру, РЖД, Яндекс, VK.
   * Банки: СберБанк, Т-Банк, ВТБ, Альфа-Банк.
   * Маркетплейсы: Авито (Qrator Captcha 439), Wildberries (WAF 498), Озон (WAF 403), Кинопоиск.

10. **Аудит фильтрации ТСПУ (Censorcheck DPI) и санкционные ресурсы:**
    * **DPI ТСПУ (18 доменов):** раздельный тест HTTP 80 (редиректы) и HTTPS 443 (DPI Drop / TLS сбросы / заглушки РКН 451): YouTube, Discord, Instagram, Facebook, X/Twitter, Rutracker, Amnezia, Outline, Telegram API, Google Play и др.
    * **Санкционные западные сервисы (10 доменов):** проверка ресурсов, закрытых со стороны Запада для IP из РФ (Spotify, Netflix, Patreon, Swagger, Snyk, MongoDB, Autodesk, Graylog, Redis, MS Copilot).

11. **Стриминги, медиа и AI-сервисы (IP Region 21 + Legend %):**
    * Точное определение страны, которую видят стриминги и нейросети: Claude AI, OpenAI ChatGPT, Google Gemini, YouTube (включая **YouTube Ad-Free**), TikTok, Disney+, Twitch, JetBrains, Ookla, Microsoft/Bing, Deezer, Steam, PlayStation, Reddit, Apple Services.
    * Сводная таблица **Legend %** распределения стран среди сервисов.

12. **Скорость и связность:**
    * **Замер скорости ноды:** нативный движок Speedtest by Ookla CLI для зарубежных нод (выгрузка и загрузка до 10 Gbps).
    * **Дуплексный iPerf3 по 7 макро-регионам РФ:** пинг и реальная пропускная способность (↓ DL / ↑ UL) до 20 узлов в Москве, СПб, Казани, Ростове-на-Дону, Екатеринбурге, Новосибирске и Иркутске.

---

## 🖥 Пример вывода

```text
+------------------------------------------------------------------------------+
| NodeCheck (RU Edition) - Node & Network Quality Auditor v4.0.0-ru            |
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
  Яндекс (ya.ru)                        OK
  ВКонтакте (vk.com)                    OK
  СберБанк (sberbank.ru)                OK
  Т-Банк (tbank.ru)                     OK
  ВТБ (vtb.ru)                          OK
  Альфа-Банк (alfabank.ru)              OK
  Авито (avito.ru)                      Blocked (439 Qrator Captcha)
  Wildberries (wildberries.ru)          Blocked (WAF 498)
  Озон (ozon.ru)                        Blocked (WAF 403)
  Кинопоиск (kinopoisk.ru)              OK

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

## ⚙️ Опции запуска

| Опция | Описание |
| :--- | :--- |
| `-h`, `--help` | Показать справку по всем опциям |
| `-f`, `--full-ip` | Отображать полный IP без маскирования (по умолчанию скрыт: `*.*`) |
| `-4`, `--ipv4` | Принудительно тестировать только IPv4 стек |
| `-6`, `--ipv6` | Принудительно тестировать только IPv6 стек |
| `-j`, `--json` | Вывод полного отчёта в чистом формате JSON |
| `-s`, `--streams N` | Количество параллельных потоков iPerf3 (по умолч.: 2 для 1 vCPU, 4 для 2+ vCPU) |
| `--no-iperf` | Пропустить замер скорости iPerf3 по регионам РФ (только пинг) |
| `--no-speedtest` | Пропустить замер скорости ноды Ookla Speedtest |
| `--no-crypto` | Пропустить аппаратный тест шифрования OpenSSL |
| `--io`, `--disk-bench` | Запустить тест записи диска I/O (включен в TUI, выключен в `-j`) |
| `--no-io` | Отключить замер скорости диска (I/O) |
| `--full-iperf` | Расширенный замер iPerf3 (по 10с на каждый регион) |
| `--iperf-time SEC` | Время замера iPerf3 (по умолч.: 3 секунды) |
| `--no-dns` | Пропустить проверку DNS-резолверов (UDP/DoH/DoT и Spoofing) |
| `--no-tg` | Пропустить аудит дата-центров Telegram (MTProto) |
| `--no-dpi` | Пропустить аудит DPI-блокировок ТСПУ |
| `--no-geoblock` | Пропустить аудит санкционных зарубежных сервисов |
| `--no-color` | Отключить форматирование ANSI-цветов |
| `-p`, `--proxy ADDR` | Тестирование через SOCKS5/SOCKS5h прокси (`хост:порт`) |
| `-i`, `--interface IF`| Привязка запросов к конкретному сетевому интерфейсу (`eth0`, `ens3`) |
| `--no-doh` | Использовать системный DNS вместо DNS-over-HTTPS |
| `--doh PROVIDER` | Выбор DoH-провайдера (`cloudflare`, `quad9`, `adguard`) |
| `--install-deps` | Автоматически установить недостающие утилиты через `apt` |
| `-v`, `--verbose` | Подробное логирование запросов в консоль |
| `-d`, `--debug` | Отладочный режим с записью трассировки в лог-файл |

---

## 🔒 Безопасность и чистота (Zero Traces)

* **Изолированная среда:** все временные данные сессии хранятся в защищенной директории `/tmp/nodecheck.$PID.*`.
* **Песочница конфигураций:** для сторонних бинарников (включая Ookla Speedtest) принудительно устанавливается `XDG_CONFIG_HOME="$TMP_WORK_DIR"`, что исключает создание служебных директорий в домашнем каталоге (`~/.config/ookla`).
* **Гарантированная очистка:** при штатном завершении, прерывании через `Ctrl+C` или аварийном выходе срабатывает глобальный обработчик сигналов `trap cleanup EXIT INT TERM`, немедленно удаляющий тестовые файлы дискового бенчмарка и 100% временных директорий.
* **Безопасность системы:** скрипт не модифицирует настройки системы, не меняет системные конфигурации сети, изолированно читает метаданные дистрибутива без выполнения стороннего кода через `source` и не оставляет следов на диске.

---

## 📄 Лицензия

Проект распространяется под лицензией [MIT](LICENSE).
