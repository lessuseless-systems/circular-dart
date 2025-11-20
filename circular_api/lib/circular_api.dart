///********************************************************************************
///                                                                             ///
///     CIRCULAR LAYER 1 BLOCKCHAIN PROTOCOL INTERFACE LIBRARY                  ///
///     License : Open Source for private and commercial use                    ///
///                                                                             ///
///     CIRCULAR GLOBAL LEDGERS, INC. - USA                                     ///
///                                                                             ///
///                                                                             ///
///     Version : 1.0.9                                                         ///
///     Package : 1.0.2                                                         ///
///                                                                             ///
///     Creation: 16/09/2024                                                    ///
///     Update  : 29/09/2024                                                    ///
///                                                                             ///
///      Originator: Danny De Novi                                              ///
///      Contributors: Gianluca De Novi, PhD                                    ///
///                                                                             ///
///*******************************************************************************///
// ignore_for_file: slash_for_doc_comments

library;

export 'src/circular_api_base.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';
import 'package:intl/intl.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;
import 'package:asn1lib/asn1lib.dart';

class CircularApi {
  // VARIABLES
  String _NAGKEY = '';
  String _NAGURL = 'https://nag.circularlabs.io/NAG.php?cep=';
  final String _version = '1.0.9';
  final String _packageVersion = '1.0.4';

  // SETTERS AND GETTERS

  set nagKey(String key) {
    _NAGKEY = key;
  }

  set nagUrl(String url) {
    _NAGURL = url;
  }

  String get nagKey => _NAGKEY;
  String get nagUrl => _NAGURL;
  String get version => _version;
  String get packageVersion => _packageVersion;

  // HELPER FUNCTIONS

  String hexFix(String hex) {
    return hex.startsWith("0x") ? hex.substring(2) : hex;
  }

  Uint8List _convertToIEEE1363(BigInt rBI, BigInt sBI) {
    return Uint8List.fromList(
        _pad(_bigIntToBytes(rBI)) + _pad(_bigIntToBytes(sBI)));
  }

  List<int> _pad(List<int> data) {
    if (data.length < 32) data = Uint8List(32 - data.length) + data;
    return data;
  }

  String get formattedTimestamp {
    final now = DateTime.now().toUtc();
    final formatter = DateFormat('yyyy:MM:dd-HH:mm:ss');
    return formatter.format(now);
  }

  String _stringToHex(String input) {
    final bytes = utf8.encode(input);
    return hex.encode(bytes);
  }

  String _uint8ListToHex(Uint8List input) {
    return hex.encode(input);
  }

  static Uint8List _bigIntToBytes(BigInt bigInt) {
    return _hexToBytes(bigInt.toRadixString(16).padLeft(32, "0"));
  }

  String _hexToString(String input) {
    final bytes = hex.decode(hexFix(input));
    return utf8.decode(bytes);
  }

  static Uint8List _hexToBytes(String hex) {
    return Uint8List.fromList(HEX.decode(hex));
  }

