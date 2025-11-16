# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.9] - 2025-11-15

### 🔧 Fixed

#### Critical Endpoint Corrections
- **`getDomain`**: Fixed incorrect endpoint from `'GetDomain'` to `'ResolveDomain'`
  - Now matches circular-js-npm canonical implementation
- **`getBlockCount`**: Fixed incorrect endpoint from `'GetBlockCount'` to `'GetBlockHeight'`
  - Now matches circular-js-npm canonical implementation

These were critical bugs that would have caused API calls to fail against the actual NAG API.

### ✨ Added

#### New Methods
- **`verifySignature`**: Verify ECDSA secp256k1 signatures against public keys
  - Full DER signature format support
  - Returns `bool` for easy validation
  - Complements existing `signMessage` method

#### Public Helper Methods
- **`hexFix`**: Made public for external use (strip `0x` prefix from hex strings)
- **`padNumber`**: Made public for external use (zero-pad single-digit numbers)

These helpers were previously internal but are now exposed for developer convenience.

### 📝 Documentation

#### Comprehensive DartDoc Comments (800+ lines of documentation)
All public methods now have professional-grade DartDoc comments including:
- Detailed descriptions of functionality
- Complete parameter documentation with types and constraints
- Return value specifications
- Practical code examples for every method
- Cross-references to related methods
- Technical implementation details where relevant
- Security warnings for sensitive operations
- Error/exception documentation

**Coverage:**
- ✅ All 24 API endpoint methods
- ✅ All 6 cryptographic helpers
- ✅ All 4 encoding helpers
- ✅ All 3 advanced helpers
- ✅ Convenience methods and configuration

**Benefits:**
- IDE autocomplete shows full documentation
- `dart doc` generates comprehensive API reference
- pub.dev will display complete documentation
- New developers can learn from inline examples
- Reduced need for external documentation

#### New Documentation Files
- **AGENTS.md** - Comprehensive architecture guide (450+ lines)
  - Design philosophy and principles
  - Class structure and organization
  - Request flow and method patterns
  - Error handling strategy
  - Type system design
  - Testing strategy
  - Cryptographic implementation details
  - Best practices for contributors

- **CONTRIBUTING.md** - Development and contribution guidelines
  - Development setup instructions
  - Code style requirements (Dart conventions)
  - Testing requirements and guidelines
  - Documentation standards
  - Pull request process
  - Release procedures

- **SECURITY.md** - Security policy and best practices
  - Vulnerability reporting process
  - Severity levels and response timelines
  - Private key management guidelines
  - API key security
  - Input validation examples
  - Mobile and web security considerations

- **CODE_OF_CONDUCT.md** - Community guidelines (Contributor Covenant v2.1)
  - Community standards and expectations
  - Enforcement guidelines
  - Reporting procedures

#### Repository Cleanup
- **Removed outdated `docs/` directory**: The Jekyll/GitBook documentation was outdated and not aligned with the current implementation. The SDK now relies on:
  - README.md for primary documentation
  - DartDoc (`///`) comments for API documentation
  - pub.dev auto-generated documentation
  - AGENTS.md for architecture details
  - CONTRIBUTING.md for development guidelines

This aligns with the documentation strategy of circular-js-npm and circular-py.

#### Method Naming Conventions
- Standardized all method names to Dart lowerCamelCase convention
- **`getTransactionbyID`** → **`getTransactionById`**
- **`getTransactionbyNode`** → **`getTransactionByNode`**
- **`getTransactionbyAddress`** → **`getTransactionByAddress`**
- **`getTransactionbyDate`** → **`getTransactionByDate`**
- **`GetError`** → **`getError`** (for consistency)

#### README Updates
- Corrected method count: 40 → 39 methods
- Updated all method names to match Dart naming conventions
- Added `getKeysFromString` to documented cryptographic helpers (6 total)
- Enhanced API reference with proper method categories

### 🧪 Testing

#### Test Suite Updates
- Updated all E2E tests to use new method names
- Updated all integration tests to use new method names
- All tests passing with corrected endpoints

