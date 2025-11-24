/// Circular Protocol Dart SDK
/// Official Dart SDK for the Circular Protocol blockchain API
/// Version: 1.0.9
///
/// Example usage:
/// ```dart
/// final client = CircularProtocolAPI(
///   nagUrl: 'https://nag.circularlabs.io/NAG.php?cep=',
///   nagKey: 'your-api-key',
/// );
///
/// final result = await client.checkWallet({
///   'Address': '0x...',
///   'Blockchain': '714d2ac07a826b66ac56752eebd7c77b58d2ee842e523d913fd0ef06e6bdfcae',
///   'Version': '1.0.9',
/// });
/// print(result);
/// ```
library circular_protocol;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:intl/intl.dart';

/// API client for Circular Protocol blockchain
class CircularProtocolAPI {
  /// NAG endpoint URL
  String nagUrl;

  /// NAG API key (optional)
  String nagKey;

  /// HTTP client for making requests
  final http.Client _httpClient;

  /// Custom headers to include in requests
  final Map<String, String> _headers;

  /// Request timeout duration
  final Duration timeout;

String _lastError = '';

  /// Constructor
  CircularProtocolAPI({
    String? nagUrl,
    this.nagKey = '',
    http.Client? httpClient,
    Map<String, String>? headers,
    this.timeout = const Duration(seconds: 30),
  })  : nagUrl = nagUrl ?? 'https://nag.circularlabs.io/NAG.php?cep=',
        _httpClient = httpClient ?? http.Client(),
        _headers = headers ?? {};

  /// Update NAG endpoint URL
  void setNagUrl(String url) {
    nagUrl = url;
  }

  /// Get current NAG endpoint URL
  String getNagUrl() => nagUrl;

  /// Update NAG API key
  void setNagKey(String key) {
    nagKey = key;
  }

  /// Get current NAG API key
  String getNagKey() => nagKey;

  /// Set custom HTTP header
  void setHeader(String key, String value) {
    _headers[key] = value;
  }

