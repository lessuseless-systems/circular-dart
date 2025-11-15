/// Circular Protocol Dart SDK
/// Official Dart SDK for the Circular Protocol blockchain API
/// Version: 1.0.8
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
///   'Version': '1.0.8',
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
    Map<String, dynamic> data,
  ) async {
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
          .timeout(timeout);

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
/// Check if wallet exists
/// Checks whether a wallet address exists on the specified blockchain.
/// Returns existence status and confirms the address format.
Future<Map<String, dynamic>> checkWallet(Map<String, dynamic> request) async {
  return _makeRequest('CheckWallet', request);
}
/// Get wallet information
/// Retrieves complete wallet information including balance and nonce.
/// Returns all wallet properties including current state on the blockchain.
Future<Map<String, dynamic>> getWallet(Map<String, dynamic> request) async {
  return _makeRequest('GetWallet', request);
}
/// Get latest transactions for wallet
/// Retrieves the latest transactions for a wallet address.
/// Returns an array of transaction objects with details.
Future<Map<String, dynamic>> getLatestTransactions(Map<String, dynamic> request) async {
  return _makeRequest('GetLatestTransactions', request);
}
/// Get wallet balance for specific asset
/// Retrieves the balance of a specified asset in a wallet.
/// Returns the balance amount for the requested asset.
Future<Map<String, dynamic>> getWalletBalance(Map<String, dynamic> request) async {
  return _makeRequest('GetWalletBalance', request);
}
/// Get wallet nonce
/// Retrieves the nonce (transaction counter) of a wallet.
/// The nonce is used for transaction ordering and must increment with each transaction.
Future<Map<String, dynamic>> getWalletNonce(Map<String, dynamic> request) async {
  return _makeRequest('GetWalletNonce', request);
}
/// Submit transaction to blockchain
/// Submits a transaction to the blockchain. Requires a complete signed transaction
/// including ID, addresses, payload, nonce, and signature.
Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> request) async {
  return _makeRequest('AddTransaction', request);
}
/// Get pending transaction by ID
/// Searches for a transaction by ID among pending transactions.
/// Returns the transaction if it exists and is still pending.
Future<Map<String, dynamic>> getPendingTransaction(Map<String, dynamic> request) async {
  return _makeRequest('GetPendingTransaction', request);
}
/// Find transaction by ID
/// Finds a transaction by ID within a specified block range.
/// Searches through blocks to locate the transaction.
Future<Map<String, dynamic>> getTransactionbyID(Map<String, dynamic> request) async {
  return _makeRequest('GetTransactionbyID', request);
}
/// Find transactions by node ID
/// Finds transactions by node ID within a specified block range.
/// Returns all transactions associated with the node.
Future<Map<String, dynamic>> getTransactionbyNode(Map<String, dynamic> request) async {
  return _makeRequest('GetTransactionbyNode', request);
}
/// Find transactions by address
/// Finds transactions by wallet address within a specified block range.
/// Returns transactions where the address is sender or recipient.
Future<Map<String, dynamic>> getTransactionbyAddress(Map<String, dynamic> request) async {
  return _makeRequest('GetTransactionbyAddress', request);
}
/// Find transactions by date range
/// Finds transactions by wallet address within a specified date range.
/// Returns all transactions for the address between the dates.
Future<Map<String, dynamic>> getTransactionbyDate(Map<String, dynamic> request) async {
  return _makeRequest('GetTransactionbyDate', request);
}
/// Get specific block
/// Retrieves a desired block by block number.
/// Returns complete block information including transactions and hash.
Future<Map<String, dynamic>> getBlock(Map<String, dynamic> request) async {
  return _makeRequest('GetBlock', request);
}
/// Get range of blocks
/// Retrieves all blocks in a specified range.
/// If End = 0, then Start is the number of blocks from the last one minted going backward.
Future<Map<String, dynamic>> getBlockRange(Map<String, dynamic> request) async {
  return _makeRequest('GetBlockRange', request);
}
/// Get blockchain height
/// Retrieves the blockchain block height (total number of blocks).
/// Also known as getBlockHeight in some documentation.
Future<Map<String, dynamic>> getBlockCount(Map<String, dynamic> request) async {
  return _makeRequest('GetBlockCount', request);
}
/// Get blockchain analytics
/// Retrieves blockchain analytics and statistics.
/// Returns comprehensive information about the blockchain state.
Future<Map<String, dynamic>> getAnalytics(Map<String, dynamic> request) async {
  return _makeRequest('GetAnalytics', request);
}
/// Test smart contract execution
/// Tests smart contract execution locally without sending a transaction.
/// Useful for testing contract logic before deploying or executing.
Future<Map<String, dynamic>> testContract(Map<String, dynamic> request) async {
  return _makeRequest('TestContract', request);
}
/// Call smart contract function
/// Calls a smart contract function on the blockchain.
/// Executes the specified function with provided parameters.
Future<Map<String, dynamic>> callContract(Map<String, dynamic> request) async {
  return _makeRequest('CallContract', request);
}
/// List all assets on blockchain
/// Retrieves the list of all assets minted on a specific blockchain.
/// Returns an array of asset information.
Future<Map<String, dynamic>> getAssetList(Map<String, dynamic> request) async {
  return _makeRequest('GetAssetList', request);
}
/// Get specific asset information
/// Retrieves an asset descriptor with complete asset information.
/// Returns detailed information about the specified asset.
Future<Map<String, dynamic>> getAsset(Map<String, dynamic> request) async {
  return _makeRequest('GetAsset', request);
}
/// Get asset supply information
/// Retrieves the total, circulating, and residual supply of a specified asset.
/// Returns comprehensive supply metrics.
Future<Map<String, dynamic>> getAssetSupply(Map<String, dynamic> request) async {
  return _makeRequest('GetAssetSupply', request);
}
/// Retrieve voucher information
/// Retrieves an existing voucher by code.
/// Code is automatically stripped of 0x prefix if present.
Future<Map<String, dynamic>> getVoucher(Map<String, dynamic> request) async {
  return _makeRequest('GetVoucher', request);
}
/// Resolve domain to wallet address
/// Resolves a domain name to a wallet address.
/// A single wallet can have multiple domain associations.
/// Also known as resolveDomain.
Future<Map<String, dynamic>> getDomain(Map<String, dynamic> request) async {
  return _makeRequest('GetDomain', request);
}
/// List available blockchains
/// Retrieves the list of blockchains available in the network.
/// Returns information about all active and inactive blockchains.
Future<Map<String, dynamic>> getBlockchains(Map<String, dynamic> request) async {
  return _makeRequest('GetBlockchains', request);
}

  // ============================================================================
  // Convenience Methods
  // ============================================================================
  // These methods wrap underlying API calls to simplify common workflows

