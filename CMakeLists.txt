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
