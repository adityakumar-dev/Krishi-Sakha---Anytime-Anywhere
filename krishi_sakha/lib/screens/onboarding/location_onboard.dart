import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sakha/apis/api_manager.dart';
import 'package:krishi_sakha/models/station_model.dart';
import 'package:krishi_sakha/models/users_model.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

class LocationOnboardScreen extends StatefulWidget {
  const LocationOnboardScreen({super.key});

  @override
  State<LocationOnboardScreen> createState() => _LocationOnboardScreenState();
}

class _LocationOnboardScreenState extends State<LocationOnboardScreen> {
  final _supabase = Supabase.instance.client;
  
  // Step 1: State Selection
  String? _selectedState;
  bool _isDetectingState = false;
  bool _stateDetectionFailed = false;
  
  // Step 2: Station Selection
  String? _selectedStationId;
  String? _selectedStationName;
  double? _stationDistance;
  bool _isDetectingStation = false;
  
  bool _isSaving = false;
  String? _errorMessage;
  
  Position? _currentPosition;
  List<dynamic> _alternatives = [];
  
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredStates = Station.stateList;
  
  // Current step: 1 = State Selection, 2 = Station Selection
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    
    // Auto-detect state on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectStateAutomatically();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Step 1: Detect State Automatically
  Future<void> _detectStateAutomatically() async {
    setState(() {
      _isDetectingState = true;
      _errorMessage = null;
      _stateDetectionFailed = false;
    });

    try {
      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission blocked');
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      debugPrint('📍 GPS Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      // Detect state from coordinates
      String? detectedState = _detectStateFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (detectedState == null) {
        throw Exception('Could not detect your state');
      }

      setState(() {
        _selectedState = detectedState;
        _isDetectingState = false;
      });

      // Auto-proceed to step 2: Station detection
      await Future.delayed(const Duration(milliseconds: 500));
      _detectStationAutomatically();

    } catch (e) {
      setState(() {
        _stateDetectionFailed = true;
        _isDetectingState = false;
      });
      debugPrint('⚠️ State detection failed: $e');
    }
  }

  // Step 2: Detect Nearest Station (after state is selected)
  Future<void> _detectStationAutomatically() async {
    if (_selectedState == null || _currentPosition == null) {
      // If no GPS, show manual selection
      setState(() {
        _currentStep = 2;
      });
      return;
    }

    setState(() {
      _isDetectingStation = true;
      _errorMessage = null;
      _currentStep = 2;
    });

    try {
      await _findNearestStation(
        _selectedState!,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not find nearest station. Please select manually.';
      });
      debugPrint('⚠️ Station detection failed: $e');
    } finally {
      setState(() {
        _isDetectingStation = false;
      });
    }
  }

