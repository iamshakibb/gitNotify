# Contributing to GitNotify

Thank you for your interest in contributing to GitNotify! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How to Contribute

### Reporting Bugs

Before submitting a bug report:

1. Check existing [issues](https://github.com/yourusername/GitNotify/issues) to avoid duplicates
2. Update to the latest version to see if the issue persists
3. Collect relevant information:
   - macOS version
   - GitNotify version
   - Steps to reproduce
   - Expected vs actual behavior
   - Console logs (if applicable)

### Suggesting Features

We welcome feature suggestions! Please:

1. Check if the feature has already been requested
2. Open a new issue with the "Feature Request" template
3. Clearly describe the use case and expected behavior

### Pull Requests

#### Getting Started

1. **Fork the repository** and clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/GitNotify.git
   cd GitNotify
   ```

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Open the project in Xcode**:
   ```bash
   open GitNotify/GitNotify.xcodeproj
   ```

#### Development Guidelines

##### Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions focused and concise

##### Architecture

- Follow the existing MVVM pattern
- Use `@MainActor` for UI-related code
- Use actors for thread-safe state management
- Prefer async/await over callbacks
- Use Combine for reactive updates

##### Swift Conventions

```swift
// Good: Clear, descriptive naming
func fetchNotifications(since lastUpdate: Date?) async throws -> [GitHubNotification]

// Good: Use of async/await
func refreshData() async {
    do {
        let notifications = try await apiService.fetchNotifications()
        await updateUI(with: notifications)
    } catch {
        await handleError(error)
    }
}

// Good: Documentation for public API
/// Fetches the user's GitHub notifications.
/// - Parameter token: GitHub Personal Access Token
/// - Returns: Array of notifications
/// - Throws: `GitHubAPIError` if the request fails
func fetchNotifications(token: String) async throws -> [GitHubNotification]
```

##### Testing

- Test on both Apple Silicon and Intel Macs if possible
- Test with various macOS versions (13.0+)
- Verify dark mode and light mode appearance
- Test with different notification volumes

#### Commit Messages

Use clear, descriptive commit messages:

```
Add: notification filtering by repository
Fix: memory leak in polling service
Update: improve error handling in API service
Refactor: simplify database queries
Docs: update installation instructions
```

Prefixes:
- `Add:` - New features
- `Fix:` - Bug fixes
- `Update:` - Improvements to existing features
- `Refactor:` - Code restructuring without behavior changes
- `Docs:` - Documentation updates
- `Test:` - Test additions or modifications
- `Chore:` - Maintenance tasks

#### Submitting Your PR

1. **Ensure your code compiles** without warnings:
   ```bash
   xcodebuild -project GitNotify/GitNotify.xcodeproj \
              -scheme GitNotify \
              -configuration Debug \
              build
   ```

2. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**:
   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill in the PR template

4. **PR Description** should include:
   - What changes were made
   - Why the changes were needed
   - How to test the changes
   - Screenshots for UI changes

### Review Process

1. Maintainers will review your PR
2. Address any feedback or requested changes
3. Once approved, your PR will be merged

## Development Setup

### Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building

```bash
# Debug build
xcodebuild -project GitNotify/GitNotify.xcodeproj \
           -scheme GitNotify \
           -configuration Debug \
           build

# Release build
xcodebuild -project GitNotify/GitNotify.xcodeproj \
           -scheme GitNotify \
           -configuration Release \
           build
```

### Project Structure

```
GitNotify/
├── App/              # App entry point and delegate
├── Models/           # Data models (GRDB entities)
├── ViewModels/       # Business logic and state
├── Views/            # SwiftUI views
├── Services/         # API, database, keychain services
├── Utilities/        # Constants, extensions
└── Resources/        # Assets, entitlements, Info.plist
```

## Areas for Contribution

We especially welcome contributions in:

- **Bug fixes** - Help us squash bugs
- **Documentation** - Improve README, add code comments
- **Accessibility** - Improve VoiceOver support
- **Localization** - Add translations for other languages
- **Performance** - Optimize database queries, reduce memory usage
- **Testing** - Add unit tests and UI tests

## Questions?

If you have questions about contributing:

1. Check the [README](README.md) for documentation
2. Search existing [issues](https://github.com/yourusername/GitNotify/issues)
3. Open a new issue with the "Question" label

## License

By contributing to GitNotify, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to GitNotify!
