import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krishi_sakha/providers/scheme_provider.dart';
import 'package:krishi_sakha/screens/schemes/scheme_detail_screen.dart';
import 'package:krishi_sakha/screens/schemes/widgets/scheme_card.dart';
import 'package:krishi_sakha/screens/schemes/widgets/scheme_filter_sheet.dart';
import 'package:krishi_sakha/screens/schemes/widgets/scheme_shimmer.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SchemeProvider>();
      if (provider.state == SchemeLoadingState.initial) {
        provider.init();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<SchemeProvider>();
      if (provider.hasMore && provider.state != SchemeLoadingState.loadingMore) {
        provider.fetchMoreSchemes();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SchemeFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _buildSchemesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.haraColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Government Schemes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                Consumer<SchemeProvider>(
                  builder: (context, provider, _) {
                    final count = provider.filteredSchemes.length;
                    return Text(
                      '$count schemes available',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.haraColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<SchemeProvider>().searchSchemes(value);
          setState(() {
            _isSearching = value.isNotEmpty;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search schemes by name, category...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
          ),
          suffixIcon: _isSearching
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    context.read<SchemeProvider>().searchSchemes('');
                    setState(() {
                      _isSearching = false;
                    });
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade400,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<SchemeProvider>(
      builder: (context, provider, _) {
        if (!provider.criteria.hasFilters) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (provider.criteria.level != null)
                _buildFilterChip(
                  label: provider.criteria.level!,
                  onRemove: () => provider.setLevelFilter(null),
                ),
              if (provider.criteria.states != null)
                for (final state in provider.criteria.states!)
                  _buildFilterChip(
                    label: state,
                    onRemove: () {
                      final newStates = List<String>.from(provider.criteria.states!)
                        ..remove(state);
                      provider.setStatesFilter(
                        newStates.isEmpty ? null : newStates,
                      );
                    },
                  ),
              if (provider.criteria.categories != null)
                for (final cat in provider.criteria.categories!)
                  _buildFilterChip(
                    label: cat,
                    onRemove: () {
                      final newCats = List<String>.from(provider.criteria.categories!)
                        ..remove(cat);
                      provider.setCategoriesFilter(
                        newCats.isEmpty ? null : newCats,
                      );
                    },
                  ),
              if (provider.criteria.tags != null)
                for (final tag in provider.criteria.tags!)
                  _buildFilterChip(
                    label: '#$tag',
                    onRemove: () {
                      final newTags = List<String>.from(provider.criteria.tags!)
                        ..remove(tag);
                      provider.setTagsFilter(
                        newTags.isEmpty ? null : newTags,
                      );
                    },
                  ),
              _buildClearAllChip(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.haraColor,
          ),
        ),
        deleteIcon: const Icon(
          Icons.close_rounded,
          size: 16,
          color: AppColors.haraColor,
        ),
        onDeleted: onRemove,
        backgroundColor: AppColors.haraColor.withOpacity(0.1),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildClearAllChip(SchemeProvider provider) {
    return GestureDetector(
      onTap: () => provider.clearFilters(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear_all_rounded,
              size: 16,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              'Clear All',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemesList() {
    return Consumer<SchemeProvider>(
      builder: (context, provider, _) {
        if (provider.state == SchemeLoadingState.loading) {
          return const SchemeShimmerList();
        }

        if (provider.state == SchemeLoadingState.error) {
          return _buildErrorState(provider);
        }

        final schemes = provider.filteredSchemes;

        if (schemes.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          color: AppColors.haraColor,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: schemes.length + (provider.state == SchemeLoadingState.loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == schemes.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.haraColor,
                    ),
                  ),
                );
              }

              final scheme = schemes[index];
              return SchemeCard(
                scheme: scheme,
                onTap: () {
                  debugPrint('🚀 Navigating to scheme: ${scheme.schemeName}');
                  debugPrint('🔑 Slug: "${scheme.slug}"');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SchemeDetailScreen(
                        slug: scheme.slug,
                        schemeName: scheme.schemeName,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(SchemeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Failed to load schemes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.haraColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Schemes Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