  String? _detectStateFromCoordinates(double lat, double lon) {
    // Simple state detection based on coordinate ranges
    final stateRanges = {
      'Kerala': {'latMin': 8.0, 'latMax': 13.0, 'lonMin': 74.0, 'lonMax': 78.0},
      'Tamil Nadu': {'latMin': 8.0, 'latMax': 14.0, 'lonMin': 76.0, 'lonMax': 81.0},
      'Karnataka': {'latMin': 11.0, 'latMax': 18.5, 'lonMin': 74.0, 'lonMax': 79.0},
      'Maharashtra': {'latMin': 15.5, 'latMax': 22.0, 'lonMin': 72.5, 'lonMax': 80.5},
      'Gujarat': {'latMin': 20.0, 'latMax': 24.5, 'lonMin': 68.0, 'lonMax': 74.5},
      'Rajasthan': {'latMin': 23.0, 'latMax': 30.5, 'lonMin': 69.5, 'lonMax': 78.5},
      'Uttar Pradesh': {'latMin': 23.5, 'latMax': 31.0, 'lonMin': 77.0, 'lonMax': 84.5},
      'West Bengal': {'latMin': 21.5, 'latMax': 27.5, 'lonMin': 85.0, 'lonMax': 89.5},
      'Andhra Pradesh': {'latMin': 12.5, 'latMax': 19.5, 'lonMin': 76.5, 'lonMax': 85.0},
      'Telangana': {'latMin': 15.5, 'latMax': 20.0, 'lonMin': 77.0, 'lonMax': 81.5},
      'Madhya Pradesh': {'latMin': 21.0, 'latMax': 26.5, 'lonMin': 74.0, 'lonMax': 82.5},
      'Punjab': {'latMin': 29.5, 'latMax': 32.5, 'lonMin': 73.5, 'lonMax': 76.5},
      'Haryana': {'latMin': 27.5, 'latMax': 30.5, 'lonMin': 74.5, 'lonMax': 77.5},
      'Bihar': {'latMin': 24.0, 'latMax': 27.5, 'lonMin': 83.0, 'lonMax': 88.5},
      'Orissa': {'latMin': 17.5, 'latMax': 22.5, 'lonMin': 81.5, 'lonMax': 87.5},
    };

    for (var entry in stateRanges.entries) {
      final range = entry.value;
      if (lat >= range['latMin']! && lat <= range['latMax']! &&
          lon >= range['lonMin']! && lon <= range['lonMax']!) {
        debugPrint('🎯 Detected state: ${entry.key}');
        return entry.key;
      }
    }

    return null;
  }

  Future<void> _findNearestStation(String state, double lat, double lon) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session?.accessToken == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse('${ApiManager.baseUrl}/weather/find-station');
      
