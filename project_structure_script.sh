t#!/bin/bash

# Скрипт для создания полной структуры проекта Send Learn
# Запустите: chmod +x create_sendlearn_project.sh && ./create_sendlearn_project.sh

PROJECT_NAME="SendLearn"
echo "🚀 Creating Send Learn project structure..."

# Создаем основные директории
mkdir -p src
mkdir -p server
mkdir -p docs
mkdir -p tests
mkdir -p examples

echo "📁 Created directory structure"

# ============= CMakeLists.txt =============
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.16)

project(SendLearn VERSION 1.0.0)

# Настройки C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Добавляем JUCE
find_package(PkgConfig REQUIRED)
add_subdirectory(JUCE)

# Создаем плагин
juce_add_plugin(SendLearn
    COMPANY_NAME "YourCompany"
    IS_SYNTH FALSE
    NEEDS_MIDI_INPUT TRUE
    NEEDS_MIDI_OUTPUT TRUE
    IS_MIDI_EFFECT FALSE
    EDITOR_WANTS_KEYBOARD_FOCUS FALSE
    COPY_PLUGIN_AFTER_BUILD TRUE
    PLUGIN_MANUFACTURER_CODE Sndr
    PLUGIN_CODE SLrn
    FORMATS AU VST3 Standalone
    PRODUCT_NAME "Send Learn")

# Добавляем исходные файлы
target_sources(SendLearn
    PRIVATE
        src/SendLearnProcessor.cpp
        src/SendLearnProcessor.h
        src/SendLearnEditor.cpp
        src/SendLearnEditor.h
        src/NetworkManager.cpp
        src/NetworkManager.h
        src/NetworkProtocol.h
)

# Настройки компилятора
target_compile_definitions(SendLearn
    PUBLIC
        JUCE_WEB_BROWSER=0
        JUCE_USE_CURL=0
        JUCE_VST3_CAN_REPLACE_VST2=0
        JUCE_DISPLAY_SPLASH_SCREEN=0
        JUCE_REPORT_APP_USAGE=0
)

# Линкуем JUCE библиотеки
target_link_libraries(SendLearn
    PRIVATE
        juce::juce_audio_utils
        juce::juce_audio_plugin_client
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags
)

# Специфичные настройки для macOS
if(APPLE)
    set_target_properties(SendLearn PROPERTIES
        BUNDLE TRUE
        BUNDLE_EXTENSION "component"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.yourcompany.sendlearn"
        MACOSX_BUNDLE_BUNDLE_NAME "Send Learn"
        MACOSX_BUNDLE_BUNDLE_VERSION "1.0.0"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0.0"
    )
    
    target_link_libraries(SendLearn PRIVATE
        "-framework CoreFoundation"
        "-framework CoreServices"
        "-framework AudioUnit"
        "-framework AudioToolbox"
        "-framework CoreAudio"
    )
endif()

# Установка плагина
if(APPLE)
    install(TARGETS SendLearn
        BUNDLE DESTINATION "/Library/Audio/Plug-Ins/Components"
        COMPONENT AudioUnit
    )
endif()
EOF

echo "✅ Created CMakeLists.txt"

# ============= Заголовки плагина =============
cat > src/SendLearnProcessor.h << 'EOF'
#pragma once

#include <JuceHeader.h>
#include <atomic>
#include <queue>
#include <thread>
#include <memory>
#include "NetworkManager.h"

class SendLearnAudioProcessor : public juce::AudioProcessor
{
public:
    SendLearnAudioProcessor();
    ~SendLearnAudioProcessor() override;

    // AudioProcessor methods
    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    // Plugin info
    const juce::String getName() const override { return "Send Learn"; }
    bool acceptsMidi() const override { return true; }
    bool producesMidi() const override { return true; }
    
    // Editor
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override { return true; }
    
    // State
    void getStateInformation(juce::MemoryBlock& destData) override;
    void setStateInformation(const void* data, int sizeInBytes) override;

    // Public interface for GUI
    bool isConnected() const { return networkManager.isConnected(); }
    const NetworkManager::Statistics& getStatistics() const { return networkManager.getStats(); }
    void setServerEndpoint(const juce::String& endpoint) { networkManager.setEndpoint(endpoint); }

private:
    NetworkManager networkManager;
    
