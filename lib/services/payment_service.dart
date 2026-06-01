// lib/services/payment_service.dart
// ============================================================================
// PAYMENT SERVICE - Handle all payment-related API calls
// ============================================================================

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';

class PaymentService {
  final AuthService _auth = AuthService();
  
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();
  
  // ==========================================================================
  // PAYMENT INVOICE
  // ==========================================================================
  
  /// Create payment invoice for a project
  /// Returns: { success, data, is_existing, message }
  Future<Map<String, dynamic>> createPaymentInvoice(String projectId) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createPaymentInvoice(projectId)}'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'is_existing': data['is_existing'] ?? false,
          'message': data['message'],
        };
      }
      
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to create payment invoice',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }
  
  // ==========================================================================
  // PAYMENT PROOF UPLOAD
  // ==========================================================================
  
  /// Upload payment proof (image or PDF)
  /// Parameters:
  ///   - projectId: ID of the project
  ///   - proofFile: File (image or PDF)
  ///   - paymentMethod: virtual_account, transfer, e-wallet, other
  ///   - paymentDate: DateTime when payment was made
  ///   - notes: Optional notes from UMKM
  Future<Map<String, dynamic>> uploadPaymentProof({
    required String projectId,
    required File proofFile,
    required String paymentMethod,
    required DateTime paymentDate,
    String? notes,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      
      // Determine media type for the file
      final extension = proofFile.path.split('.').last.toLowerCase();
      final contentType = _getContentType(extension);
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.uploadPaymentProof(projectId)}'),
      );
      
      request.headers['Authorization'] = token;
      request.headers['Accept'] = 'application/json';
      
      // Add file
      var fileStream = http.ByteStream(proofFile.openRead());
      var fileLength = await proofFile.length();
      var multipartFile = http.MultipartFile(
        'proof_file',
        fileStream,
        fileLength,
        filename: proofFile.path.split('/').last,
        contentType: MediaType(contentType['type']!, contentType['subtype']!),
      );
      request.files.add(multipartFile);
      
      // Add fields
      request.fields['payment_method'] = paymentMethod;
      request.fields['payment_date'] = paymentDate.toIso8601String();
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }
      
      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      }
      
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to upload payment proof',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }
  
  // ==========================================================================
  // PAYMENT STATUS
  // ==========================================================================
  
  /// Check payment status for a project
  /// Returns: { success, has_payment, data, status_info, message }
  Future<Map<String, dynamic>> checkPaymentStatus(String projectId) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkPaymentStatus(projectId)}'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'has_payment': data['has_payment'] ?? false,
          'data': data['data'],
          'status_info': data['status_info'],
          'message': data['message'],
        };
      }
      
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to check payment status',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }
  
  // ==========================================================================
  // PAYMENT DETAIL
  // ==========================================================================
  
  /// Get detailed payment information
  Future<Map<String, dynamic>> getPaymentDetail(String paymentId) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.paymentDetail(paymentId)}'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      }
      
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get payment detail',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }
  
  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================
  
  /// Get content type for file extension
  Map<String, String> _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return {'type': 'image', 'subtype': 'jpeg'};
      case 'png':
        return {'type': 'image', 'subtype': 'png'};
      case 'gif':
        return {'type': 'image', 'subtype': 'gif'};
      case 'pdf':
        return {'type': 'application', 'subtype': 'pdf'};
      default:
        return {'type': 'application', 'subtype': 'octet-stream'};
    }
  }
  
  /// Handle API errors
  String _handleError(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'Tidak ada koneksi internet';
    } else if (e.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Silakan coba lagi';
    } else if (e.toString().contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server';
    }
    return e.toString();
  }
  
  // ==========================================================================
  // PAYMENT STATUS HELPER
  // ==========================================================================
  
  /// Get human-readable payment status label
  static String getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'paid':
        return 'Menunggu Verifikasi Admin';
      case 'failed':
        return 'Verifikasi Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
  
  /// Get status color
  static int getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return 0xFFFF9800; // Orange
      case 'paid':
        return 0xFF2196F3; // Blue
      case 'failed':
        return 0xFFF44336; // Red
      case 'cancelled':
        return 0xFF9E9E9E; // Grey
      default:
        return 0xFF1A4B84; // Primary blue
    }
  }
  
  /// Get status icon data
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'paid':
        return Icons.upload_file;
      case 'failed':
        return Icons.error_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.payment;
    }
  }
  
  /// Check if payment can be uploaded
  static bool canUploadProof(String status) {
    return status == 'pending';
  }
  
  /// Check if payment is awaiting verification
  static bool isAwaitingVerification(String status) {
    return status == 'paid';
  }
  
  /// Check if payment is verified
  static bool isVerified(PaymentData? payment) {
    return payment?.verifiedAt != null && payment?.status == 'paid';
  }
}