      debugPrint('🔍 Finding nearest station for $state at ($lat, $lon)');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${session!.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'state_name': state,
          'latitude': lat,
          'longitude': lon,
          'max_distance_km': 200,
          'max_workers': 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['station'] != null) {
          final station = data['station'];
          setState(() {
            _selectedStationId = station['station_id'];
            _selectedStationName = station['station_name'];
            _stationDistance = station['distance_km']?.toDouble();
            _alternatives = data['alternatives'] ?? [];
          });
          
          debugPrint('✅ Found station: $_selectedStationName ($_selectedStationId) - ${_stationDistance}km away');
        } else {
          throw Exception(data['error'] ?? 'No station found nearby');
        }
      } else {
        throw Exception('Failed to find station: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to find nearest station: $e';
      });
      debugPrint('❌ Station search error: $e');
    }
  }

  Future<void> _saveLocationPreferences() async {
    if (_selectedState == null || _selectedStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select state and station')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Save to backend
      final session = _supabase.auth.currentSession;
      final url = Uri.parse('${ApiManager.baseUrl}/user/location');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${session!.accessToken}',
        },
        body: {
          'state_name': _selectedState!,
          'station_id': _selectedStationId!,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save location: ${response.body}');
      }

      debugPrint('✅ Location saved to backend');

      // Save to local storage using ProfileProvider
      if (mounted) {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        
        // Update the user profile with location preferences
        if (profileProvider.userProfile != null) {
          final updatedUser = profileProvider.userProfile!.copyWith(
            preferedStateName: _selectedState,
            preferredWeatherStationId: _selectedStationId,
          );
          
          // Save using ProfileProvider's Hive box
          final box = await Hive.openBox<UsersModel>('user_profile');
          await box.clear();
          await box.add(updatedUser);
          
          debugPrint('✅ Location saved to local storage via ProfileProvider');
          
          // Refresh profile provider to reflect changes
          await profileProvider.initProfile();
        }
      }

      // Navigate to home
      if (mounted) {
        
        context.go(AppRoutes.home);
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save: $e';
      });
      debugPrint('❌ Save error: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStates = Station.stateList;
      } else {
        _filteredStates = Station.stateList
            .where((state) => state.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step 1: State Selection
                    if (_currentStep == 1) ...[
                      _buildStep1StateSelection(),
                    ],
                    
                    // Step 2: Station Selection
                    if (_currentStep == 2) ...[
                      _buildStep2StationSelection(),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Show selected location summary
                    if (_selectedState != null && _selectedStationId != null) ...[
                      _buildSelectedLocationCard(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Show alternatives
                    if (_alternatives.isNotEmpty && _currentStep == 2) ...[
                      _buildAlternativeStations(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Save button (only on step 2 with selections)
                    if (_currentStep == 2 && _selectedState != null)
                      _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep == 2)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                  _selectedStationId = null;
                  _selectedStationName = null;
                  _stationDistance = null;
                  _alternatives = [];
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.primaryBlack),
              onPressed: () => Navigator.pop(context),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentStep == 1 ? 'Where do you live?' : 'Find Weather Station',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentStep == 1 
                      ? 'First, let\'s find your state' 
                      : 'Finding nearest weather station',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepCircle(1, 'State', _currentStep >= 1),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 2 
                  ? AppColors.haraColor 
                  : Colors.grey.shade300,
            ),
          ),
          _buildStepCircle(2, 'Station', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    final isCompleted = _currentStep > step || 
        (step == 1 && _selectedState != null) ||
        (step == 2 && _selectedStationId != null);
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppColors.haraColor 
                : isActive 
                    ? AppColors.haraColor.withOpacity(0.2)
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.haraColor : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.haraColor : Colors.grey,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.haraColor : Colors.grey,
          ),
        ),
      ],
    );
  }

  // Step 1: State Selection Screen
  Widget _buildStep1StateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Auto-detect state card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.haraColor, AppColors.haraColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.haraColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_isDetectingState)
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
                  ),
                )
              else if (_selectedState != null)
                const Icon(Icons.check_circle, size: 70, color: Colors.white)
              else if (_stateDetectionFailed)
                const Icon(Icons.location_off, size: 70, color: Colors.white70)
              else
                Lottie.asset(
                  'assets/lottie/sattelite.json',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              const SizedBox(height: 16),
              Text(
                _isDetectingState
                    ? '📍 Finding your location...'
                    : _selectedState != null
                        ? '✅ Found: $_selectedState!'
                        : _stateDetectionFailed
                            ? '❌ Could not detect'
                            : '🔍 Detecting your state...',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isDetectingState
                    ? 'Please wait while we locate you'
                    : _selectedState != null
                        ? 'Tap "Continue" to find weather station'
                        : _stateDetectionFailed
                            ? 'Don\'t worry! Select your state manually below'
                            : 'Using GPS to find your state automatically',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              if (_selectedState != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 2;
                    });
                    _detectStationAutomatically();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.haraColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 24),
                  label: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (!_isDetectingState && _stateDetectionFailed) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _detectStateAutomatically,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Manual selection section
        if (_stateDetectionFailed || !_isDetectingState) ...[
          const Row(
            children: [
              Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR CHOOSE YOUR STATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(child: Divider(thickness: 1)),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text(
            '🗺️ Select Your State',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick the state where you live from the list',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // State selector button
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _showStateSelector,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedState != null 
                        ? AppColors.haraColor 
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.haraColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: AppColors.haraColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedState ?? 'Tap to select',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedState != null 
                                  ? AppColors.primaryBlack 
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedState != null 
                                ? 'Tap to change' 
                                : 'Choose from ${Station.stateList.length} states',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.haraColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_selectedState != null && _stateDetectionFailed) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.haraColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'Continue to Find Station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // Step 2: Station Selection Screen
  Widget _buildStep2StationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show selected state
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.haraColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.haraColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.haraColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your State',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _selectedState ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Auto-detect station
        if (_isDetectingStation)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Lottie.asset(
                  'assets/lottie/loading.json',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                const Text(
                  '🛰️ Finding nearest weather station...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Searching for the closest station in your area',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_selectedStationId == null && _currentPosition != null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Could not auto-detect station',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please select a weather station manually from the list below',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    if (_currentPosition != null) {
                      _detectStationAutomatically();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          )
        else if (_selectedStationId == null)
          const SizedBox.shrink(),
        
        if (!_isDetectingStation && _currentPosition == null) ...[
          const Text(
            '☁️ Select Weather Station',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the weather station closest to you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _showStationSelector(_selectedState!),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedStationId != null 
                        ? AppColors.haraColor 
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.haraColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud,
                        color: AppColors.haraColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStationName ?? 'Tap to select station',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedStationId != null 
                                  ? AppColors.primaryBlack 
                                  : Colors.grey,
                            ),
                          ),
                          if (_selectedStationId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ID: $_selectedStationId',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.haraColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManualSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR SELECT MANUALLY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        
        // State Selection
        const Text(
          'Select Your State',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search or select state...',
            prefixIcon: const Icon(Icons.search, color: AppColors.haraColor),
            suffixIcon: _selectedState != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedState = null;
                        _selectedStationId = null;
                        _selectedStationName = null;
                        _searchController.clear();
                        _filteredStates = Station.stateList;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.haraColor, width: 2),
            ),
          ),
          readOnly: true,
          onTap: () => _showStateSelector(),
        ),
      ],
    );
  }

  Widget _buildSelectedLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.haraColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.haraColor, size: 24),
              SizedBox(width: 12),
              Text(
                'Selected Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, 'State', _selectedState!),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.cloud, 'Weather Station', _selectedStationName ?? 'Unknown'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.badge, 'Station ID', _selectedStationId!),
          if (_stationDistance != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.straighten,
              'Distance',
              '${_stationDistance!.toStringAsFixed(1)} km away',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.haraColor.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeStations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Alternative Stations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 12),
        ...(_alternatives.take(3).map((station) => _buildAlternativeCard(station))),
      ],
    );
  }

  Widget _buildAlternativeCard(dynamic station) {
    final stationId = station['station_id'];
    final stationName = station['station_name'];
    final distance = station['distance_km']?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.haraColor.withOpacity(0.1),
          child: const Icon(Icons.cloud_outlined, color: AppColors.haraColor),
        ),
        title: Text(
          stationName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${distance.toStringAsFixed(1)} km away • ID: $stationId'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          setState(() {
            _selectedStationId = stationId;
            _selectedStationName = stationName;
            _stationDistance = distance;
          });
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _selectedState != null && _selectedStationId != null;

    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton(
          onPressed: canSave && !_isSaving ? _saveLocationPreferences : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.haraColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check),
                    SizedBox(width: 8),
                    Text(
                      'Save & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showStateSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F5E8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Select State',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredStates.length,
                  itemBuilder: (context, index) {
                    final state = _filteredStates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.haraColor.withOpacity(0.1),
                          child: const Icon(
                            Icons.location_city,
                            color: AppColors.haraColor,
                          ),
                        ),
                        title: Text(
                          state,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          setState(() {
                            _selectedState = state;
                            _searchController.text = state;
                          });
                          Navigator.pop(context);
                          _showStationSelector(state);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStationSelector(String state) async {
    // Show loading while fetching stations
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.haraColor),
      ),
    );

    try {
      // Fetch stations from API
      final url = Uri.parse('${ApiManager.baseUrl}/weather/stations/$state');
      final session = _supabase.auth.currentSession;
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${session!.accessToken}',
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch stations');
      }

      final data = jsonDecode(response.body);
      final stationList = (data['stations'] as List)
          .map((s) => Station.fromJson(s))
          .toList();

      _showStationBottomSheet(state, stationList);
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load stations: $e')),
      );
    }
  }

  void _showStationBottomSheet(String state, List<Station> stations) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F5E8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Weather Station',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$state • ${stations.length} stations',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.haraColor.withOpacity(0.1),
                          child: const Icon(
                            Icons.cloud,
                            color: AppColors.haraColor,
                          ),
                        ),
                        title: Text(
                          station.stationName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Station ID: ${station.stationId}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          setState(() {
                            _selectedStationId = station.stationId;
                            _selectedStationName = station.stationName;
                            _stationDistance = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