  static BigInt _decodeBigInt(List<int> bytes) {
    BigInt result = BigInt.from(0);
    for (int i = 0; i < bytes.length; i++) {
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    return result;
  }

  static BigInt _byteToBigInt(Uint8List bigIntBytes) {
    return _decodeBigInt(bigIntBytes);
  }

  // ERROR THROWING FUNCTIONS

  void _throwError(String message) {
    throw Exception(message);
  }

  // MESSAGE SIGNING FUNCTIONS

  /// # signMessage()
  /// ## Sign a message with a private key
  /// **plainMessage** The message to sign <br>
  /// **privateKey** The private key to sign the message with <br>
  /// **return** The signature of the message in hex format
  ///
  String signMessage(String plainMessage, String privateKey) {
    if (privateKey.length < 64) {
      _throwError("Invalid private key length");
    }

    if (privateKey.length > 66) {
      _throwError("Invalid private key length");
    }

    String remove0x = hexFix(privateKey);

    // Hash the message to sign with SHA256
    Uint8List msgHash =
        sha256.convert(utf8.encode(plainMessage)).bytes as Uint8List;

    // Create a private key object from the private key string provided
    Uint8List key = Uint8List.fromList(hex.decode(remove0x));
    ECPrivateKey pk =
        ECPrivateKey(_byteToBigInt(key), ECDomainParameters("secp256k1"));

    // Create a signer object and initialize with the private key object
    ECDSASigner ecdsaSigner = ECDSASigner(null, HMac(SHA256Digest(), 64));

    // Normalize the signer object because with the normalization the signature will be deterministic and can be verified by other libraries
    NormalizedECDSASigner necdsaSigner = NormalizedECDSASigner(ecdsaSigner);

    // Initialize the signer object with the private key
    necdsaSigner.init(true, PrivateKeyParameter(pk));

    // Generate the signature
    ECSignature signature =
        necdsaSigner.generateSignature(msgHash) as ECSignature;

    // Encode the signature to DER format
    ASN1Sequence seq = ASN1Sequence();
    seq.add(ASN1Integer(signature.r));
    seq.add(ASN1Integer(signature.s));
    Uint8List derEncodedSignature = seq.encodedBytes;

    // Convert the DER-encoded signature to a hex string
    String hexSignature = hex.encode(derEncodedSignature);

    // Return the hex string
    return hexSignature;
  }

  /// # getKeysFromString()
  /// ## Generate a public key, private key and address from a seed phrase
  /// **seedPhrase** The seed phrase to generate the keys from <br>
  /// **return** A map containing the public key, private key, address and seed phrase
  Map<String, String> getKeysFromString(String seedPhrase) {
    final String seed = seedPhrase.split(' ').join(' ');

    // Calculate the SHA-256 hash of the seed phrase
    final Uint8List seedHash =
        sha256.convert(utf8.encode(seed)).bytes as Uint8List;

    // Use PointyCastle to generate a private key from the secp256k1 curve
    final ECDomainParameters params = ECDomainParameters('secp256k1');
    final ECPrivateKey privateKey = ECPrivateKey(
        BigInt.parse(_uint8ListToHex(seedHash), radix: 16), params);

    // Obtain the public key from the private key
    final ECPublicKey publicKey = ECPublicKey(params.G * privateKey.d!, params);

    // Convert the public key to a compressed format (PKCS1)
    final String publicKeyHex = _uint8ListToHex(publicKey.Q!.getEncoded(false));
    final String privateKeyHex = _uint8ListToHex(seedHash);

    // Calculate the address from the public key using SHA-256
    final Uint8List addressHash =
        sha256.convert(utf8.encode(publicKeyHex)).bytes as Uint8List;

    return {
      'publicKey': publicKeyHex,
      'privateKey': privateKeyHex,
      'address': _uint8ListToHex(addressHash),
      'seedPhrase': seedPhrase
    };
  }

  /// # getKeysFromListOfStrings()
  /// ## Generate a public key, private key and address from a list of strings
  /// **seedPhrase** The list of strings to generate the keys from <br>
  /// **return** A map containing the public key, private key, address and seed phrase
  Map<String, String> getKeysFromListOfStrings(List<String> seedPhrase) {
    final String seed = seedPhrase.join(' ');

    return getKeysFromString(seed);
  }

  /// # verifySignature()
  /// ## Verify a signature with a public key
  /// **publicKey** The public key to verify the signature with <br>
  /// **message** The message to verify <br>
  /// **signature** The signature to verify <br>
  /// **return** True if the signature is valid, false otherwise
  ///
  bool verifySignature(String publicKey, String message, String signature) {
    if (publicKey.length != 130) {
      _throwError("Invalid public key length");
    }

    // Remove the 0x prefix from the public key
    String remove0x = hexFix(publicKey);

    // Hash the message to verify with SHA256
    Uint8List msgHash = sha256.convert(utf8.encode(message)).bytes as Uint8List;

    // Create a public key object from the public key string provided
    Uint8List key = Uint8List.fromList(hex.decode(remove0x));

    // Create a public key object from the public key string provided and the domain parameters of the secp256k1 curve
    ECPublicKey pk = ECPublicKey(
        ECDomainParameters("secp256k1").curve.decodePoint(key) as ECPoint,
        ECDomainParameters("secp256k1"));

    // Create a signer object and initialize with the public key object
    ECDSASigner ecdsaSigner = ECDSASigner(null, HMac(SHA256Digest(), 64));
    NormalizedECDSASigner necdsaSigner = NormalizedECDSASigner(ecdsaSigner);
    necdsaSigner.init(false, PublicKeyParameter(pk));

    // Decode the signature from hex to bytes
    Uint8List signatureBytes = Uint8List.fromList(hex.decode(signature));

    // Decode the signature from DER format
    ASN1Sequence seq = ASN1Sequence.fromBytes(signatureBytes);
    ECSignature ecsignature = ECSignature(
        (seq.elements[0] as ASN1Integer).valueAsBigInteger,
        (seq.elements[1] as ASN1Integer).valueAsBigInteger);

    // Verify the signature
    return necdsaSigner.verifySignature(msgHash, ecsignature);
  }

  /// # getPublicKey()
  /// ## Get the public key from a private key
  /// **privateKey** The private key to get the public key from <br>
  /// **return** The public key in hex format
  ///
  String getPublicKey(String privateKey) {
    if (privateKey.length < 64) {
      _throwError("Invalid private key length");
    }

    if (privateKey.length > 66) {
      _throwError("Invalid private key length");
    }

    // Remove the 0x prefix from the private key
    String remove0x = hexFix(privateKey);

    // Decode the private key from hex to bytes
    Uint8List key = Uint8List.fromList(hex.decode(remove0x));

    // Create a domain parameter object with the secp256k1 curve
    final domainParams = ECDomainParameters('secp256k1');
    final privateKeyBigInt = _byteToBigInt(key);
    final ecPrivateKey = ECPrivateKey(privateKeyBigInt, domainParams);

    // Create a public key object from the private key object
    final ecPublicKey =
        ECPublicKey(domainParams.G * ecPrivateKey.d, domainParams);

    // Convert the public key to hex format and return it
    return _uint8ListToHex(ecPublicKey.Q!.getEncoded(false));
  }

  // WALLET FUNCTIONS

  /// # checkWallet()
  /// ## Check if a wallet exists on a blockchain
  /// **blockchain** The blockchain to check the wallet on <br>
  /// **address** The address of the wallet to check <br>
  /// **return** A map containing the response from the API
  ///
  Future<Map<String, dynamic>> checkWallet(
      String blockchain, String address) async {
    final url = Uri.parse('${_NAGURL}Circular_CheckWallet_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "Address": hexFix(address),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getWallet()
  /// ## Get a wallet from a blockchain
  /// **blockchain** The blockchain to get the wallet from <br>
  /// **address** The address of the wallet to get <br>
  /// **return** A map containing the response from the API
  ///
  Future<Map<String, dynamic>> getWallet(
      String blockchain, String address) async {
    final url = Uri.parse('${_NAGURL}Circular_GetWallet_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "Address": hexFix(address),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getLatestTransaction()
  /// ## Get the latest transaction for a wallet on a blockchain <br>
  /// **blockchain** The blockchain to get the latest transaction from <br>
  /// **address** The address of the wallet to get the latest transaction for <br>
  /// **return** A map containing the response from the API
  ///
  Future<Map<String, dynamic>> getLatestTransaction(
      String blockchain, String address) async {
    final url = Uri.parse('${_NAGURL}Circular_GetLatestTransactions_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "Address": hexFix(address),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getWalletBalance()
  /// ## Get the balance of a wallet on a blockchain
  /// **blockchain** The blockchain to get the balance from <br>
  /// **address** The address of the wallet to get the balance for <br>
  /// **asset** The asset to get the balance for <br>
  /// **return** A map containing the filtered response from the API
  ///
  Future<dynamic> getWalletBalance(
      String blockchain, String address, String asset) async {
    final url = Uri.parse('${_NAGURL}Circular_GetWalletBalance_');

    if (asset.isEmpty) {
      asset = 'CIRX';
    }

    final data = {
      "Blockchain": hexFix(blockchain),
      "Address": hexFix(address),
      "Asset": asset,
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getWalletNonce()
  /// ## Get the nonce of a wallet on a blockchain
  /// **blockchain** The blockchain to get the nonce from <br>
  /// **address** The address of the wallet to get the nonce for <br>
  /// **return** The nonce of the wallet
  ///
  Future<dynamic> getWalletNonce(String blockchain, String address) async {
    final url = Uri.parse('${_NAGURL}Circular_GetWalletNonce_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "Address": hexFix(address),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  // SMART CONTRACT FUNCTIONS

  /// # testContract()
  /// ## Test a contract on a blockchain
  /// **blockchain** The blockchain to test the contract on <br>
  /// **from** The address of the contract's owner (developer) <br>
  /// **project** The address of the project to test the contract for <br>
  /// **return** A map containing the response from the API
  Future<Map<String, dynamic>> testContract(
      String blockchain, String from, String project) async {
    final url = Uri.parse('${_NAGURL}Circular_TestContract_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "From": hexFix(from),
      "Timestamp": formattedTimestamp,
      "Project": _stringToHex(project),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # callContract()
  /// ## Call a contract on a blockchain sending a function request
  /// **blockchain** The blockchain to call the contract on <br>
  /// **from** The address of the contract's owner (developer) <br>
  /// **project** The address of the project to call the contract for <br>
  /// **request** The request to send to the contract <br>
  /// **return** A map containing the response from the API
  ///
  Future<Map<String, dynamic>> callContract(
      String blockchain, String from, String project, String request) async {
    final url = Uri.parse('${_NAGURL}Circular_CallContract_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "From": hexFix(from),
      "Address": hexFix(project),
      "Request": _stringToHex(request),
      "Timestamp": formattedTimestamp,
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # callContractWithPlainConsoleOutput()
  /// ## Call a contract on a blockchain and return the console output
  /// **blockchain** The blockchain to call the contract on <br>
  /// **from** The address of the contract's owner (developer) <br>
  /// **project** The address of the project to call the contract for <br>
  /// **request** The request to send to the contract <br>
  /// **return** The console output of the contract

  Future<dynamic> callContractWithPlainConsoleOutput(
      String blockchain, String from, String project, String request) async {
    final url = Uri.parse('${_NAGURL}Circular_CallContract_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "From": hexFix(from),
      "Address": hexFix(project),
      "Request": _stringToHex(request),
      "Timestamp": formattedTimestamp,
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    final decodedResponse = jsonDecode(response.body)["Response"];
    final output = _hexToString(
        jsonDecode(_hexToString(decodedResponse))["_Console_Output"]);

    return output;
  }

  /// # registerWallet()
  ///  ##  Register a wallet on a desired blockchain. The same wallet can be registered on multiple blockchains.
  /// **blockchain** The blockchain to register the wallet on <br>
  /// **publicKey** The public key of the wallet to register <br>
  /// **return** The response from the transaction <br>

  Future<dynamic> registerWallet(String blockchain, String publicKey) async {
    final from = sha256.convert(utf8.encode(hexFix(publicKey))).toString();
    final to = from;
    final nonce = 0;
    final type = "C_TYPE_REGISTERWALLET";
    final payloadObj = {
      "Action": "CP_REGISTERWALLET",
      "PublicKey": hexFix(publicKey),
    };
    final jsonStr = jsonEncode(payloadObj);
    final payload = _stringToHex(jsonStr);
    final timestamp = formattedTimestamp;
    final signature = "";
    final ID = sha256
        .convert(utf8.encode(hexFix(blockchain) +
            from +
            to +
            payload +
            nonce.toString() +
            signature +
            timestamp))
        .toString();

    return await sendTransaction(
        ID, from, to, timestamp, type, payload, nonce, signature, blockchain);
  }

  // DOMAIN MANAGEMENT FUNCTIONS

  /// # getDomain()
  /// ## Get the domain from a blockchain
  /// **blockchain** The blockchain to get the domain from <br>
  /// **name** The name of the domain to get <br>
  /// **return** The domain from the blockchain <br>
  ///
  Future<dynamic> getDomain(String blockchain, String name) async {
    final url = Uri.parse('${_NAGURL}Circular_ResolveDomain_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "Domain": name,
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  // PARAMETRIC ASSETS MANAGEMENT FUNCTIONS

  /// # getAssetList()
  /// ## Get the list of assets from a blockchain
  /// **blockchain** The blockchain to get the asset list from <br>
  /// **return** The list of assets from the blockchain
  ///
  Future<dynamic> getAssetList(String blockchain) async {
    final url = Uri.parse('${_NAGURL}Circular_GetAssetList_');

    final data = {"Blockchain": hexFix(blockchain), "Version": _version};

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /** # getAsset()
  * ## Get an asset from a blockchain
  * **blockchain** The blockchain to get the asset from <br>
  * **name** The name of the asset to get <br>
  * **return** The asset from the blockchain <br>

  ```dart
  final circular = CircularApi();
  final blockchain = '0x8a20baa40c45dc5055aeb26197c203e576ef389d9acb171bd62da11dc5ad72b2';
  final asset = await circular.getAsset(blockchain, 'cirx');
  ```
  **/
  Future<dynamic> getAsset(String blockchain, String name) async {
    final url = Uri.parse('${_NAGURL}Circular_GetAsset_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "AssetName": name,
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getAssetSupply()
  /// ## Get the supply of an asset from a blockchain
  /// **blockchain** The blockchain to get the asset supply from <br>
  /// **name** The name of the asset to get the supply for <br>
  /// **return** The supply of the asset from the blockchain
  ///
  Future<dynamic> getAssetSupply(String blockchain, String name) async {
    final url = Uri.parse('${_NAGURL}Circular_GetAssetSupply_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "AssetName": name,
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  // VOUCHERSW MANAGEMENT FUNCTIONS

  /// # getVoucher()
  /// ## Get a voucher from a blockchain
  /// **blockchain** The blockchain to get the voucher from <br>
  /// **code** The code of the voucher to get <br>
  /// **return** The voucher from the blockchain
  ///
  Future<dynamic> getVoucher(String blockchain, int code) async {
    final url = Uri.parse('${_NAGURL}Circular_GetVoucher_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "AssetName": code.toString(),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  // BLOCKS MANAGEMENT FUNCTIONS

  /// # getBlockRange()
  /// ## Retrieve all blocks in a specified range
  /// **blockchain** The blockchain to get the block range from <br>
  /// **start** The start block number <br>
  /// **end** The end block number <br>
  /// **return** The range of blocks from the blockchain <br>
  /// If End = 0, then Start is the number of blocks from the last one minted going backward.
  ///
  Future<dynamic> getBlockRange(String blockchain, int start, int end) async {
    final url = Uri.parse('${_NAGURL}Circular_GetBlockRange_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "Start": start.toString(),
      "End": end.toString(),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getBlock()
  /// ## Get a block from a blockchain
  /// **blockchain** The blockchain to get the block from <br>
  /// **blockNumber** The number of the block to get <br>
  /// **return** The block from the blockchain
  ///
  Future<dynamic> getBlock(String blockchain, int blockNumber) async {
    final url = Uri.parse('${_NAGURL}Circular_GetBlock_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "BlockNumber": blockNumber.toString(),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getBlockCount()
  /// ## Retrieves the blockchain block height
  /// **blockchain** The blockchain to get the block count from <br>
  /// **return** The block count from the blockchain
  ///
  Future<dynamic> getBlockCount(String blockchain) async {
    final url = Uri.parse('${_NAGURL}Circular_GetBlockHeight_');

    final data = {"Blockchain": hexFix(blockchain), "Version": _version};

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  // ANALYTICS FUNCTIONS

  /// # getAnalytics()
  /// ## Get analytics data from a blockchain
  /// **blockchain** The blockchain to get the analytics data from <br>
  /// **return** The analytics data from the blockchain
  ///
  Future<dynamic> getAnalytics(String blockchain) async {
    final url = Uri.parse('${_NAGURL}Circular_GetAnalytics_');

    final data = {"Blockchain": hexFix(blockchain), "Version": _version};

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getBlockchains()
  /// ## Get the list of blockchains
  /// **return** The list of blockchains
  ///
  Future<dynamic> getBlockchains() async {
    final url = Uri.parse('${_NAGURL}Circular_GetBlockchains_');

    final data = {};

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  // TRANSACTIONS MANAGEMENT FUNCTIONS

  /// # getPendingTransaction()
  ///  ## Searches a transaction by ID between the pending transactions <br>
  /// **blockchain** The blockchain to get the transaction from <br>
  /// **TxID** The ID of the transaction to get <br>
  /// **return** The transaction from the blockchain
  Future<dynamic> getPendingTransaction(String blockchain, String TxID) async {
    final url = Uri.parse('${_NAGURL}Circular_GetPendingTransaction_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "ID": hexFix(TxID),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getTransactionByID()
  /// ## Searches a Transaction by its ID. The transaction will be searched initially between the pending transactions and then in the blockchain
  /// **blockchain** The blockchain to get the transaction from <br>
  /// **TxID** The ID of the transaction to get <br>
  /// **start** The start block number <br>
  /// **end** The end block number <br>
  /// **return** The transaction from the blockchain <br>
  ///

  Future<dynamic> getTransactionByID(
      String blockchain, String TxID, int start, int end) async {
    final url = Uri.parse('${_NAGURL}Circular_GetTransactionbyID_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "ID": hexFix(TxID),
      "Start": start.toString(),
      "End": end.toString(),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getTransactionByNode()
  /// ## Searches all transactions broadcasted by a specified node
  /// **blockchain** The blockchain to get the transaction from <br>
  /// **nodeID** The ID of the node to get the transactions from <br>
  /// **start** The start block number <br>
  /// **end** The end block number <br>
  /// **return** The transaction from the blockchain <br>
  ///
  Future<dynamic> getTransactionByNode(
      String blockchain, String nodeID, int start, int end) async {
    final url = Uri.parse('${_NAGURL}Circular_GetTransactionbyNode_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "NodeID": hexFix(nodeID),
      "Start": start.toString(),
      "End": end.toString(),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getTransactionByAddress()
  /// ## Searches all transactions broadcasted or received by a specified address <br>
  /// **blockchain** The blockchain to get the transaction from <br>
  /// **address** The address to get the transactions from <br>
  /// **start** The start block number <br>
  /// **end** The end block number <br>
  /// **return** The transaction from the blockchain <br>
  ///
  Future<dynamic> getTransactionByAddress(
      String blockchain, String address, int start, int end) async {
    final url = Uri.parse('${_NAGURL}Circular_GetTransactionbyAddress_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "Address": hexFix(address),
      "Start": start.toString(),
      "End": end.toString(),
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # getTransactionByDate()
  /// ## Searches all transactions broadcasted or received by a specified address in a specified timeframe <br>
  /// **blockchain** The blockchain to get the transaction from <br>
  /// **address** The address to get the transactions from <br>
  /// **startDate** The start date of the transactions <br>
  /// **endDate** The end date of the transactions <br>
  /// **return** The transaction from the blockchain <br>
  ///
  Future<dynamic> getTransactionByDate(String blockchain, String address,
      String startDate, String endDate) async {
    final url = Uri.parse('${_NAGURL}Circular_GetTransactionbyDate_');

    final data = {
      "Blockchain": hexFix(blockchain),
      "Address": hexFix(address),
      "StartDate": startDate,
      "EndDate": endDate,
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }

  /// # sendTransaction()
  /// ## Send a transaction to a blockchain <br>
  /// **id** The ID of the transaction <br>
  /// **from** The address of the sender <br>
  /// **to** The address of the receiver <br>
  /// **timestamp** The timestamp of the transaction <br>
  /// **type** The type of the transaction <br>
  /// **payload** The payload of the transaction in hex format <br>
  /// **nonce** The nonce of the transaction <br>
  /// **signature** The signature of the transaction in hex format <br>
  /// **blockchain** The blockchain to send the transaction to <br>
  /// **return** The response from the API
  ///
  Future<dynamic> sendTransaction(
      String id,
      String from,
      String to,
      String timestamp,
      String type,
      String payload,
      int nonce,
      String signature,
      String blockchain) async {
    final url = Uri.parse('${_NAGURL}Circular_AddTransaction_');

    final hashedPayload = _stringToHex(jsonEncode(payload));

    final data = {
      "ID": hexFix(id),
      "From": hexFix(from),
      "To": hexFix(to),
      "Timestamp": timestamp,
      "Payload": hexFix(hashedPayload),
      "Nonce": nonce.toString(),
      "Signature": hexFix(signature),
      "Blockchain": hexFix(blockchain),
      "Type": type,
      "Version": _version
    };

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Network response was not ok'};
      }
    }

    return jsonDecode(response.body);
  }
}
