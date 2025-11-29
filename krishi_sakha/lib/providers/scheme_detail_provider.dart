import 'package:flutter/material.dart';
import 'package:krishi_sakha/models/scheme_detail_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SchemeDetailLoadingState { initial, loading, loaded, error }

class SchemeDetailProvider extends ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // State
  SchemeDetailLoadingState _state = SchemeDetailLoadingState.initial;
  SchemeDetailLoadingState get state => _state;

  // Current scheme detail
  SchemeDetailModel? _currentScheme;
  SchemeDetailModel? get currentScheme => _currentScheme;

  // Error handling
  String? _error;
  String? get error => _error;

  // Cache for scheme details (key: slug)
  final Map<String, SchemeDetailModel> _cache = {};

  /// Fetch scheme details by slug
  Future<void> fetchSchemeBySlug(String slug) async {
    debugPrint('🔍 Fetching scheme details for slug: "$slug"');
    
    // Check cache first
    if (_cache.containsKey(slug)) {
      _currentScheme = _cache[slug];
      _state = SchemeDetailLoadingState.loaded;
      debugPrint('✅ Found in cache');
      notifyListeners();
      return;
    }

    _state = SchemeDetailLoadingState.loading;
    _error = null;
    _currentScheme = null;
    notifyListeners();

    try {
      // Fetch scheme details
      debugPrint('📡 Querying scheme_details table...');
      final detailResponse = await _supabaseClient
          .from('scheme_details')
          .select()
          .eq('slug', slug)
          .maybeSingle();

      debugPrint('📦 Response: ${detailResponse != null ? "Found" : "null"}');
      
      if (detailResponse == null) {
        _error = 'Scheme details not found for slug: $slug';
        _state = SchemeDetailLoadingState.error;
        debugPrint('❌ Scheme not found');
        notifyListeners();
        return;
      }

      debugPrint('📋 Scheme ID: ${detailResponse['id']}');
      debugPrint('📋 Scheme Name: ${detailResponse['name']}');

      final schemeDetail = SchemeDetailModel.fromJson(detailResponse);
      debugPrint('✅ Parsed scheme detail: ${schemeDetail.name}');

      // Fetch related documents and FAQs in parallel
      debugPrint('📡 Fetching documents and FAQs for id: ${schemeDetail.id}');
      final results = await Future.wait([
        _fetchDocuments(schemeDetail.id),
        _fetchFaqs(schemeDetail.id),
      ]);

      schemeDetail.documents = results[0] as List<SchemeDocumentModel>;
      schemeDetail.faqs = results[1] as List<SchemeFaqModel>;
      
      debugPrint('📄 Documents count: ${schemeDetail.documents.length}');
      debugPrint('❓ FAQs count: ${schemeDetail.faqs.length}');

      // Cache the result
      _cache[slug] = schemeDetail;
      _currentScheme = schemeDetail;
      _state = SchemeDetailLoadingState.loaded;
      debugPrint('✅ Scheme loaded successfully!');
    } catch (e, stackTrace) {
      _error = e.toString();
      _state = SchemeDetailLoadingState.error;
      debugPrint('❌ Error fetching scheme details: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }

    notifyListeners();
  }

  /// Fetch documents for a scheme
  Future<List<SchemeDocumentModel>> _fetchDocuments(String schemeId) async {
    try {
      final response = await _supabaseClient
          .from('scheme_documents')
          .select()
          .eq('scheme_id', schemeId)
          .order('id');

      if (response.isEmpty) return [];

      return (response as List)
          .map((item) => SchemeDocumentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      return [];
    }
  }

  /// Fetch FAQs for a scheme
  Future<List<SchemeFaqModel>> _fetchFaqs(String schemeId) async {
    try {
      final response = await _supabaseClient
          .from('scheme_faqs')
          .select()
          .eq('scheme_id', schemeId)
          .order('id');

      if (response.isEmpty) return [];

      return (response as List)
          .map((item) => SchemeFaqModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      return [];
    }
  }

  /// Clear current scheme
  void clearCurrentScheme() {
    _currentScheme = null;
    _state = SchemeDetailLoadingState.initial;
    _error = null;
    notifyListeners();
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Check if scheme is in cache
  bool isInCache(String slug) => _cache.containsKey(slug);

  /// Get cached scheme
  SchemeDetailModel? getCached(String slug) => _cache[slug];
}