/// Register wallet on blockchain (Convenience Method)
/// Registers a wallet on the specified blockchain by creating and sending
a C_TYPE_REGISTERWALLET transaction. This convenience method handles all
transaction construction internally:

- Derives From/To addresses from public key (sha256)
- Builds Payload: hex(JSON.stringify({Action: "CP_REGISTERWALLET", PublicKey: publicKey}))
- Calculates transaction ID: sha256(blockchain + from + to + payload + nonce + timestamp)
- Sets Nonce to "0" and Signature to "" (empty for registration)
- Calls sendTransaction with constructed parameters

Without registration, the wallet will not be reachable on the blockchain.
The same wallet can be registered on multiple blockchains.
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
    'Version': '1.0.8',
  };

  // Call sendTransaction
  return sendTransaction(request);
}

  // ============================================================================
  // Cryptographic Helper Functions
  // ============================================================================

  /// Get formatted UTC timestamp in Circular Protocol format
  /// Returns timestamp as "YYYY:MM:DD-HH:mm:ss"
  String getFormattedTimestamp() {
    final now = DateTime.now().toUtc();
    final formatter = DateFormat('yyyy:MM:dd-HH:mm:ss');
    return formatter.format(now);
  }

  /// Remove "0x" prefix from hex string if present
  String _hexFix(String hex) {
    return hex.startsWith("0x") ? hex.substring(2) : hex;
  }

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

  /// Hash a string using SHA256
  /// Returns hex-encoded hash
  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return _uint8ListToHex(Uint8List.fromList(digest.bytes));
  }

  /// Get public key from private key
  /// Returns uncompressed public key (128 hex characters, no 0x04 prefix)
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

  /// Sign a message with a private key
  /// Returns DER-encoded ECDSA signature as hex string
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

  /// Generate keys from seed phrase
  /// Returns map with publicKey, privateKey, address, and seed
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

/// Normalize hex strings (remove 0x prefix if present)
String _hexFix(String hexString) {
  if (hexString.startsWith('0x') || hexString.startsWith('0X')) {
    return hexString.substring(2);
  }
  return hexString;
}

/// Convert string to hex encoding
String stringToHex(String str) {
  return str.codeUnits.map((c) => c.toRadixString(16).padLeft(2, '0')).join();
}

/// Convert hex encoding to string
String hexToString(String hexString) {
  final normalized = _hexFix(hexString);
  final List<int> bytes = [];
  for (int i = 0; i < normalized.length; i += 2) {
    bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
  }
  return String.fromCharCodes(bytes);
}

/// Pad number with leading zero if single digit
String _padNumber(int num) {
  return num < 10 ? '0$num' : num.toString();
}

/// Get current timestamp in Circular Protocol format
/// Format: YYYY:MM:DD-hh:mm:ss (UTC)
String getFormattedTimestamp() {
  final now = DateTime.now().toUtc();
  return '${now.year}:${_padNumber(now.month)}:${_padNumber(now.day)}-${_padNumber(now.hour)}:${_padNumber(now.minute)}:${_padNumber(now.second)}';
}

  // ============================================================================
  // Helper Methods - Advanced
  // ============================================================================

/// Get last error message
String getError() {
  return _lastError;
}

/// Handle error and store error message
void _handleError(dynamic error) {
  if (error is Exception) {
    _lastError = error.toString();
  } else if (error is String) {
    _lastError = error;
  } else {
    _lastError = 'Unknown error';
  }
}

/// Poll for transaction confirmation
///
/// [blockchain] Blockchain network (e.g., 'MainNet', 'testnet')
/// [txID] Transaction ID to monitor
/// [start] Start block number for search
/// [end] End block number for search
/// [timeoutSec] Maximum time to wait in seconds (default: 120)
/// [intervalSec] Polling interval in seconds (default: 5)
///
/// Returns: Transaction response when confirmed
/// Throws: Exception if transaction fails or times out
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
      final tx = await getTransactionbyID({
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