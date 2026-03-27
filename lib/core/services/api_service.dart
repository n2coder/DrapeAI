import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:style_ai/core/constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiService {
  final String _baseUrl = AppConstants.apiBaseUrl;
  final http.Client _client;
  final _secureStorage = const FlutterSecureStorage();

  /// Called when a 401 response is received so the app can force a sign-out.
  final Future<void> Function()? onUnauthorized;

  ApiService({http.Client? client, this.onUnauthorized})
      : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    return _secureStorage.read(key: AppConstants.jwtTokenKey);
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Clear stored JWT and notify the app to move to unauthenticated state.
      await _secureStorage.delete(key: AppConstants.jwtTokenKey);
      await _secureStorage.delete(key: AppConstants.userIdKey);
      if (onUnauthorized != null) {
        await onUnauthorized!();
      }
      throw const ApiException('Session expired. Please sign in again.', statusCode: 401);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded['detail'] ?? decoded['message'] ?? 'Unknown error';
    throw ApiException(message.toString(), statusCode: response.statusCode);
  }

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) {
    return _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw const ApiException('Request timed out. Please check your connection.');
    });
  }

  Future<http.Response> _post(Uri uri, {Map<String, String>? headers, Object? body}) {
    return _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw const ApiException('Request timed out. Please check your connection.');
    });
  }

  Future<http.Response> _put(Uri uri, {Map<String, String>? headers, Object? body}) {
    return _client
        .put(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw const ApiException('Request timed out. Please check your connection.');
    });
  }

  Future<http.Response> _delete(Uri uri, {Map<String, String>? headers}) {
    return _client
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw const ApiException('Request timed out. Please check your connection.');
    });
  }

  // ─── Auth endpoints ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final headers = await _buildHeaders(requiresAuth: false);
    final response = await _post(
      Uri.parse('$_baseUrl/auth/send-otp'),
      headers: headers,
      body: jsonEncode({'phone_number': phoneNumber}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String firebaseToken,
  }) async {
    final headers = await _buildHeaders(requiresAuth: false);
    final response = await _post(
      Uri.parse('$_baseUrl/auth/verify-otp'),
      headers: headers,
      body: jsonEncode({
        'firebase_id_token': firebaseToken,
      }),
    );
    final result = await _handleResponse(response);
    return result['data'] as Map<String, dynamic>? ?? result;
  }

  Future<void> logout() async {
    final headers = await _buildHeaders();
    await _post(
      Uri.parse('$_baseUrl/auth/logout'),
      headers: headers,
    );
    await _secureStorage.delete(key: AppConstants.jwtTokenKey);
    await _secureStorage.delete(key: AppConstants.userIdKey);
  }

  // ─── User profile endpoints ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserProfile() async {
    final headers = await _buildHeaders();
    final response = await _get(
      Uri.parse('$_baseUrl/users/profile'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    final headers = await _buildHeaders();
    final response = await _put(
      Uri.parse('$_baseUrl/users/profile'),
      headers: headers,
      body: jsonEncode(profileData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> completeOnboarding({
    required String gender,
    required String ageRange,
    required String city,
    required List<String> stylePreferences,
  }) async {
    final headers = await _buildHeaders();
    final response = await _post(
      Uri.parse('$_baseUrl/users/onboarding'),
      headers: headers,
      body: jsonEncode({
        'gender': gender.toLowerCase().replaceAll(' ', '_'),
        'age_range': ageRange,
        'city': city,
        'style_preferences': stylePreferences.map((s) => s.toLowerCase()).toList(),
      }),
    );
    return _handleResponse(response);
  }

  // ─── Wardrobe endpoints ────────────────────────────────────────────────────

  Future<List<dynamic>> getWardrobeItems() async {
    final headers = await _buildHeaders();
    final response = await _get(
      Uri.parse('$_baseUrl/wardrobe/list'),
      headers: headers,
    );
    final result = await _handleResponse(response);
    return result['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> addClothingItem({
    required String category,
    required String color,
    required String style,
    required String imageUrl,
    String? brand,
    String? notes,
  }) async {
    final headers = await _buildHeaders();
    final response = await _post(
      Uri.parse('$_baseUrl/wardrobe/add'),
      headers: headers,
      body: jsonEncode({
        // Normalize to lowercase + underscores to match backend enums
        'category': category.toLowerCase().replaceAll(' ', '_'),
        'color': color.toLowerCase(),
        'style': style.toLowerCase(),
        'image_url': imageUrl,
        if (brand != null) 'brand': brand,
        if (notes != null) 'notes': notes,
      }),
    );
    final result = await _handleResponse(response);
    return result['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> updateClothingItem({
    required String itemId,
    required Map<String, dynamic> updates,
  }) async {
    final headers = await _buildHeaders();
    // Normalize enum fields to lowercase+underscores to match backend enums
    final normalized = Map<String, dynamic>.from(updates);
    if (normalized.containsKey('category')) {
      normalized['category'] =
          (normalized['category'] as String).toLowerCase().replaceAll(' ', '_');
    }
    if (normalized.containsKey('color')) {
      normalized['color'] = (normalized['color'] as String).toLowerCase();
    }
    if (normalized.containsKey('style')) {
      normalized['style'] = (normalized['style'] as String).toLowerCase();
    }
    final response = await _put(
      Uri.parse('$_baseUrl/wardrobe/$itemId'),
      headers: headers,
      body: jsonEncode(normalized),
    );
    final result = await _handleResponse(response);
    return result['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> deleteClothingItem(String itemId) async {
    final headers = await _buildHeaders();
    final response = await _delete(
      Uri.parse('$_baseUrl/wardrobe/$itemId'),
      headers: headers,
    );
    if (response.statusCode == 401) {
      await _handleResponse(response);
    } else if (response.statusCode != 200 && response.statusCode != 204) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final message = decoded['detail'] ?? 'Failed to delete item';
      throw ApiException(message.toString(), statusCode: response.statusCode);
    }
  }

  // ─── Recommendation endpoints ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getTodayRecommendation() async {
    final headers = await _buildHeaders();
    final response = await _get(
      Uri.parse('$_baseUrl/recommendations/today'),
      headers: headers,
    );
    final result = await _handleResponse(response);
    return result['data'] as Map<String, dynamic>? ?? result;
  }

  Future<Map<String, dynamic>> getRecommendationByOccasion({
    required String occasion,
    String? weatherContext,
  }) async {
    final headers = await _buildHeaders();
    final response = await _post(
      Uri.parse('$_baseUrl/recommendations/custom'),
      headers: headers,
      body: jsonEncode({
        'occasion': occasion.toLowerCase(),
        'use_current_weather': weatherContext != null,
      }),
    );
    final result = await _handleResponse(response);
    return result['data'] as Map<String, dynamic>? ?? result;
  }

  Future<void> saveRecommendation(String recId) async {
    final headers = await _buildHeaders();
    final response = await _post(
      Uri.parse('$_baseUrl/recommendations/$recId/save'),
      headers: headers,
    );
    await _handleResponse(response);
  }

  Future<List<dynamic>> getSavedOutfits() async {
    final headers = await _buildHeaders();
    final response = await _get(
      Uri.parse('$_baseUrl/recommendations/saved'),
      headers: headers,
    );
    final result = await _handleResponse(response);
    return result['data'] as List<dynamic>? ?? [];
  }

  // ─── Image upload ──────────────────────────────────────────────────────────

  Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    final streamedResponse = await _client.send(request).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw const ApiException('Image upload timed out. Please try again.');
      },
    );
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawUrl = data['secure_url'] as String? ?? '';
      if (rawUrl.isEmpty) {
        throw const ApiException('Image upload failed: no URL returned.');
      }
      // Store a thumbnail URL in the database — Cloudinary serves
      // a small 400×500 image on-the-fly; the original stays on Cloudinary
      // but is never referenced directly in MongoDB.
      return _thumbnailUrl(rawUrl);
    }
    final errBody = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    final errMsg = errBody['error']?['message'] as String? ?? 'Failed to upload image (${response.statusCode})';
    throw ApiException(errMsg);
  }

  /// Injects Cloudinary thumbnail transforms into a secure URL so that
  /// what gets stored in MongoDB always points to a small image (~15–30 KB).
  static String _thumbnailUrl(String url) {
    if (!url.contains('res.cloudinary.com')) return url;
    return url.replaceFirst(
      '/upload/',
      '/upload/w_400,h_500,c_fill,q_70,f_auto/',
    );
  }

  void dispose() {
    _client.close();
  }
}
