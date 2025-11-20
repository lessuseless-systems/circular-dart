/// Circular Protocol E2E Tests (Layer 5)
/// Tests against real NAG endpoints when environment variables are present
///
/// Required environment variables:
/// - CIRCULAR_TEST_ADDRESS: Wallet address for testing (required)
/// - CIRCULAR_TEST_BLOCKCHAIN: Blockchain hash or name (default: MainNet)
///
/// Optional:
/// - CIRCULAR_NAG_URL: Custom NAG endpoint URL
///
/// Usage:
/// ```bash
/// export CIRCULAR_TEST_ADDRESS="0xd55872dbe508fd27445889b9d81bbc9411bb0f1353153a249f2fb34ef2690310"
/// export CIRCULAR_TEST_BLOCKCHAIN="MainNet"
/// dart test test/e2e_test.dart
/// ```
library e2e_test;

import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import '../lib/circular_protocol.dart';

late CircularProtocolAPI api;

void main() {
  // Check for required environment variables
  final testAddress = Platform.environment['CIRCULAR_TEST_ADDRESS'];

  if (testAddress == null || testAddress.isEmpty) {
    print('⏭️  Skipping E2E tests: CIRCULAR_TEST_ADDRESS not set');
    print('');
    print('To run E2E tests, set:');
    print('  export CIRCULAR_TEST_ADDRESS="0x..."');
    print('  export CIRCULAR_TEST_BLOCKCHAIN="MainNet"  # optional');
    return;
  }

  setUpAll(() {
    final nagUrl = Platform.environment['CIRCULAR_NAG_URL'] ??
                   'https://nag.circularlabs.io/NAG.php?cep=';

    api = CircularProtocolAPI(nagUrl: nagUrl);

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌐 E2E Tests - Live NAG Endpoint');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Version: 1.0.9');
    print('Endpoint: $nagUrl');
    print('Test Address: $testAddress');
    print('Total tests: 21');
    print('');
  });

  tearDownAll(() {
    api.dispose();
  });

  group('Wallet Operations', () {
  test('E2E: Check if test wallet exists on blockchain', () async {
    final requestJson = '''{
  "Address": "\${CIRCULAR_TEST_ADDRESS}",
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.checkWallet(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Check if test wallet exists on blockchain');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get latest transactions for wallet', () async {
    final requestJson = '''{
  "Address": "\${CIRCULAR_TEST_ADDRESS}",
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getLatestTransactions(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get latest transactions for wallet');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Retrieve wallet details from blockchain', () async {
    final requestJson = '''{
  "Address": "\${CIRCULAR_TEST_ADDRESS}",
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getWallet(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Retrieve wallet details from blockchain');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get wallet balance from blockchain', () async {
    final requestJson = '''{
  "Address": "\${CIRCULAR_TEST_ADDRESS}",
  "Asset": "CIRX",
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getWalletBalance(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get wallet balance from blockchain');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get wallet nonce from blockchain', () async {
    final requestJson = '''{
  "Address": "\${CIRCULAR_TEST_ADDRESS}",
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getWalletNonce(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get wallet nonce from blockchain');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  });

  group('Transaction Operations', () {
  test('E2E: Get pending transactions', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getPendingTransaction(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get pending transactions');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get transactions by wallet address', () async {
    final requestJson = '''{
  "Address": "\${CIRCULAR_TEST_ADDRESS}",
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getTransactionByAddress(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get transactions by wallet address');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get transactions by date range', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "EndDate": "2024-12-31",
  "StartDate": "2024-01-01",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getTransactionByDate(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get transactions by date range');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get transaction by transaction ID', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "TransactionID": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getTransactionById(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get transaction by transaction ID');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get transactions by node ID', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "NodeID": "node-0001",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getTransactionByNode(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get transactions by node ID');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  });

  group('Asset Operations', () {
  test('E2E: Get specific asset information', () async {
    final requestJson = '''{
  "AssetName": "CIRX",
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getAsset(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get specific asset information');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get list of all assets on blockchain', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getAssetList(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get list of all assets on blockchain');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get asset supply information', () async {
    final requestJson = '''{
  "AssetName": "CIRX",
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getAssetSupply(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get asset supply information');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get voucher details', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9",
  "VoucherID": "test-voucher-id"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getVoucher(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get voucher details');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  });

  group('Network Operations', () {
  test('E2E: Retrieve list of available blockchains', () async {
    final requestJson = '''{
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getBlockchains(request);

expect(result['Result'], equals(200));
expect(result['Response.Blockchains'], isA<List>());

    print('  ✅ E2E: Retrieve list of available blockchains');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  });

  group('Block Operations', () {
  test('E2E: Get blockchain analytics and statistics', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getAnalytics(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get blockchain analytics and statistics');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Retrieve specific block by number', () async {
    final requestJson = '''{
  "BlockNumber": 1,
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getBlock(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Retrieve specific block by number');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Get current block count from blockchain', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getBlockCount(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Get current block count from blockchain');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  test('E2E: Retrieve range of blocks', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "EndBlock": 10,
  "StartBlock": 1,
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getBlockRange(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Retrieve range of blocks');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  });

  group('Domain Operations', () {
  test('E2E: Resolve domain name to wallet address', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "Domain": "test.circular",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.getDomain(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Resolve domain name to wallet address');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  });

  group('Contract Operations', () {
  test('E2E: Test smart contract execution (simulation)', () async {
    final requestJson = '''{
  "Blockchain": "\${CIRCULAR_TEST_BLOCKCHAIN}",
  "ContractAddress": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "Method": "testMethod",
  "Parameters": "{}",
  "Version": "1.0.9"
}'''
        .replaceAll('\${CIRCULAR_TEST_ADDRESS}', Platform.environment['CIRCULAR_TEST_ADDRESS'] ?? '')
        .replaceAll('\${CIRCULAR_TEST_BLOCKCHAIN}', Platform.environment['CIRCULAR_TEST_BLOCKCHAIN'] ?? '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2');

    final request = jsonDecode(requestJson) as Map<String, dynamic>;

    final result = await api.testContract(request);

expect(result['Result'], isNotNull);

    print('  ✅ E2E: Test smart contract execution (simulation)');
  }, timeout: Timeout(Duration(milliseconds: 30000)));
  });
}