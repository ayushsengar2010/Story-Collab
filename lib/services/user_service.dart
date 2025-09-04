// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:collabwrite/services/auth_service.dart';

import '../data/models/author_model.dart'; // To get token

class UserService {
  static const String _baseUrl = 'http://18.232.150.66:8080';
  final AuthService _authService = AuthService(); // For token access

  // Helper to get headers, optionally with auth token
  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (requireAuth) {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] =
            'Bearer $token'; // Adjust if your API uses a different auth scheme
      } else if (requireAuth) {
        // Optionally throw an error if auth is required but no token is found
        // throw Exception('Authentication token not found for a protected route.');
        print(
            'Warning: Auth token not found for a route that might require it.');
      }
    }
    return headers;
  }

  // 1. Get Author by ID
  Future<Author> getAuthorById(String authorId) async {
    final String url = '$_baseUrl/GetAuthor/$authorId';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers:
            await _getHeaders(), // Assuming public, set requireAuth: true if needed
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Author.fromJson(responseData);
      } else {
        throw Exception(
            'Failed to load author (ID: $authorId). Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching author (ID: $authorId): ${e.toString()}');
    }
  }

  // 2. Get All Authors
  Future<List<Author>> getAllAuthors() async {
    final String url = '$_baseUrl/GetAuthors';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(), // Assuming public
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((data) => Author.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to load authors. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching authors: ${e.toString()}');
    }
  }

  // 3. Delete Author
  // API URL: /deleteauthor/user_3. 'authorId' here should be the numeric part (e.g., "3").
  Future<bool> deleteAuthor(String authorNumericId) async {
    final String url = '$_baseUrl/deleteauthor/user_$authorNumericId';
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: await _getHeaders(
            requireAuth: true), // Deletion typically requires authentication
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content is also success for DELETE
        return true;
      } else {
        // Attempt to parse error message from response body
        String errorMessage =
            'Failed to delete author (ID: $authorNumericId). Status: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map &&
              (errorData.containsKey('message') ||
                  errorData.containsKey('error'))) {
            errorMessage += ': ${errorData['message'] ?? errorData['error']}';
          } else {
            errorMessage += ': ${response.body}';
          }
        } catch (_) {
          errorMessage +=
              ': ${response.body}'; // Fallback if body isn't JSON or doesn't have expected keys
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(
          'Error deleting author (ID: $authorNumericId): ${e.toString()}');
    }
  }
}
