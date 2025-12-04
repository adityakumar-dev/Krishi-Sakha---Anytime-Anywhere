import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';
import 'package:provider/provider.dart';
import '../../models/mandi_price_model.dart';
import '../../providers/mandi_provider.dart';
import '../../utils/theme/colors.dart';

class MandiPriceScreen extends StatefulWidget {
  const MandiPriceScreen({super.key});

  @override
  State<MandiPriceScreen> createState() => _MandiPriceScreenState();
}

class _MandiPriceScreenState extends State<MandiPriceScreen> {
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
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<MandiProvider>(context, listen: false);
    await provider.fetchMandiPriceData();
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final provider = Provider.of<MandiProvider>(context, listen: false);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.fromDate,
      firstDate: provider.minFromDate,
      lastDate: provider.maxFromDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.black,
              surface: Color(0xFFF7F5E8),
              onSurface: AppColors.primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setFromDate(picked);
      await provider.fetchMandiPriceData();
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final provider = Provider.of<MandiProvider>(context, listen: false);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.toDate,
      firstDate: provider.fromDate, // Can't be before fromDate
      lastDate: provider.maxToDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.black,
              surface: Color(0xFFF7F5E8),
              onSurface: AppColors.primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setToDate(picked);
      await provider.fetchMandiPriceData();
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FilterBottomSheet(),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatStateName(String state) {
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
      body: Consumer<MandiProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildDateSelector(provider),
              _buildFilterBar(provider),
              if (provider.selectedApmc != null || provider.selectedCommodity != null)
                _buildActiveFilters(provider),
              Expanded(
                child: _buildBody(provider),
              ),
            ],
          );
        },
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
      title: Consumer<MandiProvider>(
        builder: (context, provider, child) {
          return Text(
            provider.selectedState != null
                ? '${_formatStateName(provider.selectedState!)} Mandi'
                : 'Mandi Prices',
            style: const TextStyle(
              color: AppColors.primaryBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
      actions: [
            Consumer<MandiProvider>(
          builder: (context, provider, child) {
            return TextButton(
              child: Row(children: [
                Text(provider.selectedState ?? 'Select State',
                    style: const TextStyle(
                      color: AppColors.primaryBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
              ],),
              onPressed: ()=> context.push(AppRoutes.mandiStateSelect),
            );
          },
        ),
    
        Consumer<MandiProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primaryBlack),
              onPressed: provider.isLoading ? null : () => _fetchData(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector(MandiProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              label: 'From',
              date: provider.fromDate,
              onTap: () => _selectFromDate(context),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDateButton(
              label: 'To',
              date: provider.toDate,
              onTap: () => _selectToDate(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(MandiProvider provider) {
    final hasFilters = provider.selectedApmc != null || provider.selectedCommodity != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showFilterSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: hasFilters ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasFilters ? AppColors.primaryGreen : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: hasFilters ? AppColors.primaryGreen : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasFilters ? 'Filters Applied' : 'Add Filters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: hasFilters ? AppColors.primaryGreen : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: () => provider.clearFilters(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.clear,
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters(MandiProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (provider.selectedApmc != null)
            _buildFilterChip(
              label: 'Mandi: ${provider.selectedApmc}',
              onRemove: () => provider.setApmcFilter(null),
            ),
          if (provider.selectedCommodity != null)
            _buildFilterChip(
              label: 'Commodity: ${provider.selectedCommodity}',
              onRemove: () => provider.setCommodityFilter(null),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MandiProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Loading mandi prices...',
              style: TextStyle(color: AppColors.primaryBlack),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      return _buildErrorWidget(provider);
    }

    final data = provider.filteredData;

    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildSummaryCard(provider),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchData,
            color: AppColors.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return _buildPriceCard(data[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(MandiProvider provider) {
    final stats = provider.summaryStats;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Items', stats['totalItems'].toString()),
          _buildStatDivider(),
          _buildStatItem('Mandis', stats['uniqueApmcs'].toString()),
          _buildStatDivider(),
          _buildStatItem('Commodities', stats['uniqueCommodities'].toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildPriceCard(MandiPriceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Commodity name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.grass,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.commodity,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.apmc,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.displayDate,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Price section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPriceColumn(
                      'Min',
                      item.minPriceFormatted,
                      Colors.red,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildPriceColumn(
                      'Modal',
                      item.modalPriceFormatted,
                      AppColors.primaryGreen,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildPriceColumn(
                      'Max',
                      item.maxPriceFormatted,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bottom info row
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.local_shipping,
                  label: 'Arrivals',
                  value: item.commodityArrivals.isNotEmpty ? item.commodityArrivals : 'N/A',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.swap_horiz,
                  label: 'Traded',
                  value: item.commodityTraded.isNotEmpty ? item.commodityTraded : 'N/A',
                ),
                const Spacer(),
                Text(
                  '/${item.unitLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
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
              Icons.store_outlined,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Data Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No mandi price data available for the selected date range and filters.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.primaryBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(MandiProvider provider) {
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
              provider.errorMessage ?? 'Unknown error',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearError();
                _fetchData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.primaryBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Bottom Sheet
class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet();

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _tempApmc;
  String? _tempCommodity;
  final TextEditingController _apmcSearchController = TextEditingController();
  final TextEditingController _commoditySearchController = TextEditingController();
  List<String> _filteredApmcs = [];
  List<String> _filteredCommodities = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MandiProvider>(context, listen: false);
    _tempApmc = provider.selectedApmc;
    _tempCommodity = provider.selectedCommodity;
    _filteredApmcs = provider.availableApmcs;
    _filteredCommodities = provider.availableCommodities;
  }

  @override
  void dispose() {
    _apmcSearchController.dispose();
    _commoditySearchController.dispose();
    super.dispose();
  }

  void _filterApmcs(String query) {
    final provider = Provider.of<MandiProvider>(context, listen: false);
    setState(() {
      if (query.isEmpty) {
        _filteredApmcs = provider.availableApmcs;
      } else {
        _filteredApmcs = provider.availableApmcs
            .where((apmc) => apmc.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _filterCommodities(String query) {
    final provider = Provider.of<MandiProvider>(context, listen: false);
    setState(() {
      if (query.isEmpty) {
        _filteredCommodities = provider.availableCommodities;
      } else {
        _filteredCommodities = provider.availableCommodities
            .where((commodity) => commodity.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _applyFilters() {
    final provider = Provider.of<MandiProvider>(context, listen: false);
    provider.setApmcFilter(_tempApmc);
    provider.setCommodityFilter(_tempCommodity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5E8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
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
                  'Filter Options',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempApmc = null;
                      _tempCommodity = null;
                    });
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filters content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // APMC/Mandi Filter
                  _buildFilterSection(
                    title: 'Mandi (APMC)',
                    icon: Icons.storefront,
                    searchController: _apmcSearchController,
                    searchHint: 'Search mandis...',
                    onSearchChanged: _filterApmcs,
                    items: _filteredApmcs,
                    selectedItem: _tempApmc,
                    onItemSelected: (item) {
                      setState(() {
                        _tempApmc = _tempApmc == item ? null : item;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Commodity Filter
                  _buildFilterSection(
                    title: 'Commodity',
                    icon: Icons.grass,
                    searchController: _commoditySearchController,
                    searchHint: 'Search commodities...',
                    onSearchChanged: _filterCommodities,
                    items: _filteredCommodities,
                    selectedItem: _tempCommodity,
                    onItemSelected: (item) {
                      setState(() {
                        _tempCommodity = _tempCommodity == item ? null : item;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.primaryBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required TextEditingController searchController,
    required String searchHint,
    required Function(String) onSearchChanged,
    required List<String> items,
    required String? selectedItem,
    required Function(String) onItemSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            if (selectedItem != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Search field
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: searchHint,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Items
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No options available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item == selectedItem;

                return InkWell(
                  onTap: () => onItemSelected(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: AppColors.primaryGreen) : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? AppColors.primaryGreen : AppColors.primaryBlack,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
