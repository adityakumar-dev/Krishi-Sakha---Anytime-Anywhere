import 'dart:convert';
import 'package:hive/hive.dart';

part 'scheme_meta_model.g.dart';

/// Model for the `schemes` table
@HiveType(typeId: 20)
class SchemeModel extends HiveObject {
  @HiveField(0)
  final int sNo;

  @HiveField(1)
  final String id;

  @HiveField(2)
  final List<String>? highlight;

  @HiveField(3)
  final List<String>? beneficiaryState;

  @HiveField(4)
  final String? schemeShortTitle;

  @HiveField(5)
  final String? level;

  @HiveField(6)
  final String? schemeFor;

  @HiveField(7)
  final List<String>? schemeCategory;

  @HiveField(8)
  final String schemeName;

  @HiveField(9)
  final DateTime? schemeCloseDate;

  @HiveField(10)
  final double? priority;

  @HiveField(11)
  final String slug;

  @HiveField(12)
  final String? briefDescription;

  @HiveField(13)
  final List<String>? tags;

  @HiveField(14)
  final String? nodalMinistryName;

  @HiveField(15)
  final DateTime uploadDate;

  @HiveField(16)
  final DateTime? createdAt;

  @HiveField(17)
  final DateTime? updatedAt;

  SchemeModel({
    required this.sNo,
    required this.id,
    this.highlight,
    this.beneficiaryState,
    this.schemeShortTitle,
    this.level,
    this.schemeFor,
    this.schemeCategory,
    required this.schemeName,
    this.schemeCloseDate,
    this.priority,
    required this.slug,
    this.briefDescription,
    this.tags,
    this.nodalMinistryName,
    required this.uploadDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      sNo: json['s_no'] as int,
      id: json['id'] as String,
      highlight: _parseJsonbArray(json['highlight']),
      beneficiaryState: _parseJsonbArray(json['beneficiarystate']),
      schemeShortTitle: json['schemeshorttitle'] as String?,
      level: json['level'] as String?,
      schemeFor: json['schemefor'] as String?,
      schemeCategory: _parseJsonbArray(json['schemecategory']),
      schemeName: json['schemename'] as String,
      schemeCloseDate: json['schemeclosedate'] != null
          ? DateTime.parse(json['schemeclosedate'] as String)
          : null,
      priority: json['priority'] != null
          ? (json['priority'] as num).toDouble()
          : null,
      slug: json['slug'] as String,
      briefDescription: json['briefdescription'] as String?,
      tags: _parseJsonbArray(json['tags']),
      nodalMinistryName: json['nodalministryname'] as String?,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      's_no': sNo,
      'id': id,
      'highlight': highlight != null ? jsonEncode(highlight) : null,
      'beneficiarystate': beneficiaryState != null ? jsonEncode(beneficiaryState) : null,
      'schemeshorttitle': schemeShortTitle,
      'level': level,
      'schemefor': schemeFor,
      'schemecategory': schemeCategory != null ? jsonEncode(schemeCategory) : null,
      'schemename': schemeName,
      'schemeclosedate': schemeCloseDate?.toIso8601String().split('T').first,
      'priority': priority,
      'slug': slug,
      'briefdescription': briefDescription,
      'tags': tags != null ? jsonEncode(tags) : null,
      'nodalministryname': nodalMinistryName,
      'upload_date': uploadDate.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Helper to parse JSONB arrays from Supabase
  static List<String>? _parseJsonbArray(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return null;
  }

  /// Check if scheme is central level
  bool get isCentralScheme => level?.toLowerCase() == 'central';

  /// Check if scheme is state level
  bool get isStateScheme => level?.toLowerCase() == 'state';

  /// Copy with method for immutability
  SchemeModel copyWith({
    int? sNo,
    String? id,
    List<String>? highlight,
    List<String>? beneficiaryState,
    String? schemeShortTitle,
    String? level,
    String? schemeFor,
    List<String>? schemeCategory,
    String? schemeName,
    DateTime? schemeCloseDate,
    double? priority,
    String? slug,
    String? briefDescription,
    List<String>? tags,
    String? nodalMinistryName,
    DateTime? uploadDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchemeModel(
      sNo: sNo ?? this.sNo,
      id: id ?? this.id,
      highlight: highlight ?? this.highlight,
      beneficiaryState: beneficiaryState ?? this.beneficiaryState,
      schemeShortTitle: schemeShortTitle ?? this.schemeShortTitle,
      level: level ?? this.level,
      schemeFor: schemeFor ?? this.schemeFor,
      schemeCategory: schemeCategory ?? this.schemeCategory,
      schemeName: schemeName ?? this.schemeName,
      schemeCloseDate: schemeCloseDate ?? this.schemeCloseDate,
      priority: priority ?? this.priority,
      slug: slug ?? this.slug,
      briefDescription: briefDescription ?? this.briefDescription,
      tags: tags ?? this.tags,
      nodalMinistryName: nodalMinistryName ?? this.nodalMinistryName,
      uploadDate: uploadDate ?? this.uploadDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SchemeModel(sNo: $sNo, id: $id, schemeName: $schemeName, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchemeModel && other.sNo == sNo && other.id == id;
  }

  @override
  int get hashCode => sNo.hashCode ^ id.hashCode;
}

/// Model for the `scheme_filters` table
@HiveType(typeId: 21)
class SchemeFilterModel extends HiveObject {
  @HiveField(0)
  final int filterId;

  @HiveField(1)
  final String filterType;

  @HiveField(2)
  final String filterValue;

  @HiveField(3)
  final DateTime? createdAt;

  SchemeFilterModel({
    required this.filterId,
    required this.filterType,
    required this.filterValue,
    this.createdAt,
  });

  /// Create from JSON (Supabase response)
  factory SchemeFilterModel.fromJson(Map<String, dynamic> json) {
    return SchemeFilterModel(
      filterId: json['filter_id'] as int,
      filterType: json['filter_type'] as String,
      filterValue: json['filter_value'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'filter_id': filterId,
      'filter_type': filterType,
      'filter_value': filterValue,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Convert to JSON for insert (without filter_id as it's auto-generated)
  Map<String, dynamic> toInsertJson() {
    return {
      'filter_type': filterType,
      'filter_value': filterValue,
    };
  }

  @override
  String toString() {
    return 'SchemeFilterModel(filterId: $filterId, filterType: $filterType, filterValue: $filterValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchemeFilterModel && other.filterId == filterId;
  }

  @override
  int get hashCode => filterId.hashCode;
}

/// Enum for filter types
enum SchemeFilterType {
  level('level'),
  schemeFor('schemefor'),
  state('state'),
  category('category'),
  ministry('ministry'),
  tag('tag');

  final String value;
  const SchemeFilterType(this.value);

  static SchemeFilterType? fromString(String value) {
    try {
      return SchemeFilterType.values.firstWhere(
        (e) => e.value.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Model for scheme search/filter criteria
class SchemeSearchCriteria {
  final String? searchQuery;
  final String? level;
  final String? schemeFor;
  final List<String>? states;
  final List<String>? categories;
  final List<String>? tags;
  final String? ministry;
  final SchemeSortBy sortBy;
  final bool ascending;
  final int limit;
  final int offset;

  SchemeSearchCriteria({
    this.searchQuery,
    this.level,
    this.schemeFor,
    this.states,
    this.categories,
    this.tags,
    this.ministry,
    this.sortBy = SchemeSortBy.priority,
    this.ascending = false,
    this.limit = 20,
    this.offset = 0,
  });

  /// Copy with method
  SchemeSearchCriteria copyWith({
    String? searchQuery,
    String? level,
    String? schemeFor,
    List<String>? states,
    List<String>? categories,
    List<String>? tags,
    String? ministry,
    SchemeSortBy? sortBy,
    bool? ascending,
    int? limit,
    int? offset,
  }) {
    return SchemeSearchCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      level: level ?? this.level,
      schemeFor: schemeFor ?? this.schemeFor,
      states: states ?? this.states,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      ministry: ministry ?? this.ministry,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Reset all filters
  SchemeSearchCriteria reset() {
    return SchemeSearchCriteria(
      sortBy: sortBy,
      ascending: ascending,
      limit: limit,
    );
  }

  /// Check if any filter is applied
  bool get hasFilters {
    return searchQuery != null ||
        level != null ||
        schemeFor != null ||
        (states != null && states!.isNotEmpty) ||
        (categories != null && categories!.isNotEmpty) ||
        (tags != null && tags!.isNotEmpty) ||
        ministry != null;
  }
}

/// Enum for sorting schemes
enum SchemeSortBy {
  priority('priority'),
  uploadDate('upload_date'),
  schemeName('schemename');

  final String column;
  const SchemeSortBy(this.column);
}

/// Model for grouped filters (useful for UI)
class SchemeFiltersGrouped {
  final List<String> levels;
  final List<String> schemeForOptions;
  final List<String> states;
  final List<String> categories;
  final List<String> ministries;
  final List<String> tags;

  SchemeFiltersGrouped({
    this.levels = const [],
    this.schemeForOptions = const [],
    this.states = const [],
    this.categories = const [],
    this.ministries = const [],
    this.tags = const [],
  });

  /// Create from list of SchemeFilterModel
  factory SchemeFiltersGrouped.fromFilterList(List<SchemeFilterModel> filters) {
    final levels = <String>[];
    final schemeForOptions = <String>[];
    final states = <String>[];
    final categories = <String>[];
    final ministries = <String>[];
    final tags = <String>[];

    for (final filter in filters) {
      switch (filter.filterType.toLowerCase()) {
        case 'level':
          levels.add(filter.filterValue);
          break;
        case 'schemefor':
          schemeForOptions.add(filter.filterValue);
          break;
        case 'state':
          states.add(filter.filterValue);
          break;
        case 'category':
          categories.add(filter.filterValue);
          break;
        case 'ministry':
          ministries.add(filter.filterValue);
          break;
        case 'tag':
          tags.add(filter.filterValue);
          break;
      }
    }

    return SchemeFiltersGrouped(
      levels: levels..sort(),
      schemeForOptions: schemeForOptions..sort(),
      states: states..sort(),
      categories: categories..sort(),
      ministries: ministries..sort(),
      tags: tags..sort(),
    );
  }

  /// Check if filters are empty
  bool get isEmpty {
    return levels.isEmpty &&
        schemeForOptions.isEmpty &&
        states.isEmpty &&
        categories.isEmpty &&
        ministries.isEmpty &&
        tags.isEmpty;
  }
}

/// Paginated response model for schemes
class SchemesPaginatedResponse {
  final List<SchemeModel> schemes;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  SchemesPaginatedResponse({
    required this.schemes,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });

  factory SchemesPaginatedResponse.fromResponse({
    required List<SchemeModel> schemes,
    required int totalCount,
    required int limit,
    required int offset,
  }) {
    final currentPage = (offset / limit).floor() + 1;
    final totalPages = (totalCount / limit).ceil();
    final hasMore = offset + schemes.length < totalCount;

    return SchemesPaginatedResponse(
      schemes: schemes,
      totalCount: totalCount,
      currentPage: currentPage,
      totalPages: totalPages,
      hasMore: hasMore,
    );
  }

  /// Empty response
  factory SchemesPaginatedResponse.empty() {
    return SchemesPaginatedResponse(
      schemes: [],
      totalCount: 0,
      currentPage: 1,
      totalPages: 0,
      hasMore: false,
    );
  }
}
