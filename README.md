# 🇷🇺 VPNCheck (RU Edition)

> **Комплексный высокоскоростной аудитор годности, геолокации и сетевых ограничений VPN-нод для аудитории из РФ.**  
> Создан для быстрой и глубокой проверки VPS, VPN-серверов (VLESS / Reality / XHTTP / AmneziaWG / WireGuard) и прокси под реалии Рунета (ТСПУ / Reverse Geoblocking).

[![CI](https://github.com/justik13/vpncheck/actions/workflows/ci.yml/badge.svg)](https://github.com/justik13/vpncheck/actions/workflows/ci.yml)
[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## ⚡️ Быстрый запуск в 1 строку (One-Liner)

Запуск на любой Linux-машине (без установки, результат через ~30 секунд):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/vpncheck/main/vpncheck.sh)
```

*Или через `wget`:*
```bash
bash <(wget -qO- https://raw.githubusercontent.com/justik13/vpncheck/main/vpncheck.sh)
```

*Без замера пропускной способности `iPerf3` (только пинг):*
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/vpncheck/main/vpncheck.sh) --no-iperf
```

---

## 🎯 Зачем это нужно для пользователей из РФ?

При развёртывании VPN для пользователей из России критически важно проверить два противоположных фактора:

1. **Обход блокировок РКН/ТСПУ (Зарубежные сервисы):**
   * Доступны ли Instagram, Discord (включая голосовой шлюз), Twitter/X, ChatGPT, Claude AI, Rutracker?
   * Нет ли троттлинга YouTube и как определяется регион?
   * **Показ YouTube без рекламы:** входит ли страна IP-адреса в список регионов без монетизации (Албания `AL`, Россия `RU`, Молдова `MD`, Монголия `MN`, Мьянма `MM`, Камбоджа `KH`)? При совпадении нода помечается бейджем `[Без рекламы 🎬]`.
2. **Доступность Рунета (Reverse Geoblocking):**
   * Не блокируют ли зарубежный IP российские банки (Сбер, Т-Банк, ВТБ), Госуслуги и Авито? Если блокируют — скрипт выдаёт точный вердикт и рекомендацию настроить Split-Tunneling.
3. **Реальная связность со всей Россией:**
   * Россия — это не только Москва. Скрипт замеряет RTT до 7 ключевых макрорегионов РФ (Центр, Северо-Запад, Юг, Поволжье, Урал, Сибирь, Дальний Восток) и сквозную скорость `iPerf3` на серверах из базы `itdoginfo/russian-iperf3-servers`.
4. **Консенсус 18 баз данных GeoIP:**
   * Сверка геолокации IP по 18 независимым базам (MaxMind, IPinfo, Cloudflare, IP-API, RIPE, 2ip и др.) с подсчётом процента совпадения и распределения.

---

## 📊 Что проверяет VPNCheck

### 1. 🌐 Консенсус 18 GeoIP баз данных
* IPinfo.io, IP-API.com, Cloudflare (Trace), IP.SB, Ipregistry, IP-API.co, IP2Location.io, Country.is, GeoJS, 2ip.io, ipwho.is, ifconfig.co, IPLocation.net, ipbase.com, ipquery.io, IPAPI.is, RIPE NCC, IP.Guide.
* Отображение таблицы стран, процента согласия (Consensus Agreement) и отсортированной таблицы распределения долей.

### 2. 🔓 Обход блокировок (Western Services)
* **Instagram & Threads (Meta)** — проверка веб-шлюза и доступности контента.
* **Discord** — проверка API-шлюза (`gateway.discord.gg`) и голосовой инфраструктуры.
* **Twitter / X** — доступность `x.com`.
* **AI-платформы:** OpenAI ChatGPT, Anthropic Claude (проверка на 403 Cloudflare бан), Google Gemini.
* **Google & YouTube:** Строгая проверка региона аккаунта Google (GlifSetupAndroid), детекция региона YouTube с бейджем `[Без рекламы 🎬]`, YouTube CDN (код аэропорта IATA), YouTube Premium и YouTube Music.
* **Медиа, игры и стриминг:** Rutracker, Spotify Signup, Netflix, Steam Store, PlayStation Network, Reddit, Apple Services.

### 3. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)
* **Госуслуги:** `gosuslugi.ru`.
* **Поисковики и медиа:** Яндекс (`ya.ru` — детекция SmartCaptcha), ВКонтакте (`vk.com`), Кинопоиск (`kinopoisk.ru`).
* **Банки РФ:** СберБанк (`sberbank.ru`), Т-Банк (`tbank.ru`), ВТБ (`vtb.ru`).
* **Доски объявлений:** Авито (`avito.ru` — проверка на GeeTest / 429 Firewall).

### 4. ⚡️ Связность по всей России (Multi-Region Latency & iPerf3)
* **Москва (Центр, MSK-IX / Hostkey)**
* **Санкт-Петербург (Северо-Запад, SPB-IX)**
* **Ростов-на-Дону (Юг, ER-Telecom)**
* **Казань (Поволжье, ER-Telecom)**
* **Екатеринбург (Урал, ER-Telecom)**
* **Новосибирск (Сибирь, ER-Telecom)**
* **Иркутск (Восточная Сибирь, ER-Telecom)**
* **iPerf3 Скорость до Москвы:** 3-секундный параллельный замер реальной пропускной способности (10G порт).

### 5. 🛡 Качество IP и безопасность периметра
* **Антифрод и репутация:** Оценка Fraud Score от 0 до 100 (Clean / Moderate / High Risk).
* **Тип ноды:** Определение `Residential / ISP` vs `Data Center / Hosting`.
* **Google Captcha:** Проверка на срабатывание поисковой капчи Google (*«Необычный трафик»*).
* **Сетевой стек:** Статус TCP BBR, открытость UDP (для AmneziaWG / Hysteria 2), исходящий порт 25 (SMTP).
* **Zero-Probing Check:** Проверка портов 80 и 443 на утечку SNI / Default VHost сканерам ТСПУ/РКН.

---

## 🖥 Пример вывода

```text
================================================================================
 🇷🇺 VPNCheck (RU Edition) - VPN Node & Quality Auditor v3.1.0-ru
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
  Anthropic Claude AI                   No (403 Cloudflare)
  Google (Регион)                       GB
  Google Gemini                         Yes (GB)
  YouTube                               GB
  YouTube CDN                           Yes (VMC)
  YouTube Premium                       Yes
  YouTube Music                         Yes
  Rutracker                             Yes
  Spotify Signup                        Yes
  Netflix                               Yes
  Steam Store (Игры)                    Yes
  PlayStation Network                   Yes
  Reddit                                Yes
  Apple Services                        DE

3. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)
  Сервис                                Статус
  ------------------------------------  ------
  Госуслуги (gosuslugi.ru)              OK
  Яндекс (ya.ru)                        OK
  ВКонтакте (vk.com)                    OK
  СберБанк (sberbank.ru)                Blocked (Timeout)
  Т-Банк (tbank.ru)                     Blocked (Timeout)
  ВТБ (vtb.ru)                          Blocked (Timeout)
  Авито (avito.ru)                      OK
  Кинопоиск (kinopoisk.ru)              OK

4. ⚡️ Связность по регионам РФ (Multi-Region Latency & Throughput)
  Регион / Тест                         Задержка / Скорость
  ------------------------------------  -------------------
  Москва (Центр, MSK-IX)                45.9 ms
  Санкт-Петербург (Северо-Запад)        59.9 ms
  Ростов-на-Дону (Юг)                   64.4 ms
  Казань (Поволжье)                     60.0 ms
  Екатеринбург (Урал)                   66.4 ms
  Новосибирск (Сибирь)                  95.7 ms
  Иркутск (Восточная Сибирь)            116.0 ms
  iPerf3 Скорость до Москвы (10G Port)  740 Mbps

5. 🛡 Безопасность периметра (Zero-Probing Check)
  Порт 80/443 IP-Probe                  Normal

================================================================================
 ⚖️  Вердикт пригодности ноды для РФ аудитории
================================================================================
 • Оценка ноды: 9.3 / 10 (ОТЛИЧНО ДЛЯ VPN)
   - Зарубежные сервисы: Обход блокировок функционирует (17/18 сервисов доступно).
   - ⚠️ Внимание: Зарубежный IP блокируется сервисами РФ: СберБанк (sberbank.ru), Т-Банк (tbank.ru), ВТБ (vtb.ru).
   - Рекомендация: настройте Split-Tunneling (прямой маршрут без VPN для этих доменов).
   - Связность: Москва 45.9 ms, СПб 59.9 ms, Поволжье 60.0 ms, Урал 66.4 ms, Сибирь 95.7 ms.
   - Пропускная способность iPerf3: 740 Mbps.
================================================================================
```

---

## ⚙️ Опции командной строки

| Опция | Описание |
| :--- | :--- |
| `-h`, `--help` | Показать справку по всем опциям |
| `--no-iperf` | Пропустить замер скорости iPerf3 (только пинг) |
| `-j`, `--json` | Вывод в чистом формате JSON (для интеграции в боты и мониторинг) |
| `-p`, `--proxy ADDR` | Проверка ноды через локальный SOCKS5 (`127.0.0.1:1080`) |
| `-i`, `--interface IF` | Привязка запросов к сетевому интерфейсу (`wg0`, `tun0`) |
| `--no-doh` | Отключить DNS-over-HTTPS (использовать системный резолвер) |
| `--doh PROVIDER` | Выбор провайдера DoH (`cloudflare`, `quad9`, `adguard`) |
| `-v`, `--verbose` | Подробный вывод сетевых запросов |

---

## 🐧 Поддержка Linux (Ubuntu 24.04 Noble Numbat)

* 100% нативный bash без сторонних интерпретаторов.
* Полная совместимость с Ubuntu 24.04 LTS (`bsdextrautils` + `awk` fallback).
* Время полного теста: **~25–35 секунд**.
* Чистый запуск: временные файлы в `/tmp` изолированы и гарантированно удаляются через `trap ... EXIT INT TERM`.

---

## 📜 Лицензия

Распространяется под свободной лицензией [MIT](LICENSE).