  /// Make HTTP request to NAG API
  Future<Map<String, dynamic>> _makeRequest(
    String endpoint,
    Map<String, dynamic> data, {
    Duration? requestTimeout,
  }) async {
    final url = Uri.parse('${nagUrl}Circular_${endpoint}_');

    // Build headers
    final headers = {
      'Content-Type': 'application/json',
      ..._headers,
    };
    if (nagKey.isNotEmpty) {
      headers['X-NAG-Key'] = nagKey;
    }

    try {
      // Make POST request
      final response = await _httpClient
          .post(
            url,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(requestTimeout ?? timeout);

      // Check HTTP status
      if (response.statusCode != 200) {
        throw CircularAPIException(
          'HTTP error: ${response.statusCode} ${response.reasonPhrase}',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }

      // Parse JSON response
      final Map<String, dynamic> result = jsonDecode(response.body) as Map<String, dynamic>;

      // Check API-level errors
      final resultCode = result['Result'] as int?;
      if (resultCode == null || resultCode != 200) {
        final errorMessage = (result['Response'] as String?) ?? 'API request failed';
        throw CircularAPIException(
          errorMessage,
          statusCode: resultCode ?? 0,
          endpoint: endpoint,
        );
      }

      // Return full response (with Result and Response fields)
      return result;
    } on TimeoutException {
      throw CircularAPIException(
        'Request timeout after ${timeout.inSeconds}s',
        statusCode: 0,
        endpoint: endpoint,
      );
    } on http.ClientException catch (e) {
      throw CircularAPIException(
        'Network error: ${e.message}',
        statusCode: 0,
        endpoint: endpoint,
      );
    } catch (e) {
      if (e is CircularAPIException) rethrow;
      throw CircularAPIException(
        'Unexpected error: $e',
        statusCode: 0,
        endpoint: endpoint,
      );
    }
  }

  // ============================================================================
  // API Methods
  // ============================================================================

  /// Checks whether a wallet address exists on the specified blockchain.
  ///
  /// This method verifies wallet existence and confirms the address format is valid.
  /// Useful for validating addresses before attempting transactions.
  ///
  /// **Parameters** (in [request] map):
  /// - `Address` (String): Wallet address to check (with or without 0x prefix)
  /// - `Blockchain` (String): Blockchain identifier (e.g., 'MainNet')
  /// - `Version` (String): API version (e.g., '1.0.9')
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.checkWallet({
  ///   'Address': '0xd55872dbe508fd27445889b9d81bbc9411bb0f1353153a249f2fb34ef2690310',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// if (result['Result'] == 200) {
  ///   print('Wallet exists: ${result['Response']}');
  /// }
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] containing:
  /// - `Result` (int): Status code (200 for success)
  /// - `Response` (dynamic): Wallet existence data
  ///
  /// **Throws:**
  /// - [CircularAPIException] if the API request fails
  /// - [TimeoutException] if the request times out
  Future<Map<String, dynamic>> checkWallet(Map<String, dynamic> request) async {
    return _makeRequest('CheckWallet', request);
  }

  /// Retrieves complete wallet information including balance and nonce.
  ///
  /// Returns all wallet properties including current state on the blockchain.
  ///
  /// **Parameters** (in [request] map):
  /// - `Address` (String): Wallet address to query
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getWallet({
  ///   'Address': '0xd55872dbe508fd27445889b9d81bbc9411bb0f1353153a249f2fb34ef2690310',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Balance: ${result['Response']['Balance']}');
  /// print('Nonce: ${result['Response']['Nonce']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] containing wallet details
  ///
  /// **Throws:**
  /// - [CircularAPIException] if the wallet doesn't exist or request fails
  Future<Map<String, dynamic>> getWallet(Map<String, dynamic> request) async {
    return _makeRequest('GetWallet', request);
  }

  /// Retrieves the latest transactions for a wallet address.
  ///
  /// Returns an array of transaction objects with complete details.
  ///
  /// **Parameters** (in [request] map):
  /// - `Address` (String): Wallet address to query
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Limit` (int, optional): Maximum number of transactions to return
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getLatestTransactions({
  ///   'Address': '0xd55872dbe508fd27445889b9d81bbc9411bb0f1353153a249f2fb34ef2690310',
  ///   'Blockchain': 'MainNet',
  ///   'Limit': 10,
  ///   'Version': '1.0.9',
  /// });
  ///
  /// final transactions = result['Response']['Transactions'] as List;
  /// for (var tx in transactions) {
  ///   print('TX: ${tx['ID']} - ${tx['Type']}');
  /// }
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] containing transaction array
  Future<Map<String, dynamic>> getLatestTransactions(Map<String, dynamic> request) async {
    return _makeRequest('GetLatestTransactions', request);
  }

  /// Retrieves the balance of a specified asset in a wallet.
  ///
  /// Returns the balance amount for the requested asset.
  ///
  /// **Parameters** (in [request] map):
  /// - `Address` (String): Wallet address to query
  /// - `Asset` (String): Asset name or identifier (e.g., 'CIRX')
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getWalletBalance({
  ///   'Address': '0xd55872dbe508fd27445889b9d81bbc9411bb0f1353153a249f2fb34ef2690310',
  ///   'Asset': 'CIRX',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('CIRX Balance: ${result['Response']['Balance']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] containing balance information
  Future<Map<String, dynamic>> getWalletBalance(Map<String, dynamic> request) async {
    return _makeRequest('GetWalletBalance', request);
  }

  /// Retrieves the nonce (transaction counter) of a wallet.
  ///
  /// The nonce is used for transaction ordering and must increment with each transaction.
  /// Essential for creating new transactions.
  ///
  /// **Parameters** (in [request] map):
  /// - `Address` (String): Wallet address to query
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getWalletNonce({
  ///   'Address': '0xd55872dbe508fd27445889b9d81bbc9411bb0f1353153a249f2fb34ef2690310',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// final currentNonce = result['Response']['Nonce'];
  /// final nextNonce = (int.parse(currentNonce) + 1).toString();
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] containing the current nonce
  Future<Map<String, dynamic>> getWalletNonce(Map<String, dynamic> request) async {
    return _makeRequest('GetWalletNonce', request);
  }
  /// Submits a transaction to the blockchain.
  ///
  /// Requires a complete signed transaction including ID, addresses, payload,
  /// nonce, and signature. This is the primary method for transaction submission.
  ///
  /// **Parameters** (in [request] map):
  /// - `ID` (String): Transaction hash/identifier
  /// - `From` (String): Sender wallet address
  /// - `To` (String): Recipient wallet address
  /// - `Timestamp` (String): UTC timestamp (YYYY:MM:DD-HH:mm:ss)
  /// - `Type` (String): Transaction type (e.g., 'C_TYPE_TRANSACTION')
  /// - `Payload` (String): Hex-encoded transaction data
  /// - `Nonce` (String): Transaction nonce (must increment)
  /// - `Signature` (String): DER-encoded ECDSA signature
  /// - `Blockchain` (String): Target blockchain
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.addTransaction({
  ///   'ID': transactionHash,
  ///   'From': senderAddress,
  ///   'To': recipientAddress,
  ///   'Timestamp': api.getFormattedTimestamp(),
  ///   'Type': 'C_TYPE_TRANSACTION',
  ///   'Payload': hexEncodedPayload,
  ///   'Nonce': '1',
  ///   'Signature': signature,
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with transaction result
  ///
  /// **Throws:**
  /// - [CircularAPIException] if the transaction is invalid or fails
  ///
  /// **See also:** [sendTransaction], [registerWallet]
  Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> request) async {
    return _makeRequest('AddTransaction', request);
  }

  /// Submits a transaction to the blockchain (alias for [addTransaction]).
  ///
  /// This is an alias method that calls [addTransaction]. Use whichever name
  /// you prefer - both behave identically.
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.sendTransaction({
  ///   'ID': transactionHash,
  ///   'From': senderAddress,
  ///   // ... other transaction fields
  /// });
  /// ```
  ///
  /// **See also:** [addTransaction]
  Future<Map<String, dynamic>> sendTransaction(Map<String, dynamic> request) async {
    return addTransaction(request);
  }

  /// Sends a batch of transactions to the blockchain.
  ///
  /// **Parameters**:
  /// - `transactions` (List<Map<String, dynamic>>): List of transaction objects
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with batch result
  Future<Map<String, dynamic>> sendBatch(List<Map<String, dynamic>> transactions) async {
    try {
      return await _makeRequest(
        'AddBatch',
        {'Transactions': transactions},
        requestTimeout: const Duration(seconds: 120),
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Server unreachable or request timeout',
        'error': e.toString(),
      };
    }
  }

  /// Searches for a transaction by ID among pending transactions.
  ///
  /// Returns the transaction if it exists and is still in the mempool (pending).
  ///
  /// **Parameters** (in [request] map):
  /// - `ID` (String): Transaction ID to search for
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getPendingTransaction({
  ///   'ID': transactionId,
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// if (result['Result'] == 200) {
  ///   print('Transaction still pending: ${result['Response']}');
  /// }
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with pending transaction data
  Future<Map<String, dynamic>> getPendingTransaction(Map<String, dynamic> request) async {
    return _makeRequest('GetPendingTransaction', request);
  }

  /// Finds a transaction by ID within a specified block range.
  ///
  /// Searches through blocks to locate a confirmed transaction.
  ///
  /// **Parameters** (in [request] map):
  /// - `ID` (String): Transaction ID to search for
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Start` (String): Start block number
  /// - `End` (String): End block number
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getTransactionById({
  ///   'ID': transactionId,
  ///   'Blockchain': 'MainNet',
  ///   'Start': '0',
  ///   'End': '1000',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Block number: ${result['Response']['BlockNumber']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with transaction details
  Future<Map<String, dynamic>> getTransactionById(Map<String, dynamic> request) async {
    return _makeRequest('GetTransactionbyID', request);
  }

  /// Finds transactions by validator node ID within a specified block range.
  ///
  /// Returns all transactions associated with the specified node.
  ///
  /// **Parameters** (in [request] map):
  /// - `Node` (String): Node ID to search for
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Start` (String): Start block number
  /// - `End` (String): End block number
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getTransactionByNode({
  ///   'Node': nodeId,
  ///   'Blockchain': 'MainNet',
  ///   'Start': '0',
  ///   'End': '1000',
  ///   'Version': '1.0.9',
  /// });
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with transaction list
  Future<Map<String, dynamic>> getTransactionByNode(Map<String, dynamic> request) async {
    return _makeRequest('GetTransactionbyNode', request);
  }

  /// Finds transactions by wallet address within a specified block range.
  ///
  /// Returns transactions where the address is either sender or recipient.
  ///
  /// **Parameters** (in [request] map):
  /// - `Address` (String): Wallet address to search for
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Start` (String): Start block number
  /// - `End` (String): End block number
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getTransactionByAddress({
  ///   'Address': '0xd55872dbe508fd27445889b9d81bbc9411bb0f1353153a249f2fb34ef2690310',
  ///   'Blockchain': 'MainNet',
  ///   'Start': '0',
  ///   'End': '1000',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// final txList = result['Response']['Transactions'] as List;
  /// print('Found ${txList.length} transactions');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with transaction list
  Future<Map<String, dynamic>> getTransactionByAddress(Map<String, dynamic> request) async {
    return _makeRequest('GetTransactionbyAddress', request);
  }

  /// Finds transactions by wallet address within a specified date range.
  ///
  /// Returns all transactions for the address between the specified dates.
  ///
  /// **Parameters** (in [request] map):
  /// - `Address` (String): Wallet address to search for
  /// - `Blockchain` (String): Blockchain identifier
  /// - `StartDate` (String): Start date (YYYY-MM-DD)
  /// - `EndDate` (String): End date (YYYY-MM-DD)
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getTransactionByDate({
  ///   'Address': '0xd55872dbe508fd27445889b9d81bbc9411bb0f1353153a249f2fb34ef2690310',
  ///   'Blockchain': 'MainNet',
  ///   'StartDate': '2024-01-01',
  ///   'EndDate': '2024-12-31',
  ///   'Version': '1.0.9',
  /// });
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with transaction list
  Future<Map<String, dynamic>> getTransactionByDate(Map<String, dynamic> request) async {
    return _makeRequest('GetTransactionbyDate', request);
  }
  /// Retrieves a specific block by block number.
  ///
  /// Returns complete block information including transactions, hash, and metadata.
  ///
  /// **Parameters** (in [request] map):
  /// - `BlockNumber` (String): Block number to retrieve
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getBlock({
  ///   'BlockNumber': '1000',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Block hash: ${result['Response']['Hash']}');
  /// print('Transactions: ${result['Response']['Transactions'].length}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with complete block data
  Future<Map<String, dynamic>> getBlock(Map<String, dynamic> request) async {
    return _makeRequest('GetBlock', request);
  }

  /// Retrieves all blocks within a specified range.
  ///
  /// If End = 0, then Start is the number of blocks from the latest block going backward.
  ///
  /// **Parameters** (in [request] map):
  /// - `Start` (String): Start block number
  /// - `End` (String): End block number (0 for "Start blocks from latest")
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// // Get blocks 100-200
  /// final result = await api.getBlockRange({
  ///   'Start': '100',
  ///   'End': '200',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// // Get last 50 blocks
  /// final recent = await api.getBlockRange({
  ///   'Start': '50',
  ///   'End': '0',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with array of blocks
  Future<Map<String, dynamic>> getBlockRange(Map<String, dynamic> request) async {
    return _makeRequest('GetBlockRange', request);
  }

  /// Retrieves the blockchain block height (total number of blocks).
  ///
  /// Returns the current height of the blockchain, indicating the total number
  /// of minted blocks. Also known as getBlockHeight.
  ///
  /// **Parameters** (in [request] map):
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getBlockCount({
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// final height = result['Response']['Height'];
  /// print('Current blockchain height: $height');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with blockchain height
  Future<Map<String, dynamic>> getBlockCount(Map<String, dynamic> request) async {
    return _makeRequest('GetBlockHeight', request);
  }

  /// Retrieves blockchain analytics and statistics.
  ///
  /// Returns comprehensive information about the blockchain state including
  /// performance metrics, transaction counts, and network statistics.
  ///
  /// **Parameters** (in [request] map):
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getAnalytics({
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Total transactions: ${result['Response']['TotalTransactions']}');
  /// print('Active wallets: ${result['Response']['ActiveWallets']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with analytics data
  Future<Map<String, dynamic>> getAnalytics(Map<String, dynamic> request) async {
    return _makeRequest('GetAnalytics', request);
  }

  /// Tests smart contract execution locally without sending a transaction.
  ///
  /// Useful for testing contract logic, validating parameters, and estimating
  /// gas costs before actually deploying or executing on-chain.
  ///
  /// **Parameters** (in [request] map):
  /// - `Blockchain` (String): Blockchain identifier
  /// - `From` (String): Sender address for simulation
  /// - `Project` (String): Contract code or project identifier
  /// - `Request` (String): Contract function call parameters
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.testContract({
  ///   'Blockchain': 'MainNet',
  ///   'From': senderAddress,
  ///   'Project': contractCode,
  ///   'Request': functionParameters,
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Test result: ${result['Response']['Output']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with test execution results
  Future<Map<String, dynamic>> testContract(Map<String, dynamic> request) async {
    return _makeRequest('TestContract', request);
  }

  /// Calls a smart contract function on the blockchain.
  ///
  /// Executes the specified contract function with provided parameters and
  /// creates an on-chain transaction.
  ///
  /// **Parameters** (in [request] map):
  /// - `Blockchain` (String): Blockchain identifier
  /// - `From` (String): Sender address
  /// - `Project` (String): Contract code or project identifier
  /// - `Request` (String): Contract function call parameters
  /// - `Timestamp` (String): UTC timestamp
  /// - `Nonce` (String): Transaction nonce
  /// - `Signature` (String): Transaction signature
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.callContract({
  ///   'Blockchain': 'MainNet',
  ///   'From': senderAddress,
  ///   'Project': contractCode,
  ///   'Request': functionParameters,
  ///   'Timestamp': api.getFormattedTimestamp(),
  ///   'Nonce': '1',
  ///   'Signature': signature,
  ///   'Version': '1.0.9',
  /// });
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with execution results
  ///
  /// **See also:** [testContract]
  Future<Map<String, dynamic>> callContract(Map<String, dynamic> request) async {
    return _makeRequest('CallContract', request);
  }

  /// Retrieves the list of all assets minted on a specific blockchain.
  ///
  /// Returns an array of asset information including names, symbols, and metadata.
  ///
  /// **Parameters** (in [request] map):
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getAssetList({
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// final assets = result['Response']['Assets'] as List;
  /// for (var asset in assets) {
  ///   print('Asset: ${asset['Symbol']} - ${asset['Name']}');
  /// }
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with asset list
  Future<Map<String, dynamic>> getAssetList(Map<String, dynamic> request) async {
    return _makeRequest('GetAssetList', request);
  }

  /// Retrieves an asset descriptor with complete asset information.
  ///
  /// Returns detailed information about the specified asset including metadata,
  /// supply, and creation details.
  ///
  /// **Parameters** (in [request] map):
  /// - `Asset` (String): Asset identifier or symbol (e.g., 'CIRX')
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getAsset({
  ///   'Asset': 'CIRX',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Asset name: ${result['Response']['Name']}');
  /// print('Total supply: ${result['Response']['TotalSupply']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with asset details
  Future<Map<String, dynamic>> getAsset(Map<String, dynamic> request) async {
    return _makeRequest('GetAsset', request);
  }

  /// Retrieves the total, circulating, and residual supply of a specified asset.
  ///
  /// Returns comprehensive supply metrics for the asset.
  ///
  /// **Parameters** (in [request] map):
  /// - `Asset` (String): Asset identifier or symbol
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getAssetSupply({
  ///   'Asset': 'CIRX',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Total supply: ${result['Response']['TotalSupply']}');
  /// print('Circulating: ${result['Response']['CirculatingSupply']}');
  /// print('Residual: ${result['Response']['ResidualSupply']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with supply information
  Future<Map<String, dynamic>> getAssetSupply(Map<String, dynamic> request) async {
    return _makeRequest('GetAssetSupply', request);
  }

  /// Retrieves an existing voucher by code.
  ///
  /// Code is automatically stripped of 0x prefix if present. Returns voucher
  /// details including redemption status and value.
  ///
  /// **Parameters** (in [request] map):
  /// - `Code` (String): Voucher code (with or without 0x prefix)
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getVoucher({
  ///   'Code': '0xVOUCHERCODE123',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Voucher value: ${result['Response']['Value']}');
  /// print('Redeemed: ${result['Response']['Redeemed']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with voucher details
  Future<Map<String, dynamic>> getVoucher(Map<String, dynamic> request) async {
    return _makeRequest('GetVoucher', request);
  }

  /// Resolves a domain name to a wallet address.
  ///
  /// Returns the wallet address associated with the domain. A single wallet
  /// can have multiple domain associations. Also known as resolveDomain.
  ///
  /// **Parameters** (in [request] map):
  /// - `Domain` (String): Domain name to resolve
  /// - `Blockchain` (String): Blockchain identifier
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getDomain({
  ///   'Domain': 'myname.circular',
  ///   'Blockchain': 'MainNet',
  ///   'Version': '1.0.9',
  /// });
  ///
  /// print('Resolved to: ${result['Response']['Address']}');
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with wallet address
  Future<Map<String, dynamic>> getDomain(Map<String, dynamic> request) async {
    return _makeRequest('ResolveDomain', request);
  }

  /// Retrieves the list of blockchains available in the network.
  ///
  /// Returns information about all active and inactive blockchains including
  /// their identifiers, names, and status.
  ///
  /// **Parameters** (in [request] map):
  /// - `Version` (String): API version
  ///
  /// **Example:**
  /// ```dart
  /// final result = await api.getBlockchains({
  ///   'Version': '1.0.9',
  /// });
  ///
  /// final blockchains = result['Response']['Blockchains'] as List;
  /// for (var chain in blockchains) {
  ///   print('Blockchain: ${chain['Name']} - ${chain['ID']}');
  /// }
  /// ```
  ///
  /// **Returns:** A [Future] that resolves to a [Map] with blockchain list
  Future<Map<String, dynamic>> getBlockchains(Map<String, dynamic> request) async {
    return _makeRequest('GetBlockchains', request);
  }

  // ============================================================================
  // Convenience Methods
  // ============================================================================
  // These methods wrap underlying API calls to simplify common workflows

/// Register wallet on blockchain (Convenience Method)
///
/// Registers a wallet on the specified blockchain by creating and sending
/// a C_TYPE_REGISTERWALLET transaction. This convenience method handles all
/// transaction construction internally:
///
/// - Derives From/To addresses from public key (sha256)
/// - Builds Payload: hex(JSON.stringify({Action: "CP_REGISTERWALLET", PublicKey: publicKey}))
/// - Calculates transaction ID: sha256(blockchain + from + to + payload + nonce + timestamp)
/// - Sets Nonce to "0" and Signature to "" (empty for registration)
/// - Calls sendTransaction with constructed parameters
///
/// Without registration, the wallet will not be reachable on the blockchain.
/// The same wallet can be registered on multiple blockchains.
///
/// This is a convenience method that wraps sendTransaction().
/// It handles transaction construction internally.
///
/// [blockchain] Blockchain where the wallet will be registered
/// [publicKey] Wallet public key (128 hex characters)
/// Returns: Same as sendTransaction response
Future<Map<String, dynamic>> registerWallet(String blockchain, String publicKey) async {
  // Derive addresses from public key
  final from = hashString(publicKey);
  final to = from;
  final nonce = '0';
  final type = 'C_TYPE_REGISTERWALLET';

  // Build payload
  final payloadObj = {
    'Action': 'CP_REGISTERWALLET',
    'PublicKey': publicKey,
  };
  final payload = stringToHex(jsonEncode(payloadObj));
  final timestamp = getFormattedTimestamp();

  // Calculate transaction ID
  final id = hashString(blockchain + from + to + payload + nonce + timestamp);
  final signature = '';

  // Build request
  final request = {
    'ID': id,
    'From': from,
    'To': to,
    'Timestamp': timestamp,
    'Type': type,
    'Payload': payload,
    'Nonce': nonce,
    'Signature': signature,
    'Blockchain': blockchain,
    'Version': '1.0.9',
  };

  // Call sendTransaction
  return sendTransaction(request);
}

  // ============================================================================
  // Cryptographic Helper Functions
  // ============================================================================


  /// Convert Uint8List to hex string
  String _uint8ListToHex(Uint8List input) {
    return hex.encode(input);
  }

  /// Convert hex string to Uint8List
  static Uint8List _hexToBytes(String hexStr) {
    return Uint8List.fromList(hex.decode(hexStr));
  }

  /// Convert BigInt to bytes
  static Uint8List _bigIntToBytes(BigInt bigInt) {
    return _hexToBytes(bigInt.toRadixString(16).padLeft(32, "0"));
  }

  /// Decode bytes to BigInt
  static BigInt _decodeBigInt(List<int> bytes) {
    BigInt result = BigInt.from(0);
    for (int i = 0; i < bytes.length; i++) {
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    return result;
  }

  /// Convert bytes to BigInt
  static BigInt _byteToBigInt(Uint8List bigIntBytes) {
    return _decodeBigInt(bigIntBytes);
  }

  /// Pad bytes to 32 bytes
  List<int> _pad(List<int> data) {
    if (data.length < 32) data = Uint8List(32 - data.length) + data;
    return data;
  }

  /// Convert ECDSA signature to IEEE P1363 format
  Uint8List _convertToIEEE1363(BigInt rBI, BigInt sBI) {
    return Uint8List.fromList(
        _pad(_bigIntToBytes(rBI)) + _pad(_bigIntToBytes(sBI)));
  }

  /// Hashes a string using SHA-256.
  ///
  /// Useful for generating transaction IDs, wallet addresses, and other
  /// blockchain identifiers.
  ///
  /// **Parameters:**
  /// - [input]: String to hash
  ///
  /// **Returns:** Hex-encoded SHA-256 hash (64 characters)
  ///
  /// **Example:**
  /// ```dart
  /// final hash = api.hashString('Hello, Circular!');
  /// print('SHA-256: $hash');
  /// // Output: SHA-256: a1b2c3d4... (64 hex characters)
  ///
  /// // Generate transaction ID
  /// final txId = api.hashString(blockchain + from + to + payload + nonce + timestamp);
  /// ```
  ///
  /// **See also:** [signMessage], [getKeysFromString]
  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return _uint8ListToHex(Uint8List.fromList(digest.bytes));
  }

  /// Derives the public key from a private key using ECDSA secp256k1.
  ///
  /// Returns the uncompressed public key (128 hex characters) without the 0x04 prefix.
  /// This is the format expected by Circular Protocol for wallet addresses and signatures.
  ///
  /// **Parameters:**
  /// - [privateKey]: Private key as hex string (64-66 characters, with or without 0x prefix)
  ///
  /// **Returns:** Uncompressed public key (128 hex characters, no 0x04 prefix)
  ///
  /// **Example:**
  /// ```dart
  /// final privateKey = '1234567890abcdef...'; // 64 hex chars
  /// final publicKey = api.getPublicKey(privateKey);
  /// print('Public key length: ${publicKey.length}'); // 128
  ///
  /// // Use for wallet address
  /// final address = api.hashString(publicKey);
  /// ```
  ///
  /// **Technical details:**
  /// - Uses secp256k1 elliptic curve (same as Bitcoin/Ethereum)
  /// - Implemented with PointyCastle library
  /// - Format: X + Y coordinates (64 + 64 hex chars)
  ///
  /// **See also:** [getKeysFromString], [signMessage]
  String getPublicKey(String privateKey) {
    final String remove0x = _hexFix(privateKey);

    // Create private key object from hex string
    final Uint8List key = Uint8List.fromList(hex.decode(remove0x));
    final ECPrivateKey pk = ECPrivateKey(
      _byteToBigInt(key),
      ECDomainParameters("secp256k1"),
    );

    // Derive public key
    final ECDomainParameters params = ECDomainParameters('secp256k1');
    final ECPublicKey publicKey = ECPublicKey(params.G * pk.d!, params);

    // Return uncompressed public key without 0x04 prefix
    final String publicKeyHex = _uint8ListToHex(publicKey.Q!.getEncoded(false));
    return publicKeyHex.substring(2); // Remove 0x04 prefix
  }

  /// Signs a message using ECDSA secp256k1 with a private key.
  ///
  /// Generates a DER-encoded signature that can be verified with the corresponding
  /// public key. Essential for transaction signing and authentication.
  ///
  /// **Parameters:**
  /// - [plainMessage]: Message to sign (will be SHA-256 hashed internally)
  /// - [privateKey]: Private key as hex string (64-66 characters, with or without 0x prefix)
  ///
  /// **Returns:** DER-encoded ECDSA signature as hex string
  ///
  /// **Example:**
  /// ```dart
  /// final privateKey = '1234567890abcdef...';
  /// final message = 'Transaction data to sign';
  /// final signature = api.signMessage(message, privateKey);
  ///
  /// // Use in transaction
  /// final tx = {
  ///   'ID': transactionId,
  ///   'From': senderAddress,
  ///   'To': recipientAddress,
  ///   'Signature': signature,  // DER-encoded
  ///   // ... other fields
  /// };
  /// ```
  ///
  /// **Technical details:**
  /// - Message is SHA-256 hashed before signing
  /// - Uses normalized ECDSA to prevent signature malleability
  /// - Output is DER-encoded (not raw R,S values)
  /// - Signature format complies with Circular Protocol requirements
  ///
  /// **Throws:**
  /// - [Exception] if private key length is invalid (must be 64-66 chars)
  ///
  /// **See also:** [verifySignature], [getPublicKey], [addTransaction]
  String signMessage(String plainMessage, String privateKey) {
    if (privateKey.length < 64) {
      throw Exception("Invalid private key length");
    }
    if (privateKey.length > 66) {
      throw Exception("Invalid private key length");
    }

    final String remove0x = _hexFix(privateKey);

    // Hash the message with SHA256
    final Uint8List msgHash =
        Uint8List.fromList(sha256.convert(utf8.encode(plainMessage)).bytes);

    // Create private key object
    final Uint8List key = Uint8List.fromList(hex.decode(remove0x));
    final ECPrivateKey pk =
        ECPrivateKey(_byteToBigInt(key), ECDomainParameters("secp256k1"));

    // Create and initialize signer
    final ECDSASigner ecdsaSigner = ECDSASigner(null, HMac(SHA256Digest(), 64));
    final NormalizedECDSASigner necdsaSigner = NormalizedECDSASigner(ecdsaSigner);
    necdsaSigner.init(true, PrivateKeyParameter(pk));

    // Generate signature
    final ECSignature signature =
        necdsaSigner.generateSignature(msgHash) as ECSignature;

    // Encode signature to DER format
    final ASN1Sequence seq = ASN1Sequence();
    seq.add(ASN1Integer(signature.r));
    seq.add(ASN1Integer(signature.s));
    final Uint8List derEncodedSignature = seq.encodedBytes;

    // Return hex string
    return hex.encode(derEncodedSignature);
  }

  /// Verifies an ECDSA signature against a public key.
  ///
  /// Checks that the signature was created by the owner of the public key.
  /// Useful for validating transactions and authentication proofs.
  ///
  /// **Parameters:**
  /// - [plainMessage]: Original message that was signed
  /// - [signature]: DER-encoded ECDSA signature (hex string)
  /// - [publicKey]: Public key to verify against (128 hex chars, no 0x04 prefix)
  ///
  /// **Returns:** `true` if signature is valid, `false` otherwise
  ///
  /// **Example:**
  /// ```dart
  /// final message = 'Transaction data';
  /// final signature = '3045022100...';  // DER-encoded from signMessage
  /// final publicKey = 'abc123...';  // 128 hex chars
  ///
  /// final isValid = api.verifySignature(message, signature, publicKey);
  /// if (isValid) {
  ///   print('Signature verified! Message is authentic.');
  /// } else {
  ///   print('Invalid signature or wrong public key.');
  /// }
  /// ```
  ///
  /// **Technical details:**
  /// - Message is SHA-256 hashed (must match hash from signing)
  /// - Decodes DER signature to R,S values
  /// - Public key format: uncompressed without 0x04 prefix
  /// - Returns `false` on any error (invalid format, wrong key, etc.)
  ///
  /// **See also:** [signMessage], [getPublicKey]
  bool verifySignature(String plainMessage, String signature, String publicKey) {
    try {
      // Hash the message with SHA256
      final Uint8List msgHash =
          Uint8List.fromList(sha256.convert(utf8.encode(plainMessage)).bytes);

      // Decode DER signature
      final Uint8List derBytes = Uint8List.fromList(hex.decode(signature));
      final ASN1Parser parser = ASN1Parser(derBytes);
      final ASN1Sequence seq = parser.nextObject() as ASN1Sequence;
      final BigInt r = (seq.elements[0] as ASN1Integer).valueAsBigInteger;
      final BigInt s = (seq.elements[1] as ASN1Integer).valueAsBigInteger;
      final ECSignature ecSignature = ECSignature(r, s);

      // Parse public key (uncompressed format without 0x04 prefix)
      final String publicKeyWithPrefix = '04' + _hexFix(publicKey);
      final Uint8List publicKeyBytes = _hexToBytes(publicKeyWithPrefix);

      // Create public key point
      final ECDomainParameters params = ECDomainParameters('secp256k1');
      final ECPoint? point = params.curve.decodePoint(publicKeyBytes);
      if (point == null) {
        return false;
      }

      final ECPublicKey ecPublicKey = ECPublicKey(point, params);

      // Verify signature
      final ECDSASigner signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
      signer.init(false, PublicKeyParameter(ecPublicKey));

      return signer.verifySignature(msgHash, ecSignature);
    } catch (e) {
      return false;
    }
  }

  /// Generates a complete key set from a seed phrase.
  ///
  /// Derives private key, public key, and wallet address from a seed phrase.
  /// Useful for wallet creation and recovery from mnemonic phrases.
  ///
  /// **Parameters:**
  /// - [seedPhrase]: Seed phrase (any string, typically BIP-39 mnemonic)
  ///
  /// **Returns:** Map containing:
  /// - `publicKey` (String): 128 hex characters (uncompressed, no 0x04 prefix)
  /// - `privateKey` (String): 64 hex characters
  /// - `address` (String): Wallet address (SHA-256 of public key)
  /// - `seed` (String): Normalized seed phrase (spaces joined)
  ///
  /// **Example:**
  /// ```dart
  /// final seedPhrase = 'witch collapse practice feed shame open despair creek road again ice least';
  /// final keys = api.getKeysFromString(seedPhrase);
  ///
  /// print('Public Key: ${keys['publicKey']}');
  /// print('Private Key: ${keys['privateKey']}');
  /// print('Address: ${keys['address']}');
  ///
  /// // Register wallet with generated keys
  /// await api.registerWallet('MainNet', keys['publicKey']!);
  /// ```
  ///
  /// **Security warning:**
  /// - **NEVER** expose private keys in logs or storage
  /// - Use secure storage for private keys (e.g., flutter_secure_storage)
  /// - Seed phrases should be stored securely offline
  ///
  /// **Technical details:**
  /// - Private key = SHA-256 of seed phrase
  /// - Public key derived from private key using secp256k1
  /// - Address = SHA-256 of public key
  /// - Not BIP-32/BIP-44 compliant (simpler derivation)
  ///
  /// **See also:** [getPublicKey], [registerWallet], [signMessage]
  Map<String, String> getKeysFromString(String seedPhrase) {
    final String seed = seedPhrase.split(' ').join(' ');

    // Calculate SHA-256 hash of seed phrase
    final Uint8List seedHash =
        Uint8List.fromList(sha256.convert(utf8.encode(seed)).bytes);

    // Generate private key from secp256k1 curve
    final ECDomainParameters params = ECDomainParameters('secp256k1');
    final ECPrivateKey privateKey = ECPrivateKey(
      BigInt.parse(_uint8ListToHex(seedHash), radix: 16),
      params,
    );

    // Derive public key
    final ECPublicKey publicKey = ECPublicKey(params.G * privateKey.d!, params);

    // Get public key hex (uncompressed, no 0x04 prefix)
    final String publicKeyHex = _uint8ListToHex(publicKey.Q!.getEncoded(false));
    final String publicKeyWithoutPrefix = publicKeyHex.substring(2);
    final String privateKeyHex = _uint8ListToHex(seedHash);

    // Calculate address from public key using SHA-256
    final Uint8List addressHash =
        Uint8List.fromList(sha256.convert(utf8.encode(publicKeyWithoutPrefix)).bytes);

    return {
      'publicKey': publicKeyWithoutPrefix,
      'privateKey': privateKeyHex,
      'address': _uint8ListToHex(addressHash),
      'seed': seed,
    };
  }

  // ============================================================================
  // Helper Methods - Encoding
  // ============================================================================

  /// Normalizes hex strings by removing the '0x' or '0X' prefix if present.
  ///
  /// Useful for cleaning user input or blockchain data before processing.
  ///
  /// **Parameters:**
  /// - [hexString]: Hex string to normalize
  ///
  /// **Returns:** Hex string without '0x' prefix
  ///
  /// **Example:**
  /// ```dart
  /// final normalized1 = api.hexFix('0x1234abcd');
  /// print(normalized1); // '1234abcd'
  ///
  /// final normalized2 = api.hexFix('1234abcd');
  /// print(normalized2); // '1234abcd' (unchanged)
  ///
  /// final normalized3 = api.hexFix('0X5678EF');
  /// print(normalized3); // '5678EF'
  /// ```
  ///
  /// **See also:** [stringToHex], [hexToString]
  String hexFix(String hexString) {
    if (hexString.startsWith('0x') || hexString.startsWith('0X')) {
      return hexString.substring(2);
    }
    return hexString;
  }

  // Private alias for internal use
  String _hexFix(String hexString) => hexFix(hexString);

  /// Converts a string to hex encoding.
  ///
  /// Each character is converted to its hex representation (2 hex digits per character).
  /// Useful for encoding payloads and contract parameters.
  ///
  /// **Parameters:**
  /// - [str]: String to encode
  ///
  /// **Returns:** Hex-encoded string (2x original length)
  ///
  /// **Example:**
  /// ```dart
  /// final hex = api.stringToHex('Hello');
  /// print(hex); // '48656c6c6f'
  ///
  /// final payload = api.stringToHex(jsonEncode({'action': 'transfer', 'amount': 100}));
  /// // Use in transaction
  /// ```
  ///
  /// **See also:** [hexToString], [hexFix]
  String stringToHex(String str) {
    return str.codeUnits.map((c) => c.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Converts hex encoding back to a string.
  ///
  /// Decodes hex-encoded data back to its original string form.
  /// Automatically strips '0x' prefix if present.
  ///
  /// **Parameters:**
  /// - [hexString]: Hex-encoded string (with or without '0x' prefix)
  ///
  /// **Returns:** Decoded string
  ///
  /// **Example:**
  /// ```dart
  /// final decoded = api.hexToString('48656c6c6f');
  /// print(decoded); // 'Hello'
  ///
  /// final withPrefix = api.hexToString('0x48656c6c6f');
  /// print(withPrefix); // 'Hello'
  ///
  /// // Decode transaction payload
  /// final payload = result['Response']['Payload'];
  /// final decodedPayload = api.hexToString(payload);
  /// final data = jsonDecode(decodedPayload);
  /// ```
  ///
  /// **See also:** [stringToHex], [hexFix]
  String hexToString(String hexString) {
    final normalized = _hexFix(hexString);
    final List<int> bytes = [];
    for (int i = 0; i < normalized.length; i += 2) {
      bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
    }
    return String.fromCharCodes(bytes);
  }

  /// Pads a number with a leading zero if it's a single digit.
  ///
  /// Useful for formatting timestamps and other zero-padded values.
  ///
  /// **Parameters:**
  /// - [num]: Number to pad (0-99)
  ///
  /// **Returns:** Padded string ('00'-'99')
  ///
  /// **Example:**
  /// ```dart
  /// print(api.padNumber(5));   // '05'
  /// print(api.padNumber(15));  // '15'
  /// print(api.padNumber(0));   // '00'
  ///
  /// // Used internally for timestamps
  /// final month = api.padNumber(DateTime.now().month);
  /// ```
  ///
  /// **See also:** [getFormattedTimestamp]
  String padNumber(int num) {
    return num < 10 ? '0$num' : num.toString();
  }

  // Private alias for internal use
  String _padNumber(int num) => padNumber(num);

  /// Gets the current UTC timestamp in Circular Protocol format.
  ///
  /// Returns timestamp formatted as `YYYY:MM:DD-HH:mm:ss` in UTC timezone.
  /// This format is required for all blockchain transactions.
  ///
  /// **Returns:** Formatted UTC timestamp string
  ///
  /// **Example:**
  /// ```dart
  /// final timestamp = api.getFormattedTimestamp();
  /// print(timestamp); // '2024:11:15-18:30:45'
  ///
  /// // Use in transaction
  /// final tx = {
  ///   'Timestamp': api.getFormattedTimestamp(),
  ///   'From': senderAddress,
  ///   'To': recipientAddress,
  ///   // ... other fields
  /// };
  /// ```
  ///
  /// **Format details:**
  /// - Uses UTC timezone (not local time)
  /// - Format: `YYYY:MM:DD-HH:mm:ss`
  /// - Zero-padded values (e.g., '05' not '5')
  ///
  /// **See also:** [addTransaction], [registerWallet]
  String getFormattedTimestamp() {
    final now = DateTime.now().toUtc();
    return '${now.year}:${_padNumber(now.month)}:${_padNumber(now.day)}-${_padNumber(now.hour)}:${_padNumber(now.minute)}:${_padNumber(now.second)}';
  }

  // ============================================================================
  // Helper Methods - Advanced
  // ============================================================================

  /// Gets the SDK version string.
  ///
  /// Returns the current version of the Circular Protocol Dart SDK.
  /// Useful for debugging, logging, and ensuring SDK compatibility.
  ///
  /// **Returns:** SDK version string (e.g., '1.0.9')
  ///
  /// **Example:**
  /// ```dart
  /// final version = api.getVersion();
  /// print('Using Circular Protocol Dart SDK v$version');
  ///
  /// // Use in requests
  /// final result = await api.checkWallet({
  ///   'Address': walletAddress,
  ///   'Blockchain': 'MainNet',
  ///   'Version': api.getVersion(),
  /// });
  /// ```
  ///
  /// **See also:** [setNode], [getNagUrl]
  String getVersion() {
    return '1.0.9';
  }

  /// Sets the primary node address for querying the blockchain.
  ///
  /// Updates the NAG endpoint URL used for all API requests. This is an alias
  /// for [setNagUrl] provided for consistency with other SDKs.
  ///
  /// **Parameters:**
  /// - [address]: Node address or NAG endpoint URL
  ///
  /// **Example:**
  /// ```dart
  /// // Set custom node
  /// api.setNode('https://custom-node.example.com/NAG.php?cep=');
  ///
  /// // Switch to testnet
  /// api.setNode('https://testnet.circularlabs.io/NAG.php?cep=');
  ///
  /// // Verify change
  /// print('Current node: ${api.getNagUrl()}');
  /// ```
  ///
  /// **See also:** [setNagUrl], [getNagUrl], [getVersion]
  void setNode(String address) {
    nagUrl = address;
  }

  /// Retrieves the last error message from the SDK.
  ///
  /// Returns the most recent error encountered by helper methods.
  /// Useful for debugging and error reporting.
  ///
  /// **Returns:** Last error message string (empty if no errors)
  ///
  /// **Example:**
  /// ```dart
  /// try {
  ///   await api.getTransactionOutcome('MainNet', txId, '0', '1000');
  /// } catch (e) {
  ///   print('Error: $e');
  ///   print('Last error: ${api.getError()}');
  /// }
  /// ```
  ///
  /// **See also:** [getTransactionOutcome]
  String getError() {
    return _lastError;
  }

  /// Handles errors and stores error messages internally.
  ///
  /// Private method used by helper functions to track errors.
  void _handleError(dynamic error) {
    if (error is Exception) {
      _lastError = error.toString();
    } else if (error is String) {
      _lastError = error;
    } else {
      _lastError = 'Unknown error';
    }
  }

  /// Polls for transaction confirmation with automatic retries.
  ///
  /// Continuously checks if a transaction has been confirmed (included in a block)
  /// until it's found or the timeout is reached. Useful for waiting on transaction
  /// finality before proceeding.
  ///
  /// **Parameters:**
  /// - [blockchain]: Blockchain network (e.g., 'MainNet', 'testnet')
  /// - [txID]: Transaction ID to monitor
  /// - [start]: Start block number for search range
  /// - [end]: End block number for search range
  /// - [timeoutSec]: Maximum time to wait in seconds (default: 120)
  /// - [intervalSec]: Polling interval in seconds (default: 5)
  ///
  /// **Returns:** Transaction response when confirmed (includes BlockNumber)
  ///
  /// **Throws:**
  /// - [Exception] if transaction fails or times out
  ///
  /// **Example:**
  /// ```dart
  /// // Submit transaction
  /// final txResult = await api.sendTransaction(txData);
  /// final txId = txResult['Response']['ID'];
  ///
  /// // Wait for confirmation
  /// try {
  ///   final confirmed = await api.getTransactionOutcome(
  ///     'MainNet',
  ///     txId,
  ///     '0',
  ///     '10000',
  ///     timeoutSec: 60,
  ///     intervalSec: 3,
  ///   );
  ///
  ///   print('Transaction confirmed in block: ${confirmed['Response']['BlockNumber']}');
  /// } catch (e) {
  ///   print('Transaction failed or timed out: $e');
  /// }
  /// ```
  ///
  /// **Behavior:**
  /// - Polls every [intervalSec] seconds
  /// - Checks if transaction has a BlockNumber (confirmed)
  /// - Continues polling while transaction is pending
  /// - Throws exception after [timeoutSec] seconds
  ///
  /// **See also:** [getTransactionById], [sendTransaction]
  Future<Map<String, dynamic>> getTransactionOutcome(
    String blockchain,
    String txID,
    String start,
    String end, {
    int timeoutSec = 120,
    int intervalSec = 5,
  }) async {
  final startTime = DateTime.now();
  final timeout = Duration(seconds: timeoutSec);
  final interval = Duration(seconds: intervalSec);

  while (true) {
    // Check if timeout exceeded
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed >= timeout) {
      final error = 'Transaction $txID timed out after $timeoutSec seconds';
      _handleError(error);
      throw Exception(error);
    }

    try {
      // Check transaction status
      final tx = await getTransactionById({
        'Blockchain': blockchain,
        'ID': txID,
        'Start': start,
        'End': end,
        'Version': '2.0.0-alpha.1',
      });

      // Check if transaction is confirmed (has BlockNumber)
      if (tx['Response'] != null &&
          tx['Response']['BlockNumber'] != null &&
          tx['Response']['BlockNumber'] > 0) {
        // Transaction confirmed
        return tx;
      }

      // Still pending, wait before next check
      await Future.delayed(interval);

    } catch (error) {
      // If error is not just "pending", rethrow
      if (!error.toString().toLowerCase().contains('pending')) {
        _handleError(error);
        rethrow;
      }

      // Otherwise, wait and retry
      await Future.delayed(interval);
    }
  }
}

  /// Close HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown by Circular Protocol API
class CircularAPIException implements Exception {
  /// Error message
  final String message;

  /// HTTP or API status code
  final int statusCode;

  /// Endpoint that caused the error
  final String endpoint;

  /// Constructor
  CircularAPIException(
    this.message, {
    required this.statusCode,
    required this.endpoint,
  });

  @override
  String toString() =>
      'CircularAPIException: $message (endpoint: $endpoint, code: $statusCode)';
}