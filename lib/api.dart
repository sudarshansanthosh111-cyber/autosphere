import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Api {
  static const _configuredBaseUrl = String.fromEnvironment(
    'AUTOSPHERE_API_BASE_URL',
  );
  static http.Client _client = http.Client();
  static const _timeout = Duration(seconds: 15);

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  @visibleForTesting
  static void useHttpClient(http.Client client) => _client = client;

  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
  }) => _post('/users/', {'email': email, 'password': password});

  static Future<Map<String, dynamic>> getUser(String userId) =>
      _getObject('/users/${Uri.encodeComponent(userId)}');

  static Future<Map<String, dynamic>> createVehicle({
    required String userId,
    required String make,
    required String model,
    required int year,
    required int currentMileage,
  }) => _post('/users/${Uri.encodeComponent(userId)}/vehicles/', {
    'make': make,
    'model': model,
    'year': year,
    'current_mileage': currentMileage,
  });

  static Future<Map<String, dynamic>> createMaintenance({
    required String vehicleId,
    required String serviceDate,
    required String serviceType,
    required double cost,
    required int mileageAtService,
    String? notes,
  }) => _post('/vehicles/${Uri.encodeComponent(vehicleId)}/maintenance/', {
    'service_date': serviceDate,
    'service_type': serviceType,
    'cost': cost,
    'mileage_at_service': mileageAtService,
    'notes': notes,
  });

  static Future<List<Map<String, dynamic>>> getMaintenance(
    String vehicleId,
  ) async {
    final response = await _client
        .get(_uri('/vehicles/${Uri.encodeComponent(vehicleId)}/maintenance/'))
        .timeout(_timeout);
    final decoded = _decode(response);
    if (decoded is! List) {
      throw const ApiException(
        'The backend returned an invalid maintenance list.',
      );
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getPrediction(String vehicleId) =>
      _getObject(
        '/vehicles/${Uri.encodeComponent(vehicleId)}/predict-maintenance/',
      );

  static Future<Map<String, dynamic>> healthCheck() => _getObject('/');

  static Future<Map<String, dynamic>> _getObject(String path) async {
    final response = await _client.get(_uri(path)).timeout(_timeout);
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('The backend returned an invalid response.');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client
        .post(
          _uri(path),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('The backend returned an invalid response.');
    }
    return decoded;
  }

  static Object? _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      decoded = response.body;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;
      throw ApiException(
        message ?? 'Backend request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  static Uri _uri(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path');
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
