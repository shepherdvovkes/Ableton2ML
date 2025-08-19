# Ableton2ML Max for Live Plugins

Коллекция Max for Live плагинов для интеграции с Google Magenta AI в Ableton Live 12.

## Плагины

### 1. Ableton2ML.amxd
Базовый плагин с интеграцией Google Magenta. Включает:
- Основной интерфейс для подключения к Google Magenta API
- Базовые элементы управления
- Совместимость с Ableton Live 12

### 2. Ableton2ML_MIDI_Generator.amxd
MIDI эффект для генерации мелодий с помощью AI:
- **Generate Melody** - кнопка для ручной генерации мелодий
- **Creativity Level** - слайдер для настройки уровня креативности AI (0-100)
- **Tempo** - слайдер для настройки темпа генерации
- **Auto Generate** - переключатель для автоматической генерации
- **MIDI вход/выход** - для обработки MIDI данных
- **Google Magenta API Integration** - готовые объекты для HTTP запросов

### 3. Ableton2ML_Audio_Processor.amxd
Аудио эффект для обработки сгенерированного аудио:
- **Volume** - слайдер для управления громкостью
- **Filter Cutoff** - слайдер для настройки частоты среза фильтра
- **Compression** - слайдер для настройки компрессии
- **AI Enhance** - кнопка для AI-улучшения аудио
- **Аудио цепочка**: ADC → Gain → Filter → Compressor → DAC
- **Google Magenta Audio API** - интеграция для AI-обработки аудио

## Установка

1. Скопируйте `.amxd` файлы в папку Max for Live Devices:
   - **macOS**: `~/Music/Ableton/User Library/Presets/MIDI Effects/Max MIDI Effect/`
   - **Windows**: `%USERPROFILE%\Music\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\`

2. Или перетащите файлы прямо в Ableton Live 12

## Использование

### MIDI Generator
1. Создайте MIDI трек в Ableton Live
2. Добавьте плагин `Ableton2ML_MIDI_Generator.amxd`
3. Настройте параметры:
   - Установите уровень креативности
   - Настройте темп
   - Включите Auto Generate или используйте кнопку Generate Melody
4. Подключите к инструменту или другому MIDI устройству

### Audio Processor
1. Создайте аудио трек в Ableton Live
2. Добавьте плагин `Ableton2ML_Audio_Processor.amxd`
3. Настройте параметры:
   - Volume для громкости
   - Filter Cutoff для фильтрации
   - Compression для динамической обработки
4. Используйте кнопку AI Enhance для AI-улучшения

## Интеграция с Google Magenta

Все плагины включают готовые объекты для интеграции с Google Magenta:
- `url` - для HTTP запросов к Magenta API
- `json` - для обработки JSON ответов
- `live.thisdevice` - для доступа к параметрам Live
- `live.object` - для работы с объектами Live

## Требования

- Ableton Live 12 (Suite версия)
- Max for Live (включен в Live Suite)
- Интернет-соединение для работы с Google Magenta API

## Разработка

Для разработки собственных плагинов:
1. Откройте `.amxd` файлы в Max for Live
2. Переключитесь в режим редактирования (Edit Mode)
3. Модифицируйте патчи под свои нужды
4. Сохраните как новый `.amxd` файл

## Поддержка

Для получения поддержки или сообщения об ошибках, создайте issue в репозитории проекта.

## Лицензия

Этот проект распространяется под лицензией MIT. См. файл LICENSE для подробностей.
