import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:krishi_sakha/models/scheme_meta_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SchemeLoadingState { initial, loading, loaded, loadingMore, error }

class SchemeProvider extends ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // State
  SchemeLoadingState _state = SchemeLoadingState.initial;
  SchemeLoadingState get state => _state;

  // Schemes data
  List<SchemeModel> _schemes = [];
  List<SchemeModel> get schemes => _schemes;

  // Filtered schemes (for UI display)
  List<SchemeModel> _filteredSchemes = [];
  List<SchemeModel> get filteredSchemes =>
      _filteredSchemes.isEmpty && !_hasActiveFilters ? _schemes : _filteredSchemes;

  // Filters
  List<SchemeFilterModel> _filters = [];
  List<SchemeFilterModel> get filters => _filters;
  SchemeFiltersGrouped _groupedFilters = SchemeFiltersGrouped();
  SchemeFiltersGrouped get groupedFilters => _groupedFilters;

  // Search & Filter criteria
  SchemeSearchCriteria _criteria = SchemeSearchCriteria();
  SchemeSearchCriteria get criteria => _criteria;
  bool get _hasActiveFilters => _criteria.hasFilters;

  // Pagination
  int _totalCount = 0;
  int get totalCount => _totalCount;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  static const int _pageSize = 20;

  // Error handling
  String? _error;
  String? get error => _error;

  // Cache management
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 30);
  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;

  // Hive boxes
  Box<SchemeModel>? _schemesBox;
  Box<SchemeFilterModel>? _filtersBox;

  /// Initialize provider and load cached data
  Future<void> init() async {
    await _openHiveBoxes();
    await _loadFromCache();
    // Fetch fresh data if cache is invalid or empty
    if (!_isCacheValid || _schemes.isEmpty) {
      await fetchSchemes();
    }
  }

  /// Open Hive boxes for caching
  Future<void> _openHiveBoxes() async {
    try {
      _schemesBox = await Hive.openBox<SchemeModel>('schemes_cache');
      _filtersBox = await Hive.openBox<SchemeFilterModel>('filters_cache');
    } catch (e) {
      debugPrint('Error opening Hive boxes: $e');
    }
  }

  /// Load data from local cache
  Future<void> _loadFromCache() async {
    try {
      if (_schemesBox != null && _schemesBox!.isNotEmpty) {
        _schemes = _schemesBox!.values.toList();
        _schemes.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));
      }
      if (_filtersBox != null && _filtersBox!.isNotEmpty) {
        _filters = _filtersBox!.values.toList();
        _groupedFilters = SchemeFiltersGrouped.fromFilterList(_filters);
      }
      if (_schemes.isNotEmpty) {
        _state = SchemeLoadingState.loaded;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  /// Save data to local cache
  Future<void> _saveToCache() async {
    try {
      if (_schemesBox != null) {
        await _schemesBox!.clear();
        for (final scheme in _schemes) {
          await _schemesBox!.put(scheme.id, scheme);
        }
      }
      if (_filtersBox != null) {
        await _filtersBox!.clear();
        for (final filter in _filters) {
          await _filtersBox!.put(filter.filterId, filter);
        }
      }
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  /// Fetch schemes and filters in parallel
  Future<void> fetchSchemes({bool forceRefresh = false}) async {
    if (_state == SchemeLoadingState.loading) return;

    // Use cache if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && _schemes.isNotEmpty) {
      return;
    }

    _state = SchemeLoadingState.loading;
    _error = null;
    notifyListeners();

    try {
      // Fetch schemes and filters in parallel
      final results = await Future.wait([
        _fetchSchemesFromServer(),
        _fetchFiltersFromServer(),
      ]);

      _schemes = results[0] as List<SchemeModel>;
      _filters = results[1] as List<SchemeFilterModel>;
      _groupedFilters = SchemeFiltersGrouped.fromFilterList(_filters);
      _totalCount = _schemes.length;
      _hasMore = false; // All loaded initially
      _lastFetchTime = DateTime.now();
      _state = SchemeLoadingState.loaded;

      // Save to cache in background
      _saveToCache();

      // Apply any existing filters
      if (_hasActiveFilters) {
        _applyFilters();
      }
    } catch (e) {
      _error = e.toString();
      _state = SchemeLoadingState.error;
      debugPrint('Error fetching schemes: $e');
    }

    notifyListeners();
  }

  /// Fetch schemes from server with pagination support
  Future<List<SchemeModel>> _fetchSchemesFromServer({
    int offset = 0,
    int limit = 1000,
  }) async {
    final response = await _supabaseClient
        .from('schemes')
        .select()
        .order('priority', ascending: false)
        .range(offset, offset + limit - 1);

    if (response.isEmpty) {
      return [];
    }

    return (response as List)
        .map((item) => SchemeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetch filters from server
  Future<List<SchemeFilterModel>> _fetchFiltersFromServer() async {
    final response = await _supabaseClient
        .from('scheme_filters')
        .select()
        .order('filter_type');

    if (response.isEmpty) {
      return [];
    }

    return (response as List)
        .map((item) => SchemeFilterModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetch paginated schemes (for lazy loading)
  Future<void> fetchMoreSchemes() async {
    if (_state == SchemeLoadingState.loadingMore || !_hasMore) return;

    _state = SchemeLoadingState.loadingMore;
    notifyListeners();

    try {
      final newSchemes = await _fetchSchemesFromServer(
        offset: _schemes.length,
        limit: _pageSize,
      );

      if (newSchemes.isEmpty) {
        _hasMore = false;
      } else {
        _schemes.addAll(newSchemes);
        _hasMore = newSchemes.length >= _pageSize;

        // Re-apply filters if active
        if (_hasActiveFilters) {
          _applyFilters();
        }
      }

      _state = SchemeLoadingState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = SchemeLoadingState.error;
    }

    notifyListeners();
  }

  /// Search schemes by query
  Future<void> searchSchemes(String query) async {
    if (query.isEmpty) {
      _criteria = _criteria.copyWith(searchQuery: null);
      _filteredSchemes = [];
      notifyListeners();
      return;
    }

    _criteria = _criteria.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Update filter criteria
  void updateCriteria(SchemeSearchCriteria newCriteria) {
    _criteria = newCriteria;
    _applyFilters();
  }

  /// Set level filter
  void setLevelFilter(String? level) {
    _criteria = _criteria.copyWith(level: level);
    _applyFilters();
  }

  /// Set schemeFor filter
  void setSchemeForFilter(String? schemeFor) {
    _criteria = _criteria.copyWith(schemeFor: schemeFor);
    _applyFilters();
  }

  /// Set states filter
  void setStatesFilter(List<String>? states) {
    _criteria = _criteria.copyWith(states: states);
    _applyFilters();
  }

  /// Set categories filter
  void setCategoriesFilter(List<String>? categories) {
    _criteria = _criteria.copyWith(categories: categories);
    _applyFilters();
  }

  /// Set ministry filter
  void setMinistryFilter(String? ministry) {
    _criteria = _criteria.copyWith(ministry: ministry);
    _applyFilters();
  }

  /// Set tags filter
  void setTagsFilter(List<String>? tags) {
    _criteria = _criteria.copyWith(tags: tags);
    _applyFilters();
  }

  /// Get all unique tags from schemes
  List<String> get allTags {
    final tagsSet = <String>{};
    for (final scheme in _schemes) {
      if (scheme.tags != null) {
        tagsSet.addAll(scheme.tags!);
      }
    }
    return tagsSet.toList()..sort();
  }

  /// Set sort option
  void setSortBy(SchemeSortBy sortBy, {bool? ascending}) {
    _criteria = _criteria.copyWith(
      sortBy: sortBy,
      ascending: ascending ?? _criteria.ascending,
    );
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _criteria = SchemeSearchCriteria();
    _filteredSchemes = [];
    notifyListeners();
  }

  /// Apply current filters to schemes
  void _applyFilters() {
    var result = List<SchemeModel>.from(_schemes);

    // Search query filter - also checks beneficiaryState for state-based search
    if (_criteria.searchQuery != null && _criteria.searchQuery!.isNotEmpty) {
      final query = _criteria.searchQuery!.toLowerCase();
      result = result.where((scheme) {
        return scheme.schemeName.toLowerCase().contains(query) ||
            (scheme.briefDescription?.toLowerCase().contains(query) ?? false) ||
            (scheme.schemeShortTitle?.toLowerCase().contains(query) ?? false) ||
            (scheme.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false) ||
            (scheme.schemeCategory?.any((cat) => cat.toLowerCase().contains(query)) ?? false) ||
            (scheme.beneficiaryState?.any((state) => state.toLowerCase().contains(query)) ?? false) ||
            (scheme.nodalMinistryName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Level filter
    if (_criteria.level != null) {
      result = result.where((s) => 
          s.level?.toLowerCase() == _criteria.level!.toLowerCase()
      ).toList();
    }

    // SchemeFor filter
    if (_criteria.schemeFor != null) {
      result = result.where((s) => 
          s.schemeFor?.toLowerCase() == _criteria.schemeFor!.toLowerCase()
      ).toList();
    }

    // States filter (check if any state matches)
    if (_criteria.states != null && _criteria.states!.isNotEmpty) {
      result = result.where((scheme) {
        if (scheme.beneficiaryState == null) return false;
        return _criteria.states!.any((state) =>
            scheme.beneficiaryState!.any((s) => 
                s.toLowerCase() == state.toLowerCase()
            )
        );
      }).toList();
    }

    // Categories filter
    if (_criteria.categories != null && _criteria.categories!.isNotEmpty) {
      result = result.where((scheme) {
        if (scheme.schemeCategory == null) return false;
        return _criteria.categories!.any((cat) =>
            scheme.schemeCategory!.any((c) => 
                c.toLowerCase() == cat.toLowerCase()
            )
        );
      }).toList();
    }

    // Ministry filter
    if (_criteria.ministry != null) {
      result = result.where((s) =>
          s.nodalMinistryName?.toLowerCase() == _criteria.ministry!.toLowerCase()
      ).toList();
    }

    // Tags filter
    if (_criteria.tags != null && _criteria.tags!.isNotEmpty) {
      result = result.where((scheme) {
        if (scheme.tags == null) return false;
        return _criteria.tags!.any((tag) =>
            scheme.tags!.any((t) => t.toLowerCase() == tag.toLowerCase())
        );
      }).toList();
    }

    // Sort
    result.sort((a, b) {
      int comparison;
      switch (_criteria.sortBy) {
        case SchemeSortBy.priority:
          comparison = (b.priority ?? 0).compareTo(a.priority ?? 0);
          break;
        case SchemeSortBy.uploadDate:
          comparison = b.uploadDate.compareTo(a.uploadDate);
          break;
        case SchemeSortBy.schemeName:
          comparison = a.schemeName.compareTo(b.schemeName);
          break;
      }
      return _criteria.ascending ? comparison : -comparison;
    });

    _filteredSchemes = result;
    notifyListeners();
  }

  /// Get scheme by ID
  SchemeModel? getSchemeById(String id) {
    try {
      return _schemes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get scheme by slug
  SchemeModel? getSchemeBySlug(String slug) {
    try {
      return _schemes.firstWhere((s) => s.slug == slug);
    } catch (_) {
      return null;
    }
  }

  /// Get schemes by level
  List<SchemeModel> getSchemesByLevel(String level) {
    return _schemes.where((s) => 
        s.level?.toLowerCase() == level.toLowerCase()
    ).toList();
  }

  /// Get central schemes
  List<SchemeModel> get centralSchemes => 
      _schemes.where((s) => s.isCentralScheme).toList();

  /// Get state schemes
  List<SchemeModel> get stateSchemes => 
      _schemes.where((s) => s.isStateScheme).toList();

  /// Get recommended schemes based on user state
  List<SchemeModel> getRecommendedSchemes(String userState, {int limit = 10}) {
    return _schemes.where((scheme) {
      if (scheme.beneficiaryState == null) return true; // Central schemes
      return scheme.beneficiaryState!.any((s) => 
          s.toLowerCase() == userState.toLowerCase() ||
          s.toLowerCase() == 'all'
      );
    }).take(limit).toList();
  }

  /// Refresh data
  Future<void> refresh() async {
    await fetchSchemes(forceRefresh: true);
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _schemesBox?.clear();
    await _filtersBox?.clear();
    _lastFetchTime = null;
    _schemes = [];
    _filters = [];
    _filteredSchemes = [];
    _groupedFilters = SchemeFiltersGrouped();
    _state = SchemeLoadingState.initial;
    notifyListeners();
  }

  @override
  void dispose() {
    _schemesBox?.close();
    _filtersBox?.close();
    super.dispose();
  }
}