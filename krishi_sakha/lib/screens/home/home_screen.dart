import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';
import 'package:krishi_sakha/models/weather_model.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/providers/weather_provider.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';
import 'package:krishi_sakha/utils/ui/set_system_ui_overlay.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    setSystemUIOverlayStyle();
    _initConnectivity();
    _loadWeather();
  }

  Future<void> _initConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = !connectivityResult.contains(ConnectivityResult.none);
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = !result.contains(ConnectivityResult.none);
      });
    });
  }

  Future<void> _loadWeather() async {
    if (_isLoadingWeather) return;
    
    setState(() => _isLoadingWeather = true);
    
    try {
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      
      // Initialize weather with current location or refresh existing data
      if (weatherProvider.savedCities.isEmpty) {
        await weatherProvider.initializeWithCurrentLocation();
      } else {
        await weatherProvider.refreshCurrentWeather();
      }
    } catch (e) {
      print('Error loading weather: $e');
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWeather,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Sticky Header
              SliverAppBar(
                pinned: true,
                floating: false,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primaryWhite,
                elevation: 0,
                toolbarHeight: 140,
                flexibleSpace: _buildHeader(profileProvider.userProfile?.name, _isOnline),
              ),
              // Scrollable content
              SliverList(
                delegate: SliverChildListDelegate([
                  // Weather Section (Compact)
                  _buildWeatherSection(weatherProvider, _isLoadingWeather),
                
                // Connectivity Banner
                if (!_isOnline)
                  _buildOfflineBanner(),
                
                // Online Section (shown first when online)
                if (_isOnline) ...[
                  _buildOnlineSection(profileProvider.userProfile?.role ?? 'normal'),
                  const SizedBox(height: 24),
                ],
                
                // Offline Section (always visible, blurred when offline)
                _buildOfflineSection(_isOnline),
                
                // Online Section (blurred when offline, shown after offline when offline)
                if (!_isOnline)
                  _buildOnlineSection(
                    profileProvider.userProfile?.role ?? 'normal',
                    isBlurred: true,
                  ),
                  
                  const SizedBox(height: 24),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? name, bool isOnline) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/krishi_logo.png', height: 24, width: 24),
                    const SizedBox(width: 8),
                    // Connection indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOnline ? Icons.wifi : Icons.wifi_off,
                            size: 12,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isOnline ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context)!.hello}, ${name ?? "Farmer"}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.smartFarmingBegins,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Leaderboard Icon
          IconButton(
            onPressed: () => context.push(AppRoutes.leaderboard),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFB5607).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/trophy.png',
                height: 24,
                width: 24,
              ),
            ),
          ),
          // Create Post Icon (role-based)
          IconButton(
            onPressed: () => context.push(
              profileProvider.userProfile?.role != 'normal'
                  ? AppRoutes.createExpertPosts
                  : AppRoutes.createPost,
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3A86FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/pencil.png',
                height: 24,
                width: 24,
              ),
            ),
          ),
          // Profile Icon
          IconButton(
            onPressed: () => context.push(AppRoutes.profile),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.haraColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.haraColor,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(WeatherProvider weatherProvider, bool isLoading) {
    final weatherData = weatherProvider.currentWeatherData;
    final currentCity = weatherProvider.currentCity;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3),
            const Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : weatherData == null
              ? _buildWeatherError()
              : _buildWeatherContent(weatherData, currentCity),
    );
  }

  Widget _buildWeatherError() {
    return Column(
      children: [
        const Icon(Icons.cloud_off, size: 48, color: Colors.white70),
        const SizedBox(height: 12),
        Text(
          'Weather data unavailable',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _loadWeather,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2196F3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherContent(WeatherData weatherData, CityLocation? location) {
    final current = weatherData.current;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location?.name ?? 'Current Location',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.weather),
              icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              label: const Text(
                'View Details',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current.temperature.toStringAsFixed(0)}°C',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current.weatherDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _getWeatherIcon(int.tryParse(current.weatherCode) ?? 0),
              size: 48,
              color: Colors.white70,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildWeatherInfo(Icons.water_drop, 'Humidity', '${current.humidity}%'),
            const SizedBox(width: 20),
            _buildWeatherInfo(Icons.air, 'Wind', '${current.windSpeed.toStringAsFixed(1)} km/h'),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are currently offline. Some features may not work.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineSection(String role, {bool isBlurred = false}) {
    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.onlineFeatures,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              // AI Chat
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.chat,
                subtitle: AppLocalizations.of(context)!.askAnything,
                imagePath: 'assets/images/chatbot.png',
                color: const Color(0xFF5C7C8A),
                onTap: () => context.push(AppRoutes.chatServer),
                isEnabled: !isBlurred,
              ),
              // Voice Chat
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.voiceChat,
                subtitle: AppLocalizations.of(context)!.speakToAI,
                imagePath: 'assets/images/voice-bot.png',
                color: const Color(0xFFFF6B6B),
                onTap: () => context.push(AppRoutes.voiceChat),
                isEnabled: !isBlurred,
              ),
              // Community Posts
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.posts,
                subtitle: AppLocalizations.of(context)!.community,
                imagePath: 'assets/images/add_post.png',
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.posts),
                isEnabled: !isBlurred,
              ),
              // Expert Posts
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.expertPosts,
                subtitle: AppLocalizations.of(context)!.advice,
                imagePath: 'assets/images/badge.png',
                color: const Color(0xFF4ECDC4),
                onTap: () => context.push(AppRoutes.expertPosts),
                isEnabled: !isBlurred,
              ),
              // Schemes
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.myScheme,
                subtitle: AppLocalizations.of(context)!.govtSchemes,
                imagePath: 'assets/images/money-bag.png',
                color: const Color(0xFF95E1D3),
                onTap: () => context.push(AppRoutes.schemes),
                isEnabled: !isBlurred,
              ),
              // Mandi Prices
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.mandiPrices,
                subtitle: AppLocalizations.of(context)!.liveRates,
                imagePath: 'assets/images/price-up.png',
                color: const Color(0xFFFFBE0B),
                onTap: () => context.push(AppRoutes.mandiPrice),
                isEnabled: !isBlurred,
              ),
            ],
          ),
        ],
      ),
    );

    if (isBlurred) {
      return Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Opacity(opacity: 0.5, child: content),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.requiresInternet,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }

  Widget _buildOfflineSection(bool isOnline) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_bolt, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.offlineFeatures,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              // Offline AI
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.offlineAI,
                subtitle: AppLocalizations.of(context)!.noInternetConnection,
                imagePath: 'assets/images/offline_chat.png',
                color: const Color(0xFF5C7C8A),
                onTap: () => context.push(AppRoutes.selector),
                isEnabled: true,
              ),
              // Disease Detection
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.disease,
                subtitle: AppLocalizations.of(context)!.detect,
                imagePath: 'assets/images/disease.jpeg',
                color: const Color(0xFF66BB6A),
                onTap: () => context.push(AppRoutes.plantDisease),
                isEnabled: true,
              ),
              // Weather Cache
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.weather,
                subtitle: AppLocalizations.of(context)!.cached,
                imagePath: 'assets/images/weather.png',
                color: const Color(0xFF2196F3),
                onTap: () => context.push(AppRoutes.weather),
                isEnabled: true,
              ),
              // Saved Posts
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.savedPosts,
                subtitle: AppLocalizations.of(context)!.offlineMode,
                imagePath: 'assets/images/save_post.png',
                color: const Color(0xFFFF9800),
                onTap: () => context.push(AppRoutes.savedPosts),
                isEnabled: true,
              ),
              // // Satellite View
              // _buildFeatureCard(
              //   title: AppLocalizations.of(context)!.satellite,
              //   subtitle: 'View',
              //   imagePath: 'assets/icons/satellite.png',
              //   color: const Color(0xFF9C27B0),
              //   onTap: () => context.push(AppRoutes.satteliteView),
              //   isEnabled: true,
              // ),
              // Offline Translation
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.translation,
                subtitle: AppLocalizations.of(context)!.offlineMode,
                imagePath: 'assets/images/languages.png',
                color: const Color(0xFF00BCD4),
                onTap: () => context.push(AppRoutes.test_offline_translation),
                isEnabled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                imagePath,
                height: 40,
                width: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlack,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(int weatherCode) {
    if (weatherCode == 0) return Icons.wb_sunny;
    if (weatherCode <= 3) return Icons.wb_cloudy;
    if (weatherCode <= 67) return Icons.grain;
    if (weatherCode <= 77) return Icons.ac_unit;
    return Icons.thunderstorm;
  }
}
