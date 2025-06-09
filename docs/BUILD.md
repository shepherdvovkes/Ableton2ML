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
