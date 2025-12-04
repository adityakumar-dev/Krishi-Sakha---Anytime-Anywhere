import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sakha/apis/api_manager.dart';
import 'package:krishi_sakha/models/mandi_price_model.dart';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MandiProvider extends ChangeNotifier {
  SupabaseClient  _supabaseClient = Supabase.instance.client;
  // Response data
  MandiPriceResponse? _responseData;
  MandiPriceResponse? get responseData => _responseData;

  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Selected state
  String? _selectedState;
  String? get selectedState => _selectedState;

  // Date range
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 2));
  DateTime _toDate = DateTime.now().subtract(const Duration(days: 1));

  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;

  // Filters
  String? _selectedApmc;
  String? get selectedApmc => _selectedApmc;

  String? _selectedCommodity;
  String? get selectedCommodity => _selectedCommodity;

  // Available filter options (extracted from data)
  List<String> _availableApmcs = [];
  List<String> get availableApmcs => _availableApmcs;

  List<String> _availableCommodities = [];
  List<String> get availableCommodities => _availableCommodities;

  // Filtered data
  List<MandiPriceItem> get filteredData {
    if (_responseData == null) return [];

    return _responseData!.data.where((item) {
      bool matchesApmc = _selectedApmc == null || _selectedApmc!.isEmpty || item.apmc == _selectedApmc;
      bool matchesCommodity = _selectedCommodity == null || _selectedCommodity!.isEmpty || item.commodity == _selectedCommodity;
      return matchesApmc && matchesCommodity;
    }).toList();
  }

  // Date constraints
  DateTime get minFromDate => DateTime.now().subtract(const Duration(days: 6));
  DateTime get maxFromDate => DateTime.now().subtract(const Duration(days: 1));
  DateTime get minToDate => DateTime.now().subtract(const Duration(days: 5));
  DateTime get maxToDate => DateTime.now().subtract(const Duration(days: 1));

  // Format date for API
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Set selected state
  void setSelectedState(String state) {
    _selectedState = state;
    // Reset filters when state changes
    _selectedApmc = null;
    _selectedCommodity = null;
    _availableApmcs = [];
    _availableCommodities = [];
    notifyListeners();
  }

  // Set from date
  void setFromDate(DateTime date) {
    // Ensure date is within allowed range
    if (date.isBefore(minFromDate)) {
      date = minFromDate;
    }
    if (date.isAfter(maxFromDate)) {
      date = maxFromDate;
    }
    _fromDate = date;

    // Adjust toDate if necessary
    if (_toDate.isBefore(_fromDate)) {
      _toDate = _fromDate;
    }
    notifyListeners();
  }

  // Set to date
  void setToDate(DateTime date) {
    // Ensure date is within allowed range
    if (date.isBefore(minToDate)) {
      date = minToDate;
    }
    if (date.isAfter(maxToDate)) {
      date = maxToDate;
    }
    // Ensure toDate is not before fromDate
    if (date.isBefore(_fromDate)) {
      date = _fromDate;
    }
    _toDate = date;
    notifyListeners();
  }

  // Set APMC filter
  void setApmcFilter(String? apmc) {
    _selectedApmc = apmc;
    notifyListeners();
  }

  // Set commodity filter
  void setCommodityFilter(String? commodity) {
    _selectedCommodity = commodity;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _selectedApmc = null;
    _selectedCommodity = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Extract filter options from data
  void _extractFilterOptions() {
    if (_responseData == null) return;

    final apmcSet = <String>{};
    final commoditySet = <String>{};

    for (final item in _responseData!.data) {
      if (item.apmc.isNotEmpty) apmcSet.add(item.apmc);
      if (item.commodity.isNotEmpty) commoditySet.add(item.commodity);
    }

    _availableApmcs = apmcSet.toList()..sort();
    _availableCommodities = commoditySet.toList()..sort();
  }

  // Fetch mandi price data
  Future<void> fetchMandiPriceData() async {
    if (_selectedState == null) {
      _errorMessage = 'Please select a state first';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final fromDateStr = _formatDateForApi(_fromDate);
    final toDateStr = _formatDateForApi(_toDate);
    final token = await _supabaseClient.auth.currentSession?.accessToken;
    final String url = ApiManager.mandiTradeDataUrl(_selectedState!, fromDateStr, toDateStr);

    AppLogger.info('Fetching mandi price data from URL: $url');

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        _responseData = MandiPriceResponse.fromJson(jsonDecode(response.body));
        _extractFilterOptions();
        AppLogger.info('✅ Mandi price data fetched successfully: ${_responseData!.data.length} items');
        _isLoading = false;
        notifyListeners();
      } else {
        AppLogger.error('❌ Failed to fetch mandi price data: ${response.statusCode}');
        _errorMessage = 'Failed to fetch data. Status: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching mandi price data: $e');
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch with specific state (convenience method)
  Future<void> fetchMandiPriceDataForState(String stateName) async {
    setSelectedState(stateName);
    await fetchMandiPriceData();
  }

  // Refresh data
  Future<void> refreshData() async {
    await fetchMandiPriceData();
  }

  // Get summary statistics
  Map<String, dynamic> get summaryStats {
    final data = filteredData;
    if (data.isEmpty) {
      return {
        'totalItems': 0,
        'uniqueApmcs': 0,
        'uniqueCommodities': 0,
        'avgModalPrice': 0.0,
      };
    }

    final apmcSet = data.map((e) => e.apmc).toSet();
    final commoditySet = data.map((e) => e.commodity).toSet();

    double totalModalPrice = 0;
    int validPriceCount = 0;
    for (final item in data) {
      final price = item.modalPriceValue;
      if (price != null) {
        totalModalPrice += price;
        validPriceCount++;
      }
    }

    return {
      'totalItems': data.length,
      'uniqueApmcs': apmcSet.length,
      'uniqueCommodities': commoditySet.length,
      'avgModalPrice': validPriceCount > 0 ? totalModalPrice / validPriceCount : 0.0,
    };
  }
}
