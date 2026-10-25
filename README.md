# NodeCheck (RU Edition)

Скрипт комплексного аудита VPS и VPN-нод под Рунет: сверка по 18 базам GeoIP, обход блокировок, доступность сервисов РФ, аудит режима «Белых списков» (White List), защита периметра от активного зондирования ТСПУ и отказоустойчивый замер связности по регионам РФ.

[![CI](https://github.com/justik13/nodecheck/actions/workflows/ci.yml/badge.svg)](https://github.com/justik13/nodecheck/actions/workflows/ci.yml)
[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Быстрый запуск

Запуск одной командой без предварительной установки (время работы ~25–35 секунд):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Через `wget`:
```bash
bash <(wget -qO- https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh)
```

Полный замер скорости iPerf3 по всем 7 регионам РФ:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) --full-iperf
```

Без замера скорости через iPerf3 (только пинг):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) --no-iperf
```

---

## Назначение и ключевые возможности

При настройке VPN-сервера для пользователей в РФ критически важно контролировать:

1. **Реестр блокировок РКН:** проверка IP-адреса ноды на нахождение в едином реестре запрещенных сайтов (базы Antifilter). Если IP заблокирован РКН, нода не откроется у провайдеров РФ.
2. **Обход блокировок РКН и ТСПУ (с защитой от Burst Window):** доступность Instagram, Discord (включая шлюз голосовых каналов), Twitter/X, ChatGPT, Claude, Rutracker, Signal, Notion. Все тесты считывают полезную нагрузку для исключения ложных пропусков на эвристической отсечке DPI в 16–20 КБ (10–14 пакетов).
3. **YouTube без рекламы:** входит ли страна IP в список регионов без монетизации (Албания `AL`, Россия `RU`, Молдова `MD`, Монголия `MN`, Мьянма `MM`, Камбоджа `KH`).
4. **Обратный геобондинг (Reverse Geoblocking):** открываются ли Госуслуги, ФНС, Мос.ру, РЖД, Авито, Wildberries и российские банки (Сбер, Т-Банк, ВТБ, Альфа-Банк). Скрипт формирует готовый список доменов для Split-Tunneling (bypass).
5. **Готовность к режиму «Белых списков» (White List & Anycast CDN):** аудит доступности ключевых узлов белого списка (мессенджер MAX `max.ru`, Anycast Яндекс `yastatic.net`, VK Cloud, Госуслуги) и расчет RTT-порога для каскада VLESS XHTTP через Yandex Cloud CDN (предотвращение ошибок HTTP 504 Gateway Timeout).
6. **Безопасность периметра и Anti-Active Probing:** аудит портов 80 и 443 на утечки доменных имен в HTTP-редиректах (`Location:`) и TLS-сертификатах (`CN/SAN`) цензурным роботам ТСПУ. Проверка соответствия SelfSteal SNI через `--sni`.
7. **Отказоустойчивый iPerf3 (пул портов 5201–5209):** перебор портов и пулы fallback-серверов в каждом макрорегионе (на базе `itdoginfo/russian-iperf3-servers`), предотвращающие сбои «сервер занят».
8. **Сетевой стек и Path MTU:** статус TCP BBR, открытость UDP, замер Path MTU с рекомендацией точного размера MTU под WireGuard / AmneziaWG (1360).

---

## Пример вывода

```text
================================================================================
 🇷🇺 NodeCheck (RU Edition) - VPN Node & Quality Auditor v3.2.0-ru
================================================================================
 IPv4:             168.222.254.191
 Локация / ASN:    DE (Frankfurt am Main) — AS198550 (NODE HOST LIMITED)
 Тип хоста:        Residential / ISP
 Реестр РКН:       Clean (Not in Registry)
 Антифрод / Риск:  Clean / Low Risk (0/100), Google Captcha: Clean (No Captcha)
 Сетевой стек:     BBR: Active | UDP: Open (DNS Bidirectional) | Port 25: Open
 Path MTU (PMTU):  1500 (Standard Ethernet) (Рек. для WG: 1420 (WG) / 1360 (AWG))
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
  Санкт-Петербург (Северо-Запад, SPB)   16.0 ms         — (--full-iperf)
  Казань (Поволжье, ER-Telecom)         35.9 ms         — (--full-iperf)
  Ростов-на-Дону (Юг, ER-Telecom)       41.1 ms         — (--full-iperf)
  Екатеринбург (Урал, ER-Telecom)       48.2 ms         ↓ 173 / ↑ 801 Mbps
  Новосибирск (Сибирь, ER-Telecom)      72.9 ms         — (--full-iperf)
  Иркутск (Восточная Сибирь, ER)        87.5 ms         — (--full-iperf)

5. ⚪ Готовность к режиму «Белых списков» (White List & RU CDN Readiness)
  Параметр / Узел                       Статус
  ------------------------------------  ------
  Роль ноды в топологии                 Exit / Outbound (Зарубежный шлюз)
  Мессенджер MAX (max.ru, Уровень 1)    OK (Доступен)
  Anycast Яндекс / CDN (yastatic.net)   OK (Доступен)
  VK Cloud / ВКонтакте (vk.com)         OK (Доступен)
  Портал Госуслуг (gosuslugi.ru)        OK (Доступен)
  Задержка до Anycast РФ (RTT)          27.6 ms — Отлично (<80 ms, минимальный джиттер)
  Стек протоколов под Белые Списки      UDP мертв в WL ➔ VLESS XHTTP over TCP/TLS 443

6. 🛡 Безопасность периметра и Zero-Probing (Anti-Active Probing / SelfSteal)
  Тест периметра                        Результат
  ------------------------------------  ------
  Защита от зондов ТСПУ (80/443)        Protected (Ports Closed / Silent Drop)

================================================================================
 ⚖️  Вердикт пригодности ноды для РФ аудитории
================================================================================
 • Оценка ноды: 8.5 / 10 (ХОРОШО ДЛЯ VPN)
   - Зарубежные сервисы: Обход блокировок функционирует (19/20 сервисов доступно).
   - Внимание: Зарубежный IP блокируется сервисами РФ: ВТБ, Альфа-Банк, Авито, Wildberries.
   - Рекомендация Split-Tunneling (bypass): vtb.ru, alfabank.ru, avito.ru, wildberries.ru
   - Белые списки (WL): Зарубежный Exit. Каскад VLESS XHTTP через CDN: Отлично (<80 ms, минимальный джиттер) (RTT 27.6 ms).
   - Сетевой стек под VPN: Path MTU 1500 (Рекомендуемый для WG/AWG: 1420 (WG) / 1360 (AWG)).
   - Примечание WL: В режиме Белых Списков UDP полностью блокируется ТСПУ — WireGuard/AWG не работают, используйте VLESS XHTTP over TCP/TLS 443.
   - Связность: Москва 27.6 ms, СПб 16.0 ms, Поволжье 35.9 ms, Урал 48.2 ms, Сибирь 72.9 ms.
   - Пропускная способность iPerf3 (Москва): ↓ 295 / ↑ 273 Mbps.
================================================================================
```

---

## Опции

| Опция | Описание |
| :--- | :--- |
| `-h`, `--help` | Справка по всем опциям |
| `--full-iperf` | Полный замер скорости iPerf3 по всем 7 регионам РФ |
| `--no-iperf` | Пропустить замер скорости iPerf3 (только пинг) |
| `--sni DOMAIN` | Проверка совпадения домена и IP (SelfSteal против `NDPI_UNRESOLVED_HOSTNAME`) |
| `--cdn URL` | Проверка кастомного эндпоинта VLESS XHTTP CDN (Bodiless GET / Header Uplink) |
| `-j`, `--json` | Вывод в формате JSON (для ботов и мониторинга) |
| `-p`, `--proxy ADDR` | Проверка ноды через SOCKS5 (`127.0.0.1:1080`) |
| `-i`, `--interface IF` | Привязка запросов к интерфейсу (`wg0`, `tun0`) |
| `--no-doh` | Отключить DNS-over-HTTPS (системный резолвер) |
| `--doh PROVIDER` | Провайдер DoH (`cloudflare`, `quad9`, `adguard`) |
| `-v`, `--verbose` | Логирование сетевых запросов |

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
