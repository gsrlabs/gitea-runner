# 🏃 Gitea Act Runner - Self-Hosted CI/CD Runner

Простая и надежная конфигурация для развертывания Gitea Actions Runner на собственном сервере с использованием Docker Compose.

## ✨ Особенности

- ✅ **Простота установки** — одна команда для запуска
- ✅ **Docker-based execution** — задачи выполняются в изолированных контейнерах
- ✅ **Интеграция с Gitea** — автоматическая регистрация и подключение
- ✅ **Поддержка Actions** — выполнение рабочих процессов Gitea Actions
- ✅ **Масштабируемость** — можно запускать несколько раннеров
- ✅ **Автоматические обновления** — перезапуск контейнера с последним образом

## 🏗️ Архитектура

```
Ваш Gitea сервер (https://gitea.your-domain.com)
         │
         ▼
    Act Runner ←── подписывается на webhook'и
         │
         ▼
  Запускает Docker ←── контейнеры для каждой задачи
         │
         ▼
Выполняет workflow ←── из .gitea/workflows/*.yml
```

## 📋 Предварительные требования

### Системные требования
- **Ubuntu/Debian сервер** с Docker и Docker Compose
- **Доступ к Docker daemon** (пользователь в группе `docker`)
- **Сеть Gitea** — раннер должен быть в той же Docker сети, что и Gitea 