// ==========================================================================
// PAYMENT DATA MODEL
// ==========================================================================

class PaymentData {
  final String id;
  final String paymentNumber;
  final String projectId;
  final String? projectTitle;
  final int amount;
  final String amountFormatted;
  final int platformFee;
  final String platformFeeFormatted;
  final int netAmount;
  final String netAmountFormatted;
  final String status;
  final String statusLabel;
  final String? virtualAccountBank;
  final String? virtualAccountNumber;
  final DateTime? paymentDueAt;
  final DateTime? paymentDate;
  final String? proofFileUrl;
  final String? notesFromUmkm;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  
  PaymentData({
    required this.id,
    required this.paymentNumber,
    required this.projectId,
    this.projectTitle,
    required this.amount,
    required this.amountFormatted,
    required this.platformFee,
    required this.platformFeeFormatted,
    required this.netAmount,
    required this.netAmountFormatted,
    required this.status,
    required this.statusLabel,
    this.virtualAccountBank,
    this.virtualAccountNumber,
    this.paymentDueAt,
    this.paymentDate,
    this.proofFileUrl,
    this.notesFromUmkm,
    this.verifiedAt,
    this.rejectionReason,
    this.createdAt,
  });
  
  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['id'] ?? '',
      paymentNumber: json['payment_number'] ?? '',
      projectId: json['project_id'] ?? '',
      projectTitle: json['project_title'],
      amount: json['amount'] ?? 0,
      amountFormatted: json['amount_formatted'] ?? 'Rp 0',
      platformFee: json['platform_fee'] ?? 0,
      platformFeeFormatted: json['platform_fee_formatted'] ?? 'Rp 0',
      netAmount: json['net_amount'] ?? 0,
      netAmountFormatted: json['net_amount_formatted'] ?? 'Rp 0',
      status: json['status'] ?? 'pending',
      statusLabel: json['status_label'] ?? 'Menunggu Pembayaran',
      virtualAccountBank: json['virtual_account_bank'],
      virtualAccountNumber: json['virtual_account_number'],
      paymentDueAt: json['payment_due_at'] != null 
          ? DateTime.parse(json['payment_due_at']) 
          : null,
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : null,
      proofFileUrl: json['proof_file_url'],
      notesFromUmkm: json['notes_from_umkm'],
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }
  
  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
  bool get isVerified => verifiedAt != null;
  bool get canUploadProof => isPending;
  bool get isAwaitingVerification => isPaid && !isVerified;
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_number': paymentNumber,
      'project_id': projectId,
      'project_title': projectTitle,
      'amount': amount,
      'amount_formatted': amountFormatted,
      'platform_fee': platformFee,
      'platform_fee_formatted': platformFeeFormatted,
      'net_amount': netAmount,
      'net_amount_formatted': netAmountFormatted,
      'status': status,
      'status_label': statusLabel,
      'virtual_account_bank': virtualAccountBank,
      'virtual_account_number': virtualAccountNumber,
      'payment_due_at': paymentDueAt?.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'proof_file_url': proofFileUrl,
      'notes_from_umkm': notesFromUmkm,
      'verified_at': verifiedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

// Required imports for Icons
