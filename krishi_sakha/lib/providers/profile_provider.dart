import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:krishi_sakha/apis/api_manager.dart';
import 'package:krishi_sakha/models/users_model.dart';
import 'package:krishi_sakha/services/weather_service.dart';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
class ProfileProvider extends ChangeNotifier{
  UsersModel? _userProfile;
  String? error;
  String? status = "";
  final String _boxName = 'user_profile';
  final WeatherService _service = WeatherService();
  UsersModel? get userProfile => _userProfile;

  // controller for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  
  // other fields like latitude, longitude, locationiqPlaceId can be managed directly from userProfile
  String latitude = "";
  String longitude = "";
  String locationiqPlaceId = "";
  String postalCode = "";


  Future<void> initProfile()async{
    try {
      final data = await Hive.openBox<UsersModel>(_boxName);
      if(data.isNotEmpty){
        _userProfile = data.getAt(0);
        AppLogger.debug("Profile loaded from local storage: ${_userProfile?.name}");
        status = "Profile loaded from local storage";
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 500), (){
          status = "";
          notifyListeners();
        });
        return;
      }
      else{
        _userProfile = null;
        AppLogger.debug("No profile in local storage, fetching from Supabase");
        await fetchProfile();
        notifyListeners();
        return;
      }
    } catch (e) {
      AppLogger.error("Error in initProfile: $e");
      _userProfile = null;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if(id == null) {
      _userProfile = null;
      notifyListeners();
      return;
    }
    AppLogger.debug("Fetching profile for user ID: $id");
    status = "Fetching user profile...";
    notifyListeners();

    try {
      final response = await Supabase.instance.client.from('users').select().eq('id', id).single();
      _userProfile = UsersModel.fromJson(response);
      status = "Profile fetched successfully";
      AppLogger.debug("Profile fetched: ${_userProfile?.name}");
      notifyListeners();
      
      final box = await Hive.openBox<UsersModel>(_boxName);
      await box.clear();
      await box.add(_userProfile!);
      
      Future.delayed(const Duration(milliseconds: 500), (){
        status = "";
        notifyListeners();
      });
    } catch (error) {
      AppLogger.error("Error fetching profile: $error");
      // Handle case where no profile exists (PGRST116 error)
      if (error.toString().contains('PGRST116') || error.toString().contains('multiple (or no) rows returned')) {
        _userProfile = null;
        status = "No profile found";
        AppLogger.debug("No profile found in Supabase for user $id");
      } else {
        this.error = "Failed to fetch profile: $error";
        _userProfile = null;
        AppLogger.error("Error fetching profile: $error");
      }
      status = "";
      notifyListeners();
    }
  }

  void setProfile(
    UsersModel profile
  ) async{
    final id = Supabase.instance.client.auth.currentUser?.id;
    if(id == null) {
      error = "User not authenticated";
      notifyListeners();
      return;
    }

    status = "Updating profile...";
    error = null;
    notifyListeners();

    try {
      // Prepare JSON data for the backend API
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.accessToken == null) {
        error = "User not authenticated";
        status = "";
        notifyListeners();
        return;
      }

      // Prepare JSON payload
      final jsonData = <String, dynamic>{};
      jsonData['name'] = profile.name ?? '';
      jsonData['phone'] = profile.phone ?? '';
      jsonData['city_name'] = profile.cityName ?? '';
      jsonData['state_name'] = profile.stateName ?? '';
      jsonData['latitude'] = profile.latitude ?? 0.0;
      jsonData['longitude'] = profile.longitude ?? 0.0;
      jsonData['locationiq_place_id'] = profile.locationiqPlaceId ?? '';

      // Send JSON request
     final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiManager.baseUrl + ApiManager.usersUrl),
      );
      request.headers.addAll({
            'Authorization': 'Bearer ${session!.accessToken}',
      });
    request.fields.addAll(jsonData.map((key, value) => MapEntry(key, value.toString())));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        // Success - update local profile and Hive storage
        _userProfile = profile;
        final box = await Hive.openBox<UsersModel>(_boxName);
        await box.clear();
        await box.add(_userProfile!);

        status = "Profile updated successfully";
        notifyListeners();

        // Optionally refetch from Supabase to ensure consistency
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchProfile();
        });
      } else {
        // Error handling
        error = "Failed to update profile: ${response.body}";
        AppLogger.debug("Failed to update profile: ${response.body}");
        status = "";
        notifyListeners();
      }
    } catch (e) {
      error = "Error updating profile: $e";
      status = "";
      notifyListeners();
    }
  }


  Future<void> autoFillProfile() async {
   final data = await _service.getLocationDetails(updateStatus);
    if(data.isEmpty) return;
    cityController.text = data['city_name'] ?? "";
    stateController.text = data['state_name'] ?? "";
    latitude = data['latitude'] ?? "";
    longitude = data['longitude'] ?? "";
    locationiqPlaceId = data['locationiq_place_id'] ?? "";
    postalCode = data['postal_code'] ?? "";

    AppLogger.debug("Auto-filled profile data: ${cityController.text}, ${stateController.text}, $latitude, $longitude, $locationiqPlaceId, $postalCode");
    
    notifyListeners();
  }
  void updateStatus(String newStatus){
    status = newStatus;
    notifyListeners();
  }

  // Logout method to clear all user data
  Future<void> logout() async{
    try {
      // Clear user profile
      _userProfile = null;
      
      // Clear all fields
      error = null;
      status = "";
      
      // Clear text controllers
      nameController.clear();
      phoneController.clear();
      cityController.clear();
      stateController.clear();
      
      // Clear location data
      latitude = "";
      longitude = "";
      locationiqPlaceId = "";
      Box<UsersModel> box;
      if(Hive.isBoxOpen(_boxName)){
        box = Hive.box<UsersModel>(_boxName);
      } else {
        box = await Hive.openBox<UsersModel>(_boxName);
      }
      box.clear();
      notifyListeners();
    } catch (e) {
      AppLogger.error("Error during profile logout: $e");
    }
  }

}