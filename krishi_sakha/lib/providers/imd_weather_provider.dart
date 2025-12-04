import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/station_model.dart';
import '../models/imd_weather_model.dart';
import 'package:http/http.dart' as http;
import '../apis/api_manager.dart';

class ImdWeatherProvider with ChangeNotifier {
  static const String _weatherBoxName = 'imd_weather';

  static const String _savedStationsKey = 'saved_stations';
  SupabaseClient client = Supabase.instance.client; 
  Box<ImdWeatherResponse>? _weatherBox;
  Box<String>? _stationsBox;
  
  // Station data for selection
  List<Station> _availableStations = [];
  
  // Saved stations (ordered list of station IDs)
  List<String> _savedStationIds = [];
  
  // Weather data map
  Map<String, ImdWeatherResponse> _weatherMap = {};
  
  // UI State
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isFetchingStations = false;
  String? _error;
  int _currentStationIndex = 0;
  PageController? _pageController;

  // Getters
  List<Station> get availableStations => _availableStations;
  List<String> get savedStationIds => _savedStationIds;
  Map<String, ImdWeatherResponse> get weatherData => _weatherMap;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isFetchingStations => _isFetchingStations;
  String? get error => _error;
  int get currentStationIndex => _currentStationIndex;
  PageController? get pageController => _pageController;
  
  // Get ordered weather list based on saved station order
  List<ImdWeatherResponse> get orderedWeatherList {
    return _savedStationIds
        .where((id) => _weatherMap.containsKey(id))
        .map((id) => _weatherMap[id]!)
        .toList();
  }
  
  ImdWeatherResponse? get currentWeather {
    final list = orderedWeatherList;
    if (list.isEmpty || _currentStationIndex >= list.length) return null;
    return list[_currentStationIndex];
  }
  
  bool get hasStations => _savedStationIds.isNotEmpty;

