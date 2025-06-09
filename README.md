# 🚀 Send Learn - Automatic Music Data Collection for LLM Training

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![C++](https://img.shields.io/badge/C++-17-blue.svg)](https://isocpp.org/)
[![JUCE](https://img.shields.io/badge/JUCE-7.0+-green.svg)](https://juce.com/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows-lightgrey.svg)](https://github.com)

**Send Learn** is an innovative AU/VST plugin system that automatically collects synchronized MIDI and audio data from your DAW for training Large Language Models on musical patterns. Simply install the plugin and it starts collecting your entire creative process with sample-accurate timing.

![Send Learn Demo](docs/demo.gif)

## ✨ Features

### 🔄 **Automatic Operation**
- **Zero-configuration**: Starts collecting data immediately after plugin load
- **Transparent processing**: Passes all audio/MIDI through unchanged
- **Auto-reconnection**: Handles network interruptions gracefully
- **Live indicators**: Real-time visual feedback of connection and data transmission

### ⏱️ **Sample-Accurate Synchronization**
- **Precise timing**: MIDI events synced to exact sample positions in audio blocks
- **Playhead tracking**: DAW timeline position for musical context
- **Tempo & time signature**: Automatic capture of musical timing information
- **Automation data**: Parameter movements and controller changes

### 🎵 **Comprehensive Data Collection**
- **MIDI events**: Notes, controllers, pitch bend, aftertouch
- **Audio streams**: Multi-channel audio with adaptive quality
- **DAW context**: Transport state, tempo, time signatures
- **Creative process**: Records composition, editing, and experimentation

### 🌐 **Intelligent Network Handling**
- **Adaptive quality**: Automatically adjusts data quality based on network conditions
- **Data compression**: GZIP compression for efficient transmission
- **Buffering**: Reliable delivery with packet ordering and integrity checks
- **Multiple clients**: Support for multiple simultaneous plugin instances

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Ableton Live  │    │   Send Learn     │    │  ML Training    │
│                 │◄──►│     Plugin       │◄──►│     Server      │
│  🎹 MIDI Track  │    │                  │    │                 │
│  🔊 Audio Track │    │  • Data Capture  │    │ • Data Storage  │
│  🎚️ Automation  │    │  • Sync Engine   │    │ • Feature Ext.  │
│                 │    │  • Network TX    │    │ • ML Export     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### 1. Clone and Build

```bash
git clone https://github.com/yourusername/send-learn.git
cd send-learn

# Initialize JUCE submodule
git submodule update --init --recursive

# Build the plugin
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Install (macOS)
sudo cmake --build . --target install
```

### 2. Start the ML Training Server

```bash
cd server
pip install -r requirements.txt

# Start server
python3 ml_training_server.py --host 0.0.0.0 --port 8080

🤖 ML Training Data Server started on 0.0.0.0:8080
📁 Dataset saving to: ./ml_dataset
```

### 3. Load Plugin in Your DAW

1. **Add "Send Learn"** plugin to your MIDI and/or Audio tracks
2. **Plugin auto-connects** to `127.0.0.1:8080` by default
3. **Green pulsing indicator** shows successful connection
4. **Start creating music** - all data is automatically collected!

## 🎛️ Plugin Interface

```
🚀 Send Learn
● ⬆ [████████████] 
Connected | 2.4 Mbps | 0 errors

Server: 127.0.0.1:8080 [Test] [Reconnect]
MIDI: 2.8K | Audio: 15.2M | Packets: 847 | Latency: 3.2ms
```

### Status Indicators
- **🟢 Green Circle**: Connected to server (pulsing animation)
- **⬆️ Blue Arrows**: Data transmission active (flashing)
- **Data Flow Bar**: MIDI (yellow) and Audio (cyan) activity visualization
- **Real-time Counters**: Live statistics of collected data

## 📊 Collected Data Format

### Synchronized Data Packet
```json
{
  "hostTimeStamp": 1634567890.123,
  "playheadPosition": 45.678,
  "sampleRate": 44100,
  "blockSize": 512,
  
  "midiMessages": [
    {
      "message": "Note On C4 Vel 87",
      "samplePosition": 128,
      "timestamp": 1634567890.126
    }
  ],
  
  "audioChannels": [
    [0.023, -0.145, 0.678, ...],
    [0.012, -0.234, 0.567, ...]
  ],
  
  "playbackInfo": {
    "isPlaying": true,
    "tempo": 120.0,
    "timeSignature": "4/4",
    "ppqPosition": 384.75
  },
  
  "dataHash": "a1b2c3d4e5f6..."
}
```

## 🤖 ML Training Server

The Python server processes incoming data streams and prepares structured datasets for machine learning.

### Features
- **Real-time processing**: Handles multiple simultaneous plugin connections
- **Feature extraction**: MFCC, chroma, spectral features from audio
- **Sequence generation**: Creates 30-second training sequences with metadata
- **Multiple export formats**: PyTorch, TensorFlow, HDF5
- **Quality metrics**: Automatic dataset quality analysis

### Server Commands
```bash
🤖 > status
📊 Collected: 45 sequences, 12847 MIDI events

🤖 > export pytorch
📦 Exporting dataset in pytorch format...
✅ PyTorch dataset saved to pytorch_dataset.pt

🤖 > quality
📈 Data quality: avg complexity 0.67, tempo range 60-180 BPM

🤖 > report
📊 Dataset report saved to training_report.json
```

## 🛠️ Configuration

### Plugin Settings
```cpp
// Network configuration
serverIP = "127.0.0.1";
serverPort = 8080;
enableCompression = true;

// Quality settings  
adaptiveQuality = 1.0;  // 0.1 - 1.0
compressionLevel = 6;   // 0-9
```

### Server Configuration
```python
# Dataset settings
sequence_duration = 30.0  # seconds
overlap_duration = 5.0    # seconds
min_sequence_events = 10  # minimum MIDI events

# Feature extraction
mfcc_n = 13
chroma_n = 12
hop_length = 512
```

## 🎯 Use Cases

### 🎹 **Music Education**
```
Student plays → Send Learn collects performance data
Teacher reviews → ML learns to identify technique patterns
Automated feedback → Personalized practice recommendations
```

### 🎵 **Genre Analysis**
```
Collect compositions across genres → Style classification training
MIDI + Audio correlation → Generate authentic arrangements  
Tempo/rhythm patterns → Groove generation models
```

### 🎧 **Production Workflow Learning**
```
Record entire creative process → Learn production techniques
Automation patterns → Intelligent mixing assistance
Sound design choices → Timbre recommendation systems
```

## 📈 ML Applications

### Trained Models Can:
- **Predict audio output** from MIDI input sequences
- **Generate realistic automation** curves and parameter movements
- **Classify musical styles** and genres from performance data
- **Suggest arrangements** based on harmonic and rhythmic patterns
- **Provide real-time feedback** on timing and musical expression

### Training Pipeline
```python
# Load collected dataset
dataset = torch.load('pytorch_dataset.pt')

# Extract features
midi_sequences = [sample['midi_notes'] for sample in dataset]
audio_features = [sample['mfcc'] for sample in dataset]

# Train sequence-to-sequence model
model = MusicLLM(midi_vocab_size=128, audio_feat_dim=13)
train_model(model, midi_sequences, audio_features)
```

## 🏃‍♂️ Performance

### Typical Performance Metrics
- **Latency**: 1-5ms additional processing overhead
- **CPU Usage**: <1% on modern systems
- **Network**: 1-10 Mbps depending on activity and quality settings
- **Storage**: ~100MB per hour of active recording (compressed)

### Adaptive Quality System
```
Network Good (>95% success) → Full quality (1.0)
Network Issues (80-95%)     → Reduced quality (0.7)
Network Poor (<80%)         → Minimal quality (0.3)
```

## 🔧 Building from Source

### Requirements
- **CMake 3.16+**
- **JUCE Framework 7.0+** 
- **C++17 compatible compiler**
- **macOS 10.15+** or **Windows 10+**

### Build Steps
```bash
# Configure
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build --config Release

# Install (requires admin privileges)
cmake --build build --target install

# Create installer package (macOS)
cmake --build build --target package
```

### Custom Build Options
```bash
# Build specific formats only
cmake .. -DJUCE_FORMATS="AU;VST3"

# Enable debugging
cmake .. -DCMAKE_BUILD_TYPE=Debug -DSEND_LEARN_DEBUG=ON

# Disable compression
cmake .. -DSEND_LEARN_COMPRESSION=OFF
```

## 🧪 Testing

### Unit Tests
```bash
cd build
ctest --verbose
```

### Integration Testing
```bash
# Start test server
python3 tests/test_server.py

# Run plugin tests
./build/tests/plugin_tests

# Load test project
open tests/TestProject.als
```

## 📚 Documentation

- **[Plugin API Reference](docs/api.md)** - Detailed plugin interface documentation
- **[Server Protocol](docs/protocol.md)** - Network protocol specification  
- **[ML Integration Guide](docs/ml_guide.md)** - Training pipeline examples
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
# Fork and clone the repository
git clone https://github.com/yourusername/send-learn.git
cd send-learn

# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Create feature branch
git checkout -b feature/your-feature-name
```

### Code Standards
- **C++17** standard with modern practices
- **JUCE coding conventions** for plugin code
- **PEP 8** for Python server code
- **Comprehensive tests** for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[JUCE Framework](https://juce.com/)** - Cross-platform audio development
- **[librosa](https://librosa.org/)** - Audio feature extraction
- **[PyTorch](https://pytorch.org/)** - Machine learning framework
- **Music ML Community** - Inspiration and research foundation

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/send-learn/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/send-learn/discussions)
- **Email**: support@send-learn.dev
- **Discord**: [Join our community](https://discord.gg/send-learn)

---

<div align="center">

**[Website](https://send-learn.dev)** • **[Documentation](https://docs.send-learn.dev)** • **[Examples](https://examples.send-learn.dev)**

Made with ❤️ for the music and AI community

</div>