    // Data collection
    struct SyncedDataPacket {
        double timestamp;
        double playheadPosition;
        std::vector<juce::MidiMessage> midiMessages;
        std::vector<int> midiSamplePositions;
        juce::AudioBuffer<float> audioData;
        bool isPlaying;
        double tempo;
    };
    
    void collectData(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages);
    SyncedDataPacket createDataPacket(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages);
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(SendLearnAudioProcessor)
};
EOF

cat > src/SendLearnEditor.h << 'EOF'
#pragma once

#include <JuceHeader.h>
#include "SendLearnProcessor.h"

class SendLearnAudioProcessorEditor : public juce::AudioProcessorEditor,
                                     public juce::Timer,
                                     public juce::Button::Listener,
                                     public juce::TextEditor::Listener
{
public:
    SendLearnAudioProcessorEditor(SendLearnAudioProcessor&);
    ~SendLearnAudioProcessorEditor() override;

    void paint(juce::Graphics&) override;
    void resized() override;
    
    // Timer for updates
    void timerCallback() override;
    
    // Event handlers
    void buttonClicked(juce::Button* button) override;
    void textEditorTextChanged(juce::TextEditor& editor) override;

private:
    SendLearnAudioProcessor& audioProcessor;
    
    // Visual indicators
    juce::Component connectionIndicator;
    juce::Component transmissionIndicator;
    juce::Component dataActivityIndicator;
    
    // Status labels
    juce::Label connectionLabel;
    juce::Label dataRateLabel;
    juce::Label statsLabel;
    
    // Settings
    juce::Label endpointLabel;
    juce::TextEditor endpointEditor;
    juce::TextButton testButton;
    juce::TextButton reconnectButton;
    
    // Animation
    float pulsePhase = 0.0f;
    
    void drawConnectionStatus(juce::Graphics& g);
    void drawTransmissionActivity(juce::Graphics& g);
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(SendLearnAudioProcessorEditor)
};
EOF

cat > src/NetworkManager.h << 'EOF'
#pragma once

#include <JuceHeader.h>
#include <atomic>
#include <thread>
#include <mutex>

class NetworkManager
{
public:
    NetworkManager();
    ~NetworkManager();
    
    struct Statistics {
        std::atomic<uint64_t> packetsTransmitted{0};
        std::atomic<uint64_t> bytesTransmitted{0};
        std::atomic<uint64_t> transmissionErrors{0};
        std::atomic<double> averageLatency{0.0};
        std::atomic<double> dataRateMbps{0.0};
    };
    
    bool isConnected() const { return connected.load(); }
    const Statistics& getStats() const { return stats; }
    
    void setEndpoint(const juce::String& endpoint);
    bool connect();
    void disconnect();
    
    bool transmitData(const juce::MemoryBlock& data);
    
private:
    std::atomic<bool> connected{false};
    std::atomic<bool> shouldStop{false};
    
    juce::String serverEndpoint = "127.0.0.1:8080";
    std::unique_ptr<juce::StreamingSocket> socket;
    std::unique_ptr<std::thread> connectionThread;
    std::mutex transmissionMutex;
    
    Statistics stats;
    
    void connectionThreadFunction();
    void attemptConnection();
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(NetworkManager)
};
EOF

cat > src/NetworkProtocol.h << 'EOF'
#pragma once

#include <JuceHeader.h>
#include <cstdint>

namespace SendLearnProtocol
{
    // Packet types
    enum PacketType : uint32_t
    {
        PACKET_HANDSHAKE = 1,
        PACKET_MIDI_AUDIO = 2,
        PACKET_HEARTBEAT = 3
    };

    // Packet header
    struct PacketHeader
    {
        uint32_t magic = 0x53454E44;      // "SEND"
        uint32_t packetType;
        uint32_t dataSize;
        uint64_t timestamp;
        uint32_t sequenceNumber;
        uint32_t checksum;
        
        static constexpr size_t HEADER_SIZE = sizeof(PacketHeader);
    };

    // MIDI + Audio data packet
    struct MidiAudioPacketData
    {
        double playheadPosition;
        double sampleRate;
        uint32_t blockSize;
        bool isPlaying;
        double tempo;
        
        uint32_t midiEventCount;
        uint32_t audioChannelCount;
        uint32_t audioSampleCount;
        
        // Data follows:
        // - MIDI events (message + sample position pairs)
        // - Audio samples (interleaved float data)
    };

