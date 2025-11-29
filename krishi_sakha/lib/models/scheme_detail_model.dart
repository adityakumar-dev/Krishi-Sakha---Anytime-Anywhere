import 'dart:convert';

/// Model for the `scheme_details` table
class SchemeDetailModel {
  final int sNo;
  final String id;
  final String? slug;
  final String? name;
  final String? shortTitle;
  final List<String>? tags;
  final String? level;
  final String? schemeType;
  final List<String>? categories;
  final List<String>? subcategories;
  final String? openDate;
  final String? benefitType;
  final String? briefDescription;
  final String? detailedDescription;
  final List<String>? benefits;
  final List<String>? eligibility;
  final List<String>? exclusions;
  final List<String>? definitions;
  final List<String>? references;
  final List<String>? applicationProcess;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data
  List<SchemeDocumentModel> documents;
  List<SchemeFaqModel> faqs;

  SchemeDetailModel({
    required this.sNo,
    required this.id,
    this.slug,
    this.name,
    this.shortTitle,
    this.tags,
    this.level,
    this.schemeType,
    this.categories,
    this.subcategories,
    this.openDate,
    this.benefitType,
    this.briefDescription,
    this.detailedDescription,
    this.benefits,
    this.eligibility,
    this.exclusions,
    this.definitions,
    this.references,
    this.applicationProcess,
    this.createdAt,
    this.updatedAt,
    this.documents = const [],
    this.faqs = const [],
  });

  /// Create from JSON (Supabase response)
  factory SchemeDetailModel.fromJson(Map<String, dynamic> json) {
    return SchemeDetailModel(
      sNo: json['s_no'] as int,
      id: json['id'] as String,
      slug: json['slug'] as String?,
      name: json['name'] as String?,
      shortTitle: json['short_title'] as String?,
      tags: _parseTextToList(json['tags']),
      level: json['level'] as String?,
      schemeType: json['scheme_type'] as String?,
      categories: _parseTextToList(json['categories']),
      subcategories: _parseTextToList(json['subcategories']),
      openDate: json['open_date'] as String?,
      benefitType: json['benefit_type'] as String?,
      briefDescription: json['brief_description'] as String?,
      detailedDescription: json['detailed_description'] as String?,
      benefits: _parseTextToList(json['benefits']),
      eligibility: _parseTextToList(json['eligibility']),
      exclusions: _parseTextToList(json['exclusions']),
      definitions: _parseDefinitions(json['definitions']),
      references: _parseReferences(json['references']),
      applicationProcess: _parseTextToList(json['application_process']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Parse text fields that may contain JSON arrays or newline-separated text
  static List<String>? _parseTextToList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    if (value is String) {
      if (value.trim().isEmpty) return null;
      
      // Try parsing as JSON array first
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
        }
      } catch (_) {}
      
      // If not JSON, split by newlines and filter numbered items
      if (value.contains('\n')) {
        final lines = value.split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map((s) {
              // Remove leading numbers like "1. ", "2. ", etc.
              return s.replaceFirst(RegExp(r'^\d+\.\s*'), '');
            })
            .where((s) => s.isNotEmpty)
            .toList();
        return lines.isEmpty ? null : lines;
      }
      return [value];
    }
    return null;
  }