### 📊 Method Breakdown (v1.0.9)

- **24** API Endpoint Methods (includes `sendTransaction` as alias for `addTransaction`)
  - 5 Wallet Operations
  - 7 Transaction Operations (sendTransaction, addTransaction, getPendingTransaction, getTransactionById, getTransactionByNode, getTransactionByAddress, getTransactionByDate)
  - 4 Block Operations
  - 2 Contract Operations
  - 4 Asset Operations
  - 1 Domain Operation
  - 1 Network Operation
- **6** Cryptographic Helpers (`signMessage`, `verifySignature`, `getPublicKey`, `hashString`, `getFormattedTimestamp`, `getKeysFromString`)
- **4** Encoding Helpers (`hexFix`, `stringToHex`, `hexToString`, `padNumber`)
- **3** Advanced Helpers (`getError`, `handleError`, `getTransactionOutcome`)
- **2** Configuration Methods (getNagUrl/setNagUrl, getNagKey/setNagKey, setHeader)

**Total: 39 methods** (matching circular-js-npm and circular-py)

### 🎯 Alignment with Other SDKs

This release brings the Dart SDK to full parity with:
- `circular-js-npm` v1.0.9 (TypeScript/JavaScript)
- `circular-py` v1.0.12 (Python)

All naming conventions and method signatures now match across all official SDKs.

### ⚠️ Breaking Changes

**None**. All changes are backward compatible:
- New method names added (old names remain functional)
- New methods are additive

### 📦 Migration Guide

#### From v1.0.8 to v1.0.9

**Recommended**: Update method names to use proper Dart conventions:

```dart
// Before (still works, but deprecated)
await api.getTransactionbyID(request);
await api.getTransactionbyNode(request);

// After (recommended)
await api.getTransactionById(request);
await api.getTransactionByNode(request);
```

**New features** you can now use:

```dart
// Verify signatures
final isValid = api.verifySignature(message, signature, publicKey);

// Public helper methods
final normalized = api.hexFix('0x1234');  // '1234'
final padded = api.padNumber(5);  // '05'
```

## [1.0.8] - 2025-11-13

### Added
- Initial Dart SDK release for Circular Protocol blockchain
- Complete API client with 24 blockchain operations:
  - **Wallet Operations**: checkWallet, getWallet, getWalletBalance, getWalletNonce, getLatestTransactions
  - **Transaction Operations**: sendTransaction, addTransaction, getPendingTransaction, getTransactionById, getTransactionByNode, getTransactionByAddress, getTransactionByDate
  - **Block Operations**: getBlock, getBlockRange, getBlockCount
  - **Asset Operations**: getAssetList, getAsset, getAssetSupply, getVoucher
  - **Smart Contract Operations**: testContract, callContract
  - **Network Operations**: getBlockchains, getAnalytics
  - **Domain Operations**: getDomain (resolve domains to wallet addresses)
- Async/await support with Future-based API
- Comprehensive error handling with CircularAPIException
- HTTP timeout support (configurable, 30s default)
- Custom header support for authentication and API keys
- Configurable NAG endpoint URL
- Cross-platform support (Android, iOS, Linux, macOS, Web, Windows)
- Full test suite:
  - 11 unit tests with mocked HTTP client
  - 26 integration tests with local mock server
  - 24 E2E tests (optional, ENV-gated)
- Complete documentation with usage examples
- GitHub Actions CI/CD workflow with multi-version testing
- Static analysis configuration (analysis_options.yaml)
- Dart 2.19+ and Dart 3.x support

### Developer Experience
- Idiomatic Dart code with proper type hints
- Null-safety support
- Package follows pub.dev best practices
- Comprehensive API documentation
- Clean exception hierarchy
- Resource cleanup with dispose() method

### Package Metadata
- Published to pub.dev as `circular_protocol`
- MIT License
- Full platform compatibility
- Proper dependency management

[1.0.9]: https://github.com/circular-protocol/circular-dart/releases/tag/v1.0.9
[1.0.8]: https://github.com/circular-protocol/circular-dart/releases/tag/v1.0.8