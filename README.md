# SpeakEasy

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

## Installation

Download the latest release from [Releases](../../releases):

1. Download and extract `SpeakEasy-vX.X.X-macOS.zip`
2. Remove the quarantine attribute (required for unsigned apps):
   ```bash
   xattr -cr ~/Downloads/SpeakEasy.app
   ```
3. Move `SpeakEasy.app` to your Applications folder
4. Open the app (you may need to right-click and select "Open" the first time)
5. Grant microphone and accessibility permissions when prompted

## Development Setup

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

## Testing

Run tests using:

```bash
mise run test
# or
swift test
```

### Adding Tests

Tests live in `Tests/SpeakEasyTests/` and use Swift Testing:

```swift
import Testing
@testable import SpeakEasyLib

@Suite("My Feature Tests")
struct MyFeatureTests {
    @Test("Description of what this tests")
    func testSomething() {
        let result = myFunction()
        #expect(result == expectedValue)
    }
}
```

## Releasing

To publish a new version:

1. **Create and push a version tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. The [Release workflow](.github/workflows/release.yml) will automatically:
   - Build the app for macOS
   - Create a ZIP archive with the `.app` bundle
   - Generate a SHA256 checksum
   - Create a GitHub Release with auto-generated release notes

Alternatively, trigger a release manually from the Actions tab using "workflow_dispatch" and specifying a version (e.g., `v1.0.0`). The workflow will create the tag automatically.

**Note:** Use semantic versioning (e.g., `v1.0.0`). Tags containing `-` (e.g., `v1.0.0-beta`) are marked as pre-releases.

## Tech Stack

- Swift 6 / SwiftUI
- SwiftData for persistence
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) for local inference
- AVFoundation for audio capture
