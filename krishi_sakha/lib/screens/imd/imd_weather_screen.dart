import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/imd_weather_model.dart';
import '../../providers/imd_weather_provider.dart';
import '../../utils/theme/colors.dart';
import 'state_list_screen.dart';
import 'widgets/imd_station_management_sheet.dart';

class ImdWeatherScreen extends StatefulWidget {
  const ImdWeatherScreen({super.key});

  @override
  State<ImdWeatherScreen> createState() => _ImdWeatherScreenState();
}

class _ImdWeatherScreenState extends State<ImdWeatherScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF7F5E8),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF7F5E8),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    final provider = Provider.of<ImdWeatherProvider>(context, listen: false);
    provider.setPageController(_pageController);
    await provider.initHive();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showStationManagement() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ImdStationManagementSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      appBar: _buildAppBar(),
      body: Consumer<ImdWeatherProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (provider.error != null) {
            return _buildErrorWidget(provider);
          }

          if (!provider.hasStations) {
            return _buildEmptyState();
          }

          return _buildWeatherContent(provider);
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF7F5E8),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'IMD Weather',
        style: TextStyle(
          color: AppColors.primaryBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.primaryBlack),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StateListScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.primaryBlack),
          onPressed: () {
            final provider = Provider.of<ImdWeatherProvider>(context, listen: false);
            provider.refreshAllWeather();
          },
        ),
      ],
    );
  }

  Widget _buildWeatherContent(ImdWeatherProvider provider) {
    final weatherList = provider.orderedWeatherList;
    
    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () => provider.refreshAllWeather(),
      child: Column(
        children: [
          if (weatherList.length > 1)
            _buildStationIndicator(provider, weatherList.length),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                provider.setCurrentStationIndex(index);
              },
              itemCount: weatherList.length,
              itemBuilder: (context, index) {
                return _buildWeatherPage(weatherList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationIndicator(ImdWeatherProvider provider, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == provider.currentStationIndex
                ? AppColors.primaryGreen
                : Colors.grey.withOpacity(0.3),
          ),
        )),
      ),
    );
  }

  Widget _buildWeatherPage(ImdWeatherResponse weather) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Header Card
          _buildStationHeader(weather),
          
          const SizedBox(height: 16),
          
          // Sun & Moon Times
          _buildSunMoonCard(weather),
          
          const SizedBox(height: 20),
          
          // Forecast Section
          if (weather.forecastPeriod.isNotEmpty) ...[
            _buildSectionHeader('Forecast', '${weather.forecastPeriod.length} days'),
            const SizedBox(height: 12),
            ...weather.forecastPeriod.map((day) => _buildForecastDayCard(day)),
          ],
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStationHeader(ImdWeatherResponse weather) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Name
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  weather.station.isNotEmpty ? weather.station : 'N/A',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Coordinates
          Text(
            '${weather.lat.toStringAsFixed(4)}°N, ${weather.lon.toStringAsFixed(4)}°E',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Last Updated
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update, size: 14, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 4),
                Text(
                  'Updated: ${weather.lastUpdated.isNotEmpty ? weather.lastUpdated : "N/A"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunMoonCard(ImdWeatherResponse weather) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildSunMoonItem(Icons.wb_sunny, Colors.orange, 'Sunrise', weather.sunrise)),
          _buildVerticalDivider(),
          Expanded(child: _buildSunMoonItem(Icons.wb_twilight, Colors.deepOrange, 'Sunset', weather.sunset)),
          _buildVerticalDivider(),
          Expanded(child: _buildSunMoonItem(Icons.nightlight_round, Colors.indigo, 'Moonrise', weather.moonrise)),
          _buildVerticalDivider(),
          Expanded(child: _buildSunMoonItem(Icons.dark_mode, Colors.blueGrey, 'Moonset', weather.moonset)),
        ],
      ),
    );
  }

  Widget _buildSunMoonItem(IconData icon, Color color, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value.isNotEmpty ? value : 'N/A',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastDayCard(ImdForecastDay day) {
    final warningColor = _getWarningColor(day.warningColor);
    final hasWarning = day.hasWarning;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasWarning ? Border.all(color: warningColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasWarning ? warningColor.withOpacity(0.1) : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Day Label & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.dayLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      Text(
                        day.displayDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Weather Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getWeatherIcon(day.img),
                    size: 28,
                    color: AppColors.primaryGreen,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Temperature
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      day.maxTemp,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      day.minTemp,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Weather Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  day.desc.isNotEmpty ? day.desc : 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryBlack,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Humidity Row
                Row(
                  children: [
                    // Morning Humidity (8:30 AM)
                    Expanded(
                      child: _buildHumidityItem(
                        '8:30 AM',
                        day.humidity0830,
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Evening Humidity (5:30 PM)
                    Expanded(
                      child: _buildHumidityItem(
                        '5:30 PM',
                        day.humidity1730,
                        Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Warning Section (if any)
          if (hasWarning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: warningColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          day.warningColor.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      day.warning,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHumidityItem(String time, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.water_drop, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getWarningColor(String color) {
    switch (color.toLowerCase()) {
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.amber;
      case 'green': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '1': return Icons.wb_sunny; // Clear
      case '2': return Icons.wb_sunny; // Mainly clear
      case '3': return Icons.wb_cloudy; // Partly cloudy
      case '4': return Icons.cloud; // Cloudy
      case '5': return Icons.cloud; // Overcast
      case '6': return Icons.grain; // Fog
      case '7': return Icons.water_drop; // Light rain
      case '8': return Icons.water_drop; // Moderate rain
      case '9': return Icons.water; // Heavy rain
      case '10': return Icons.ac_unit; // Snow
      case '11': return Icons.thunderstorm; // Thunderstorm
      case '12': return Icons.thunderstorm; // Severe thunderstorm
      case '13': return Icons.thunderstorm; // Thunder
      case '14': return Icons.flash_on; // Lightning
      default: return Icons.cloud;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: Colors.grey[400], size: 80),
            const SizedBox(height: 24),
            const Text(
              'No Stations Added',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add IMD weather stations to view forecasts.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StateListScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.primaryBlack,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Station', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ImdWeatherProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Something Went Wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Unknown error',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                _initializeProvider();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.primaryBlack,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<ImdWeatherProvider>(
      builder: (context, provider, child) {
        if (!provider.hasStations) return const SizedBox.shrink();
        return FloatingActionButton(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.primaryBlack,
          onPressed: _showStationManagement,
          child: const Icon(Icons.list),
        );
      },
    );
  }
}