### Требования к Gitea
- **[Gitea](https://github.com/gsrlabs/gitea-compose) версии 1.19+** с включенными Actions
- **Токен регистрации** раннера (см. раздел "Получение токена")

## 🚀 Быстрый старт

### 1. Клонирование репозитория
```bash
cd /home/your/directory/
git clone https://github.com/gsrlabs/gitea-runner.git gitea-runner
cd gitea-runner
```

### 2. Проверка сети Gitea
Перед запуском убедитесь, что существует сеть Gitea:
```bash
docker network ls | grep gitea_gitea # или gitea_network
```
Если сети нет, создайте её:
```bash
docker network create gitea_gitea # или gitea_network
```

### 3. Настройка переменных окружения
Создайте файл `.env`:
```bash
touch .env
nano .env
```

Отредактируйте обязательные переменные:
```bash
# Обязательные настройки
RUNNER_TOKEN="YOUR_TOKEN_REGISTRATION"
GITEA_INSTANCE_URL= "http://gitea:3000" #  Или "https://gitea.your-domain.com" если на другом сервере
```

### 4. Получение токена регистрации
Токен зависит от уровня раннера:

#### Уровень экземпляра (все репозитории)
1. Откройте панель администратора: `https://gitea.your-domain.com/-/admin/actions/runners`
2. Нажмите "Create new runner"
3. Скопируйте токен регистрации

#### Уровень организации
1. Откройте настройки организации: `https://gitea.your-domain.com/orgs/{org}/settings/actions/runners`
2. Нажмите "Create new runner"
3. Скопируйте токен регистрации

#### Уровень репозитория
1. Откройте настройки репозитория: `https://gitea.your-domain.com/{owner}/{repo}/settings/actions/runners`
2. Нажмите "Create new runner"
3. Скопируйте токен регистрации

> **Примечание:** Токен имеет вид: `D0gvfu2iHfUjNqCYVljVyRV14fISpJxxxxxxxxxx`

### 5. Настройка конфигурации

**Создание конфигурационного файла**
Сгенерируйте базовый файл конфигурации командой:
```bash
docker run --rm --entrypoint="" docker.io/gitea/act_runner:latest act_runner generate-config > config.yaml
```

Отредактируйте config.yaml:
```bash
nano config.yaml
```

Ключевые параметры:
```yaml
container:
  network: "gitea_gitea"  # /gitea_network Сеть должна совпадать с сетью Gitea
  # Дополнительные настройки (необязательно):
  # privileged: false      # Запускать контейнеры в привилегированном режиме
  # options:              # Дополнительные опции Docker
  #   --dns: 8.8.8.8
```

### 6. Запуск раннера
```bash
docker compose up -d
```

### 7. Проверка статуса
```bash
# Проверка логов
docker compose logs -f

# Проверка статуса контейнера
docker compose ps
```

## ⚙️ Расширенная настройка

### Настройка лейблов раннера
Лейблы определяют, какие задачи может выполнять раннер:

#### Формат лейблов:
- `ubuntu-latest:docker://node:20-bullseye` — запускать в контейнере с образом Node.js
- `self-hosted:host` — запускать непосредственно на хосте (без Docker)
- `linux/amd64:host` — запускать на хосте с указанием архитектуры

#### Проверка доступных образов:
```bash
docker run --rm gitea/act_runner:latest act_runner list-images
```

### Настройка кеширования
Для использования `actions/cache` в рабочих процессах:

1. Определите свободный порт на хосте (например, 8088)
2. Откройте `config.yaml`:
```yaml
cache:
  enabled: true
  dir: ""
  host: "192.168.0.102"  # IP-адрес вашего сервера, замените на свой
  port: 8088
```

3. Обновите `docker-compose.yml`:
```yaml
services:
  runner:
    # ... существующие настройки ...
    ports:
      - "8088:8088"  # Проброс порта кеша
```

### Эфемерные раннеры (повышенная безопасность)
Для режима "одна задача — один раннер":

1. В `.env` добавьте:
```bash
RUNNER_EPHEMERAL="1"
```

2. Обновите `docker-compose.yml`:
```yaml
services:
  runner:
    environment:
      # ... другие переменные ...
      GITEA_RUNNER_EPHEMERAL: "${RUNNER_EPHEMERAL:-0}"
    volumes:
      # УБРАТЬ том /data для эфемерных раннеров:
      # - ./data:/data
      - ./config.yaml:/config.yaml
      - /var/run/docker.sock:/var/run/docker.sock
```
### Пример готового конфига
```yaml
log:
  level: info

runner:
  file: .runner
  capacity: 1
  envs:
    A_TEST_ENV_NAME_1: a_test_env_value_1
    A_TEST_ENV_NAME_2: a_test_env_value_2
  env_file: .env
  timeout: 3h
  shutdown_timeout: 0s
  insecure: false
  fetch_timeout: 5s
  fetch_interval: 2s
  github_mirror: ''
  labels:
    - "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest"
    - "ubuntu-22.04:docker://docker.gitea.com/runner-images:ubuntu-22.04"
    - "ubuntu-20.04:docker://docker.gitea.com/runner-images:ubuntu-20.04"

cache:
  enabled: true
  dir: ""
  host: "192.168.0.105"
  port: 8088
  external_server: ""

container:
  network: "gitea_gitea"
  privileged: false
  options:
  workdir_parent:
  valid_volumes: []
  docker_host: ""
  force_pull: true
  force_rebuild: false
  require_docker: false
  docker_timeout: 0s

host:
  workdir_parent:
```
## 📊 Использование

### Проверка подключения к Gitea
После запуска проверьте статус раннера в интерфейсе Gitea:

1. Откройте `https://gitea.your-domain.com/-/admin/actions/runners`
2. Убедитесь, что раннер отображается со статусом "Online"
3. Если статус "Offline", проверьте логи: `docker compose logs runner`

### Мониторинг выполнения задач
```bash
# Просмотр логов в реальном времени
docker compose logs -f runner

# Просмотр запущенных контейнеров задач
docker ps --filter "label=github_actions"

# Статистика использования ресурсов
docker stats gitea_act_runner
```

## 🔧 Управление

### Основные команды
```bash
# Запуск раннера
docker compose up -d

# Остановка раннера
docker compose down

# Перезагрузка раннера
docker compose restart

# Просмотр логов
docker compose logs -f

# Проверка статуса
docker compose ps

# Обновление до последней версии
docker compose pull && docker compose up -d --force-recreate
```

### Скрипты управления (опционально)
Используйте`manage.sh` для удобного управления:

Дайте права на выполнение:
```bash
chmod +x manage.sh
./manage.sh start
```

## 🐛 Устранение неполадок

### Проблема: Раннер не подключается к Gitea
**Симптомы:** Статус "Offline" в интерфейсе Gitea

**Решение:**
1. Проверьте логи: `docker compose logs runner`
2. Убедитесь, что URL Gitea правильный (HTTPS vs HTTP)
3. Проверьте токен регистрации
4. Убедитесь, что раннер может разрешить доменное имя Gitea:
   ```bash
   docker exec gitea_act_runner ping gitea.gsrcloud.ru
   ```

### Проблема: Задачи не запускаются
**Симптомы:** Workflow зависает на статусе "pending"

**Решение:**
1. Проверьте лейблы раннера:
   ```bash
   docker exec gitea_act_runner cat /data/.runner
   ```
2. Убедитесь, что в workflow указан правильный `runs-on`
3. Проверьте, что Docker socket доступен:
   ```bash
   docker exec gitea_act_runner ls -la /var/run/docker.sock
   ```

### Проблема: Ошибка сети в задачах
**Симптомы:** Контейнеры задач не могут выйти в интернет

**Решение:**
1. Убедитесь, что хост имеет интернет-соединение
2. Проверьте настройки DNS в `config.yaml`:
   ```yaml
   container:
     network: "gitea_gitea"
     options:
       --dns: 8.8.8.8
       --dns: 8.8.4.4
   ```

## 🔒 Безопасность

### Рекомендации по безопасности
1. **Используйте эфемерные раннеры** для production-сред
2. **Ограничьте доступ к Docker socket**
3. **Регулярно обновляйте образ** раннера
4. **Используйте отдельные токены** для разных сред
5. **Мониторьте логи** на предмет подозрительной активности

### Настройка firewall
```bash
# Разрешить только исходящие подключения
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Разрешить подключения к Gitea (если на том же сервере)
sudo ufw allow from 192.168.0.0/24 to any port 3000
```

## 📈 Масштабирование

### Запуск нескольких раннеров
Создайте файл `docker-compose.scale.yml`:

```yaml
version: "3.8"

services:
  runner-1:
    extends:
      file: docker-compose.yml
      service: runner
    container_name: gitea_act_runner_1
    environment:
      GITEA_RUNNER_NAME: "runner-1"
  
  runner-2:
    extends:
      file: docker-compose.yml
      service: runner
    container_name: gitea_act_runner_2
    environment:
      GITEA_RUNNER_NAME: "runner-2"
```

Запустите:
```bash
docker compose -f docker-compose.scale.yml up -d
```

### Балансировка нагрузки
Для балансировки между несколькими раннерами используйте разные лейблы:

```bash
# Раннер 1 - для тестов
RUNNER_LABELS="test:docker://alpine:latest"

# Раннер 2 - для сборки
RUNNER_LABELS="build:docker://node:20-bullseye"

# Раннер 3 - для production
RUNNER_LABELS="prod:docker://ubuntu:22.04"
```

## 📦 Структура проекта
```
gitea-runner/
├── docker-compose.yml     # Основная конфигурация Docker
├── config.yaml           # Конфигурация Act Runner
├── .env                  # Переменные окружения (не в репозитории)
├── README.md            # Эта документация
├── data/                # Данные раннера (создается)
└── logs/                # Логи (опционально)
```

## 🔄 Обновление

### Автоматическое обновление
Добавьте в crontab:
```bash
# Еженедельное обновление по воскресеньям в 3:00
0 3 * * 0 cd /home/gsr/hub/gitea-runner && docker compose pull && docker compose up -d >> /var/log/gitea-runner-update.log 2>&1
```

### Ручное обновление
```bash
cd /home/gsr/hub/gitea-runner
docker compose pull
docker compose up -d --force-recreate
docker system prune -f  # Очистка старых образов
```

## 🤝 Вклад в проект
Pull requests приветствуются! Для серьезных изменений, пожалуйста, откройте issue сначала для обсуждения.

## 📞 Поддержка
- Issues: https://github.com/gsrlabs/gitea-runner/issues
- Документация Gitea Actions: https://docs.gitea.com/usage/actions/overview
- Документация Act Runner: https://docs.gitea.com/usage/actions/act-runner

## 📄 Лицензия
MIT

---

**Примечание:** Этот раннер предназначен для выполнения рабочих процессов Gitea Actions. Убедитесь, что у вас есть соответствующие права на выполнение кода в рабочих процессах и что вы понимаете потенциальные риски безопасности при выполнении произвольного кода на вашем сервере.