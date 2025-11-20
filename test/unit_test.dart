import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import '../lib/circular_protocol.dart';

void main() {
  group('CircularProtocolAPI', () {
    test('creates client with default URL', () {
      final client = CircularProtocolAPI();
      expect(client.getNagUrl(), equals('https://nag.circularlabs.io/NAG.php?cep='));
    });

    test('creates client with custom URL', () {
      final client = CircularProtocolAPI(
        nagUrl: 'https://test.com/api',
        nagKey: 'test-key',
      );
      expect(client.getNagUrl(), equals('https://test.com/api'));
      expect(client.getNagKey(), equals('test-key'));
    });

    test('updates NAG URL', () {
      final client = CircularProtocolAPI();
      client.setNagUrl('https://new.com/api');
      expect(client.getNagUrl(), equals('https://new.com/api'));
    });

    test('updates NAG key', () {
      final client = CircularProtocolAPI();
      client.setNagKey('new-key');
      expect(client.getNagKey(), equals('new-key'));
    });

    test('sets custom headers', () {
      final client = CircularProtocolAPI();
      // setHeader is void, so we just verify it doesn't throw
      expect(() => client.setHeader('X-Custom', 'value'), returnsNormally);
    });

    test('makes successful API request', () async {
      // Create mock HTTP client
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.headers['Content-Type'], equals('application/json'));

        return http.Response(
          jsonEncode({
            'Result': 200,
            'Response': {'data': 'success'}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = CircularProtocolAPI(
        nagUrl: 'https://test.com/',
        httpClient: mockClient,
      );

      final result = await client.checkWallet({
        'Address': '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        'Blockchain': 'MainNet',
        'Version': '1.0.9',
      });

      expect(result['Result'], equals(200));
      expect(result['Response'], isNotNull);
    });

    test('throws CircularAPIException on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final client = CircularProtocolAPI(
        nagUrl: 'https://test.com/',
        httpClient: mockClient,
      );

      expect(
        () => client.checkWallet({
          'Address': '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'Blockchain': 'MainNet',
          'Version': '1.0.9',
        }),
        throwsA(isA<CircularAPIException>()),
      );
    });

    test('throws CircularAPIException on API error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'Result': 404,
            'Response': 'Wallet not found'
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = CircularProtocolAPI(
        nagUrl: 'https://test.com/',
        httpClient: mockClient,
      );

      expect(
        () => client.checkWallet({
          'Address': '0x0000000000000000000000000000000000000000000000000000000000000000',
          'Blockchain': 'MainNet',
          'Version': '1.0.9',
        }),
        throwsA(isA<CircularAPIException>()),
      );
    });

    test('throws CircularAPIException on timeout', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(Duration(seconds: 5));
        return http.Response('{}', 200);
      });

      final client = CircularProtocolAPI(
        nagUrl: 'https://test.com/',
        httpClient: mockClient,
        timeout: Duration(milliseconds: 100),
      );

      expect(
        () => client.checkWallet({
          'Address': '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'Blockchain': 'MainNet',
          'Version': '1.0.9',
        }),
        throwsA(isA<CircularAPIException>()),
      );
    });

    test('includes NAG key in headers when provided', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-NAG-Key'], equals('test-key'));

        return http.Response(
          jsonEncode({
            'Result': 200,
            'Response': {'data': 'success'}
          }),
          200,
        );
      });

      final client = CircularProtocolAPI(
        nagUrl: 'https://test.com/',
        nagKey: 'test-key',
        httpClient: mockClient,
      );

      await client.checkWallet({
        'Address': '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        'Blockchain': 'MainNet',
        'Version': '1.0.9',
      });
    });

    test('disposes HTTP client', () {
      final client = CircularProtocolAPI();
      expect(() => client.dispose(), returnsNormally);
    });
  });
}