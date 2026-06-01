// lib/models/portfolio_model.dart
class Portfolio {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String imageUrl;
  final String? fileUrl;
  final String? fileOpenUrl;
  final String? fileType;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Portfolio({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.fileUrl,
    this.fileOpenUrl,
    this.fileType,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      fileUrl: json['file_url'],
      fileOpenUrl: json['file_open_url'],
      fileType: json['file_type'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isVideo => fileType != null && 
      ['mp4', 'mov', 'avi', 'mkv'].contains(fileType!.toLowerCase());
  
  bool get isPdf => fileType != null && fileType!.toLowerCase() == 'pdf';
  
  bool get hasAttachment => fileUrl != null && fileUrl!.isNotEmpty;
}