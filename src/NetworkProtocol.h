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
