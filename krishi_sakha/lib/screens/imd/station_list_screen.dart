import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';
import 'package:provider/provider.dart';
import '../../models/station_model.dart';
import '../../providers/imd_weather_provider.dart';
import '../../utils/theme/colors.dart';
import 'imd_weather_screen.dart';

class StationListScreen extends StatefulWidget {
  final String stateName;

  const StationListScreen({super.key, required this.stateName});

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Station> _filteredStations = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF7F5E8),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF7F5E8),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStations() async {
    final provider = Provider.of<ImdWeatherProvider>(context, listen: false);
    await provider.fetchStationsForState(widget.stateName);
    _updateFilteredStations();
  }

  void _updateFilteredStations() {
    final provider = Provider.of<ImdWeatherProvider>(context, listen: false);
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredStations = provider.availableStations;
      } else {
        _filteredStations = provider.availableStations.where((station) {
          return station.stationName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 station.stationId.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _updateFilteredStations();
  }

  Future<void> _addStation(Station station, ImdWeatherProvider provider) async {
    // Check if already saved
    if (provider.isStationSaved(station.stationId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${station.stationName} is already in your list'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryGreen),
                SizedBox(height: 16),
                Text(
                  'Adding station...',
                  style: TextStyle(color: AppColors.primaryBlack),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await provider.addStation(station.stationId);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${station.stationName} added successfully!'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          
          
          // Navigate to weather screen
          context.push(AppRoutes.imdWeather);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add ${station.stationName}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<ImdWeatherProvider>(
              builder: (context, provider, child) {
                if (provider.isFetchingStations) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );
                }

                if (provider.error != null) {
                  return _buildErrorWidget(provider);
                }

                if (_filteredStations.isEmpty && provider.availableStations.isEmpty) {
                  return _buildEmptyState();
                }

                if (_filteredStations.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildNoSearchResults();
                }

                return _buildStationList(provider);
              },
            ),
          ),
        ],
      ),
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
      title: Text(
        '${widget.stateName} Stations',
        style: const TextStyle(
          color: AppColors.primaryBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search stations...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
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
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildStationList(ImdWeatherProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredStations.length,
      itemBuilder: (context, index) {
        final station = _filteredStations[index];
        final isSaved = provider.isStationSaved(station.stationId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _addStation(station, provider),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSaved 
                          ? AppColors.primaryGreen.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: isSaved ? AppColors.primaryGreen : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.stationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Station ID: ${station.stationId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSaved)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryGreen,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: AppColors.primaryBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Stations Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No weather stations available for ${widget.stateName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchStations,
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

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No stations match "$_searchQuery"',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
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
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something Went Wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Unknown error',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                _fetchStations();
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
}