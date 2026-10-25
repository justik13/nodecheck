# NodeCheck (RU Edition)

Скрипт комплексного аудита VPS и VPN-нод под Рунет: сверка по 18 базам GeoIP, обход блокировок, доступность сервисов РФ, аудит режима «Белых списков» (White List), защита периметра от активного зондирования ТСПУ и отказоустойчивый замер связности по регионам РФ.

[![CI](https://github.com/justik13/nodecheck/actions/workflows/ci.yml/badge.svg)](https://github.com/justik13/nodecheck/actions/workflows/ci.yml)
[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Быстрый запуск

Запуск одной командой без предварительной установки (время работы ~30–35 секунд):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Через `wget`:
```bash
bash <(wget -qO- https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Без замера скорости через iPerf3 (только пинг, занимает ~10–15 секунд):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) --no-iperf
```

---

## Назначение и ключевые возможности

При настройке VPN-сервера для пользователей в РФ критически важно контролировать:

1. **Характеристики ноды и CPU Steal:** определение гипервизора (KVM/LXC/Bare-Metal), модели процессора, vCPU, RAM, диска, аптайма и замер **CPU Steal %** (выборка 2.0 секунды + среднее за весь аптайм) для своевременного обнаружения шумных соседей по хосту и риска джиттера VPN.
2. **Консенсус 18 баз GeoIP:** одновременный параллельный опрос 18 провайдеров геолокации для предотвращения утечек региона и некорректного определения страны.
3. **Реестр блокировок РКН:** проверка IP-адреса ноды на нахождение в едином реестре запрещенных сайтов (базы Antifilter). Если IP заблокирован РКН, нода не откроется у провайдеров РФ.
4. **Обход блокировок РКН и ТСПУ:** доступность Instagram, Discord (включая шлюз голосовых каналов), Twitter/X, ChatGPT, Claude, Rutracker, Signal, Notion. Все тесты считывают полезную нагрузку для исключения ложных пропусков на эвристической отсечке DPI в 16–20 КБ.
5. **YouTube без рекламы:** входит ли страна IP в список регионов без монетизации (Албания `AL`, Россия `RU`, Молдова `MD`, Монголия `MN`, Мьянма `MM`, Камбоджа `KH`).
6. **Обратный геобондинг (Reverse Geoblocking):** открываются ли Госуслуги, ФНС, Мос.ру, РЖД, Авито, Wildberries, Озон (с детекцией anti-VPN фильтра `403`) и российские банки (Сбер, Т-Банк, ВТБ, Альфа-Банк).
7. **Готовность к режиму «Белых списков» (White List & Anycast CDN):** аудит доступности ключевых узлов белого списка (мессенджер MAX `max.ru`, Anycast Яндекс `yastatic.net`, VK Cloud, Госуслуги) и расчет RTT-порога для каскада VLESS XHTTP через Yandex Cloud CDN (предотвращение ошибок HTTP 504 Gateway Timeout).
8. **Безопасность периметра и Anti-Active Probing:** аудит портов 80 и 443 на утечки доменных имен в HTTP-редиректах (`Location:`) и TLS-сертификатах (`CN/SAN`) цензурным роботам ТСПУ. Проверка соответствия SelfSteal SNI через `--sni`.
9. **Связность и дуплексный iPerf3 по всей РФ:** замер задержки (RTT) и реальной пропускной способности (↓ DL / ↑ UL) до 7 макро-регионов РФ (Москва, Санкт-Петербург, Казань, Ростов-на-Дону, Екатеринбург, Новосибирск, Иркутск) с пулом портов 5201–5209.
10. **Сетевой стек и реальный MTU:** статус TCP BBR, открытость UDP, считывание реального MTU сетевого интерфейса и Path MTU до шлюза без выдуманных ярлыков.

---

## Пример вывода

```text
================================================================================
 🇷🇺 NodeCheck (RU Edition) - VPN Node & Quality Auditor v3.2.0-ru
================================================================================
 IPv4:             168.222.254.191
 Локация / ASN:    DE (Frankfurt am Main) — AS198550 (NODE HOST LIMITED)
 ОС и ядро:        Ubuntu 24.04.4 LTS (6.8.0-147-generic x86_64)
 Платформа:        KVM | Аптайм: 4 days, 3 hours, 56 minutes
 Процессор (CPU):  AMD Ryzen 9 5950X 16-Core Processor (1 vCPU)
 CPU Steal:        0.0% (Clean, замер 2.0s) | 0.04% (за аптайм)
 Память / Диск:    RAM: 571 MB / 961 MB (59.4%) | Диск: 5.6G / 9.8G (61%)
 Тип хоста:        Residential / ISP
 Реестр РКН:       Clean (Not in Registry)
 Антифрод / Риск:  Clean / Low Risk (0/100), Google Captcha: Clean (No Captcha)
 Сетевой стек:     BBR: Active | UDP: Open (DNS Bidirectional) | Port 25: Open
 MTU сети:         1500 (Path MTU: 1476)
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
  PlayStation Network                   No (000)
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
  Альфа-Банк (alfabank.ru)              Blocked (Timeout / Geo-Drop)
  Авито (avito.ru)                      Blocked (439 Qrator Captcha)
  Wildberries (wildberries.ru)          Blocked (WAF 498)
  Озон (ozon.ru)                        Blocked (Anti-VPN 403)
  Кинопоиск (kinopoisk.ru)              OK

4. ⚪ Готовность к режиму «Белых списков» (White List & RU CDN Readiness)
  Параметр / Узел                                 Статус
  ------------------------------------            ------
  Роль ноды в топологии                           Exit / Outbound (Зарубежный шлюз)
  Мессенджер MAX (max.ru, Уровень 1)              OK (Доступен)
  Anycast Яндекс / CDN (yastatic.net, Уровень 2)  OK (Доступен)
  VK Cloud / ВКонтакте (vk.com, Уровень 2)        OK (Доступен)
  Портал Госуслуг (gosuslugi.ru, Уровень 2)       OK (Доступен)
  Задержка до Anycast РФ (RTT)                    45.8 ms — Отлично (<80 ms, минимальный джиттер)
  Стек протоколов под Белые Списки                UDP мертв в WL ➔ VLESS XHTTP over TCP/TLS 443

5. 🛡 Безопасность периметра и Zero-Probing (Anti-Active Probing / SelfSteal)
  Тест периметра                        Результат
  ------------------------------------  ------
  Защита от зондов ТСПУ (80/443)        Protected (Ports Closed / Silent Drop)

6. ⚡️ Связность и скорость по регионам РФ (Multi-Region Latency & Throughput)
  Регион (Узел связи)                   Задержка (RTT)  Скорость (↓ DL / ↑ UL)
  ------------------------------------  --------------  -----------------------
  Москва (Центр, Hostkey / MSK-IX)      45.8 ms         ↓ 522 Mbps / ↑ 124 Mbps
  Санкт-Петербург (Северо-Запад, SPB)   57.9 ms         ↓ 429 Mbps / ↑ 1087 Mbps
  Казань (Поволжье, ER-Telecom)         60.1 ms         ↓ 335 Mbps / ↑ 1134 Mbps
  Ростов-на-Дону (Юг, ER-Telecom)       64.8 ms         ↓ 309 Mbps / ↑ 1096 Mbps
  Екатеринбург (Урал, ER-Telecom)       66.5 ms         ↓ 338 Mbps / ↑ 706 Mbps
  Новосибирск (Сибирь, ER-Telecom)      94.0 ms         ↓ 156 Mbps / ↑ 1136 Mbps
  Иркутск (Восточная Сибирь, ER)        116.1 ms        ↓ 94 Mbps / ↑ 262 Mbps
```

---

## Опции

| Опция | Описание |
| :--- | :--- |
| `-h`, `--help` | Справка по всем опциям |
| `--no-iperf` | Пропустить замер скорости iPerf3 (только пинг) |
| `--sni DOMAIN` | Проверка совпадения домена и IP (SelfSteal против `NDPI_UNRESOLVED_HOSTNAME`) |
| `--cdn URL` | Проверка кастомного эндпоинта VLESS XHTTP CDN (Bodiless GET / Header Uplink) |
| `-j`, `--json` | Вывод в формате JSON (для ботов и мониторинга) |
| `-p`, `--proxy ADDR` | Проверка ноды через SOCKS5 (`127.0.0.1:1080`) |
| `-i`, `--interface IF` | Привязка запросов к интерфейсу (`wg0`, `tun0`) |
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
