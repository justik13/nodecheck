# NodeCheck (RU Edition)

Скрипт проверки VPS и VPN-нод под Рунет: сверка по 18 базам GeoIP, обход блокировок, доступность сервисов РФ и связность с 7 макрорегионами.

[![CI](https://github.com/justik13/nodecheck/actions/workflows/ci.yml/badge.svg)](https://github.com/justik13/nodecheck/actions/workflows/ci.yml)
[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Быстрый запуск

Запуск одной командой без предварительной установки (время работы ~30 секунд):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Через `wget`:
```bash
bash <(wget -qO- https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Без замера скорости через iPerf3 (только пинг):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) --no-iperf
```

---

## Назначение

При настройке VPN-сервера для пользователей в РФ нужно контролировать четыре вещи:

1. **Обход блокировок РКН и ТСПУ:** доступность Instagram, Discord (включая шлюз голосовых каналов), Twitter/X, ChatGPT, Claude, Rutracker и региональных зон Google.
2. **YouTube без рекламы:** входит ли страна IP в список регионов без монетизации (Албания `AL`, Россия `RU`, Молдова `MD`, Монголия `MN`, Мьянма `MM`, Камбоджа `KH`). Нода помечается отметкой `[Без рекламы 🎬]`.
3. **Обратный геобондинг (Reverse Geoblocking):** открываются ли Госуслуги, Авито и российские банки (Сбер, Т-Банк, ВТБ). Если банк или сервис режет зарубежные адреса, скрипт указывает на необходимость Split-Tunneling.
4. **Связность и маршрутизация по РФ:** замер сетевой задержки до 7 узлов (Москва, Санкт-Петербург, Ростов-на-Дону, Казань, Екатеринбург, Новосибирск, Иркутск) и замер скорости через iPerf3.

---

## Проверки

### 1. Консенсус 18 баз GeoIP
* IPinfo.io, IP-API.com, Cloudflare (Trace), IP.SB, Ipregistry, IP-API.co, IP2Location.io, Country.is, GeoJS, 2ip.io, ipwho.is, ifconfig.co, IPLocation.net, ipbase.com, ipquery.io, IPAPI.is, RIPE NCC, IP.Guide.
* Параллельный опрос, процент согласия баз и отсортированное распределение стран.

### 2. Зарубежные сервисы
* **Instagram и Threads (Meta):** доступность веб-шлюза и контента.
* **Discord:** проверка шлюза `gateway.discord.gg`.
* **Twitter / X:** доступность `x.com`.
* **Нейросети:** OpenAI ChatGPT (с валидацией поддержки региона), Anthropic Claude, Google Gemini.
* **Google и YouTube:** регион аккаунта (GlifSetupAndroid), детекция отсутствия рекламы, YouTube CDN (IATA-код аэропорта), YouTube Premium, YouTube Music.
* **Мессенджеры и рабочие инструменты:** Signal (`chat.signal.org`), Notion (`notion.so`).
* **Игры и стриминг:** Spotify Signup, Steam Store, PlayStation Network, Netflix, Rutracker, Reddit, Apple Services.

### 3. Доступность сервисов РФ
* **Государственные порталы:** Госуслуги (`gosuslugi.ru`), ФНС (`nalog.gov.ru`), Мос.ру (`mos.ru`), РЖД (`ticket.rzd.ru`).
* **Поисковики и медиа:** Яндекс (`ya.ru`, проверка на SmartCaptcha), ВКонтакте (`vk.com`), Кинопоиск (`kinopoisk.ru`).
* **Банки:** СберБанк, Т-Банк, ВТБ, Альфа-Банк (проверка доступности с поддержкой сертификатов Минцифры).
* **Классифайды и маркетплейсы:** Авито (`avito.ru`, проверка на Qrator), Wildberries (`wildberries.ru`).

### 4. Связность по регионам РФ
* Москва (Центр, MSK-IX / Hostkey)
* Санкт-Петербург (Северо-Запад, SPB-IX)
* Ростов-на-Дону (Юг, ER-Telecom)
* Казань (Поволжье, ER-Telecom)
* Екатеринбург (Урал, ER-Telecom)
* Новосибирск (Сибирь, ER-Telecom)
* Иркутск (Восточная Сибирь, ER-Telecom)
* Скорость iPerf3 до Москвы (порт 10G, 3-секундный параллельный замер).

### 5. Качество IP и периметр
* **Антифрод:** Fraud Score от 0 до 100 через ipquery.io.
* **Тип адреса:** Residential / ISP либо Data Center / Hosting.
* **Google Captcha:** проверка на выдачу капчи «Необычный трафик».
* **Сетевой стек:** статус TCP BBR, открытость UDP для AmneziaWG / Hysteria 2, исходящий SMTP-порт 25.
* **Zero-Probing:** проверка локальных портов 80 и 443 на утечку SNI сканерам ТСПУ.

---

## Пример вывода

```text
================================================================================
 🇷🇺 NodeCheck (RU Edition) - VPN Node & Quality Auditor v3.1.0-ru
================================================================================
 IPv4:             168.222.254.191
 Локация / ASN:    DE (Frankfurt am Main) — AS198550 (NODE HOST LIMITED)
 Тип хоста:        Residential / ISP
 Антифрод / Риск:  Clean / Low Risk (0/100), Google Captcha: No
 Сетевой стек:     BBR: Active | UDP: Open | Port 25: Open
================================================================================

1. 🌐 Консенсус GeoIP баз данных (18 источников)
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

2. 🔓 Обход блокировок в РФ (Western Services)
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
  Signal                                Yes
  Notion                                Yes

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
  ВТБ (vtb.ru)                          Blocked (403 Geoblock)
  Альфа-Банк (alfabank.ru)              Blocked (403 Geoblock)
  Авито (avito.ru)                      Blocked (439 Qrator Captcha)
  Wildberries (wildberries.ru)          Blocked (WAF 498)
  Кинопоиск (kinopoisk.ru)              OK

4. ⚡️ Связность и скорость по регионам РФ (Multi-Region Latency & Throughput)
  Регион (Узел связи)                   Задержка (RTT)  Скорость (↓ DL / ↑ UL)
  ------------------------------------  --------------  -----------------------
  Москва (Центр, Hostkey / MSK-IX)      27.6 ms         ↓ 295 / ↑ 273 Mbps
  Санкт-Петербург (Северо-Запад, SPB)   16.0 ms         ↓ 225 / ↑ 843 Mbps
  Казань (Поволжье, ER-Telecom)         35.9 ms         ↓ 191 / ↑ 643 Mbps
  Ростов-на-Дону (Юг, ER-Telecom)       41.1 ms         ↓ 178 / ↑ 801 Mbps
  Екатеринбург (Урал, ER-Telecom)       48.2 ms         ↓ 173 / ↑ 801 Mbps
  Новосибирск (Сибирь, ER-Telecom)      72.9 ms         ↓ 76 / ↑ 602 Mbps
  Иркутск (Восточная Сибирь, ER)        87.5 ms         ↓ 49 / ↑ 308 Mbps

5. 🛡 Безопасность периметра (Zero-Probing Check)
  Порт 80/443 IP-Probe                  Protected (Drop/No SNI Leak)

================================================================================
 ⚖️  Вердикт пригодности ноды для РФ аудитории
================================================================================
 • Оценка ноды: 8.5 / 10 (ХОРОШО ДЛЯ VPN)
   - Зарубежные сервисы: Обход блокировок функционирует (19/20 сервисов доступно).
   - Внимание: Зарубежный IP блокируется сервисами РФ (4): ВТБ, Альфа-Банк, Авито, Wildberries.
   - Рекомендация Split-Tunneling (bypass): vtb.ru, alfabank.ru, avito.ru, wildberries.ru
   - Связность: Москва 27.6 ms, СПб 16.0 ms, Поволжье 35.9 ms, Урал 48.2 ms, Сибирь 72.9 ms.
   - Пропускная способность iPerf3: 740 Mbps.
================================================================================
```

---

## Опции

| Опция | Описание |
| :--- | :--- |
| `-h`, `--help` | Справка по всем опциям |
| `--no-iperf` | Пропустить замер скорости iPerf3 (только пинг) |
| `-j`, `--json` | Вывод в формате JSON (для ботов и мониторинга) |
| `-p`, `--proxy ADDR` | Проверка ноды через SOCKS5 (`127.0.0.1:1080`) |
| `-i`, `--interface IF` | Привязка запросов к интерфейсу (`wg0`, `tun0`) |
| `--no-doh` | Отключить DNS-over-HTTPS (системный резолвер) |
| `--doh PROVIDER` | Провайдер DoH (`cloudflare`, `quad9`, `adguard`) |
| `-v`, `--verbose` | Логирование сетевых запросов |

---

## Совместимость и требования

* **ОС:** Linux (тестировалось на Ubuntu 24.04 Noble Numbat).
* **Стек:** чистый Bash без Python и Node.js.
* **Утилиты:** `curl`, `jq`, `ping` (`iputils-ping`), `awk`, `column` (`bsdextrautils`), `iperf3`.
* **Безопасность:** скрипт не меняет настройки системы, временные файлы хранятся в изолированном каталоге `/tmp/nodecheck.XXXXXX` и гарантированно удаляются по триггеру `trap EXIT INT TERM`.
* **Время выполнения:** ~25–35 секунд.

---

## Лицензия

[MIT](LICENSE)
