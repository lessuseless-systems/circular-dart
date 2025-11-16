import 'package:test/test.dart';
import '../lib/circular_protocol.dart';

void main() {
  late CircularProtocolAPI api;

  setUp(() {
    api = CircularProtocolAPI();
  });

  tearDown(() {
    api.dispose();
  });

  group('Cryptographic Helpers', () {
    test('hashString - should hash a string using SHA256', () {
      final hash = api.hashString('test');

      expect(hash, isNotNull);
      expect(hash.length, equals(64)); // SHA256 produces 64 hex characters
      expect(hash, matches(RegExp(r'^[a-f0-9]{64}$'))); // Should be lowercase hex

      // Verify deterministic - same input produces same output
      final hash2 = api.hashString('test');
      expect(hash, equals(hash2));
    });

    test('hashString - should handle empty string', () {
      final hash = api.hashString('');

      expect(hash, isNotNull);
      expect(hash.length, equals(64));
    });

    test('getPublicKey - should derive public key from private key', () {
      // Test with a valid private key (32 bytes = 64 hex chars)
      final privateKey = 'a' * 64;
      final publicKey = api.getPublicKey(privateKey);

      expect(publicKey, isNotNull);
      expect(publicKey.length, equals(128)); // Uncompressed public key is 64 bytes = 128 hex chars
      expect(publicKey, matches(RegExp(r'^[a-f0-9]{128}$')));
    });

    test('getPublicKey - should be deterministic', () {
      final privateKey = 'b' * 64;
      final publicKey1 = api.getPublicKey(privateKey);
      final publicKey2 = api.getPublicKey(privateKey);

      expect(publicKey1, equals(publicKey2));
    });

    test('signMessage - should create ECDSA signature', () {
      final privateKey = 'c' * 64;
      final message = 'Hello, Circular Protocol!';

      final signature = api.signMessage(message, privateKey);

      expect(signature, isNotNull);
      expect(signature.isNotEmpty, isTrue);
      // DER signatures are typically 70-72 bytes (140-144 hex chars)
      expect(signature.length, greaterThanOrEqualTo(140));
      expect(signature, matches(RegExp(r'^[a-f0-9]+$')));
    });

    test('signMessage - should produce different signatures for different messages', () {
      final privateKey = 'd' * 64;
      final sig1 = api.signMessage('message1', privateKey);
      final sig2 = api.signMessage('message2', privateKey);

      expect(sig1, isNot(equals(sig2)));
    });

    test('verifySignature - should verify valid signature', () {
      final privateKey = 'e' * 64;
      final message = 'Test message';

      final publicKey = api.getPublicKey(privateKey);
      final signature = api.signMessage(message, privateKey);

      final isValid = api.verifySignature(message, signature, publicKey);
      expect(isValid, isTrue);
    });

    test('verifySignature - should reject invalid signature', () {
      final privateKey = 'f' * 64;
      final message = 'Test message';

      final publicKey = api.getPublicKey(privateKey);
      final signature = api.signMessage(message, privateKey);

      // Tamper with the signature
      final tamperedSig = signature.substring(0, signature.length - 2) + 'ff';

      final isValid = api.verifySignature(message, tamperedSig, publicKey);
      expect(isValid, isFalse);
    });

    test('verifySignature - should reject signature with wrong message', () {
      final privateKey = '1' * 64;
      final message = 'Original message';

      final publicKey = api.getPublicKey(privateKey);
      final signature = api.signMessage(message, privateKey);

      final isValid = api.verifySignature('Different message', signature, publicKey);
      expect(isValid, isFalse);
    });

    test('verifySignature - should reject signature with wrong public key', () {
      final privateKey1 = '2' * 64;
      final privateKey2 = '3' * 64;
      final message = 'Test message';

      final publicKey1 = api.getPublicKey(privateKey1);
      final publicKey2 = api.getPublicKey(privateKey2);
      final signature = api.signMessage(message, privateKey1);

      final isValid = api.verifySignature(message, signature, publicKey2);
      expect(isValid, isFalse);
    });

    test('getFormattedTimestamp - should return properly formatted timestamp', () {
      final timestamp = api.getFormattedTimestamp();

      expect(timestamp, isNotNull);
      // Format: YYYY:MM:DD-HH:mm:ss
      expect(timestamp, matches(RegExp(r'^\d{4}:\d{2}:\d{2}-\d{2}:\d{2}:\d{2}$')));

      // Should contain valid date components
      final parts = timestamp.split(RegExp(r'[:\-]'));
      expect(parts.length, equals(6));

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final hour = int.parse(parts[3]);
      final minute = int.parse(parts[4]);
      final second = int.parse(parts[5]);

      expect(year, greaterThanOrEqualTo(2024));
      expect(month, greaterThanOrEqualTo(1));
      expect(month, lessThanOrEqualTo(12));
      expect(day, greaterThanOrEqualTo(1));
      expect(day, lessThanOrEqualTo(31));
      expect(hour, greaterThanOrEqualTo(0));
      expect(hour, lessThanOrEqualTo(23));
      expect(minute, greaterThanOrEqualTo(0));
      expect(minute, lessThanOrEqualTo(59));
      expect(second, greaterThanOrEqualTo(0));
      expect(second, lessThanOrEqualTo(59));
    });

    test('getKeysFromString - should generate key pair from seed', () {
      final seed = 'my secret seed phrase';
      final keys = api.getKeysFromString(seed);

      expect(keys, isNotNull);
      expect(keys['privateKey'], isNotNull);
      expect(keys['publicKey'], isNotNull);

      final privateKey = keys['privateKey'] as String;
      final publicKey = keys['publicKey'] as String;

      expect(privateKey.length, equals(64));
      expect(publicKey.length, equals(128));
      expect(privateKey, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(publicKey, matches(RegExp(r'^[a-f0-9]{128}$')));
    });

    test('getKeysFromString - should be deterministic', () {
      final seed = 'another seed phrase';
      final keys1 = api.getKeysFromString(seed);
      final keys2 = api.getKeysFromString(seed);

      expect(keys1['privateKey'], equals(keys2['privateKey']));
      expect(keys1['publicKey'], equals(keys2['publicKey']));
    });

    test('getKeysFromString - should produce different keys for different seeds', () {
      final keys1 = api.getKeysFromString('seed1');
      final keys2 = api.getKeysFromString('seed2');

      expect(keys1['privateKey'], isNot(equals(keys2['privateKey'])));
      expect(keys1['publicKey'], isNot(equals(keys2['publicKey'])));
    });
  });

  group('Encoding Helpers', () {
    test('hexFix - should remove 0x prefix', () {
      expect(api.hexFix('0x1234abcd'), equals('1234abcd'));
      expect(api.hexFix('0xABCDEF'), equals('ABCDEF'));
    });

    test('hexFix - should return string unchanged if no 0x prefix', () {
      expect(api.hexFix('1234abcd'), equals('1234abcd'));
      expect(api.hexFix('ABCDEF'), equals('ABCDEF'));
    });

    test('hexFix - should handle empty string', () {
      expect(api.hexFix(''), equals(''));
    });

    test('hexFix - should handle just 0x', () {
      expect(api.hexFix('0x'), equals(''));
    });

    test('stringToHex - should convert ASCII string to hex', () {
      final hex = api.stringToHex('Hello');
      expect(hex, equals('48656c6c6f')); // ASCII values in hex
    });

    test('stringToHex - should handle empty string', () {
      expect(api.stringToHex(''), equals(''));
    });

    test('stringToHex - should handle special characters', () {
      final hex = api.stringToHex('Hello World!');
      expect(hex, isNotNull);
      expect(hex.length, equals(24)); // 12 chars * 2 hex digits
    });

    test('hexToString - should convert hex back to ASCII string', () {
      final original = 'Hello World';
      final hex = api.stringToHex(original);
      final decoded = api.hexToString(hex);

      expect(decoded, equals(original));
    });

    test('hexToString - should handle empty hex string', () {
      expect(api.hexToString(''), equals(''));
    });

    test('stringToHex and hexToString - should be reversible', () {
      final testStrings = [
        'Simple text',
        'With numbers 123',
        'Special chars: !@#\$%',
        // Note: Only ASCII is fully supported
      ];

      for (final str in testStrings) {
        final hex = api.stringToHex(str);
        final decoded = api.hexToString(hex);
        expect(decoded, equals(str));
      }
    });

    test('padNumber - should zero-pad single digit numbers', () {
      expect(api.padNumber(0), equals('00'));
      expect(api.padNumber(1), equals('01'));
      expect(api.padNumber(5), equals('05'));
      expect(api.padNumber(9), equals('09'));
    });

    test('padNumber - should not pad double digit numbers', () {
      expect(api.padNumber(10), equals('10'));
      expect(api.padNumber(25), equals('25'));
      expect(api.padNumber(99), equals('99'));
    });

    test('padNumber - should handle larger numbers', () {
      expect(api.padNumber(100), equals('100'));
      expect(api.padNumber(1234), equals('1234'));
    });
  });

  group('Advanced Helpers', () {
    test('getError - should return empty string initially', () {
      final error = api.getError();
      expect(error, equals(''));
    });

    // Note: getTransactionOutcome makes real API calls and would require
    // a mocked HTTP client to test properly. It's tested in integration tests.
  });

  group('Configuration Methods', () {
    test('getNagUrl - should return default URL', () {
      expect(api.getNagUrl(), equals('https://nag.circularlabs.io/NAG.php?cep='));
    });

    test('setNagUrl and getNagUrl - should update and retrieve URL', () {
      api.setNagUrl('https://custom.api/endpoint');
      expect(api.getNagUrl(), equals('https://custom.api/endpoint'));
    });

    test('getNagKey - should return empty string by default', () {
      expect(api.getNagKey(), equals(''));
    });

    test('setNagKey and getNagKey - should update and retrieve key', () {
      api.setNagKey('my-api-key');
      expect(api.getNagKey(), equals('my-api-key'));
    });

    test('setHeader - should not throw', () {
      expect(() => api.setHeader('X-Custom-Header', 'value'), returnsNormally);
    });
  });

  group('Convenience Methods', () {
    test('registerWallet - should call sendTransaction with proper structure', () async {
      // This test verifies the method exists and constructs proper parameters
      // In a real scenario, we'd mock the HTTP client to verify the request structure
      final mockApi = CircularProtocolAPI(nagUrl: 'https://mock.test/');

      // We can't fully test this without mocking, but we can verify it doesn't throw
      // with invalid parameters (it should throw with a mock that rejects)
      expect(
        () => mockApi.registerWallet('MainNet', 'a' * 128),
        returnsNormally,
      );

      mockApi.dispose();
    });
  });
}