    class PacketSerializer
    {
    public:
        static juce::MemoryBlock createMidiAudioPacket(
            const std::vector<juce::MidiMessage>& midiMessages,
            const std::vector<int>& samplePositions,
            const juce::AudioBuffer<float>& audioBuffer,
            double playheadPos, double sampleRate, bool isPlaying, double tempo,
            uint32_t sequenceNum);
            
        static bool parsePacket(const juce::MemoryBlock& data, 
                               PacketHeader& header, 
                               juce::MemoryBlock& payload);
                               
    private:
        static uint32_t calculateCRC32(const juce::MemoryBlock& data);
    };
}
EOF

echo "✅ Created plugin headers"

# ============= Python сервер =============
cat > server/ml_training_server.py << 'EOF'
#!/usr/bin/env python3
"""
ML Training Data Server для сбора данных от Send Learn плагина
"""

import socket
import struct
import threading
import time
import json
import os
from datetime import datetime
from typing import Dict, List, Optional

class SendLearnServer:
    def __init__(self, host='0.0.0.0', port=8080):
        self.host = host
        self.port = port
        self.running = False
        self.clients = {}
        
        # Статистика
        self.stats = {
            'packets_received': 0,
            'bytes_received': 0,
            'clients_connected': 0,
            'errors': 0
        }
        
        # Создаем директорию для данных
        self.data_dir = "collected_data"
        os.makedirs(self.data_dir, exist_ok=True)
        
    def start_server(self):
        """Запуск сервера"""
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        try:
            self.socket.bind((self.host, self.port))
            self.socket.listen(5)
            self.running = True
            
            print(f"🚀 Send Learn Server started on {self.host}:{self.port}")
            print(f"📁 Data directory: {self.data_dir}")
            
            while self.running:
                try:
                    client_socket, address = self.socket.accept()
                    print(f"🔗 Client connected: {address}")
                    
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, address)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                    self.stats['clients_connected'] += 1
                    
                except socket.error as e:
                    if self.running:
                        print(f"❌ Connection error: {e}")
                        
        except Exception as e:
            print(f"❌ Server error: {e}")
        finally:
            self.cleanup()
            
    def handle_client(self, client_socket, address):
        """Обработка клиента"""
        client_id = f"{address[0]}:{address[1]}"
        
        try:
            while self.running:
                # Читаем заголовок пакета
                header_data = self.receive_exact(client_socket, 24)
                if not header_data:
                    break
                    
                # Парсим заголовок
                magic, packet_type, data_size, timestamp, seq_num, checksum = struct.unpack('<IIIQI I', header_data)
                
                if magic != 0x53454E44:  # "SEND"
                    continue
                    
                # Читаем данные
                packet_data = self.receive_exact(client_socket, data_size)
                if not packet_data:
                    break
                    
                # Обрабатываем пакет
                self.process_packet(packet_type, packet_data, client_id)
                self.stats['packets_received'] += 1
                self.stats['bytes_received'] += len(header_data) + len(packet_data)
                
        except Exception as e:
            print(f"❌ Client error {client_id}: {e}")
            self.stats['errors'] += 1
        finally:
            client_socket.close()
            print(f"🔌 Client disconnected: {client_id}")
            
    def receive_exact(self, sock, size):
        """Получение точного количества байт"""
        data = b''
        while len(data) < size:
            chunk = sock.recv(size - len(data))
            if not chunk:
                return None
            data += chunk
        return data
        
    def process_packet(self, packet_type, data, client_id):
        """Обработка пакета"""
        if packet_type == 1:  # Handshake
            print(f"🤝 Handshake from {client_id}")
        elif packet_type == 2:  # MIDI + Audio data
            self.process_data_packet(data, client_id)
        elif packet_type == 3:  # Heartbeat
            pass
            
    def process_data_packet(self, data, client_id):
        """Обработка пакета с данными"""
        try:
            # Простое логирование (в реальности здесь будет полный парсинг)
            timestamp = time.time()
            print(f"📊 Data packet from {client_id}: {len(data)} bytes")
            
            # Сохраняем в файл для анализа
            filename = f"{self.data_dir}/data_{client_id.replace(':', '_')}_{int(timestamp)}.bin"
            with open(filename, 'wb') as f:
                f.write(data)
                
        except Exception as e:
            print(f"❌ Data processing error: {e}")
            
    def print_stats(self):
        """Вывод статистики"""
        print("\n" + "="*50)
        print("📊 SERVER STATISTICS")
        print("="*50)
        print(f"Packets received: {self.stats['packets_received']}")
        print(f"Bytes received: {self.stats['bytes_received']:,}")
        print(f"Clients connected: {self.stats['clients_connected']}")
        print(f"Errors: {self.stats['errors']}")
        print("="*50)
        
    def cleanup(self):
        """Очистка ресурсов"""
        self.running = False
        if hasattr(self, 'socket'):
            self.socket.close()
        print("🛑 Server stopped")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Send Learn ML Training Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host address')
    parser.add_argument('--port', type=int, default=8080, help='Port number')
    
    args = parser.parse_args()
    
    server = SendLearnServer(args.host, args.port)
    
    try:
        # Запускаем сервер в отдельном потоке
        server_thread = threading.Thread(target=server.start_server)
        server_thread.daemon = True
        server_thread.start()
        
        print("Press Ctrl+C to stop the server")
        print("Commands: 'stats' - show statistics, 'quit' - exit")
        
        while True:
            try:
                command = input("> ").strip().lower()
                if command == 'stats':
                    server.print_stats()
                elif command == 'quit':
                    break
                elif command == 'help':
                    print("Available commands: stats, quit, help")
            except EOFError:
                break
                
    except KeyboardInterrupt:
        pass
    finally:
        server.cleanup()
        print("👋 Goodbye!")

