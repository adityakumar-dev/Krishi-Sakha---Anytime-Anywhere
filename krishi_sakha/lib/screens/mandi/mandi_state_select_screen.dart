import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/mandi_price_model.dart';
import '../../providers/mandi_provider.dart';
import '../../utils/theme/colors.dart';
import 'mandi_price_screen.dart';

class MandiStateSelectScreen extends StatefulWidget {
  const MandiStateSelectScreen({super.key});

  @override
  State<MandiStateSelectScreen> createState() => _MandiStateSelectScreenState();
}

class _MandiStateSelectScreenState extends State<MandiStateSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredStates = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredStates = MandiPriceModel.allStatesMandiPrice;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF7F5E8),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF7F5E8),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStates = MandiPriceModel.allStatesMandiPrice;
      } else {
        _filteredStates = MandiPriceModel.allStatesMandiPrice.where((state) {
          return state.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _onStateSelected(String state) {
    final provider = Provider.of<MandiProvider>(context, listen: false);
    provider.setSelectedState(state);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MandiPriceScreen(),
      ),
    );
  }

  String _formatStateName(String state) {
    // Convert "ANDHRA PRADESH" to "Andhra Pradesh"
    return state.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSubtitle(),
          Expanded(
            child: _filteredStates.isEmpty ? _buildNoResults() : _buildStateList(),
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
      title: const Text(
        'Select State for Mandi',
        style: TextStyle(
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
          hintText: 'Search states...',
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

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.store, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '${_filteredStates.length} states/territories available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStates.length,
      itemBuilder: (context, index) {
        final state = _filteredStates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _onStateSelected(state),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _formatStateName(state),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoResults() {
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
              'No States Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No states match "$_searchQuery"',
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
}
