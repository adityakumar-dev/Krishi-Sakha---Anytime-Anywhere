import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/imd_weather_provider.dart';
import '../../../utils/theme/colors.dart';

class ImdStationManagementSheet extends StatefulWidget {
  const ImdStationManagementSheet({super.key});

  @override
  State<ImdStationManagementSheet> createState() => _ImdStationManagementSheetState();
}

class _ImdStationManagementSheetState extends State<ImdStationManagementSheet> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5E8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Stations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _isEditing = !_isEditing);
                      },
                      child: Text(
                        _isEditing ? 'Done' : 'Edit',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Station list
          Flexible(
            child: Consumer<ImdWeatherProvider>(
              builder: (context, provider, child) {
                final weatherList = provider.orderedWeatherList;
                
                if (weatherList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No stations added yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (_isEditing) {
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: weatherList.length,
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderStations(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final weather = weatherList[index];
                      final stationId = provider.savedStationIds[index];
                      return _buildEditableStationTile(
                        key: ValueKey(stationId),
                        provider: provider,
                        stationId: stationId,
                        stationName: weather.station,
                        index: index,
                      );
                    },
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: weatherList.length,
                  itemBuilder: (context, index) {
                    final weather = weatherList[index];
                    final stationId = provider.savedStationIds[index];
                    return _buildStationTile(
                      provider: provider,
                      stationId: stationId,
                      stationName: weather.station,
                      latitude: weather.lat.toString(),
                      longitude: weather.lon.toString(),
                      updateTime: weather.lastUpdated,
                      isSelected: provider.currentStationIndex == index,
                      onTap: () {
                        provider.setCurrentStationIndex(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationTile({
    required ImdWeatherProvider provider,
    required String stationId,
    required String stationName,
    required String latitude,
    required String longitude,
    required String updateTime,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryGreen.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.location_on,
          color: isSelected ? AppColors.primaryGreen : Colors.grey,
        ),
      ),
      title: Text(
        stationName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: AppColors.primaryBlack,
        ),
      ),
      subtitle: Text(
        'Updated: $updateTime',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
          : null,
    );
  }

  Widget _buildEditableStationTile({
    required Key key,
    required ImdWeatherProvider provider,
    required String stationId,
    required String stationName,
    required int index,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.drag_handle,
              color: Colors.grey,
            ),
          ),
        ),
        title: Text(
          stationName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.primaryBlack,
          ),
        ),
        subtitle: Text(
          'Station ID: $stationId',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(
            context,
            provider,
            stationId,
            stationName,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ImdWeatherProvider provider,
    String stationId,
    String stationName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF7F5E8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Remove Station',
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "$stationName" from your saved stations?',
          style: const TextStyle(color: AppColors.primaryBlack),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.removeStation(stationId);
              
              // Close bottom sheet if no stations left
              if (!provider.hasStations) {
                Navigator.pop(this.context);
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
