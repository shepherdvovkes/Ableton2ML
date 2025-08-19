# Ableton2ML Cloud Integration Guide

## Обзор

Плагин `Ableton2ML_Cloud` интегрирован с вашим сервером Google Cloud для обработки MIDI данных через Google Magenta AI.

## Архитектура

```
Ableton Live → Ableton2ML_Cloud.amxd → Google Cloud Server → Google Magenta AI → MIDI Response
```

## Сервер Google Cloud

### Endpoints API

Ваш сервер на Google Cloud предоставляет следующие API endpoints:

#### 1. Статус сервера
```
GET http://YOUR-GOOGLE-CLOUD-IP:5001/api/status
```

#### 2. Генерация вариаций
```
POST http://YOUR-GOOGLE-CLOUD-IP:5001/api/generate/variation
Content-Type: application/json

{
  "midi_data": "base64_encoded_midi",
  "num_variations": 3,
  "creativity_level": 0.8,
  "style_preset": "electronic"
}
```

#### 3. Продолжение мелодии
```
POST http://YOUR-GOOGLE-CLOUD-IP:5001/api/generate/continuation
Content-Type: application/json

{
  "midi_data": "base64_encoded_midi",
  "target_length": 16,
  "target_instrument": "piano",
  "style_preset": "jazz"
}
```

#### 4. Генерация нового трека
```
POST http://YOUR-GOOGLE-CLOUD-IP:5001/api/generate/new_track
Content-Type: application/json

{
  "context_tracks": [
    {"midi_data": "base64_encoded_midi_1"},
    {"midi_data": "base64_encoded_midi_2"}
  ],
  "target_instrument": "lead_synth",
  "style_preset": "pop",
  "track_length": 32
}
```

## Настройка плагина

### Параметры устройства

1. **Creativity** (0-100) - Уровень креативности AI
2. **Tempo** (60-200) - Темп генерации
3. **Auto Generate** (toggle) - Автоматическая генерация
4. **Server Mode** (Local/Cloud) - Выбор режима работы

### Кнопки управления

1. **Generate Melody** - Локальная генерация мелодий
2. **Send to Cloud** - Отправка данных на Google Cloud сервер

## Интеграция в плагине

### Объекты Max for Live

- **`url`** - HTTP запросы к серверу
- **`json`** - Обработка JSON ответов
- **`dict`** - Формирование данных для отправки
- **`live.parameter`** - Параметры устройства
- **`midiin/midiout`** - MIDI обработка

### Логика работы

1. **MIDI Input** → Обработка входящих MIDI данных
2. **Parameter Control** → Настройка параметров генерации
3. **Cloud Request** → Формирование и отправка запроса
4. **Response Processing** → Обработка ответа от сервера
5. **MIDI Output** → Воспроизведение сгенерированной музыки

## Развертывание сервера

### Terraform конфигурация

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Переменные окружения

Создайте файл `terraform/terraform.tfvars`:

```hcl
project_id = "your-google-cloud-project-id"
hf_token    = "your-hugging-face-token"
region      = "us-central1"
zone        = "us-central1-a"
```

### Запуск сервера

```bash
# На Google Cloud VM
cd /opt/ableton2ml
python3 server/magenta_server.py
```

## Использование

### 1. Разверните сервер Google Cloud

```bash
# Используйте скрипт развертывания
./scripts/deploy_to_gcloud.sh
```

### 2. Получите IP адрес сервера

```bash
# Из Terraform output
terraform output server_external_ip
```

### 3. Обновите URL в плагине

Замените `YOUR-GOOGLE-CLOUD-IP` на реальный IP адрес вашего сервера.

### 4. Загрузите плагин в Ableton Live

1. Скопируйте `Ableton2ML_Cloud.adv` в папку Ableton Live
2. Перезапустите Ableton Live
3. Найдите плагин в браузере устройств
4. Перетащите на MIDI трек

### 5. Настройте параметры

- Установите **Server Mode** в "Cloud"
- Настройте **Creativity** и **Tempo**
- Включите **Auto Generate** или используйте кнопки

## Отладка

### Проверка подключения

1. Откройте Max Console в Ableton Live
2. Загрузите плагин
3. Проверьте сообщения о подключении к серверу

### Логи сервера

```bash
# На Google Cloud VM
tail -f /var/log/ableton2ml/magenta_server.log
```

### Тестирование API

```bash
# Проверка статуса сервера
curl http://YOUR-GOOGLE-CLOUD-IP:5001/api/status

# Тест генерации
curl -X POST http://YOUR-GOOGLE-CLOUD-IP:5001/api/generate/variation \
  -H "Content-Type: application/json" \
  -d '{"midi_data": "test", "num_variations": 1}'
```

## Безопасность

### Firewall правила

Terraform автоматически настраивает firewall для портов:
- 22 (SSH)
- 80 (HTTP)
- 443 (HTTPS)
- 5001 (API)

### Аутентификация

- Используйте Google Cloud IAM для управления доступом
- HF_TOKEN хранится в Secret Manager
- API доступен только через авторизованные запросы

## Мониторинг

### Cloud Monitoring

```bash
# Проверка статуса сервера
gcloud compute instances describe ableton2ml-magenta-gpu

# Просмотр логов
gcloud logging read "resource.type=gce_instance"
```

### Метрики

- CPU и Memory использование
- GPU utilization (если включено)
- API request/response times
- MIDI processing latency

## Troubleshooting

### Проблемы подключения

1. **Сервер недоступен**
   - Проверьте статус VM в Google Cloud Console
   - Убедитесь, что firewall разрешает порт 5001

2. **Ошибки API**
   - Проверьте логи сервера
   - Убедитесь, что HF_TOKEN настроен правильно

3. **Плагин не отвечает**
   - Проверьте Max Console на ошибки
   - Убедитесь, что URL сервера правильный

### Частые ошибки

```
Error: Connection refused
Solution: Проверьте, что сервер запущен и доступен

Error: Invalid HF_TOKEN
Solution: Обновите токен в Secret Manager

Error: Model not loaded
Solution: Проверьте, что модели Google Magenta загружены
```

## Дополнительные возможности

### Hugging Face интеграция

Сервер поддерживает интеграцию с Hugging Face для дополнительных AI моделей.

### Масштабирование

- Используйте Cloud Run для автоматического масштабирования
- Настройте Load Balancer для высокой доступности
- Используйте Cloud Storage для хранения моделей

### Разработка

- Vertex AI Workbench для разработки моделей
- Cloud Build для CI/CD
- Cloud Logging для централизованного логирования
