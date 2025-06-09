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
