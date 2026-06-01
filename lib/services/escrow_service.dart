// lib/services/escrow_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/escrow_model.dart';
import '../services/auth_service.dart';

class EscrowService {
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> getEscrowTransactions() async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/creative/escrow'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> escrowsData = data['data'];
        final escrows = escrowsData.map((json) => EscrowTransaction.fromJson(json)).toList();
        return {
          'success': true,
          'escrows': escrows,
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to load escrows'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> getEarnings() async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/creative/earnings'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'earnings': EarningsSummary.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to load earnings'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  String _handleError(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'Tidak ada koneksi internet';
    } else if (e.toString().contains('TimeoutException')) {
      return 'Koneksi timeout';
    }
    return e.toString();
  }
}