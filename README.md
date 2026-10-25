# 🇷🇺 NodeCheck (RU Edition) — Node & Network Quality Auditor

Скрипт для комплексного аудита серверных нод (VPS/VDS/Dedicated), сетевого стека, репутации IP, геолокации и доступности сервисов под аудиторию РФ.

[![CI](https://github.com/justik13/nodecheck/actions/workflows/ci.yml/badge.svg)](https://github.com/justik13/nodecheck/actions/workflows/ci.yml)
[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Быстрый запуск

Запуск одной командой на сервере (чистый Bash, установка сторонних пакетов не требуется):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Через `wget`:
```bash
bash <(wget -qO- https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Без замера скорости iPerf3 (только пинг и сетевые проверки, ~10–12 секунд):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) --no-iperf
```

Вывод в формате чистого JSON:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) -j
```

---

## Назначение и ключевые возможности

1. **Характеристики ноды и CPU Steal:** определение гипервизора (KVM/LXC/Bare-Metal), модели процессора, vCPU, RAM, диска, аптайма и замер **CPU Steal %** (выборка 2.0 секунды + среднее за весь аптайм) для своевременного обнаружения шумных соседей по хосту.
2. **Сетевой стек:** статус TCP BBR, открытость UDP (двунаправленный DNS) и отсутствие блокировки SMTP (порт 25).
3. **Консенсус 18 баз GeoIP:** одновременный параллельный опрос 18 провайдеров геолокации (IPinfo, Cloudflare, IP-API, IP2Location, MaxMind/GeoJS и др.) для точного определения страны и предотвращения утечек региона.
4. **Реестр блокировок РКН и антифрод:** проверка IP ноды на нахождение в реестре запрещенных сайтов (базы Antifilter), оценка риска мошенничества (Fraud / Risk Score 0–100) и проверка на Google Captcha.
5. **Доступность зарубежных сервисов:** проверка доступности Instagram, Discord (включая шлюз голосовых каналов), Twitter/X, ChatGPT, Claude, Google, Gemini, YouTube, Rutracker, Spotify, Netflix, Steam, PSN, Reddit, Apple, Signal, Notion. Все тесты считывают полезную нагрузку.
6. **Доступность сервисов РФ (Reverse Geoblocking):** открываются ли Госуслуги, ФНС, Мос.ру, РЖД, Авито, Wildberries, Озон (с детекцией anti-bot фильтра `403`) и российские банки (Сбер, Т-Банк, ВТБ, Альфа-Банк).
7. **Связность и дуплексный iPerf3 по всей РФ:** замер задержки (RTT) и реальной пропускной способности (↓ DL / ↑ UL) до 7 макро-регионов РФ (Москва, Санкт-Петербург, Казань, Ростов-на-Дону, Екатеринбург, Новосибирск, Иркутск) с пулом портов 5201–5209.

---

## Пример вывода

```text
================================================================================
 🇷🇺 NodeCheck (RU Edition) - Node & Network Quality Auditor v3.4.1-ru
================================================================================
 IPv4:             168.222.254.191
 IPv6:             None (Not configured)
 Локация / ASN:    DE (Frankfurt am Main) — AS198550 (NODE HOST LIMITED)
 ОС и ядро:        Ubuntu 24.04.4 LTS (6.8.0-147-generic x86_64)
 Платформа:        KVM | Аптайм: 4 days, 4 hours, 20 minutes
 Процессор (CPU):  AMD Ryzen 9 5950X 16-Core Processor (1 vCPU)
 CPU Steal:        0.0% (Clean, замер 2.0s) | 0.04% (за аптайм)
 Память / Диск:    RAM: 544 MB / 961 MB (56.6%) | Диск: 5.6G / 9.8G (61%)
 Тип хоста:        Residential / ISP
 Реестр РКН:       Clean (Not in Registry)
 Антифрод / Риск:  Clean / Low Risk (0/100), Google Captcha: Clean (No Captcha)
 Сетевой стек:     BBR: Active | UDP: Open (DNS Bidirectional) | Port 25: Open
================================================================================

1. 📍 Консенсус GeoIP баз данных (18 источников)
  База данных                   Страна (IPv4)
  ----------------------------  -------------
  IPinfo.io                     DE
  IP-API.com                    DE
  Cloudflare                    DE
  IP.SB                         DE
  Ipregistry                    DE
  IP-API.co                     DE
  IP2Location.io                DE
  Country.is                    DE
  GeoJS                         DE
  2ip.io                        DE
  ipwho.is                      DE
  ifconfig.co                   US
  IPLocation.net                DE
  ipbase.com                    DE
  ipquery.io                    US
  IPAPI.is                      IN
  RIPE NCC                      DE
  IP.Guide                      DE

  Консенсус: DE (Germany) — 15/18 (83.3%)

  Код  Страна         Доля (IPv4)
  ---  ------         -----------
  DE   Germany        83.3% (15/18)
  US   United States  11.1% (2/18)
  IN   India          5.6% (1/18)

2. 🌍 Доступность зарубежных сервисов (Western Services)
  Сервис                                Статус
  ------------------------------------  ------
  Instagram (Meta)                      Yes
  Discord (Voice/Gateway)               Yes
  Twitter / X                           Yes
  OpenAI ChatGPT                        DE
  Anthropic Claude AI                   No (403 Cloudflare Challenge)
  Google (Регион)                       GB
  Google Gemini                         Yes (GB)
  YouTube                               GB
  YouTube CDN                           Yes (FRA)
  YouTube Premium                       Yes
  YouTube Music                         Yes
  Rutracker                             Yes
  Spotify Signup                        Yes
  Netflix                               Yes
  Steam Store (Игры)                    Yes
  PlayStation Network                   Yes
  Reddit                                Yes
  Apple Services                        DE
  Signal                                No (Timeout / TSPU Block)
  Notion                                Yes

3. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)
  Сервис                                Статус
  ------------------------------------  ------
  Госуслуги (gosuslugi.ru)              OK
  ФНС (nalog.gov.ru)                    OK
  Мос.ру (mos.ru)                       OK
  РЖД (ticket.rzd.ru)                   Blocked (Timeout / Geo-Drop)
  Яндекс (ya.ru)                        OK
  ВКонтакте (vk.com)                    OK
  СберБанк (sberbank.ru)                Blocked (Timeout / Geo-Drop)
  Т-Банк (tbank.ru)                     OK
  ВТБ (vtb.ru)                          Blocked (Timeout / Geo-Drop)
  Альфа-Банк (alfabank.ru)              OK
  Авито (avito.ru)                      Blocked (439 Qrator Captcha)
  Wildberries (wildberries.ru)          Blocked (WAF 498)
  Озон (ozon.ru)                        Blocked (Anti-VPN 403)
  Кинопоиск (kinopoisk.ru)              OK

4. ⚡️ Связность и скорость по регионам РФ (Multi-Region Latency & Throughput)
  Регион (Узел связи)                   Задержка (RTT)  Скорость (↓ DL / ↑ UL)
  ------------------------------------  --------------  -----------------------
  Москва (Центр, Hostkey / MSK-IX)      46.0 ms         ↓ 493 Mbps / ↑ 301 Mbps
  Санкт-Петербург (Северо-Запад, SPB)   57.9 ms         ↓ 419 Mbps / ↑ 1220 Mbps
  Казань (Поволжье, ER-Telecom)         59.9 ms         ↓ 356 Mbps / ↑ 1085 Mbps
  Ростов-на-Дону (Юг, ER-Telecom)       64.5 ms         ↓ 342 Mbps / ↑ 1035 Mbps
  Екатеринбург (Урал, ER-Telecom)       66.6 ms         ↓ 191 Mbps / ↑ 380 Mbps
  Новосибирск (Сибирь, ER-Telecom)      94.0 ms         ↓ 151 Mbps / ↑ 1049 Mbps
  Иркутск (Восточная Сибирь, ER)        116.4 ms        ↓ 88 Mbps / ↑ 564 Mbps

────────────────────────────────────────────────────────────────────────────────
 📊 Итоговый вердикт качества ноды под аудиторию РФ
────────────────────────────────────────────────────────────────────────────────
  Вердикт качества:          Отлично: подходит для VPN/прокси под РФ (доступ к Западу + нет гео-блокировок РФ)
  Зарубежные сервисы:        18/20 доступны
  Ресурсы РФ (Reverse Geo):  10/14 открываются
  Репутация IP и РКН:        Clean (Not in Registry) | Clean / Low Risk (0/100)
────────────────────────────────────────────────────────────────────────────────
```

---

## Опции

| Опция | Описание |
| :--- | :--- |
| `-h`, `--help` | Справка по всем опциям |
| `--no-iperf` | Пропустить замер скорости iPerf3 (только пинг) |
| `--full-iperf` | Полный тест iPerf3 (по 5с на DL и UL) |
| `--iperf-time SECS` | Время замера iPerf3 (по умолч.: 5с DL / 3с UL) |
| `--no-color` | Отключить цветовое форматирование ANSI |
| `-j`, `--json` | Вывод в формате JSON (для ботов и мониторинга) |
| `-p`, `--proxy ADDR` | Проверка ноды через SOCKS5 (`127.0.0.1:1080`) |
| `-i`, `--interface IF` | Привязка запросов к интерфейсу (`ens3`, `eth0`) |
| `--no-doh` | Отключить DNS-over-HTTPS (системный резолвер) |
| `--doh PROVIDER` | Провайдер DoH (`cloudflare`, `quad9`, `adguard`) |
| `-v`, `--verbose` | Логирование сетевых запросов |
| `-d`, `--debug` | Отладочный режим с сохранением подробного лога |

---

## Совместимость и требования

* **ОС:** Linux (полная оптимизация под Ubuntu 24.04 Noble Numbat и современные дистрибутивы).
* **Стек:** чистый Bash без Python и Node.js.
* **Утилиты:** `curl`, `jq`, `ping` (`iputils-ping`), `awk`, `column` (`bsdextrautils`), `iperf3`.
* **Безопасность:** скрипт не меняет настройки системы, временные файлы хранятся в изолированном каталоге `/tmp/nodecheck.XXXXXX` и гарантированно удаляются по триггеру `trap EXIT INT TERM`.
* **Время выполнения:** ~25–35 секунд (быстрее лимита в 2–3 минуты).

---

## Лицензия

[MIT](LICENSE)
