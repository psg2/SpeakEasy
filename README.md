# OpenVoicy

A macOS native speech-to-text app with global hotkey support, offering both cloud (OpenAI Whisper API) and local (WhisperKit) transcription.

## Features

- **Global Hotkey** — Trigger recording from anywhere with a keyboard shortcut (default: `⌥ Space`)
- **Dual Transcription Providers** — Choose between OpenAI's cloud API or on-device WhisperKit
- **Auto-Type** — Transcribed text is automatically typed into the focused application
- **Floating Overlay** — Animated waveform UI shows recording status
- **Transcription History** — Searchable history with date grouping and audio playback
- **Model Management** — Download and manage local Whisper models with progress tracking

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon recommended for local transcription
- Microphone access permission
- Accessibility permission (for auto-typing)

## Setup

1. **Build & Run** — Run `dev` (via mise) to build and launch
2. **Grant Permissions** — Allow microphone and accessibility access when prompted
3. **Configure Provider**:
   - *OpenAI*: Add your API key in Settings → Providers
   - *Local*: Download a Whisper model from Settings → Providers

## Usage

1. Press `⌥ Space` (or your custom shortcut) to start recording
2. Speak your text
3. Release or press the shortcut again to stop
4. Transcription is automatically typed at your cursor (or copied to clipboard)

Press `Esc` to cancel recording.

## Tech Stack

- Swift 6 / SwiftUI
- SwiftData for persistence
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) for local inference
- AVFoundation for audio capture