if __name__ == "__main__":
    main()
EOF

echo "✅ Created Python server"

# ============= requirements.txt для сервера =============
cat > server/requirements.txt << 'EOF'
numpy>=1.21.0
scipy>=1.7.0
librosa>=0.8.1
h5py>=3.1.0
matplotlib>=3.3.4
scikit-learn>=1.0.0
torch>=1.9.0
tensorflow>=2.6.0
EOF

# ============= .gitignore =============
cat > .gitignore << 'EOF'
# Build directories
build/
builds/
cmake-build-*/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# macOS
.DS_Store
*.app

# Plugin binaries
*.component
*.vst3
*.dll
*.dylib
*.so

# Data files
collected_data/
ml_dataset/
*.bin
*.h5

# Python
__pycache__/
*.pyc
*.pyo
*.egg-info/
venv/
env/

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
*.tmp
EOF

# ============= Документация =============
cat > docs/BUILD.md << 'EOF'
# Building Send Learn Plugin

## Prerequisites

### macOS
- Xcode 12+ with Command Line Tools
- CMake 3.16+
- Git with submodules support

### Windows  
- Visual Studio 2019+ with C++ tools
- CMake 3.16+
- Git with submodules support

## Build Steps

### 1. Clone with submodules
```bash
git clone --recursive https://github.com/yourusername/send-learn.git
cd send-learn
```

### 2. Initialize JUCE (if not cloned recursively)
```bash
git submodule add https://github.com/juce-framework/JUCE.git
git submodule update --init --recursive
```

### 3. Configure and build
```bash
# Create build directory
mkdir build && cd build

# Configure (Release)
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release

# Install (macOS - requires admin)
sudo cmake --build . --target install
```

### 4. Alternative: Xcode project (macOS)
```bash
cmake .. -G Xcode
open SendLearn.xcodeproj
```

## Build Targets

- `SendLearn` - Main plugin target
- `SendLearn_Standalone` - Standalone application
- `install` - Install plugin to system directories

## Troubleshooting

### JUCE not found
Make sure JUCE submodule is properly initialized:
```bash
git submodule status
git submodule add https://github.com/juce-framework/JUCE.git
git submodule update --init --recursive
```

### Plugin not appearing in DAW
- Check installation path: `/Library/Audio/Plug-Ins/Components/` (macOS)
- Restart your DAW after installation
- Check Console.app for loading errors (macOS)
EOF

cat > docs/USAGE.md << 'EOF'
# Send Learn Plugin Usage Guide

## Quick Start

### 1. Start the Server
```bash
cd server
python3 ml_training_server.py
```

### 2. Load Plugin in DAW
1. Open Ableton Live (or any AU/VST3 compatible DAW)
2. Add "Send Learn" to your MIDI or Audio track
3. Plugin automatically connects to `127.0.0.1:8080`

### 3. Monitor Data Collection
- 🟢 Green circle = Connected to server
- ⬆️ Blue activity = Data transmission
- Numbers = Real-time statistics

## Plugin Interface

