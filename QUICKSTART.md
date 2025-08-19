# Ableton2ML Quick Start Guide

Быстрый старт для развертывания Ableton2ML на Google Cloud с GPU.

## Предварительные требования

1. **Google Cloud Account** с включенным биллингом
2. **Terraform** (>= 1.0)
3. **Google Cloud SDK**
4. **Hugging Face токен**

## Быстрый старт (5 минут)

### 1. Клонирование репозитория
```bash
git clone https://github.com/your-repo/ableton2ml.git
cd ableton2ml
```

### 2. Настройка Google Cloud
```bash
# Аутентификация
gcloud auth login
gcloud auth application-default login

# Создайте проект (если нужно)
gcloud projects create your-project-id
gcloud config set project your-project-id
```

### 3. Настройка переменных
```bash
# Скопируйте пример конфигурации
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Отредактируйте файл
nano terraform/terraform.tfvars
```

Содержимое `terraform.tfvars`:
```hcl
project_id = "your-project-id"
hf_token   = "your-huggingface-token"
region     = "us-central1"
zone       = "us-central1-a"
```

### 4. Развертывание
```bash
# Автоматическое развертывание
cd terraform
./deploy.sh
```

### 5. Проверка
```bash
# Получить IP сервера
terraform output gpu_server_external_ip

# Проверить API
curl http://$(terraform output -raw gpu_server_external_ip):5001/api/status

# Проверить HF токен
curl http://$(terraform output -raw gpu_server_external_ip):5001/api/hf/status
```

## Использование в Ableton Live

1. **Загрузите плагин** `plugins/Ableton2ML.amxd` в Ableton Live 12
2. **Настройте IP сервера** в плагине
3. **Выберите MIDI треки** для работы
4. **Нажмите "Generate"**

## Управление инфраструктурой

```bash
# Статус
./scripts/manage_infrastructure.sh status

# Логи
./scripts/manage_infrastructure.sh logs

# SSH
./scripts/manage_infrastructure.sh ssh

# Обновление
./scripts/manage_infrastructure.sh update

# Удаление
./scripts/manage_infrastructure.sh destroy
```

## Troubleshooting

### Сервер не отвечает
```bash
# Проверить статус сервиса
./scripts/manage_infrastructure.sh ssh
sudo systemctl status ableton2ml

# Перезапустить сервис
sudo systemctl restart ableton2ml
```

### GPU не работает
```bash
# Проверить GPU
nvidia-smi

# Проверить CUDA
nvcc --version
```

### Проблемы с сетью
```bash
# Проверить порты
sudo netstat -tlnp | grep :5001

# Проверить firewall
gcloud compute firewall-rules list
```

## Стоимость

Примерная стоимость в месяц:
- **GPU Instance**: ~$300-400
- **Storage**: ~$2
- **Network**: ~$10-20
- **Итого**: ~$320-420/месяц

## Поддержка

- **Issues**: GitHub Issues
- **Documentation**: `/docs` папка
- **Examples**: `/examples` папка
