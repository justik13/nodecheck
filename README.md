# 🇷🇺 VPNCheck (RU Edition)

> **Комплексный аудитор годности, геолокации и сетевых ограничений VPN-нод для аудитории из РФ.**  
> Создан для быстрой проверки VPS, VPN-серверов (VLESS / Reality / XHTTP / AmneziaWG / WireGuard) и прокси.

[![CI](https://github.com/justik13/vpncheck/actions/workflows/ci.yml/badge.svg)](https://github.com/justik13/vpncheck/actions/workflows/ci.yml)
[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## ⚡️ Быстрый старт (Quick Start)

Запуск в одну строку на любой Linux-машине (без предварительного скачивания):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/vpncheck/main/vpncheck.sh)
```

*Или через `wget`:*
```bash
bash <(wget -qO- https://raw.githubusercontent.com/justik13/vpncheck/main/vpncheck.sh)
```

*С 3-секундным замером скорости `iPerf3` до Москвы:*
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/justik13/vpncheck/main/vpncheck.sh) -s
```

---

## 🎯 Зачем это нужно для пользователей из РФ?

В российских реалиях оценка VPN-ноды кардинально отличается от западных тестов. Пользователю нужны ответы на два противоположных вопроса:

1. **Открывает ли нода то, что заблокировано в РФ?**  
   *(Instagram, Discord, Twitter/X, ChatGPT, Claude AI, YouTube без замедления, Rutracker).*
2. **Не ломает ли нода то, что нужно внутри РФ?**  
   *(Многие отечественные банки, Госуслуги и Авито блокируют доступ с зарубежных датацентров).*

---

## 📊 Что проверяет VPNCheck

### 1. 🔓 Обход блокировок (Western Services)
* **Instagram & Threads** (Meta) — доступность шлюзов и CDN.
* **Discord** — проверка API-шлюза (`gateway.discord.gg`) и голосовых каналов (заблокирован в РФ).
* **Twitter / X** — доступность `x.com`.
* **AI-платформы:** OpenAI ChatGPT, Anthropic Claude (проверка на 403 Cloudflare бан), Google Gemini.
* **Стриминг и медиа:** YouTube CDN (определение локации эджа, проверка на отсутствие троттлинга), Rutracker, Spotify Signup, Netflix.

### 2. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)
* **Государственные сервисы:** Госуслуги (`gosuslugi.ru`).
* **Поисковики и медиа:** Яндекс (`ya.ru` — проверка на появление SmartCaptcha), ВКонтакте (`vk.com`), Кинопоиск (`kinopoisk.ru`).
* **Банки РФ:** СберБанк (`sberbank.ru`), Т-Банк (`tbank.ru`), ВТБ (`vtb.ru`).
* **Доски объявлений:** Авито (`avito.ru` — проверка на GeeTest / Firewall Captcha 429).

### 3. ⚡️ Связность с РФ (Latency & Throughput)
* **Пинг до Москвы:** Замер RTT до ключевого узла обмена трафиком (`spd-rudp.hostkey.ru` / MSK-IX).
* **Пинг до Санкт-Петербурга:** Замер RTT до Северо-Западного узла (`st.spb.ertelecom.ru` / SPB-IX).
* **Сквозная скорость `iPerf3` (флаг `-s`):** Замер реальной пропускной способности канала между нодой и сервером в Москве на базе реестра `itdoginfo/russian-iperf3-servers`.

### 4. 🛡 Качество IP и безопасность узла
* **Антифрод и репутация:** Оценка Fraud Score по шкале `0–100` (Scamalytics / ipquery.io).
* **Тип сети:** Определение `Residential / ISP` vs `Data Center / Hosting`.
* **Google Captcha:** Проверка на срабатывание поисковой капчи Google (*«Необычный трафик»*).
* **Сетевой стек:** Статус алгоритма TCP BBR, доступность UDP-трафика (для AmneziaWG и Hysteria 2), исходящий порт 25 (SMTP).
* **Zero-Probing Check:** Проверка портов 80 и 443 на утечку доменного имени или SSL-сертификата сканерам РКН/Censys при прямом опросе по IP.

---

## 🖥 Пример вывода

```text
================================================================================
 🇷🇺 VPNCheck (RU Edition) - VPN Node & Quality Auditor v3.0.0-ru
================================================================================
 IPv4:              168.222.254.191
 Локация / ASN:     DE (Frankfurt am Main) — AS198550 (NODE HOST LIMITED)
 Тип хоста:         Residential / ISP
 Антифрод / Риск:   Clean / Low Risk (0/100), Google Captcha: No
 Сетевой стек:      BBR: Active | UDP: Open | Port 25: Open
================================================================================

1. 🔓 Обход блокировок в РФ (Western Services)
  Сервис                           Статус
  -------------------------------- ------
  Instagram                        Yes
  Discord (Voice/Gateway)          Yes
  Twitter / X                      Yes
  OpenAI ChatGPT                   DE
  Anthropic Claude AI              No (403 Cloudflare)
  Google Gemini                    Yes
  YouTube CDN                      Yes (FRA)
  Rutracker                        Yes
  Spotify Signup                   Yes
  Netflix                          Yes

2. 🇷🇺 Доступность сервисов РФ (Reverse Geoblocking)
  Сервис                           Статус
  -------------------------------- ------
  Госуслуги (gosuslugi.ru)         OK
  Яндекс (ya.ru)                   OK
  ВКонтакте (vk.com)               OK
  СберБанк (sberbank.ru)           Blocked (Timeout)
  Т-Банк (tbank.ru)                Blocked (Timeout)
  ВТБ (vtb.ru)                     Blocked (Timeout)
  Авито (avito.ru)                 Blocked (Captcha/429)
  Кинопоиск (kinopoisk.ru)         OK

3. ⚡️ Связность с РФ (Latency & Throughput)
  Пинг Москва (MSK-IX / Hostkey)   45.968 ms
  Пинг Санкт-Петербург (SPB-IX)    60.067 ms
  iPerf3 Скорость до Москвы        653 Mbps

4. 🛡 Безопасность периметра (Zero-Probing Check)
  Порт 80/443 IP-Probe             Protected (Drop/No SNI Leak)

================================================================================
 ⚖️  Вердикт пригодности для аудитории РФ
================================================================================
 • Оценка ноды: 9.2 / 10 (ОТЛИЧНО)
   - Зарубежные сервисы: Все ключевые блокировки обходятся (Instagram, Discord, X, AI, YouTube).
   - ⚠️ Внимание: Зарубежный IP блокируется сервисами РФ: СберБанк, Т-Банк, ВТБ, Авито.
   - Рекомендация: настройте Split-Tunneling (прямой обход для этих доменов).
   - Связность: Пинг до Москвы 45.968 ms, BBR Active, UDP Open.
================================================================================
```

---

## ⚙️ Опции и параметры командной строки

| Опция | Описание |
| :--- | :--- |
| `-h`, `--help` | Показать справку по всем опциям |
| `-s`, `--speed` | Выполнить быстрый 3-секундный замер скорости `iPerf3` до Москвы |
| `-j`, `--json` | Вывод в чистом формате JSON (для интеграции в боты и мониторинг) |
| `-p`, `--proxy ADDR` | Проверка ноды через локальный SOCKS5 (`127.0.0.1:1080`) |
| `-i`, `--interface IF` | Привязка запросов к сетевому интерфейсу (`wg0`, `tun0`) |
| `--no-doh` | Отключить DNS-over-HTTPS (использовать системный резолвер) |
| `--doh PROVIDER` | Выбор провайдера DoH (`cloudflare`, `quad9`, `adguard`) |
| `-v`, `--verbose` | Подробный вывод сетевых запросов |

---

## 🐧 Поддержка Ubuntu 24.04 LTS (Noble Numbat)

Скрипт оптимизирован под новейшие релизы Linux:
* Корректно использует пакет `bsdextrautils` для форматирования таблиц (в Ubuntu 24 пакет `bsdmainutils` упразднён).
* Имеет встроенный fallback на `awk` — работает даже на минимальных серверных образах без `column`.
* Совместим с `systemd-resolved` и версиями `curl 8.5+`.
* Время полного выполнения теста: **30–50 секунд**.
* Не оставляет временных файлов (автоматическая очистка по `trap`).

---

## 📜 Лицензия

Распространяется под свободной лицензией [MIT](LICENSE).