  /// Parse references which can be objects with title and url
  static List<String>? _parseReferences(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.trim().isEmpty || value == '[]') return null;
      
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          final refs = <String>[];
          for (final item in decoded) {
            if (item is Map) {
              final title = item['title'] as String?;
              final url = item['url'] as String?;
              if (url != null && url.isNotEmpty) {
                refs.add(title != null && title.isNotEmpty ? '$title: $url' : url);
              } else if (title != null && title.isNotEmpty) {
                refs.add(title);
              }
            } else if (item is String && item.isNotEmpty) {
              refs.add(item);
            }
          }
          return refs.isEmpty ? null : refs;
        }
      } catch (_) {}
      
      return [value];
    }
    if (value is List) {
      final refs = <String>[];
      for (final item in value) {
        if (item is Map) {
          final title = item['title'] as String?;
          final url = item['url'] as String?;
          if (url != null && url.isNotEmpty) {
            refs.add(title != null && title.isNotEmpty ? '$title: $url' : url);
          } else if (title != null && title.isNotEmpty) {
            refs.add(title);
          }
        } else if (item != null) {
          refs.add(item.toString());
        }
      }
      return refs.isEmpty ? null : refs;
    }
    return null;
  }

  /// Parse definitions which can be an object or empty
  static List<String>? _parseDefinitions(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.trim().isEmpty || value == '{}' || value == '[]') return null;
      
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map && decoded.isNotEmpty) {
          final defs = <String>[];
          decoded.forEach((key, val) {
            if (key != null && val != null) {
              defs.add('$key: $val');
            }
          });
          return defs.isEmpty ? null : defs;
        }
        if (decoded is List) {
          return decoded.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
        }
      } catch (_) {}
      
      return [value];
    }
    if (value is Map && value.isNotEmpty) {
      final defs = <String>[];
      value.forEach((key, val) {
        if (key != null && val != null) {
          defs.add('$key: $val');
        }
      });
      return defs.isEmpty ? null : defs;
    }
    return null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      's_no': sNo,
      'id': id,
      'slug': slug,
      'name': name,
      'short_title': shortTitle,
      'tags': tags != null ? jsonEncode(tags) : null,
      'level': level,
      'scheme_type': schemeType,
      'categories': categories != null ? jsonEncode(categories) : null,
      'subcategories': subcategories != null ? jsonEncode(subcategories) : null,
      'open_date': openDate,
      'benefit_type': benefitType,
      'brief_description': briefDescription,
      'detailed_description': detailedDescription,
      'benefits': benefits != null ? jsonEncode(benefits) : null,
      'eligibility': eligibility != null ? jsonEncode(eligibility) : null,
      'exclusions': exclusions != null ? jsonEncode(exclusions) : null,
      'definitions': definitions != null ? jsonEncode(definitions) : null,
      'references': references != null ? jsonEncode(references) : null,
      'application_process': applicationProcess != null ? jsonEncode(applicationProcess) : null,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SchemeDetailModel(sNo: $sNo, id: $id, name: $name)';
  }
}

/// Model for the `scheme_documents` table
class SchemeDocumentModel {
  final int id;
  final String schemeId;
  final String? slug;
  final String? document;
  final DateTime? createdAt;

  SchemeDocumentModel({
    required this.id,
    required this.schemeId,
    this.slug,
    this.document,
    this.createdAt,
  });

  /// Create from JSON (Supabase response)
  factory SchemeDocumentModel.fromJson(Map<String, dynamic> json) {
    return SchemeDocumentModel(
      id: json['id'] as int,
      schemeId: json['scheme_id'] as String,
      slug: json['slug'] as String?,
      document: json['document'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheme_id': schemeId,
      'slug': slug,
      'document': document,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SchemeDocumentModel(id: $id, schemeId: $schemeId, document: $document)';
  }
}

/// Model for the `scheme_faqs` table
class SchemeFaqModel {
  final int id;
  final String schemeId;
  final String? slug;
  final String? question;
  final String? answer;
  final DateTime? createdAt;

  SchemeFaqModel({
    required this.id,
    required this.schemeId,
    this.slug,
    this.question,
    this.answer,
    this.createdAt,
  });

  /// Create from JSON (Supabase response)
  factory SchemeFaqModel.fromJson(Map<String, dynamic> json) {
    return SchemeFaqModel(
      id: json['id'] as int,
      schemeId: json['scheme_id'] as String,
      slug: json['slug'] as String?,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheme_id': schemeId,
      'slug': slug,
      'question': question,
      'answer': answer,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SchemeFaqModel(id: $id, question: $question)';
  }
}
