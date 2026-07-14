import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_constants.dart';
import '../models/match_result.dart';
import '../models/scan_result.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Handles profile, scanning, and matching API calls.
class ProfileService {
  static final _client = ApiClient.instance;

  /// Fetch the current user's profile from the API.
  static Future<User?> fetchProfile() async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me');
    final token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Upload a profile photo. Returns the photo's URL on success, else null.
  static Future<String?> uploadPhoto(
    Uint8List bytes,
    String fileName, {
    String? mimeType,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/photos');
    final token = await AuthService.getToken();
    if (token == null) return null;

    final parts = (mimeType ?? 'image/jpeg').split('/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: MediaType(parts.first, parts.length > 1 ? parts[1] : 'jpeg'),
    ));

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch the current user's photos: a list of { id, url, is_primary }.
  static Future<List<Map<String, dynamic>>> fetchPhotos() async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/photos');
    final token = await AuthService.getToken();
    if (token == null) return [];
    try {
      final response = await _client.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Delete one of the user's photos by id. Returns `true` on success.
  static Future<bool> deletePhoto(String id) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/photos/$id');
    final token = await AuthService.getToken();
    if (token == null) return false;
    try {
      final response = await _client.delete(url, headers: {'Authorization': 'Bearer $token'});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Save the user's dating profile (Phase 1): date of birth (18+), gender,
  /// seeking, and bio. Returns `true` on success.
  static Future<bool> updateDatingProfile({
    required String dateOfBirth, // ISO yyyy-MM-dd
    required String gender,
    required String seeking,
    String? bio,
    String? city,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/dating-profile');
    final token = await AuthService.getToken();
    if (token == null) return false;
    try {
      final response = await _client.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'date_of_birth': dateOfBirth,
          'gender': gender,
          'seeking': seeking,
          if (bio != null && bio.isNotEmpty) 'bio': bio,
          if (city != null && city.isNotEmpty) 'city': city,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Permanently delete the current user's account and all associated data
  /// (right to erasure). Returns `true` on success.
  static Future<bool> deleteAccount() async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me');
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await _client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Upload a medical report image for OCR scanning.
  static Future<ScanResult?> scanReport(
      Uint8List fileBytes, String fileName) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/scan-report');
    final token = await AuthService.getToken();

    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ScanResult.fromJson(
            data['detected_data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save genotype, blood group, and optionally rhesus factor to the user's profile.
  static Future<bool> updateProfile(
    String genotype,
    String bloodGroup, {
    String? rhesus,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/profile');
    final token = await AuthService.getToken();
    if (token == null) return false;

    final body = <String, dynamic>{
      'genotype': genotype,
      'blood_group': bloodGroup,
    };
    if (rhesus != null) body['rhesus_factor'] = rhesus;

    try {
      final response = await _client.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Check genetic compatibility between the authenticated user's saved profile
  /// and a partner's profile. Returns a typed [MatchResult].
  ///
  /// [userSex] determines which role the authenticated user takes in the
  /// rhesus factor check ('male' = father, 'female' = mother).
  /// The authenticated user's profile is always fetched from the database
  /// server-side — it is never submitted in the request body.
  static Future<MatchResult> checkMatch({
    required String userSex,
    required Map<String, dynamic> partnerProfile,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/check-match');
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_sex': userSex,
        'partner_profile': partnerProfile,
      }),
    );

    if (response.statusCode == 200) {
      return MatchResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['detail'] ?? 'Your profile is incomplete');
    } else {
      throw Exception(
          'Failed to check compatibility (${response.statusCode})');
    }
  }
}
