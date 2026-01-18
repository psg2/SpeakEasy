# OpenVoicy Tests

This directory contains unit tests for the OpenVoicy application using Swift Testing framework.

## Running Tests

### Using Swift Package Manager
```bash
swift test
```

### Using Xcode
1. Open `OpenVoicy.xcodeproj` in Xcode
2. Select Product → Test (⌘+U)
3. View test results in the Test Navigator

### Using xcodebuild (CI/Command Line)
```bash
xcodebuild test -scheme OpenVoicy -project OpenVoicy.xcodeproj
```

## Test Structure

- `ShortcutValidatorTests.swift` - Tests for keyboard shortcut validation logic
  - Valid shortcuts with various modifier combinations
  - Invalid shortcuts (too many keys, missing modifiers)
  - Reserved system shortcuts (macOS and Windows)
  - F-keys and special keys

- `TimeFormattersTests.swift` - Tests for time duration formatting
  - Milliseconds formatting (< 1 second)
  - Seconds formatting (1-59 seconds)
  - Minutes formatting (≥ 60 seconds)
  - Edge cases and real-world examples

## Requirements

- macOS 14.0+
- Swift 5.9+
- Xcode 15.0+ (for IDE support)

## Adding New Tests

1. Create a new Swift file in `Tests/OpenVoicyTests/`
2. Import the Testing framework: `import Testing`
3. Import the module to test: `@testable import OpenVoicyLib`
4. Use `@Suite` to group related tests
5. Use `@Test` to mark test functions
6. Use `#expect` for assertions

Example:
```swift
import Testing
@testable import OpenVoicyLib

@Suite("My Feature Tests")
struct MyFeatureTests {
    @Test("Description of what this tests")
    func testSomething() {
        let result = myFunction()
        #expect(result == expectedValue)
    }
}
```
