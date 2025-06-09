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
