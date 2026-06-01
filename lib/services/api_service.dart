// lib/services/api_service.dart
// ============================================================================
// API SERVICE - Centralized API calls using ApiConfig
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _auth = AuthService();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, dynamic>> _requestWithAuth(
    Future<http.Response> Function(String token) requestFn, {
    bool isRetry = false,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi tidak ditemukan, silakan login kembali'};
      }

      var response = await requestFn(token);

      if (response.statusCode == 401 && !isRetry) {
        final refreshResult = await _auth.refreshToken();
        if (refreshResult['success'] == true) {
          return await _requestWithAuth(requestFn, isRetry: true);
        } else {
          return {'success': false, 'message': 'Sesi berakhir, silakan login kembali'};
        }
      }

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Success',
        };
      }

      String errorMsg = data['message'] ?? 'Terjadi kesalahan';
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors[errors.keys.first];
          if (firstError is List && firstError.isNotEmpty) {
            errorMsg = firstError.first;
          }
        }
      }
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> _multipartRequestWithAuth(
    Future<http.MultipartRequest> Function(String token) requestBuilder, {
    bool isRetry = false,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi tidak ditemukan. Silakan login kembali.'};
      }

      var request = await requestBuilder(token);
      request.headers['Authorization'] = token;
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && !isRetry) {
        final refreshResult = await _auth.refreshToken();
        if (refreshResult['success'] == true) {
          return await _multipartRequestWithAuth(requestBuilder, isRetry: true);
        } else {
          await _auth.logout();
          return {'success': false, 'message': 'Sesi berakhir, silakan login kembali'};
        }
      }

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Success',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AUTH ENDPOINTS
  // ───────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    return _auth.login(email, password);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    return _auth.register(
      type: payload['type'],
      name: payload['name'],
      email: payload['email'],
      password: payload['password'],
      passwordConfirmation: payload['password_confirmation'],
      phone: payload['phone'],
      city: payload['city'],
      bankName: payload['bank_name'],
      bankAccountNumber: payload['bank_account_number'],
      bankAccountName: payload['bank_account_name'],
      creativeCategory: payload['creative_category'],
    );
  }

  Future<Map<String, dynamic>> logout() async {
    return _auth.logout();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DASHBOARD
  // ───────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUMKMDashboard() async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmDashboard}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> getCreativeDashboard() async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.creativeDashboard}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROJECTS - UMKM
  // ───────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUmkmProjects() async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmProjects}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> createProject(
    Map<String, dynamic> payload, {
    Uint8List? imageBytes,
  }) async {
    return _multipartRequestWithAuth((token) async {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmProjects}'),
      );
      payload.forEach((key, value) {
        if (value is List) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });
      if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'thumbnail',
          imageBytes,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      return request;
    });
  }

  Future<Map<String, dynamic>> getProjectApplications(String projectId) async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmProjectApplications(projectId)}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> approveApplication(String projectId, String applicationId) async {
    return _requestWithAuth((token) async {
      return await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmApproveApplication(projectId, applicationId)}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> getUMKMProjectProgress() async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi tidak ditemukan'};
      }
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmProjectsProgress}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
      if (response.statusCode == 401) {
        final refreshResult = await _auth.refreshToken();
        if (refreshResult['success'] == true) return getUMKMProjectProgress();
        return {'success': false, 'message': 'Sesi berakhir'};
      }
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final projectsList = decoded['data'];
        return {
          'success': true,
          'data': projectsList,
          'history': decoded['history'] ?? [],
          'message': decoded['message'] ?? 'Success',
        };
      }
      return {'success': false, 'message': decoded['message'] ?? 'Gagal'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> deleteUmkmProject(String projectId) async {
    return _requestWithAuth((token) async {
      return await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmDeleteProject(projectId)}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> processPayment(String projectId) async {
    // This method is deprecated - use PaymentService instead
    return {'success': false, 'message': 'Use PaymentService.createPaymentInvoice instead'};
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROJECTS - CREATIVE
  // ───────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProjects({String? category, String? search}) async {
    return _requestWithAuth((token) async {
      String url = '${ApiConfig.baseUrl}${ApiConfig.projects}';
      List<String> params = [];
      if (category != null && category.isNotEmpty && category != 'Semua') {
        params.add('category=${Uri.encodeQueryComponent(category)}');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeQueryComponent(search)}');
      }
      if (params.isNotEmpty) url += '?${params.join('&')}';
      
      return await http.get(
        Uri.parse(url),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> getProjectDetail(String projectId) async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.projectDetail(projectId)}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> applyToProject(
    String projectId, {
    String? coverLetter,
  }) async {
    return _requestWithAuth((token) async {
      return await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.applyToProject(projectId)}'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'cover_letter': coverLetter ?? ''}),
      );
    });
  }

  Future<Map<String, dynamic>> getCreativeProjects() async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.creativeProjects}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> updateProjectProgressWithMedia(
    String projectId,
    int progress,
    String note, {
    File? mediaFile,
  }) async {
    return _multipartRequestWithAuth((token) async {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.creativeProjectProgress(projectId)}'),
      );
      request.fields['progress_percentage'] = progress.toString();
      request.fields['note'] = note;
      if (mediaFile != null) {
        var stream = http.ByteStream(mediaFile.openRead());
        var length = await mediaFile.length();
        var multipartFile = http.MultipartFile(
          'progress_media',
          stream,
          length,
          filename: mediaFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }
      return request;
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CREATIVES / PORTFOLIO / PROFILE
  // ───────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getRecommendedCreatives() async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.creatives}?limit=5'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> searchCreatives({
    String? query,
    String? category,
  }) async {
    return _requestWithAuth((token) async {
      String url = '${ApiConfig.baseUrl}${ApiConfig.creatives}';
      List<String> params = [];
      if (query != null && query.isNotEmpty) {
        params.add('query=${Uri.encodeQueryComponent(query)}');
      }
      if (category != null && category.isNotEmpty && category != 'Semua') {
        params.add('category=${Uri.encodeQueryComponent(category)}');
      }
      if (params.isNotEmpty) url += '?${params.join('&')}';
      return await http.get(
        Uri.parse(url),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> getCreativeDetail(String creativeId) async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.creativeDetail(creativeId)}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> updateProfileWithPhoto(
    Map<String, dynamic> payload, {
    Uint8List? photoBytes,
  }) async {
    return _multipartRequestWithAuth((token) async {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileUpdate}'),
      );
      payload.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      if (photoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'profile_photo',
          photoBytes,
          filename: 'profile.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      return request;
    });
  }

  Future<Map<String, dynamic>> getPortfolios() async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.portfolios}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> createPortfolio(Map<String, dynamic> payload) async {
    return _requestWithAuth((token) async {
      return await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.portfolios}'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );
    });
  }

  Future<Map<String, dynamic>> deletePortfolio(int portfolioId) async {
    return _requestWithAuth((token) async {
      return await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deletePortfolio(portfolioId)}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> rateCreative(
    String projectId,
    int rating,
    String review,
  ) async {
    return _requestWithAuth((token) async {
      return await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmRatings}'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'project_id': projectId,
          'rating': rating,
          'review': review,
        }),
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ───────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications() async {
    return _requestWithAuth((token) async {
      return await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    return _requestWithAuth((token) async {
      return await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsReadAll}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> markNotificationRead(String notifId) async {
    return _requestWithAuth((token) async {
      return await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationRead(notifId)}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FLASK ML SERVICE
  // ───────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkFlaskStatus() async {
    for (final endpoint in ApiConfig.flaskHealthEndpoints) {
      try {
        final response = await http
            .get(Uri.parse(ApiConfig.getFlaskFullUrl(endpoint)))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          Map<String, dynamic> data = {};
          try {
            data = jsonDecode(response.body);
          } catch (_) {}
          return {
            'connected': true,
            'model_loaded': data['model_loaded'] ?? true,
          };
        }
      } catch (_) {
        continue;
      }
    }
    return {'connected': false, 'model_loaded': false};
  }

  Future<Map<String, dynamic>> getAiRecommendations(
    Map<String, dynamic> payload,
  ) async {
    return _requestWithAuth((token) async {
      return await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.recommendations}'),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));
    });
  }
  
  Future<Map<String, dynamic>> geocodeAddress(String query) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.getNominatimFullUrl(ApiConfig.nominatimSearch)}'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&format=json&limit=1&countrycodes=id',
      );
 
      final response = await http.get(url, headers: {
        'User-Agent': 'KonekinApp/1.0 (contact@konekin.id)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));
 
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final first = results[0];
          return {
            'success': true,
            'lat': first['lat'],
            'lng': first['lon'],
            'display_name': first['display_name'],
          };
        }
        return {'success': false, 'message': 'Lokasi tidak ditemukan'};
      }
      return {'success': false, 'message': 'Gagal menghubungi layanan peta'};
    } catch (e) {
      return {'success': false, 'message': 'Error geocoding: $e'};
    }
  }
 
  Future<Map<String, dynamic>> getUmkmProjectProgress() {
    return getUMKMProjectProgress();
  }

  Future<Map<String, dynamic>> getCreativeEarnings() async {
    final result = await getCreativeDashboard();
    if (result['success'] != true) return result;
    final data = result['data'];
    if (data is Map) {
      final earnings = data['earnings'] ?? data['payment_summary'] ?? data;
      return {
        'success': true,
        'data': earnings is Map
            ? earnings
            : {
                'total_earned': data['total_earned'] ?? 0,
                'total_pending': data['pending_payment'] ?? data['escrow_held'] ?? 0,
                'history': data['recent_payments'] ?? data['payment_history'] ?? [],
              },
      };
    }
    return result;
  }

  Future<Map<String, dynamic>> getCreativeEscrow() async {
    final result = await getCreativeProjects();
    if (result['success'] != true) return result;
    final raw = result['data'];
    List<dynamic> projects = raw is List
        ? raw
        : (raw is Map ? (raw['projects'] ?? raw['data'] ?? []) : []);
    final escrowList = projects.where((p) {
      if (p is! Map) return false;
      final status = (p['escrow_status'] ?? p['status'] ?? '').toString();
      return ['held', 'pending', 'paid', 'in_progress',
              'awaiting_payment', 'payment_pending'].contains(status);
    }).map((p) {
      final m = p as Map;
      return {
        'project_id':    m['id']?.toString() ?? '',
        'project_title': m['title']?.toString() ?? '',
        'amount':        m['budget'] ?? 0,
        'status':        m['escrow_status'] ?? m['status'] ?? 'held',
        'held_at':       m['created_at'],
      };
    }).toList();
    return {'success': true, 'data': escrowList};
  }

  Future<Map<String, dynamic>> approveCompletion(String projectId) async {
    return _requestWithAuth((token) async {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmApproveCompletion(projectId)}'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      );
      if (res.statusCode == 404) {
        return await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.umkmCompleteProject(projectId)}'),
          headers: {'Authorization': token, 'Accept': 'application/json'},
        );
      }
      return res;
    });
  }

  Future<Map<String, dynamic>> submitRating({
    required String projectId,
    required int rating,
    String comment = '',
  }) {
    return rateCreative(projectId, rating, comment);
  }

  Future<Map<String, dynamic>> storeCreativeProgress({
    required String projectId,
    required int progressPercentage,
    required String note,
    File? mediaFile,
  }) {
    return updateProjectProgressWithMedia(
      projectId,
      progressPercentage,
      note,
      mediaFile: mediaFile,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ERROR HANDLER
  // ───────────────────────────────────────────────────────────────────────────
  String _handleError(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'Tidak ada koneksi internet';
    }
    if (e.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Silakan coba lagi';
    }
    if (e.toString().contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server';
    }
    return 'Terjadi kesalahan. Silakan coba lagi';
  }
}