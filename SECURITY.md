# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of the Circular Protocol Dart SDK seriously. If you discover a security vulnerability, please follow these steps:

### 1. **Do Not** Publicly Disclose

Please do not open a public GitHub issue for security vulnerabilities. This protects users while we work on a fix.

### 2. Report Privately

Send your vulnerability report to:
- **Email**: security@circularlabs.io
- **Subject**: `[SECURITY] Circular Dart SDK Vulnerability`

### 3. Include Details

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)
- Your contact information

### 4. Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity (see below)

## Vulnerability Severity Levels

### Critical
- Remote code execution
- Authentication bypass
- Private key exposure
- **Fix Timeline**: 24-48 hours

### High
- Data leakage
- Privilege escalation
- Signature verification bypass
- **Fix Timeline**: 3-7 days

### Medium
- Information disclosure
- Denial of service
- **Fix Timeline**: 7-14 days

### Low
- Minor security improvements
- **Fix Timeline**: Next planned release

## Security Best Practices

### Private Key Management

**NEVER** expose private keys in your code:

```dart
// ❌ BAD - Hardcoded private key
final privateKey = '1234567890abcdef...';

// ✅ GOOD - Load from secure storage
final privateKey = await secureStorage.read(key: 'wallet_private_key');

// ✅ GOOD - Use environment variables (server-side only)
final privateKey = Platform.environment['WALLET_PRIVATE_KEY'];
```

### API Key Security

**NEVER** commit API keys to version control:

```dart
// ❌ BAD - Hardcoded API key
final api = CircularProtocolAPI(nagKey: 'my-api-key-12345');

// ✅ GOOD - Load from environment or secure storage
final nagKey = Platform.environment['CIRCULAR_NAG_KEY'] ?? '';
final api = CircularProtocolAPI(nagKey: nagKey);
```

### Secure Communication

Always use HTTPS endpoints:

```dart
// ❌ BAD - Insecure HTTP
final api = CircularProtocolAPI(
  nagUrl: 'http://nag.circularlabs.io/NAG.php?cep=',
);

// ✅ GOOD - Secure HTTPS
final api = CircularProtocolAPI(
  nagUrl: 'https://nag.circularlabs.io/NAG.php?cep=',
);
```

### Input Validation

Always validate user input before sending to the blockchain:

```dart
// ✅ GOOD - Validate addresses
bool isValidAddress(String address) {
  // Remove 0x prefix if present
  final clean = address.startsWith('0x') ? address.substring(2) : address;

  // Check if valid hex and correct length
  return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(clean);
}

// Use validation before API calls
if (!isValidAddress(userAddress)) {
  throw Exception('Invalid wallet address');
}

final result = await api.checkWallet({
  'Address': userAddress,
  'Blockchain': blockchain,
  'Version': '1.0.9',
});
```

### Transaction Signing

**NEVER** sign transactions without user verification:

```dart
// ❌ BAD - Auto-signing without confirmation
Future<void> sendFunds(String to, String amount) async {
  final tx = buildTransaction(to, amount);
  final signature = api.signMessage(tx, privateKey);  // No confirmation!
  await api.sendTransaction({...});
}

// ✅ GOOD - Require user confirmation
Future<void> sendFunds(String to, String amount) async {
  final tx = buildTransaction(to, amount);

  // Show transaction details to user
  final confirmed = await showTransactionDialog(tx);

  if (confirmed) {
    final signature = api.signMessage(tx, privateKey);
    await api.sendTransaction({...});
  }
}
```

### Dependency Security

Keep dependencies up to date:

```bash
# Check for outdated dependencies
dart pub outdated

# Update dependencies
dart pub upgrade

# Check for security vulnerabilities
dart pub audit  # (if available)
```

### Mobile Security (Flutter)

For Flutter applications:

```dart
// Use flutter_secure_storage for private keys
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Store private key securely
await storage.write(key: 'wallet_private_key', value: privateKey);

// Read private key
final privateKey = await storage.read(key: 'wallet_private_key');

// Delete private key
await storage.delete(key: 'wallet_private_key');
```

### Web Security (Dart Web)

For web applications:

- **NEVER** store private keys in localStorage or sessionStorage
- Use Web Crypto API for key generation when possible
- Consider hardware wallets for production use
- Implement proper CORS policies

## Known Security Considerations

### Cryptographic Implementation

This SDK uses PointyCastle for ECDSA secp256k1 cryptography:
- Pure Dart implementation (no native dependencies)
- Audited library with wide adoption
- Regular security updates via pub.dev

### Signature Format

- Uses DER encoding for signatures (standard format)
- SHA-256 for message hashing
- Normalized signatures to prevent malleability

### HTTP Client

- Uses Dart's http package
- Supports custom HTTP clients for advanced security needs
- Configurable timeouts to prevent hanging connections

## Security Updates

Security fixes are released as patch versions (e.g., 1.0.1, 1.0.2) and announced via:

- GitHub Security Advisories
- Release notes
- CHANGELOG.md
- Email to registered users (if severe)

## Responsible Disclosure

We appreciate responsible disclosure and will:
- Acknowledge your contribution
- Work with you to understand and resolve the issue
- Credit you in release notes (unless you prefer to remain anonymous)
- Potentially offer a bounty for significant findings (at our discretion)

## Additional Resources

- [Circular Protocol Security Best Practices](https://docs.circular.org/security)
- [Dart Security Guidelines](https://dart.dev/guides/security)
- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)

## Contact

For security concerns:
- **Email**: security@circularlabs.io
- **GPG Key**: Available upon request

For general questions:
- Open an issue on GitHub
- Community Discord (for non-sensitive questions)

---

**Thank you for helping keep Circular Protocol and our users safe!** 🔒
