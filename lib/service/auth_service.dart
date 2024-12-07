import 'dart:convert';
import 'package:eisenhower_matrix/service/token_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String? baseUrl = dotenv.env['BASE_URL'];
  final TokenService _tokenService = TokenService();

  Future<void> initiateSignUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/initiate-signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to initiate signup: ${response.body}');
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/users/verify-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to verify OTP: ${response.body}');
    }

    final responseData = jsonDecode(response.body);;
    String accessToken = responseData['token'];

    // Store the token
    await _tokenService.storeToken(accessToken);
  }

  Future<void> resendOtp({required String email}) async {
    final url = Uri.parse('$baseUrl/users/resend-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to resend OTP: ${response.body}');
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );


    if (response.statusCode != 201 && response.statusCode != 401) {
      final errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['message'] ?? 'An error occurred during login');
    }

    if (response.statusCode == 401) {
      final errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['message'] ?? 'Invalid email or password');
    }

    final responseData = jsonDecode(response.body);
    String accessToken = responseData['accessToken'];

    // Store the token
    await _tokenService.storeToken(accessToken);
    return responseData['message'] ?? 'Login successful';
  }

  Future<void> logout() async {
    final token = await _tokenService.getToken();

    if (token == null) {
      throw Exception('No token found');
    }

    final url = Uri.parse('$baseUrl/users/logout');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 201) {
      final errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['message'] ?? 'Logout failed');
    }


    await _tokenService.removeToken();
  }
}
