// lib/services/portfolio_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/portfolio1_model.dart';
import 'auth_service.dart';

class PortfolioService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': token ?? '',
      'Accept': 'application/json',
      'Content-Type': 'multipart/form-data',
    };
  }

  // Get all portfolios
  Future<List<Portfolio>> getPortfolios() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.portfolios}',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Portfolio.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load portfolios');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Get single portfolio
  Future<Portfolio> getPortfolio(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.portfolios}/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Portfolio.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to load portfolio');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Create portfolio
  Future<Portfolio> createPortfolio({
    required String title,
    required String description,
    required File image,
    File? attachment,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
        if (attachment != null)
          'attachment': await MultipartFile.fromFile(
            attachment.path,
            filename: attachment.path.split('/').last,
          ),
      });

      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.portfolios}',
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return Portfolio.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create portfolio');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        String errorMsg = '';
        if (errors != null) {
          errors.forEach((key, value) {
            errorMsg += '$key: ${(value as List).join(', ')}\n';
          });
        }
        throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Validation error');
      }
      throw Exception(_handleError(e));
    }
  }

  // Delete portfolio
  Future<void> deletePortfolio(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.delete(
        '${ApiConfig.baseUrl}${ApiConfig.portfolios}/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete portfolio');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    } else if (e.response?.statusCode == 401) {
      return 'Session expired. Please login again.';
    }
    return e.response?.data['message'] ?? 'An error occurred';
  }
}