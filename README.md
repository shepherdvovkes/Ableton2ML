# Ableton2ML - Google Magenta Integration for Ableton Live 12

Интеграция Google Magenta с Ableton Live 12 через Max for Live с поддержкой Access Virus C синтезатора.

## Архитектура

- **Max for Live Plugin (AU2)**: Основной плагин для Ableton Live
- **Google Magenta Server**: Сервер для генерации MIDI на GPU
- **Access Virus C AU Instrument**: Синтезатор с Template Manager
- **Cloud Infrastructure**: Google Cloud с CUDA GPU

## Компоненты

### 1. Ableton2ML Plugin
- MIDI трек селектор
- Параметры генерации
- HTTP клиент для связи с сервером
- Template Manager для Virus C
- MIDI роутер

### 2. Google Magenta Server
- MusicVAE для вариаций
- Music Transformer для дополнения
- REST API
- CUDA GPU поддержка

### 3. Access Virus C AU Instrument
- Эмуляция синтезатора
- Preset Browser
- Parameter Automation
- Template Manager

## Установка

### Локальная установка
```bash
# Клонирование репозитория
git clone https://github.com/your-repo/ableton2ml
cd ableton2ml

# Установка зависимостей
pip install -r requirements.txt

# Настройка переменных окружения
# Убедитесь, что в ~/.env есть HF_TOKEN
echo "HF_TOKEN=your_huggingface_token_here" >> ~/.env

# Запуск сервера
python server/magenta_server.py
```

### Переменные окружения

Сервер автоматически загружает переменные окружения из файла `~/.env`:

- `HF_TOKEN` - Hugging Face API токен для доступа к моделям
- `OPENAI_API_KEY` - OpenAI API ключ (опционально)
- `ANTHROPIC_API_KEY` - Anthropic API ключ (опционально)

### Cloud развертывание

#### Terraform (Рекомендуется)
```bash
# Настройка переменных
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Отредактируйте terraform.tfvars с вашими настройками

# Развертывание
cd terraform
./deploy.sh

# Или вручную
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

#### Управление инфраструктурой
```bash
# Показать статус
./scripts/manage_infrastructure.sh status

# Показать логи
./scripts/manage_infrastructure.sh logs

# SSH подключение
./scripts/manage_infrastructure.sh ssh

# Обновить сервер
./scripts/manage_infrastructure.sh update

# Уничтожить инфраструктуру
./scripts/manage_infrastructure.sh destroy
```

#### Legacy развертывание (gcloud)
```bash
# Развертывание на Google Cloud
./scripts/deploy_to_gcloud.sh
```

## Использование

### API Endpoints

Сервер предоставляет следующие REST API endpoints:

- `GET /api/status` - Статус сервера и загруженных моделей
- `GET /api/models` - Доступные модели и их возможности
- `POST /api/generate/variation` - Генерация вариаций MIDI
- `POST /api/generate/continuation` - Продолжение MIDI последовательности
- `POST /api/generate/new_track` - Генерация нового трека
- `GET /api/hf/status` - Статус Hugging Face токена

### Проверка HF_TOKEN

```bash
# Проверка статуса токена
curl http://localhost:5000/api/hf/status

# Проверка общего статуса сервера
curl http://localhost:5000/api/status
```

### Использование в Ableton Live

1. Загрузите плагин в Ableton Live 12
2. Выберите MIDI треки для работы
3. Настройте параметры генерации
4. Выберите пресет Virus C
5. Нажмите "Generate"

## Лицензия

MIT License