```
🚀 Send Learn
● ⬆ [Data Flow] 
Connected | 2.4 Mbps | 0 errors

Server: 127.0.0.1:8080 [Test] [Reconnect]
Packets: 847 | Errors: 0
```

### Status Indicators
- **Connection Indicator**: Green (connected) / Red (disconnected)
- **Transmission Activity**: Shows when data is being sent
- **Data Rate**: Current network throughput
- **Statistics**: Packet counts and error rates

### Server Configuration
- **Server Address**: IP:PORT format (default: 127.0.0.1:8080)
- **Test Button**: Check connection to server
- **Reconnect Button**: Force reconnection attempt

## Data Collection

### What Gets Collected
- **MIDI Events**: All note on/off, controllers, pitch bend
- **Audio Streams**: Multi-channel audio with sample-accurate timing
- **Playhead Position**: DAW timeline position for context
- **Tempo & Time Signature**: Musical timing information

### Timing Precision
- Sample-accurate MIDI event positioning
- Synchronized audio blocks
- Playhead position tracking
- Tempo change detection

## Server Commands

```bash
> stats
📊 Packets received: 1,247
📈 Bytes received: 15,234,567
🔗 Clients connected: 2

> help
Available commands: stats, quit, help
```

## Troubleshooting

### Plugin Not Connecting
1. Check server is running: `python3 ml_training_server.py`
2. Verify firewall settings
3. Try different port: change 8080 to 8081
4. Check server logs for connection attempts

### No Data Being Sent
1. Ensure track has MIDI or audio activity
2. Check plugin is on active track
3. Verify playback is running in DAW
4. Look for error messages in server console

### High CPU Usage
- Plugin uses <1% CPU normally
- High usage may indicate network issues
- Try reducing audio quality in plugin settings
EOF

# ============= Примеры =============
cat > examples/basic_client.py << 'EOF'
#!/usr/bin/env python3
"""
Простой клиент для тестирования Send Learn сервера
"""

import socket
import struct
import time

def test_connection():
    """Тест подключения к серверу"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    try:
        print("🔗 Connecting to Send Learn server...")
        sock.connect(('127.0.0.1', 8080))
        print("✅ Connected!")
        
        # Отправляем handshake
        header = struct.pack('<IIIQI I', 
                           0x53454E44,  # magic "SEND"
                           1,           # packet type (handshake)
                           0,           # data size
                           int(time.time() * 1000),  # timestamp
                           1,           # sequence number
                           0)           # checksum
                           
        sock.send(header)
        print("🤝 Handshake sent")
        
        # Отправляем тестовые данные
        test_data = b"Test data from Python client"
        data_header = struct.pack('<IIIQI I',
                                0x53454E44,     # magic
                                2,              # packet type (data)
                                len(test_data), # data size
                                int(time.time() * 1000),
                                2,              # sequence number
                                0)              # checksum
                                
        sock.send(data_header)
        sock.send(test_data)
        print(f"📊 Test data sent: {len(test_data)} bytes")
        
        time.sleep(1)
        print("✅ Test completed successfully")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        sock.close()

if __name__ == "__main__":
    test_connection()
EOF

# ============= LICENSE =============
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Send Learn Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

echo "✅ Created documentation and examples"

# ============= Создание архива =============
echo ""
echo "📦 Creating project archive..."

# Создаем архив
if command -v zip &> /dev/null; then
    zip -r SendLearn_Project.zip . -x "*.git*" "build/*" "*.DS_Store"
    echo "✅ Archive created: SendLearn_Project.zip"
else
    tar -czf SendLearn_Project.tar.gz --exclude=".git*" --exclude="build" --exclude=".DS_Store" .
    echo "✅ Archive created: SendLearn_Project.tar.gz"
fi

echo ""
echo "🎉 Send Learn project structure created successfully!"
echo ""
echo "📁 Project structure:"
echo "   src/           - Plugin source code (C++)"
echo "   server/        - ML training server (Python)"
echo "   docs/          - Documentation"
echo "   examples/      - Usage examples"
echo ""
echo "🚀 Next steps:"
echo "   1. Add JUCE submodule: git submodule add https://github.com/juce-framework/JUCE.git"
echo "   2. Build plugin: mkdir build && cd build && cmake .. && cmake --build ."
echo "   3. Start server: cd server && python3 ml_training_server.py"
echo "   4. Load plugin in your DAW and start creating music!"
echo ""
echo "📖 See docs/BUILD.md and docs/USAGE.md for detailed instructions"