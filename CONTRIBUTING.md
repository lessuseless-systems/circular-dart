# Contributing to Circular Protocol Dart SDK

Thank you for your interest in contributing to the Circular Protocol Dart SDK! We welcome contributions from the community and are grateful for your support.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

- Dart SDK 2.19.0 or higher
- Git for version control
- A GitHub account

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:

```bash
git clone git@github.com:YOUR-USERNAME/circular-dart.git
cd circular-dart
```

3. Add the upstream repository:

```bash
git remote add upstream git@github.com:circular-protocol/circular-dart.git
```

## Development Setup

### Install Dependencies

```bash
# Get all dependencies
dart pub get

# Or for Flutter projects
flutter pub get
```

### Verify Setup

```bash
# Run tests
dart test

# Run analyzer
dart analyze

# Format code
dart format .
```

## Code Style

We follow Dart's official style guide and best practices.

### Dart Conventions

- **Use lowerCamelCase** for variables, functions, and methods
- **Use UpperCamelCase** for classes, enums, typedefs, and type parameters
- **Use snake_case** for file names (e.g., `circular_protocol.dart`)
- **Use SCREAMING_CAPS** for constants
- Maximum line length: 80 characters (soft limit, 100 hard limit)

### Naming Examples

```dart
// Good
class CircularProtocolAPI { }
Future<Map<String, dynamic>> checkWallet(Map<String, dynamic> request) async { }
final String nagUrl = 'https://...';
const int MAX_RETRIES = 3;

// Bad
class circular_protocol_api { }  // Wrong case
Future<Map<String, dynamic>> CheckWallet() { }  // Wrong case
```

### Type Safety

- **All public APIs must have explicit type annotations**
- Leverage Dart's null-safety features
- Avoid using `dynamic` unless absolutely necessary
- Use type inference for local variables where type is obvious

```dart
// Good
Future<Map<String, dynamic>> getWallet(Map<String, dynamic> request) async {
  final response = await _makeRequest('GetWallet', request);
  return response;
}

// Bad
getWallet(request) async {  // Missing types
  var response = await _makeRequest('GetWallet', request);  // Unnecessary var
  return response;
}
```

### Documentation

- **All public APIs must have DartDoc comments** (`///`)
- Include description, parameters, returns, and examples
- Use markdown formatting in documentation

```dart
/// Check if wallet exists on blockchain
///
/// Verifies whether a wallet address exists on the specified blockchain.
/// Returns existence status and confirms the address format.
///
/// Example:
/// ```dart
/// final result = await api.checkWallet({
///   'Address': '0xd55872...',
///   'Blockchain': 'MainNet',
///   'Version': '1.0.9',
/// });
/// ```
///
/// Returns a [Map] containing the API response with Result and Response fields.
/// Throws [CircularAPIException] if the API request fails.
Future<Map<String, dynamic>> checkWallet(Map<String, dynamic> request) async {
  return _makeRequest('CheckWallet', request);
}
```

### Code Formatting

We use `dart format` for consistent code formatting:

```bash
# Format all Dart files
dart format .

# Check formatting without modifying
dart format --output=none --set-exit-if-changed .

# Format specific file
dart format lib/circular_protocol.dart
```

### Code Analysis

All code must pass Dart's static analysis:

```bash
# Run analyzer
dart analyze

# Fix auto-fixable issues
dart fix --apply
```

## Testing

### Test Structure

We maintain a 3-tier test suite:

1. **Unit Tests** (`test/unit_test.dart`) - Fast, isolated tests
2. **Integration Tests** (`test/integration_test.dart`) - Tests with mocked HTTP
3. **E2E Tests** (`test/e2e_test.dart`) - Optional, against real API

### Writing Tests

```dart
import 'package:test/test.dart';
import '../lib/circular_protocol.dart';

void main() {
  group('CircularProtocolAPI', () {
    late CircularProtocolAPI api;

    setUp(() {
      api = CircularProtocolAPI(nagUrl: 'https://test.api/');
    });

    test('should check wallet existence', () async {
      final result = await api.checkWallet({
        'Address': '0x123...',
        'Blockchain': 'MainNet',
        'Version': '1.0.9',
      });

      expect(result['Result'], equals(200));
      expect(result['Response'], isNotNull);
    });
  });
}
```

### Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/unit_test.dart

# Run with coverage
dart test --coverage=coverage
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib

# Run E2E tests (requires environment variables)
export CIRCULAR_TEST_ADDRESS="0x..."
export CIRCULAR_TEST_BLOCKCHAIN="MainNet"
dart test test/e2e_test.dart
```

### Test Requirements

- **All new features must include tests**
- **All bug fixes must include regression tests**
- **Maintain or improve code coverage**
- **Tests must be deterministic** (no random failures)

## Documentation

### DartDoc Generation

Generate API documentation:

```bash
# Generate documentation
dart doc

# Output will be in doc/api/
```

### Documentation Requirements

- Update README.md for user-facing changes
- Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/) format
- Update AGENTS.md for architectural changes
- Add examples for new features

## Submitting Changes

### Branch Naming

Use descriptive branch names:

- `feature/add-new-method` - New features
- `fix/transaction-timeout` - Bug fixes
- `docs/update-readme` - Documentation
- `refactor/cleanup-helpers` - Code refactoring

### Commit Messages

Follow conventional commits format:

```
type(scope): brief description

Detailed explanation of changes (if needed)

Fixes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(api): add verifySignature method

Implements ECDSA signature verification using PointyCastle.
Supports DER-encoded signatures with secp256k1.

Fixes #42
```

```
fix(endpoints): correct getDomain endpoint name

Changed from 'ResolveDomain' to 'GetDomain' to match
the canonical API specification.
```

### Pull Request Process

1. **Create a branch** from `development` (not `main`)

```bash
git checkout development
git pull upstream development
git checkout -b feature/my-new-feature
```

2. **Make your changes** following the style guide

3. **Add tests** for your changes

4. **Update documentation** (README, CHANGELOG, etc.)

5. **Ensure all checks pass**:

```bash
dart format .
dart analyze
dart test
```

6. **Commit your changes** with clear messages

7. **Push to your fork**:

```bash
git push origin feature/my-new-feature
```

8. **Create a Pull Request** on GitHub:
   - Target the `development` branch
   - Fill out the PR template
   - Reference any related issues
   - Request review from maintainers

9. **Address review feedback**

10. **Wait for approval** and merge

### PR Requirements

- [ ] Code follows Dart style guide
- [ ] All tests pass
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No breaking changes (or clearly documented)
- [ ] Commits are signed (optional but recommended)

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking API changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

### Release Checklist

1. Update version in `pubspec.yaml`
2. Update CHANGELOG.md with release notes
3. Update version in library documentation comments
4. Run full test suite
5. Create git tag: `git tag v1.0.9`
6. Push tag: `git push upstream v1.0.9`
7. Publish to pub.dev: `dart pub publish`
8. Create GitHub release with changelog

## Architecture

For detailed architecture information, see [AGENTS.md](AGENTS.md).

## Questions?

- Open an issue on GitHub
- Check existing issues and discussions
- Review the [AGENTS.md](AGENTS.md) architecture guide

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to the Circular Protocol Dart SDK! 🚀
