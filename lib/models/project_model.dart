// lib/models/project_model.dart
import '../models/project_model.dart';
class Project {
  final int id;
  final String title;
  final String description;
  final String budget;
  final String duration;
  final String status;
  final String category;
  final List<String> skills;
  final String? thumbnail;
  final int? umkmId;
  final String? umkmName;
  final String? umkmCity;
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
    this.umkmId,
    this.umkmName,
    this.umkmCity,
    required this.createdAt,
    this.deadline,
    this.applicantCount,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Handle ID safely
    int parsedId = 0;
    final idValue = json['id'];
    if (idValue is int) {
      parsedId = idValue;
    } else if (idValue is String) {
      parsedId = int.tryParse(idValue) ?? 0;
    }
    
    // Handle skills
    List<String> parsedSkills = [];
    final skillsValue = json['skills'] ?? json['requirements'];
    if (skillsValue is List) {
      parsedSkills = skillsValue.map((e) => e.toString()).toList();
    } else if (skillsValue is String && skillsValue.isNotEmpty) {
      parsedSkills = skillsValue.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    
    // Handle deadline
    DateTime? deadline;
    if (json['deadline'] != null && json['deadline'].toString().isNotEmpty) {
      deadline = DateTime.tryParse(json['deadline'].toString());
    }
    
    // Handle applicant count
    int? applicantCount;
    final acValue = json['applicant_count'] ?? json['applications_count'];
    if (acValue is int) {
      applicantCount = acValue;
    } else if (acValue is String) {
      applicantCount = int.tryParse(acValue);
    }
    
    // Handle duration
    String duration = json['duration']?.toString() ?? '';
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
    
    return Project(
      id: parsedId,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      budget: json['budget']?.toString() ?? '0',
      duration: duration,
      status: json['status']?.toString() ?? 'open',
      category: json['category']?.toString() ?? 'General',
      skills: parsedSkills,
      thumbnail: json['thumbnail']?.toString(),
      umkmId: json['client_id'] is int ? json['client_id'] : int.tryParse(json['client_id']?.toString() ?? ''),
      umkmName: json['client_name']?.toString() ?? json['umkm_name']?.toString(),
      umkmCity: json['client_city']?.toString(),
      createdAt: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
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
      'umkm_id': umkmId,
      'umkm_name': umkmName,
      'umkm_city': umkmCity,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'applicant_count': applicantCount,
    };
  }
} // ← HANYA SATU PENUTUP

// MyProjectProgress tetap di bawah
class MyProjectProgress {
  final int id;
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
    final data = json['data'] ?? json;
    return MyProjectProgress(
      id: data['id'] ?? 0,
      title: data['title'] ?? '',
      status: data['status'] ?? 'pending',
      progress: data['progress'] ?? 0,
      umkmName: data['umkm_name'],
      creativeName: data['creative_name'],
      startedAt: data['started_at'] != null ? DateTime.tryParse(data['started_at']) : null,
      deadline: data['deadline'] != null ? DateTime.tryParse(data['deadline']) : null,
    );
  }
}