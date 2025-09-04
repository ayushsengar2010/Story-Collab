// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class AuthService {
  static const String _baseUrl = 'http://18.232.150.66:8080';
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token_v2';
  static const String _userIdKey = 'user_id_v2';

  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    if (kDebugMode) {
      print("AuthService: Saved token.");
    }
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (kDebugMode) {
      print(
          "AuthService: Retrieved token: ${token != null ? 'exists' : 'null'}");
    }
    return token;
  }

  Future<void> _saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
    if (kDebugMode) {
      print("AuthService: Saved User ID: $userId");
    }
  }

  Future<String?> getCurrentUserId() async {
    final userId = await _storage.read(key: _userIdKey);
    if (kDebugMode) {
      print("AuthService: Retrieved User ID: $userId");
    }
    return userId;
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    if (kDebugMode) {
      print("AuthService: Logged out, token and User ID cleared.");
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final userId = await getCurrentUserId();
    return token != null &&
        token.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty;
  }

  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    String bio = "A passionate writer and storyteller.",
    String profileImage = "",
    String location = "",
    String website = "",
  }) async {
    final String url = '$_baseUrl/signup';
    final Map<String, String> requestBody = {
      "name": name,
      "bio": bio,
      "email": email,
      "password": password,
      "profile_image": profileImage,
      "location": location,
      "website": website,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(requestBody),
      );
      final responseData = jsonDecode(response.body);

      if (kDebugMode) {
        print("AuthService: Signup response: $responseData");
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ??
              'Account created successfully! Please login.'
        };
      } else {
        String errorMessage = responseData['message'] ??
            responseData['error'] ??
            'Signup failed.';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      if (kDebugMode) {
        print("AuthService: Signup error: ${e.toString()}");
      }
      return {
        'success': false,
        'message': 'An error occurred during signup: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final String url = '$_baseUrl/login';
    final Map<String, String> requestBody = {
      "email": email,
      "password": password
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(requestBody),
      );
      final responseData = jsonDecode(response.body);

      if (kDebugMode) {
        print("AuthService: Login response: $responseData");
      }

      if (response.statusCode == 200) {
        String? token;
        String? userId;

        if (responseData is Map) {
          token = responseData['token'] as String?;
          dynamic userDataSource = responseData['user'] ?? responseData['data'];
          if (userDataSource is Map) {
            if (userDataSource.containsKey('user') &&
                userDataSource['user'] is Map) {
              final nestedUserMap =
                  userDataSource['user'] as Map<String, dynamic>;
              userId = (nestedUserMap['ID'] ??
                      nestedUserMap['id'] ??
                      nestedUserMap['user_id'])
                  ?.toString();
            } else {
              userId = (userDataSource['ID'] ??
                      userDataSource['id'] ??
                      userDataSource['user_id'])
                  ?.toString();
            }
          }
          userId ??= (responseData['ID'] ??
                  responseData['id'] ??
                  responseData['user_id'] ??
                  responseData['UserID'])
              ?.toString();

          // Fallback: Extract userId from JWT token if not found in response body
          if (userId == null && token != null) {
            userId = _extractUserIdFromToken(token);
          }
        }

        if (token != null && token.isNotEmpty) {
          await _saveToken(token);
          if (userId != null && userId.isNotEmpty) {
            await _saveUserId(userId);
            if (kDebugMode) {
              print(
                  "AuthService: Successfully saved token and user ID: $userId");
            }
            return {
              'success': true,
              'token': token,
              'userId': userId,
              'data': responseData,
              'message': responseData['message'] ?? 'Login successful!'
            };
          } else {
            if (kDebugMode) {
              print(
                  "AuthService Warning: User ID not found in response or JWT token. Response: $responseData");
            }
            return {
              'success': false,
              'message': 'Login successful, but user ID not found.'
            };
          }
        } else {
          return {
            'success': false,
            'message': responseData['message'] ??
                'Login successful, but token not found.'
          };
        }
      } else {
        String errorMessage =
            responseData['message'] ?? responseData['error'] ?? 'Login failed.';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      if (kDebugMode) {
        print("AuthService: Login error: ${e.toString()}");
      }
      return {
        'success': false,
        'message': 'An error occurred during login: ${e.toString()}'
      };
    }
  }

  // Extract user ID from JWT token payload
  String? _extractUserIdFromToken(String token) {
    try {
      // JWT format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        if (kDebugMode) {
          print("AuthService: Invalid JWT token format");
        }
        return null;
      }
      // Decode payload (base64url encoded)
      final payload = parts[1];
      // Add padding to make it base64 compatible
      final normalizedPayload =
          payload.padRight((payload.length + 3) & ~3, '=');
      final decodedPayload = base64Url.decode(normalizedPayload);
      final payloadMap = jsonDecode(utf8.decode(decodedPayload));
      final userId = payloadMap['userid']?.toString();
      if (kDebugMode && userId != null) {
        print("AuthService: Extracted user ID from JWT: $userId");
      }
      return userId;
    } catch (e) {
      if (kDebugMode) {
        print("AuthService: Error decoding JWT token: $e");
      }
      return null;
    }
  }
}
