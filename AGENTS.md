# Project Rules

## Formatting

- Specify files to format: `swiftformat <file1> <file2> ...`
- Project formatting: `mise run format`

## Build

- mise run build

## Developing

- Run `mise run dev` to kill the running application, build the application, and open the application
- You can run it yourself to restart the application for the developer

## Testing

- Run all tests: `mise run test` or `swift test`
- Run specific test file: `swift test --filter ShortcutValidatorTests`
- Run specific test: `swift test --filter "Valid shortcut with single modifier"`