  ImdWeatherProvider() {
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      _weatherBox = await Hive.openBox<ImdWeatherResponse>(_weatherBoxName);
      _stationsBox = await Hive.openBox<String>('imd_saved_stations');
      await _loadSavedData();
      AppLogger.debug('IMD Weather Provider initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing Hive', e, stackTrace);
      _setError('Failed to initialize local storage');
    }
  }

  Future<void> initHive() async {
    if (_weatherBox == null || _stationsBox == null) {
      await _initializeHive();
    }
  }

  Future<void> _loadSavedData() async {
    try {
      // Load saved station IDs
      final savedStationsJson = _stationsBox?.get(_savedStationsKey);
      if (savedStationsJson != null) {
        _savedStationIds = List<String>.from(jsonDecode(savedStationsJson));
      }
      
      // Load weather data
      _weatherMap.clear();
      if (_weatherBox != null) {
        for (final key in _weatherBox!.keys) {
          final response = _weatherBox!.get(key);
          if (response != null && response.station.isNotEmpty) {
            // Key is the stationId we used when saving
            _weatherMap[key.toString()] = response;
          }
        }
      }
      
      // Clean up saved station IDs - remove any that don't have weather data
      _savedStationIds = _savedStationIds.where((id) => _weatherMap.containsKey(id)).toList();
      await _saveSavedStationIds();
      
      AppLogger.debug('Loaded ${_weatherMap.length} weather entries and ${_savedStationIds.length} saved stations');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error loading saved data', e, stackTrace);
    }
  }

  Future<void> _saveSavedStationIds() async {
    try {
      await _stationsBox?.put(_savedStationsKey, jsonEncode(_savedStationIds));
    } catch (e) {
      AppLogger.error('Error saving station IDs', e);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  void _setFetchingStations(bool fetching) {
    _isFetchingStations = fetching;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set page controller
  void setPageController(PageController controller) {
    _pageController = controller;
  }

  // Set current station index
  void setCurrentStationIndex(int index) {
    if (index >= 0 && index < orderedWeatherList.length) {
      _currentStationIndex = index;
      notifyListeners();
    }
  }

  /// Fetch stations for a state
  Future<void> fetchStationsForState(String stateName) async {
    _setFetchingStations(true);
    _setError(null);
    
    try {
     final token =  client.auth.currentSession?.accessToken??"";

      AppLogger.info('Fetching stations for state: $stateName');
      final response = await http.get(Uri.parse(ApiManager.imdStationsUrl(stateName)), headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final stationListResponse = StationListResponse.fromJson(jsonDecode(response.body));
        _availableStations = stationListResponse.stations;
        AppLogger.debug('Fetched ${_availableStations.length} stations for $stateName');
        notifyListeners();
      } else {
        _setError('Failed to load stations: ${response.statusCode}');
        AppLogger.error('Failed to load stations for $stateName: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _setError('Error fetching stations');
      AppLogger.error('Error fetching stations for $stateName', e, stackTrace);
    } finally {
      _setFetchingStations(false);
    }
  }

  /// Clear available stations (when leaving station selection)
  void clearAvailableStations() {
    _availableStations = [];
    notifyListeners();
  }

  /// Fetch weather for a station and add to saved list
  Future<bool> addStation(String stationId) async {
    if (_savedStationIds.contains(stationId)) {
      AppLogger.debug('Station $stationId already saved');
      return true;
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      AppLogger.info('Fetching weather for station: $stationId');
      String uri = ApiManager.imdWeatherUrl(stationId);
      AppLogger.debug('Requesting URL: $uri');
           final token =  client.auth.currentSession?.accessToken??"";

      final response = await http.get(Uri.parse(uri), headers: {
        'Authorization' : 'Bearer $token',
      });
      
      if (response.statusCode == 200) {
        final weatherResponse = ImdWeatherResponse.fromJson(jsonDecode(response.body));
        
        // Save to Hive
        await _weatherBox?.put(stationId, weatherResponse);
        
        // Update local state
        _weatherMap[stationId] = weatherResponse;
        _savedStationIds.add(stationId);
        await _saveSavedStationIds();
        
        AppLogger.debug('Added station $stationId successfully');
        notifyListeners();
        return true;
      } else {
        _setError('Failed to fetch weather: ${response.statusCode}');
        AppLogger.error('Failed to fetch weather for $stationId: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      _setError('Error adding station');
      AppLogger.error('Error fetching weather for $stationId', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Remove a station
  Future<void> removeStation(String stationId) async {
    try {
      _savedStationIds.remove(stationId);
      _weatherMap.remove(stationId);
      await _weatherBox?.delete(stationId);
      await _saveSavedStationIds();
      
      // Adjust current index if needed
      if (_currentStationIndex >= orderedWeatherList.length && _currentStationIndex > 0) {
        _currentStationIndex = orderedWeatherList.length - 1;
      }
      
      AppLogger.debug('Removed station $stationId');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error removing station $stationId', e, stackTrace);
    }
  }

  /// Reorder stations
  Future<void> reorderStations(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final stationId = _savedStationIds.removeAt(oldIndex);
    _savedStationIds.insert(newIndex, stationId);
    await _saveSavedStationIds();
    AppLogger.debug('Reordered stations: moved $stationId from $oldIndex to $newIndex');
    notifyListeners();
  }

  /// Refresh weather for a specific station
  Future<void> refreshStationWeather(String stationId) async {
    try {
      final response = await http.get(Uri.parse(ApiManager.baseUrl+ ApiManager.imdWeatherUrl(stationId)));
      
      if (response.statusCode == 200) {
        final weatherResponse = ImdWeatherResponse.fromJson(jsonDecode(response.body));
        await _weatherBox?.put(stationId, weatherResponse);
        _weatherMap[stationId] = weatherResponse;
        AppLogger.debug('Refreshed weather for station $stationId');
        notifyListeners();
      } else {
        AppLogger.error('Failed to refresh weather for $stationId: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error refreshing weather for $stationId', e, stackTrace);
    }
  }

  /// Refresh current station weather
  Future<void> refreshCurrentWeather() async {
    if (_currentStationIndex >= _savedStationIds.length) return;
    final stationId = _savedStationIds[_currentStationIndex];
    
    _setRefreshing(true);
    _setError(null);
    
    try {
      await refreshStationWeather(stationId);
    } catch (e) {
      _setError('Failed to refresh weather');
    } finally {
      _setRefreshing(false);
    }
  }

  /// Refresh all saved stations' weather
  Future<void> refreshAllWeather() async {
    _setRefreshing(true);
    _setError(null);
    
    try {
      for (final stationId in _savedStationIds) {
        await refreshStationWeather(stationId);
      }
      AppLogger.info('Refreshed weather for all ${_savedStationIds.length} stations');
    } catch (e) {
      _setError('Failed to refresh weather');
    } finally {
      _setRefreshing(false);
    }
  }

  /// Get weather for a specific station
  ImdWeatherResponse? getWeatherForStation(String stationId) {
    return _weatherMap[stationId];
  }

  /// Check if a station is already saved
  bool isStationSaved(String stationId) {
    return _savedStationIds.contains(stationId);
  }

  /// Clear all data
  Future<void> clearAllData() async {
    await _weatherBox?.clear();
    _savedStationIds.clear();
    _weatherMap.clear();
    await _saveSavedStationIds();
    _currentStationIndex = 0;
    AppLogger.info('Cleared all IMD weather data');
    notifyListeners();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}
