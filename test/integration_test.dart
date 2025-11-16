import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import '../lib/circular_protocol.dart';

late CircularProtocolAPI client;
late MockClient mockClient;

void main() {
  setUpAll(() {
    // Create mock HTTP client that responds with endpoint-specific responses
    mockClient = MockClient((request) async {
      final url = request.url.toString();

      // Return endpoint-specific mock responses
      Map<String, dynamic> response;

      // Match endpoints in order of specificity (most specific first)
      if (url.contains('Circular_CheckWallet_')) {
        response = {'Result': 200, 'Response': {'exists': true}};
      } else if (url.contains('Circular_GetLatestTransactions_')) {
        response = {'Result': 200, 'Response': {'transactions': []}};
      } else if (url.contains('Circular_GetWalletBalance_')) {
        response = {'Result': 200, 'Response': {'balance': '1000'}};
      } else if (url.contains('Circular_GetWalletNonce_')) {
        response = {'Result': 200, 'Response': {'nonce': 42}};
      } else if (url.contains('Circular_GetWallet_')) {
        response = {'Result': 200, 'Response': {'address': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'}};
      } else if (url.contains('Circular_AddTransaction_')) {
        response = {'Result': 200, 'Response': {'transaction_id': '0xaabbccdd11223344'}};
      } else if (url.contains('Circular_GetPendingTransaction_')) {
        response = {'Result': 200, 'Response': {'transactions': []}};
      } else if (url.contains('Circular_GetTransactionbyAddress_')) {
        response = {'Result': 200, 'Response': {'transactions': []}};
      } else if (url.contains('Circular_GetTransactionbyDate_')) {
        response = {'Result': 200, 'Response': {'transactions': []}};
      } else if (url.contains('Circular_GetTransactionbyID_')) {
        response = {'Result': 200, 'Response': {'transaction': {}}};
      } else if (url.contains('Circular_GetTransactionbyNode_')) {
        response = {'Result': 200, 'Response': {'transactions': []}};
      } else if (url.contains('Circular_GetAssetList_')) {
        response = {'Result': 200, 'Response': {'assets': []}};
      } else if (url.contains('Circular_GetAssetSupply_')) {
        response = {'Result': 200, 'Response': {'total_supply': 1000000}};
      } else if (url.contains('Circular_GetAsset_')) {
        response = {'Result': 200, 'Response': {'asset': {}}};
      } else if (url.contains('Circular_GetVoucher_')) {
        response = {'Result': 200, 'Response': {'voucher': {}}};
      } else if (url.contains('Circular_GetAnalytics_')) {
        response = {'Result': 200, 'Response': {'analytics': {}}};
      } else if (url.contains('Circular_GetBlockHeight_')) {
        response = {'Result': 200, 'Response': {'count': 12345}};
      } else if (url.contains('Circular_GetBlockRange_')) {
        response = {'Result': 200, 'Response': {'blocks': []}};
      } else if (url.contains('Circular_GetBlock_')) {
        response = {'Result': 200, 'Response': {'block': {}}};
      } else if (url.contains('Circular_CallContract_')) {
        response = {'Result': 200, 'Response': {'result': 'mock_result'}};
      } else if (url.contains('Circular_TestContract_')) {
        response = {'Result': 200, 'Response': {'result': 'mock_result'}};
      } else if (url.contains('Circular_ResolveDomain_')) {
        response = {'Result': 200, 'Response': {'address': '0xresolved'}};
      } else if (url.contains('Circular_GetBlockchains_')) {
        response = {'Result': 200, 'Response': {'blockchains': ['MainNet']}};
      } else {
        response = {'Result': 200, 'Response': {}};
      }

      return http.Response(
        jsonEncode(response),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    // Create client with mock HTTP client
    client = CircularProtocolAPI(
      nagUrl: 'https://mock.test/',
      nagKey: 'mock-key',
      httpClient: mockClient,
    );
  });

  tearDownAll(() {
    client.dispose();
  });

  group('Integration Tests (Layer 3)', () {
  test('Should successfully check if wallet exists', () async {
    final request = {
'Address': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.checkWallet(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['exists'], equals(true));
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should fetch recent transactions for wallet', () async {
    final request = {
'Address': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
'Blockchain': "MainNet",
'Limit': 10,
'Version': '1.0.8',
    };

    final result = await client.getLatestTransactions(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['transactions'], isA<List>());
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should retrieve wallet details', () async {
    final request = {
'Address': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getWallet(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['address'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get wallet balance for specific asset', () async {
    final request = {
'Address': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
'Asset': '0xC123',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getWalletBalance(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['balance'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get current wallet nonce', () async {
    final request = {
'Address': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getWalletNonce(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['nonce'] as int, greaterThanOrEqualTo(0));
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should submit a transaction to blockchain', () async {
    final request = {
'From': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
'ID': '0xaabbccdd11223344',
'Nonce': 1,
'Payload': '0x1234',
'Signature': '0xsignature',
'Timestamp': '1234567890',
'To': '0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
'Type': 'transfer',
'Version': '1.0.8',
    };

    final result = await client.addTransaction(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['transaction_id'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get pending transactions', () async {
    final request = {
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getPendingTransaction(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['transactions'], isA<List>());
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get transactions by address', () async {
    final request = {
'Address': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getTransactionByAddress(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['transactions'], isA<List>());
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get transactions by date range', () async {
    final request = {
'Blockchain': "MainNet",
'EndDate': '2024-12-31',
'StartDate': '2024-01-01',
'Version': '1.0.8',
    };

    final result = await client.getTransactionByDate(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['transactions'], isA<List>());
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get transaction by ID', () async {
    final request = {
'Blockchain': "MainNet",
'TransactionID': '0xaabbccdd11223344',
'Version': '1.0.8',
    };

    final result = await client.getTransactionById(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['transaction'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get transactions by node', () async {
    final request = {
'Blockchain': "MainNet",
'Node': '0xnode123',
'Version': '1.0.8',
    };

    final result = await client.getTransactionByNode(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['transactions'], isA<List>());
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get asset details', () async {
    final request = {
'Asset': '0xC123',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getAsset(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['asset'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get list of all assets', () async {
    final request = {
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getAssetList(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['assets'], isA<List>());
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get asset supply information', () async {
    final request = {
'Asset': '0xC123',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getAssetSupply(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['total_supply'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get voucher details', () async {
    final request = {
'Blockchain': "MainNet",
'Version': '1.0.8',
'VoucherID': '0xvoucher123',
    };

    final result = await client.getVoucher(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['voucher'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should list supported blockchains', () async {
    final request = {
'Version': '1.0.8',
    };

    final result = await client.getBlockchains(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['blockchains'], isA<List>());
expect((result['Response'] as Map<String, dynamic>)['blockchains'] as List, contains('MainNet'));
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get blockchain analytics', () async {
    final request = {
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getAnalytics(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['analytics'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get block by number', () async {
    final request = {
'Block': 12345,
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getBlock(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['block'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get current blockchain height', () async {
    final request = {
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    final result = await client.getBlockCount(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['count'] as int, greaterThan(0));
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should get range of blocks', () async {
    final request = {
'Blockchain': "MainNet",
'EndBlock': 10010,
'StartBlock': 10000,
'Version': '1.0.8',
    };

    final result = await client.getBlockRange(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['blocks'], isA<List>());
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should resolve domain to address', () async {
    final request = {
'Blockchain': "MainNet",
'Domain': 'myname.circular',
'Version': '1.0.8',
    };

    final result = await client.getDomain(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['address'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should call contract method', () async {
    final request = {
'Blockchain': "MainNet",
'ContractAddress': '0xcontract123',
'Method': 'balanceOf',
'Parameters': [
  "0xwallet123"
],
'Version': '1.0.8',
    };

    final result = await client.callContract(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['result'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should test contract execution (dry run)', () async {
    final request = {
'Blockchain': "MainNet",
'ContractAddress': '0xcontract123',
'Method': 'transfer',
'Parameters': [
  "0xrecipient",
  "1000"
],
'Version': '1.0.8',
    };

    final result = await client.testContract(request);

expect(result['Result'], equals(200));
expect((result['Response'] as Map<String, dynamic>)['result'], isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should handle network connection errors gracefully', () async {
    final invalidClient = CircularProtocolAPI(nagUrl: 'http://localhost:9999/');

    final request = {
'Address': '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    expect(
      invalidClient.checkWallet(request),
      throwsA(isA<Exception>()),
    );
  }, timeout: Timeout(Duration(seconds: 10)));
  test('Should handle invalid address gracefully', () async {
    // Create mock client that returns an error for invalid addresses
    final errorMockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'Result': 400, 'Response': {'error': 'Invalid address'}}),
        400,
        headers: {'content-type': 'application/json'},
      );
    });

    final errorClient = CircularProtocolAPI(
      nagUrl: 'https://mock.test/',
      nagKey: 'mock-key',
      httpClient: errorMockClient,
    );

    final request = {
'Address': 'invalid',
'Blockchain': "MainNet",
'Version': '1.0.8',
    };

    expect(
      errorClient.checkWallet(request),
      throwsA(isA<CircularAPIException>()),
    );
  }, timeout: Timeout(Duration(seconds: 10)));
  });
}