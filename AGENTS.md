# Circular Protocol Dart SDK - Architecture Guide

This document describes the internal architecture, design patterns, and implementation details of the Circular Protocol Dart SDK. It's intended for contributors, maintainers, and AI agents working with the codebase.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Architecture Overview](#architecture-overview)
3. [Class Structure](#class-structure)
4. [Request Flow](#request-flow)
5. [Method Patterns](#method-patterns)
6. [Error Handling Strategy](#error-handling-strategy)
7. [Type System](#type-system)
8. [Testing Strategy](#testing-strategy)
9. [Cryptographic Implementation](#cryptographic-implementation)
10. [Package Structure](#package-structure)
11. [Extensibility](#extensibility)

---

## Design Philosophy

### Core Principles

1. **Idiomatic Dart**: Follow Dart/Flutter conventions and best practices
2. **Type Safety**: Leverage Dart's strong type system with null-safety
3. **Async/Await**: Use Future-based APIs for all asynchronous operations
4. **Cross-Platform**: Support all Dart platforms (mobile, web, desktop, server)
5. **Developer Experience**: Simple API surface with comprehensive error handling

### Design Decisions

- **Class-based API** for state management (NAG URL, API keys, HTTP client, error tracking)
- **Request object pattern** for all API methods (idiomatic for Dart, better than positional params)
- **Future-based async** for all I/O operations
- **Single library file** for simplicity (681 lines total, well-organized sections)
- **Pure Dart crypto** using PointyCastle (no native dependencies)
- **Explicit version in requests** for API compatibility tracking

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   CircularProtocolAPI                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │          24 API Methods (Request Objects)               │ │
│  │  checkWallet, getWallet, sendTransaction, etc.         │ │
│  └────────────────┬───────────────────────────────────────┘ │
│                   │                                           │
│  ┌────────────────▼───────────────────────────────────────┐ │
│  │              _makeRequest (HTTP Layer)                  │ │
│  │  Handles POST, headers, timeout, error handling        │ │
│  └────────────────┬───────────────────────────────────────┘ │
│                   │                                           │
│  ┌────────────────▼───────────────────────────────────────┐ │
│  │         Helper Methods (15 methods)                     │ │
│  │  Crypto: signMessage, verifySignature, hashString      │ │
│  │  Encoding: hexFix, stringToHex, hexToString            │ │
│  │  Advanced: getTransactionOutcome, getError             │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────┼───────────────────────────────────────────┘
                    │
            ┌───────▼──────┐
            │  NAG API     │
            │  (REST/JSON) │
            └──────────────┘
```

---

## Class Structure

### CircularProtocolAPI Class

```dart
class CircularProtocolAPI {
  // Configuration
  String nagUrl;
  String nagKey;
  final http.Client _httpClient;
  final Map<String, String> _headers;
  final Duration timeout;

  // State
  String _lastError = '';

  // Constructor with optional parameters
  CircularProtocolAPI({
    String? nagUrl,
    this.nagKey = '',
    http.Client? httpClient,
    Map<String, String>? headers,
    this.timeout = const Duration(seconds: 30),
  });

  // Core HTTP method
  Future<Map<String, dynamic>> _makeRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async { ... }

  // 24 API methods
  // 15 helper methods
  // 1 convenience method (registerWallet)
}
```

### Organization

The library is organized into clear sections:

1. **Class Definition** (lines 32-81)
   - Properties, constructor, configuration methods

2. **HTTP Layer** (lines 82-153)
   - `_makeRequest`: JSON POST with error handling

3. **API Methods** (lines 155-302)
   - 24 blockchain API endpoints

4. **Convenience Methods** (lines 303-358)
   - `registerWallet`: Simplified wallet registration

5. **Cryptographic Helpers** (lines 360-532)
   - ECDSA secp256k1 implementation
   - SHA-256 hashing
   - Key generation and signing

6. **Encoding Helpers** (lines 570-612)
   - Hex conversion utilities
   - Timestamp formatting

7. **Advanced Helpers** (lines 614-647)
   - Error tracking
   - Transaction polling

---

## Request Flow

### Typical API Call Flow

```
User calls API method
    ↓
Method receives Map<String, dynamic> request
    ↓
Request passed to _makeRequest(endpoint, data)
    ↓
Build endpoint URL: nagUrl + 'Circular_' + endpoint + '_'
    ↓
Build headers (Content-Type, custom headers, NAG key if present)
    ↓
HTTP POST with JSON body (with timeout)
    ↓
Check HTTP status code (throw on != 200)
    ↓
Parse JSON response
    ↓
Check Result code (throw on != 200)
    ↓
Return full response Map<String, dynamic>
```

### Example: checkWallet Flow

```dart
// User calls
final result = await api.checkWallet({
  'Address': '0xd55872...',
  'Blockchain': 'MainNet',
  'Version': '1.0.9',
});

// Method implementation
Future<Map<String, dynamic>> checkWallet(Map<String, dynamic> request) async {
  return _makeRequest('CheckWallet', request);
}

// _makeRequest builds URL
// POST to: https://nag.circularlabs.io/NAG.php?cep=Circular_CheckWallet_

// Response structure
{
  Result: 200,
  Response: { ... }  // Wallet data
}
```

---

## Method Patterns

### API Method Pattern

All 24 API methods follow this consistent pattern:

```dart
/// [Method description]
/// [What it does]
/// [What it returns]
Future<Map<String, dynamic>> methodName(Map<String, dynamic> request) async {
  return _makeRequest('EndpointName', request);
}
```

**Key characteristics:**
- Accept `Map<String, dynamic>` for flexibility (matches JSON structure)
- Return `Future<Map<String, dynamic>>` (async)
- Single line implementation delegates to `_makeRequest`
- Endpoint name is PascalCase (e.g., 'CheckWallet', 'GetBlock')

### Endpoint Mapping

| Method Name | Endpoint | Notes |
|-------------|----------|-------|
| checkWallet | Circular_CheckWallet_ | |
| getWallet | Circular_GetWallet_ | |
| sendTransaction | Circular_AddTransaction_ | Alias for addTransaction |
| addTransaction | Circular_AddTransaction_ | Primary transaction method |
| getTransactionById | Circular_GetTransactionbyID_ | Note: 'by' is lowercase in endpoint |
| getDomain | Circular_GetDomain_ | Domain resolution |
| getBlockCount | Circular_GetBlockCount_ | Blockchain height |
| getVoucher | Circular_GetVoucher_ | |

---

## Error Handling Strategy

### Exception Hierarchy

```dart
class CircularAPIException implements Exception {
  final String message;
  final int statusCode;
  final String endpoint;

  CircularAPIException(
    this.message, {
    required this.statusCode,
    required this.endpoint,
  });
}
```

### Error Categories

1. **HTTP Errors** (thrown by `_makeRequest`)
   - Non-200 status codes
   - Network errors
   - Timeouts
   - JSON parsing errors

2. **API Errors** (thrown by `_makeRequest`)
   - `Result` != 200 in response
   - Contains error message from `Response` field

3. **Internal Errors** (tracked by `_lastError`)
   - Used by helper methods
   - Retrieved via `getError()`

### Error Flow

```dart
try {
  final result = await api.checkWallet(request);
  // Success: Result == 200
} on CircularAPIException catch (e) {
  print('Error: ${e.message}');
  print('Endpoint: ${e.endpoint}');
  print('Code: ${e.statusCode}');
} on TimeoutException catch (e) {
  print('Request timeout');
} catch (e) {
  print('Unexpected error: $e');
}
```

---

## Type System

### Response Types

All API methods return `Future<Map<String, dynamic>>` with this structure:

```dart
{
  'Result': int,        // 200 for success, other codes for errors
  'Response': dynamic,  // Can be Map, List, String, etc.
}
```

### Request Types

All API methods accept `Map<String, dynamic>` with common fields:

```dart
{
  'Blockchain': String,  // Often required
  'Version': String,     // Usually '1.0.9'
  // Method-specific fields...
}
```

### Null Safety

The SDK is fully null-safe:
- All public APIs have explicit nullability
- No implicit nulls in return values
- Optional parameters use `?` and have defaults

---

## Testing Strategy

### Test Structure

```
test/
├── unit_test.dart         # Unit tests (mocked)
├── integration_test.dart  # Integration tests (mocked HTTP)
└── e2e_test.dart         # E2E tests (real API, ENV-gated)
```

### Test Layers

1. **Unit Tests** (11 tests)
   - Test individual helper methods
   - Mock HTTP client
   - Fast, no network required

2. **Integration Tests** (26 tests)
   - Test API methods with mock server
   - Verify request/response structure
   - All methods covered

3. **E2E Tests** (21 tests)
   - Optional (requires ENV vars)
   - Tests against real NAG API
   - Validates actual blockchain interaction

### Running Tests

```bash
# All tests
dart test

# Specific layer
dart test test/unit_test.dart
dart test test/integration_test.dart

# E2E (requires ENV)
export CIRCULAR_TEST_ADDRESS="0x..."
export CIRCULAR_TEST_BLOCKCHAIN="MainNet"
dart test test/e2e_test.dart
```

---

## Cryptographic Implementation

### ECDSA secp256k1

Uses PointyCastle library for pure Dart cryptography:

```dart
// Key generation
ECPrivateKey privateKey = ECPrivateKey(d, ECDomainParameters('secp256k1'));
ECPublicKey publicKey = ECPublicKey(G * d, params);

// Signing (DER format)
ECDSASigner signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
NormalizedECDSASigner normalized = NormalizedECDSASigner(signer);
ECSignature signature = normalized.generateSignature(msgHash);

// DER encoding
ASN1Sequence seq = ASN1Sequence();
seq.add(ASN1Integer(signature.r));
seq.add(ASN1Integer(signature.s));
Uint8List derBytes = seq.encodedBytes;
```

### Signature Verification

```dart
bool verifySignature(String message, String signature, String publicKey) {
  // 1. Hash message with SHA-256
  // 2. Parse DER signature to r,s components
  // 3. Decode public key (uncompressed format without 0x04 prefix)
  // 4. Verify using ECDSASigner
  return signer.verifySignature(msgHash, ecSignature);
}
```

### Public Key Format

- **128 hex characters** (64 bytes)
- **Uncompressed** format
- **No 0x04 prefix** (stripped)
- Derived from 32-byte private key

---

## Package Structure

### pubspec.yaml

```yaml
name: circular_protocol
version: 1.0.9
sdk: '>=2.19.0 <4.0.0'

dependencies:
  http: ^1.1.0           # HTTP client
  crypto: ^3.0.3         # SHA-256
  pointycastle: ^3.9.1   # ECDSA secp256k1
  asn1lib: ^1.5.3        # DER encoding
  intl: ^0.19.0          # Date formatting
  convert: ^3.1.1        # Hex encoding
```

### Platform Support

- ✅ Android
- ✅ iOS
- ✅ Linux
- ✅ macOS
- ✅ Web
- ✅ Windows

---

## Extensibility

### Adding New API Methods

1. Add method to API Methods section:

```dart
/// [Description]
Future<Map<String, dynamic>> newMethod(Map<String, dynamic> request) async {
  return _makeRequest('NewEndpoint', request);
}
```

2. Update README.md documentation
3. Add tests to integration_test.dart
4. Update CHANGELOG.md

### Adding Helper Methods

1. Add to appropriate helper section
2. Use proper DartDoc comments (`///`)
3. Make public or private based on usage
4. Add unit tests

### Configuration Extensions

The class supports:
- Custom HTTP client injection
- Custom headers
- Configurable timeout
- Multiple instances with different configs

```dart
final customApi = CircularProtocolAPI(
  nagUrl: 'https://custom.endpoint/',
  nagKey: 'custom-key',
  httpClient: CustomHttpClient(),
  headers: {'Custom-Header': 'value'},
  timeout: Duration(seconds: 60),
);
```

---

## Best Practices for Contributors

### Code Style

1. **Follow Dart conventions**
   - lowerCamelCase for methods, variables
   - UpperCamelCase for classes, types
   - Use `dartfmt` for formatting

2. **DartDoc comments**
   - Use `///` for public APIs
   - Include examples where helpful
   - Document parameters and return values

3. **Type annotations**
   - Explicit types for public APIs
   - Use `dynamic` sparingly
   - Leverage type inference for locals

### Testing

1. **Write tests first** (TDD when possible)
2. **Cover all code paths**
3. **Use meaningful test names**
4. **Mock external dependencies**

### Documentation

1. **Update README.md** for public API changes
2. **Update CHANGELOG.md** for all changes
3. **Update this file** for architectural changes
4. **Keep examples current**

---

## Version History Alignment

### v1.0.9 Alignment

This version brings the Dart SDK to parity with:
- circular-js-npm v1.0.9
- circular-py v1.0.12

**Key features:**
- 39 total methods
- Dart naming conventions (lowerCamelCase)
- verifySignature method added
- Public helper methods (hexFix, padNumber)
- Comprehensive documentation
- Full test coverage

---

**Last Updated**: 2025-11-15
**SDK Version**: 1.0.9
**Maintainer**: Circular Protocol Team
