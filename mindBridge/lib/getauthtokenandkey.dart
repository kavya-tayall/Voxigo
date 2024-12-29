import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:typed_data';

class ApiService {
  String baseUrl;
  String hmacSecret;
  String authToken;

  // Private constructor for singleton
  ApiService._privateConstructor({
    required this.baseUrl,
    required this.hmacSecret,
    required this.authToken,
  });

  // Singleton instance
  static final ApiService _instance = ApiService._privateConstructor(
    baseUrl: 'https://us-central1-voxigo.cloudfunctions.net/app',
    hmacSecret: 'default-hmac-secret',
    authToken: 'default-auth-token',
  );

  // Getter for the instance
  static ApiService get instance => _instance;

  // Factory constructor to initialize the singleton with remote config
  static Future<ApiService> initialize() async {
    final configValues = await fetchRemoteConfig();
    _instance.baseUrl = "https://us-central1-voxigo.cloudfunctions.net/app";
    _instance.hmacSecret = configValues['hmac_secret'] ?? 'default-hmac-secret';
    _instance.authToken = configValues['auth_token'] ?? 'default-auth-token';
    return _instance;
  }

  /// Method to generate HMAC signature for the request body
  String generateHMACSignature(Map<String, dynamic> body) {
    final payload = jsonEncode(body);
    final hmac = Hmac(sha256, utf8.encode(hmacSecret));
    final digest = hmac.convert(utf8.encode(payload));
    return digest.toString();
  }

  /// Method to make a POST request with common headers
  Future<http.Response> _post(String endpoint, Map<String, dynamic> body,
      {String? hmacSignature}) async {
    final url = Uri.parse("$baseUrl/$endpoint");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $authToken",
      if (hmacSignature != null) "x-signature": hmacSignature,
    };
    try {
      return await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      log("HTTP Request failed: $e");
      throw Exception("Failed to make POST request: $e");
    }
  }

  Future<Uint8List> getEncryptionKeyfromVault(
      Map<String, dynamic> requestBody) async {
    final signature = generateHMACSignature(requestBody);

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response =
            await _post("getKey", requestBody, hmacSignature: signature);

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData.containsKey('key')) {
            return base64Decode(responseData['key']);
          } else {
            throw Exception("Key not found in the response body.");
          }
        } else {
          log("Failed to get encryption key: ${response.body}");
          throw Exception(
              "Error: ${response.statusCode} - ${response.reasonPhrase}");
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          log("Error in getEncryptionKey after $maxRetries attempts: $e");
          throw Exception(
              "Failed to retrieve encryption key after retries: $e");
        }
      }
    }

    throw Exception("Unexpected error in getEncryptionKey.");
  }

  /// Method to get Firebase token for a given UID
  Future<String> getFirebaseToken(String uid) async {
    final requestBody = {
      "uid": uid,
    };

    try {
      final response = await _post("generateToken", requestBody);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("token generate success ${responseData['token']}");

        return responseData[
            'token']; // Assuming the Firebase token is returned as "token"
      } else {
        log("Failed to get Firebase token: ${response.body}");
        throw Exception(
            "Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      log("Error in getFirebaseToken: $e");
      throw Exception("Failed to retrieve Firebase token: $e");
    }
  }

  void dispose() {
    baseUrl = '';
    hmacSecret = '';
    authToken = '';
    log('ApiService disposed');
  }
}

/// Function to fetch Firebase remote config
Future<Map<String, String>> fetchRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;

  try {
    await remoteConfig.setDefaults(<String, dynamic>{
      'hmac_secret': 'default-hmac-secret',
      'auth_token': 'default-auth-token',
    });

    await remoteConfig.fetchAndActivate();

    final hmacSecret = remoteConfig.getString('hmac_secret');
    final authToken = remoteConfig.getString('auth_token');

    return {
      'hmac_secret': hmacSecret,
      'auth_token': authToken,
    };
  } catch (e) {
    throw Exception('Error fetching remote config: $e');
  }
}

enum UserType {
  parent,
  child,
}

class UserSession {
  String? uid; // User ID
  Uint8List? secureKey; // Secure Key
  UserType? userType; // User Type

  // Private constructor
  UserSession._privateConstructor();

  // Static instance of the class
  static final UserSession _instance = UserSession._privateConstructor();

  // Getter to access the singleton instance
  static UserSession get instance => _instance;

  // Method to initialize or update the fields
  void initialize({
    required String uid,
    required Uint8List secureKey,
    required UserType userType,
  }) {
    this.uid = uid;
    this.secureKey = secureKey;
    this.userType = userType;
  }

  // Method to clear the session (e.g., during logout)
  void clear() {
    uid = null;
    secureKey = null;
    userType = null;
  }

  void dispose() {
    clear();
    log('UserSession disposed');
  }

  @override
  String toString() {
    return 'UserSession(uid: $uid, secureKey: $secureKey, userType: $userType)';
  }
}
