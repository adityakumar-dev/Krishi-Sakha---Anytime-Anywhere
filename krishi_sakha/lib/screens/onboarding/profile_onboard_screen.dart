import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/services/weather_service.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';
import 'package:krishi_sakha/utils/ui/set_system_ui_overlay.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krishi_sakha/models/users_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileOnboardScreen extends StatefulWidget {
  const ProfileOnboardScreen({super.key});

  @override
  State<ProfileOnboardScreen> createState() => _ProfileOnboardScreenState();
}

class _ProfileOnboardScreenState extends State<ProfileOnboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = false;
  bool _isAutofillLoading = false;

  @override
  void initState() {
    super.initState();
    setSystemUIOverlayStyle();
    // Automatically try to autofill location when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autofillLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Lottie Animation
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D5016).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    'assets/lottie/farmers.json',
                    height: 150,
                    width: 150,
                  ),
                ),

                const SizedBox(height: 30),

                // Welcome text
                const Text(
                  'Tell us about yourself',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'This information helps us provide personalized farming assistance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Profile Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.primaryBlack),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF2D5016),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D5016),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          if (value.length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: AppColors.primaryBlack),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF2D5016),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D5016),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length < 10) {
                            return 'Phone number must be at least 10 digits';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // City Field
                      TextFormField(
                        controller: _cityController,
                        readOnly: true,
                        style: const TextStyle(color: AppColors.primaryBlack),
                        decoration: InputDecoration(
                          labelText: 'City',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.location_city_outlined,
                            color: Color(0xFF2D5016),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D5016),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your city';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // State Field
                      TextFormField(
                        controller: _stateController,
                        readOnly: true,
                        style: const TextStyle(color: AppColors.primaryBlack),
                        decoration: InputDecoration(
                          labelText: 'State',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.map_outlined,
                            color: Color(0xFF2D5016),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2D5016),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your state';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Autofill Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2D5016),
                            width: 2,
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isAutofillLoading ? null : _autofillLocation,
                          icon: _isAutofillLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF2D5016),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Color(0xFF2D5016),
                                ),
                          label: Text(
                            _isAutofillLoading ? 'Getting Location...' : 'Retry Autofill Location',
                            style: const TextStyle(
                              color: Color(0xFF2D5016),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D5016).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016),
                            foregroundColor: AppColors.primaryWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryWhite,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Complete Profile',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _autofillLocation() async {
    setState(() {
      _isAutofillLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationPermissionDialog(
          title: 'Location Services Disabled',
          message: 'Location services are disabled. Please enable them to autofill your location.',
          isServiceDisabled: true,
        );
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showLocationPermissionDialog(
            title: 'Location Permission Denied',
            message: 'Location permission is required to autofill your location. Please grant permission.',
            isPermissionDenied: true,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showLocationPermissionDialog(
          title: 'Location Permission Permanently Denied',
          message: 'Location permission is permanently denied. Please enable it in app settings.',
          isPermissionDeniedForever: true,
        );
        return;
      }


      // Get location details from WeatherService
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.autoFillProfile();

      if (profileProvider.cityController.text.isNotEmpty && profileProvider.stateController.text.isNotEmpty) {
        setState(() {
          _cityController.text = profileProvider.cityController.text;
          _stateController.text = profileProvider.stateController.text;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location autofilled successfully!'),
            backgroundColor: Color(0xFF2D5016),
          ),
        );
      } else {
        _showErrorSnackBar('Failed to get location details. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error getting location: ${e.toString()}');
    } finally {
      setState(() {
        _isAutofillLoading = false;
      });
    }
  }



  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        // Get current user ID
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          _showErrorSnackBar('User not authenticated. Please login again.');
          return;
        }


        final String area_code = _cityController.text.trim() + profileProvider.postalCode;
        // Create UsersModel object
        final profile = UsersModel(
          id: userId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          cityName: _cityController.text.trim(),
          stateName: _stateController.text.trim(),
          latitude: profileProvider.latitude.isNotEmpty ? double.parse(profileProvider.latitude) : null,
          longitude: profileProvider.longitude.isNotEmpty ? double.parse(profileProvider.longitude) : null,
          locationiqPlaceId: area_code,
          role: 'normal',
          createdAt: DateTime.now(),
        );

        // Submit profile
        profileProvider.setProfile(profile);

        // Wait for the operation to complete (listen to status changes)
        // For now, just navigate after a short delay
        await Future.delayed(const Duration(seconds: 2));

        // Check if there was an error
        if (profileProvider.error != null) {
          _showErrorSnackBar(profileProvider.error!);
        } else {
          // Navigate to home
          context.go(AppRoutes.home);
        }
      } catch (e) {
        _showErrorSnackBar('Error saving profile: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showLocationPermissionDialog({
    required String title,
    required String message,
    bool isServiceDisabled = false,
    bool isPermissionDenied = false,
    bool isPermissionDeniedForever = false,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (isPermissionDeniedForever)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry autofill
                _autofillLocation();
              },
              child: const Text('Retry'),
            ),
            if (!isPermissionDeniedForever)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // User can manually enter location
                  _showManualEntryDialog();
                },
                child: const Text('Enter Manually'),
              ),
          ],
        );
      },
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final tempCityController = TextEditingController();
        final tempStateController = TextEditingController();

        return AlertDialog(
          title: const Text('Enter Location Manually'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempCityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter your city',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tempStateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  hintText: 'Enter your state',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _cityController.text = tempCityController.text;
                  _stateController.text = tempStateController.text;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location entered manually'),
                    backgroundColor: Color(0xFF2D5016),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }
}