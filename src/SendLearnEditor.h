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
