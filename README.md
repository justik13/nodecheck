# 🇷🇺 NodeCheck (RU Edition) — Комплексный аудит нод и сетевого стека под РФ

Скрипт для глубокого аудита серверных нод (VPS/VDS/Dedicated), сетевого стека, репутации IP, геолокации, скорости и доступности сервисов под аудиторию РФ.

[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Traces](https://img.shields.io/badge/Storage-Zero%20Traces%20(Safe)-brightgreen)](#безопасность-и-чистота)

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
   * Однопроходный безопасный замер последовательной записи (256 МБ `fdatasync`) с защитой от записи в `tmpfs`/`ramfs`, контролем кода завершения `dd` и проверкой наличия свободного места (не менее 2 ГБ и не более 90% заполнения).

3. **Сетевой стек и BBR:**
   * Диагностика TCP BBR: статус активности + проверка наличия скомпилированного модуля ядра `tcp_bbr.ko` (`Inactive (Available)`).
   * Мультисерверная проверка Outbound Port 25 (SMTP пул: Gmail, Outlook, Mail.ru) без ложных срабатываний из-за единичного троттлинга.
   * Двунаправленный UDP (проверка DNS-резолвинга 1.1.1.1 / 8.8.8.8).

4. **Многоисточниковый консенсус антифрода (стандарт xykt/IPQuality):**
   * Параллельный опрос 4 независимых баз (**Scamalytics, AbuseIPDB, IP-API, IPQuery**) за ~350 мс.
   * Консенсусная классификация хоста: `Tor Exit Node` -> `Commercial VPN / Proxy` -> `Data Center / Hosting` -> `Mobile` -> `Residential`.
   * Проверка на нахождение IP в реестре блокировок Роскомнадзора (**базы Antifilter `ip.lst` и CIDR `ipsum.lst`**).
   * Прямая проверка триггера **Google Captcha** («Необычный трафик»).

5. **Параллельный DNSBL-сканер (12 спам-баз):**
   * Быстрый (~210 мс) параллельный опрос 12 проверенных мировых почтовых черных списков (Barracuda, SpamCop, DroneBL, Surriel PSBL, Mailspike, UCEPROTECT-1, GBUdb, Blocklist.de, s5h, InterServer, 0spam, Nordspam).
   * Встроенная фильтрация служебных кодов отказа публичных DNS (`127.255.255.*`) и исключение закрытых сервисов (вроде SORBS).

6. **Консенсус 18 баз GeoIP:**
   * Одновременный параллельный опрос 18 провайдеров геолокации (IPinfo, Cloudflare, IP-API, IP2Location, 2ip, ipwho.is, ifconfig.co, IPLocation, ipbase, ipquery, IPAPI.is, RIPE NCC, IP.Guide и др.) с подсчетом процента голосов за страну.

7. **Доступность зарубежных сервисов (Western Services):**
   * **Claude AI (Anthropic)** — детекция фильтрации датацентровых IP через Cloudflare WAF 403.
   * **OpenAI ChatGPT** — проверка доступности с отдачей кода региона.
   * **Google Gemini, Google (Регион)**.
   * **YouTube & YouTube CDN** — определение геопривязки кеш-сервера и **YouTube Ad-Free** (маршруты без рекламы).
   * **Instagram, Discord, Twitter/X, Rutracker, Amnezia VPN, Spotify, Netflix, Steam, PSN, Reddit, Apple Services**.

8. **Сервисы РФ (Reverse Geoblocking):**
   * Проверка пробива через Geo-WAF и Anti-VPN фильтры с зарубежных нод: Госуслуги, ФНС, Мос.ру, РЖД, Яндекс, VK.
   * Банки: СберБанк, Т-Банк, ВТБ, Альфа-Банк.
   * Маркетплейсы: Авито (Qrator Captcha 439), Wildberries (WAF 498), Озон (WAF 403), Кинопоиск.

9. **Скорость и связность:**
   * **Замер скорости ноды:** нативный движок Speedtest by Ookla CLI для зарубежных нод (выгрузка и загрузка до 10 Gbps).
   * **Дуплексный iPerf3 по 7 макро-регионам РФ:** пинг и реальная пропускная способность (↓ DL / ↑ UL) до узлов в Москве, СПб, Казани, Ростове-на-Дону, Екатеринбурге, Новосибирске и Иркутске.

---

## 🖥 Пример вывода

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ NodeCheck (RU Edition) - Node & Network Quality Auditor v3.9.0-ru            │
└──────────────────────────────────────────────────────────────────────────────┘
 IPv4:              198.51.100.24
 IPv6:              None (Not configured)
 Локация / ASN:     PL (Warsaw) — AS12345 (Hosting Provider Ltd)
 ОС и ядро:         Ubuntu 24.04.4 LTS (6.8.0-111-generic x86_64)
 Платформа:         KVM | Аптайм: 4d 3h 11m
 Процессор (CPU):   AMD Ryzen 9 9950X 16-Core Processor (1 vCPU) [VAES, 10.76 GB/s]
 CPU Steal:         0.0% (Clean) | 0.02% (за аптайм)
 Память / Диск:     RAM: 352 MB / 1967 MB (17.9%) | Диск: 3.8G / 15G (28%) [Virtual Disk, I/O: 1.1 GB/s]
 Тип хоста:         Data Center / Hosting
 Репутация / Базы:  РКН: Clean (Not in Registry) | DNSBL: Clean (0/12)
 Антифрод / Риск:   Clean / Low Risk (Scam: 0/100 | Abuse: 0% | IPQ: 20/100), Google Captcha: Clean (No Captcha)
 Сетевой стек:      BBR: Inactive (Available) | UDP: Open (DNS Bidirectional) | Port 25: Open
────────────────────────────────────────────────────────────────────────────────

1. Консенсус баз GeoIP (18 источников)
  База данных                   Страна (IPv4)
  ----------------------------  -------------
  IPinfo.io                     PL
  IP-API.com                    PL
  Cloudflare                    PL
  IP.SB                         PL
  Ipregistry                    PL
  IP-API.co                     PL
  IP2Location.io                PL
  Country.is                    PL
  GeoJS                         PL
  2ip.io                        PL
  ipwho.is                      PL
  ifconfig.co                   BR
  IPLocation.net                PL
  ipbase.com                    PL
  ipquery.io                    PL
  IPAPI.is                      PL
  RIPE NCC                      PL
  IP.Guide                      PL

  Консенсус: PL (Poland) — 17/18 (94.4%)

  Код  Страна  Доля (IPv4)
  ---  ------  -----------
  PL   Poland  94.4% (17/18)
  BR   Brazil  5.6% (1/18)

2. Доступность зарубежных сервисов (Western Services)
  Сервис                                Статус
  ------------------------------------  ------
  Instagram (Meta)                      Yes
  Discord (Voice/Gateway)               Yes
  Twitter / X                           Yes
  OpenAI ChatGPT                        PL
  Claude AI (Anthropic)                 No (Cloudflare 403)
  Google (Регион)                       PL
  Google Gemini                         Yes (PL)
  YouTube                               PL
  YouTube CDN                           Yes (WAW)
  YouTube Premium                       Yes
  YouTube Music                         Yes
  Rutracker                             Yes
  Amnezia VPN (amnezia.org)             Yes
  Spotify Signup                        Yes (PL)
  Netflix                               Yes
  Steam Store (Игры)                    Yes
  PlayStation Network                   Yes
  Reddit                                Yes
  Apple Services                        PL

3. Доступность сервисов РФ (Reverse Geoblocking)
  Сервис                                Статус
  ------------------------------------  ------
  Госуслуги (gosuslugi.ru)              OK
  ФНС (nalog.gov.ru)                    OK
  Мос.ру (mos.ru)                       OK
  РЖД (ticket.rzd.ru)                   OK
  Яндекс (ya.ru)                        OK
  ВКонтакте (vk.com)                    OK
  СберБанк (sberbank.ru)                OK
  Т-Банк (tbank.ru)                     Blocked (Timeout / Geo-Drop)
  ВТБ (vtb.ru)                          OK
  Альфа-Банк (alfabank.ru)              OK
  Авито (avito.ru)                      Blocked (439 Qrator Captcha)
  Wildberries (wildberries.ru)          Blocked (WAF 498)
  Озон (ozon.ru)                        Blocked (WAF 403)
  Кинопоиск (kinopoisk.ru)              OK

4. 🚀 Тест скорости ноды (Speedtest by Ookla)
  • Провайдер:        KPN B.V. (Amsterdam, Netherlands) [Ping: 2.1 ms]
  • Скорость:         ↓ 6192.4 Mbps / ↑ 7630.8 Mbps (Full Duplex 10G)

5. ⚡️ Связность и скорость по регионам РФ (Multi-Region Latency & Throughput)
  Регион              Город            Провайдер             Задержка  Скорость (↓ DL / ↑ UL)
  ------------------  ---------------  --------------------  --------  ----------------------
  Центральный         Москва           Hostkey DataLine      44.7 ms   ↓ 480 Mbps / ↑ 520 Mbps
  Северо-Западный     СПб              ЭР-Телеком            52.1 ms   ↓ 410 Mbps / ↑ 490 Mbps
  Поволжский          Казань           ТТК                   58.3 ms   ↓ 320 Mbps / ↑ 380 Mbps
  Южный               Ростов-на-Дону   ЭР-Телеком            54.0 ms   ↓ 340 Mbps / ↑ 390 Mbps
  Уральский           Екатеринбург     ЭР-Телеком            62.0 ms   ↓ 210 Mbps / ↑ 260 Mbps
  Сибирский           Новосибирск      ЭР-Телеком            92.0 ms   ↓ 150 Mbps / ↑ 180 Mbps
  Дальневосточный     Якутск           МТС                   212.6 ms  ↓ 65 Mbps / ↑ 80 Mbps
```

---

## ⚙️ Опции запуска

| Опция | Описание |
| :--- | :--- |
| `-h`, `--help` | Показать справку по всем опциям |
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
* **Гарантированная очистка:** при штатном завершении, прерывании через `Ctrl+C` или аварийном выходе срабатывает обработчик сигналов `trap cleanup EXIT INT TERM`, удаляющий 100% временных файлов.
* **Безопасность системы:** скрипт не модифицирует настройки системы, не меняет системные конфигурации сети и не оставляет следов на диске.

---

## 📄 Лицензия

Проект распространяется под лицензией [MIT](LICENSE).
