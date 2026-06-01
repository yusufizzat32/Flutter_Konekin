// lib/models/revision_model.dart

class RevisionRequest {
  final String id;
  final String projectId;
  final String reason;
  final String? feedback;
  final DateTime? deadline;
  final int revisionNumber;
  final String status;
  final DateTime requestedAt;
  final DateTime? submittedAt;
  final String? submissionNote;
  final String? submissionMedia;

  RevisionRequest({
    required this.id,
    required this.projectId,
    required this.reason,
    this.feedback,
    this.deadline,
    required this.revisionNumber,
    required this.status,
    required this.requestedAt,
    this.submittedAt,
    this.submissionNote,
    this.submissionMedia,
  });

  factory RevisionRequest.fromJson(Map<String, dynamic> json) {
    return RevisionRequest(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      feedback: json['feedback']?.toString(),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      revisionNumber: json['revision_number'] ?? 0,
      status: json['status']?.toString() ?? 'requested',
      requestedAt: json['requested_at'] != null 
          ? DateTime.parse(json['requested_at']) 
          : DateTime.now(),
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at']) : null,
      submissionNote: json['submission_note']?.toString(),
      submissionMedia: json['submission_media']?.toString(),
    );
  }

  bool get isOverdue => deadline != null && deadline!.isBefore(DateTime.now());
  bool get isRequested => status == 'requested';
  bool get isSubmitted => status == 'submitted';
}

class RevisionData {
  final Map<String, dynamic> currentRevision;
  final List<Map<String, dynamic>> revisionHistory;

  RevisionData({
    required this.currentRevision,
    required this.revisionHistory,
  });

  factory RevisionData.fromJson(Map<String, dynamic> json) {
    return RevisionData(
      currentRevision: json['current_revision'] as Map<String, dynamic>? ?? {},
      revisionHistory: (json['revision_history'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }
}