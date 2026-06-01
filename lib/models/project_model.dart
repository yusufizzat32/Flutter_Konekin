// lib/models/project_model.dart
//
// CATATAN PENTING:
// Backend menggunakan MongoDB → ID berbentuk hex string ObjectId
// contoh: "6a063605958c901392095242"
// Bukan integer! Semua field 'id' diubah ke String.

class Project {
  final String id;        // ← String, bukan int
  final String title;
  final String description;
  final String budget;
  final String duration;
  final String status;
  final String category;
  final List<String> skills;
  final String? thumbnail;
  final String? mediaUrl;
  final String? mediaType;
  final String? umkmId;
  final String? umkmName;
  final String? umkmCity;
  final String? selectedCreativeId;
  final String? selectedCreativeName;
  final String? selectedCreativeAvatar;
  final String? escrowStatus;
  final int progressPercentage;
  final DateTime createdAt;
  final DateTime? deadline;
  final int? applicantCount;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.duration,
    required this.status,
    required this.category,
    required this.skills,
    this.thumbnail,
    this.mediaUrl,
    this.mediaType,
    this.umkmId,
    this.umkmName,
    this.umkmCity,
    this.selectedCreativeId,
    this.selectedCreativeName,
    this.selectedCreativeAvatar,
    this.escrowStatus,
    this.progressPercentage = 0,
    required this.createdAt,
    this.deadline,
    this.applicantCount,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // ── Unwrap nested response kalau perlu ──────────────────────────────────
    late final Map<String, dynamic> d;
    if (json.containsKey('id') || json.containsKey('title')) {
      d = json;
    } else if (json['data'] is Map<String, dynamic>) {
      d = json['data'] as Map<String, dynamic>;
    } else if (json['project'] is Map<String, dynamic>) {
      d = json['project'] as Map<String, dynamic>;
    } else {
      d = json;
    }

    // ── ID: simpan langsung sebagai String (MongoDB ObjectId) ───────────────
    final String parsedId = d['id']?.toString() ?? '';

    // ── Skills ──────────────────────────────────────────────────────────────
    List<String> parsedSkills = [];
    final skillsRaw = d['skills'] ?? d['requirements'];
    if (skillsRaw is List) {
      parsedSkills = skillsRaw.map((e) => e.toString()).toList();
    } else if (skillsRaw is String && skillsRaw.isNotEmpty) {
      parsedSkills = skillsRaw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // ── Deadline ────────────────────────────────────────────────────────────
    DateTime? deadline;
    final deadlineRaw = d['deadline'] ?? d['expired_at'];
    if (deadlineRaw != null && deadlineRaw.toString().isNotEmpty) {
      deadline = DateTime.tryParse(deadlineRaw.toString());
    }

    // ── Duration ─────────────────────────────────────────────────────────────
    String duration = d['duration']?.toString() ?? '';
    if (duration.isEmpty && deadline != null) {
      final diff = deadline.difference(DateTime.now());
      if (diff.inDays <= 0) {
        duration = 'Hari ini';
      } else if (diff.inDays < 30) {
        duration = '${diff.inDays} hari';
      } else {
        duration = '${(diff.inDays / 30).round()} bulan';
      }
    }

    // ── Applicant count ─────────────────────────────────────────────────────
    int? applicantCount;
    final acRaw = d['applicant_count'] ??
        d['applications_count'] ??
        d['applicants_count'] ??
        d['total_applicants'];
    if (acRaw != null) {
      applicantCount =
          acRaw is int ? acRaw : int.tryParse(acRaw.toString());
    }

    // ── Progress ─────────────────────────────────────────────────────────────
    final progRaw = d['progress_percentage'] ?? d['progress'];
    final int progress = progRaw == null
        ? 0
        : (progRaw is int ? progRaw : int.tryParse(progRaw.toString()) ?? 0);

    return Project(
      id: parsedId,
      title: d['title']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      budget: d['budget']?.toString() ?? '0',
      duration: duration,
      status: d['status']?.toString() ?? 'open',
      category: d['category']?.toString() ?? 'General',
      skills: parsedSkills,
      thumbnail: d['thumbnail']?.toString(),
      mediaUrl: d['media_url']?.toString(),
      mediaType: d['media_type']?.toString(),
      umkmId: d['client_id']?.toString() ?? d['umkm_id']?.toString(),
      umkmName: d['client_name']?.toString() ?? d['umkm_name']?.toString(),
      umkmCity: d['client_city']?.toString() ?? d['umkm_city']?.toString(),
      selectedCreativeId: d['selected_creative_id']?.toString(),
      selectedCreativeName: d['selected_creative_name']?.toString(),
      selectedCreativeAvatar: d['selected_creative_avatar']?.toString(),
      escrowStatus: d['escrow_status']?.toString(),
      progressPercentage: progress,
      createdAt: d['created_at'] != null
          ? (DateTime.tryParse(d['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      deadline: deadline,
      applicantCount: applicantCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'budget': budget,
      'duration': duration,
      'status': status,
      'category': category,
      'skills': skills,
      'thumbnail': thumbnail,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'client_id': umkmId,
      'client_name': umkmName,
      'client_city': umkmCity,
      'selected_creative_id': selectedCreativeId,
      'selected_creative_name': selectedCreativeName,
      'selected_creative_avatar': selectedCreativeAvatar,
      'escrow_status': escrowStatus,
      'progress_percentage': progressPercentage,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'applicant_count': applicantCount,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class MyProjectProgress {
  final String id;
  final String title;
  final String status;
  final int progress;
  final String? umkmName;
  final String? creativeName;
  final DateTime? startedAt;
  final DateTime? deadline;

  MyProjectProgress({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
    this.umkmName,
    this.creativeName,
    this.startedAt,
    this.deadline,
  });

  factory MyProjectProgress.fromJson(Map<String, dynamic> json) {
    final d = (json.containsKey('id') || json.containsKey('title'))
        ? json
        : (json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json);

    return MyProjectProgress(
      id: d['id']?.toString() ?? '',
      title: d['title']?.toString() ?? '',
      status: d['status']?.toString() ?? 'pending',
      progress: int.tryParse(
              (d['progress'] ?? d['progress_percentage'])?.toString() ?? '0') ??
          0,
      umkmName: d['umkm_name']?.toString(),
      creativeName: d['creative_name']?.toString(),
      startedAt: d['started_at'] != null
          ? DateTime.tryParse(d['started_at'].toString())
          : null,
      deadline: d['deadline'] != null
          ? DateTime.tryParse(d['deadline'].toString())
          : null,
    );
  }
}