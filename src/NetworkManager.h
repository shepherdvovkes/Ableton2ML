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
