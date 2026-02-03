/// Source entity - origin container (book, website, document, manual)
class SourceModel {
  const SourceModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.author,
    this.asin,
    this.url,
    this.domain,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      asin: json['asin'] as String?,
      url: json['url'] as String?,
      domain: json['domain'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  final String id;
  final String userId;
  final String type; // 'book', 'website', 'document', 'manual'
  final String title;
  final String? author;
  final String? asin;
  final String? url;
  final String? domain;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'author': author,
      'asin': asin,
      'url': url,
      'domain': domain,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  SourceModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? author,
    String? asin,
    String? url,
    String? domain,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SourceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      author: author ?? this.author,
      asin: asin ?? this.asin,
      url: url ?? this.url,
      domain: domain ?? this.domain,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
