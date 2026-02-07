# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Security Features

GitNotify takes security seriously:

- **Token Storage**: GitHub tokens are stored in the macOS Keychain, not in plain text files
- **Network Security**: All API calls use HTTPS
- **App Sandbox**: The app runs in a macOS sandbox with limited permissions
- **Minimal Permissions**: Only requests the `notifications` scope from GitHub

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **DO NOT** open a public issue for security vulnerabilities
2. Email the maintainers directly (if contact info is available)
3. Or use GitHub's private vulnerability reporting feature

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- We will acknowledge receipt within 48 hours
- We aim to provide an initial assessment within 7 days
- We will work with you to understand and resolve the issue

## Security Best Practices for Users

1. **Token Scope**: Only grant the `notifications` scope to your GitHub token
2. **Token Rotation**: Periodically regenerate your GitHub token
3. **Token Expiration**: Use tokens with expiration dates when possible
4. **App Updates**: Keep GitNotify updated to receive security fixes

## Third-Party Dependencies

GitNotify uses the following third-party dependencies:

| Dependency | Purpose | Security Considerations |
|------------|---------|-------------------------|
| GRDB.swift | SQLite database | Well-maintained, no known vulnerabilities |

We regularly monitor dependencies for security updates.
