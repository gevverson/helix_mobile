import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import '../models/scan_result.dart';
import '../models/user.dart';
import 'auth_service.dart';

/// Handles profile, scanning, and matching API calls.
class ProfileService {
  /// Fetch the current user's profile from the API.
  static Future<User?> fetchProfile() async {
    final url = Uri.parse('${AppConstants.baseUrl}/users/me');
    final token = await AuthService.getToken();

    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload a medical report image for OCR scanning.
  /// Returns a [ScanResult] on success, or `null` on failure.
  static Future<ScanResult?> scanReport(Uint8List fileBytes, String fileName) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/v1/scan-report');
    final token = await AuthService.getToken();
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final detected = data['detected_data'] as Map<String, dynamic>;
        return ScanResult.fromJson(detected);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save genotype and blood group to the authenticated user's profile.
  static Future<bool> updateProfile(String genotype, String bloodGroup) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/profile');
    final token = await AuthService.getToken();

    if (token == null) return false;

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'genotype': genotype,
          'blood_group': bloodGroup,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check genetic compatibility between two profiles.
  static Future<Map<String, dynamic>> checkMatch(
    Map<String, dynamic> male,
    Map<String, dynamic> female,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/check-match');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'male_profile': male,
        'female_profile': female,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to check match');
    }
  }
}
