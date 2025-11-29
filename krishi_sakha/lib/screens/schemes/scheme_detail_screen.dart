import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:krishi_sakha/models/scheme_detail_model.dart';
import 'package:krishi_sakha/providers/scheme_detail_provider.dart';
import 'package:krishi_sakha/screens/schemes/scheme_webview_screen.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeDetailScreen extends StatefulWidget {
  final String slug;
  final String schemeName;

  const SchemeDetailScreen({
    super.key,
    required this.slug,
    required this.schemeName,
  });

  @override
  State<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SchemeDetailProvider>().fetchSchemeBySlug(widget.slug);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      body: Consumer<SchemeDetailProvider>(
        builder: (context, provider, _) {
          if (provider.state == SchemeDetailLoadingState.loading) {
            return _buildLoading();
          }

          if (provider.state == SchemeDetailLoadingState.error) {
            return _buildError(provider);
          }

          final scheme = provider.currentScheme;
          if (scheme == null) {
            return _buildLoading();
          }

          return _buildContent(scheme);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(null),
        const SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.haraColor),
                SizedBox(height: 16),
                Text(
                  'Loading scheme details...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(SchemeDetailProvider provider) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(null),
        SliverFillRemaining(
          child: Center(
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
                    'Failed to load details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchSchemeBySlug(widget.slug),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
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
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(SchemeDetailModel? scheme) {
    return SliverAppBar(
      expandedHeight: scheme != null ? 280 : 120,
      pinned: true,
      backgroundColor: AppColors.haraColor,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      actions: [
        // Web view button
        GestureDetector(
          onTap: () => _openSchemeWebView(),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        // Share button
        GestureDetector(
          onTap: () => _shareScheme(scheme),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.haraColor,
                AppColors.haraColor.withValues(alpha: 0.85),
                AppColors.halkaHaraColor,
              ],
            ),
          ),
          child: SafeArea(
            child: scheme != null
                ? _buildAppBarContent(scheme)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                    child: Text(
                      widget.schemeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarContent(SchemeDetailModel scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level and Type badges
          Row(
            children: [
              if (scheme.level != null)
                _buildHeaderBadge(scheme.level!, Icons.public_rounded),
              const SizedBox(width: 8),
              if (scheme.schemeType != null)
                _buildHeaderBadge(scheme.schemeType!, Icons.category_rounded),
            ],
          ),
          const SizedBox(height: 12),

          // Scheme name
          Text(
            scheme.name ?? widget.schemeName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Short title
          if (scheme.shortTitle != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                scheme.shortTitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const Spacer(),

          // Benefit type and categories row
          Row(
            children: [
              if (scheme.benefitType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scheme.benefitType!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              if (scheme.categories != null && scheme.categories!.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: scheme.categories!.take(2).map((cat) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),

          // Tags
          if (scheme.tags != null && scheme.tags!.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: scheme.tags!.take(4).map((tag) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SchemeDetailModel scheme) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildAppBar(scheme),
        
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.haraColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.haraColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Eligibility'),
                  Tab(text: 'Process'),
                  Tab(text: 'FAQs'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(scheme),
          _buildEligibilityTab(scheme),
          _buildProcessTab(scheme),
          _buildFaqsTab(scheme),
        ],
      ),
    );
  }

  
  Widget _buildOverviewTab(SchemeDetailModel scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brief description
          if (scheme.briefDescription != null)
            _buildSection(
              title: 'Brief Description',
              icon: Icons.description_outlined,
              child: Text(
                scheme.briefDescription!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ),

          // Detailed description
          if (scheme.detailedDescription != null)
            _buildSection(
              title: 'Detailed Description',
              icon: Icons.article_outlined,
              child: Text(
                scheme.detailedDescription!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ),

          // Benefits
          if (scheme.benefits != null && scheme.benefits!.isNotEmpty)
            _buildSection(
              title: 'Benefits',
              icon: Icons.star_outline_rounded,
              child: _buildBulletList(scheme.benefits!),
            ),

          // Documents
          if (scheme.documents.isNotEmpty)
            _buildSection(
              title: 'Required Documents',
              icon: Icons.folder_outlined,
              child: _buildDocumentsList(scheme.documents),
            ),

          // Definitions
          if (scheme.definitions != null && scheme.definitions!.isNotEmpty)
            _buildSection(
              title: 'Definitions',
              icon: Icons.book_outlined,
              child: _buildBulletList(scheme.definitions!),
            ),

          // References
          if (scheme.references != null && scheme.references!.isNotEmpty)
            _buildSection(
              title: 'References',
              icon: Icons.link_rounded,
              child: _buildReferencesList(scheme.references!),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEligibilityTab(SchemeDetailModel scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eligibility criteria
          if (scheme.eligibility != null && scheme.eligibility!.isNotEmpty)
            _buildSection(
              title: 'Eligibility Criteria',
              icon: Icons.check_circle_outline_rounded,
              child: _buildCheckList(scheme.eligibility!, Colors.green),
            ),

          // Exclusions
          if (scheme.exclusions != null && scheme.exclusions!.isNotEmpty)
            _buildSection(
              title: 'Exclusions',
              icon: Icons.cancel_outlined,
              child: _buildCheckList(scheme.exclusions!, Colors.red),
            ),

          if ((scheme.eligibility == null || scheme.eligibility!.isEmpty) &&
              (scheme.exclusions == null || scheme.exclusions!.isEmpty))
            _buildEmptyState(
              icon: Icons.info_outline_rounded,
              message: 'No eligibility information available',
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProcessTab(SchemeDetailModel scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application process
          if (scheme.applicationProcess != null && scheme.applicationProcess!.isNotEmpty)
            _buildSection(
              title: 'Application Process',
              icon: Icons.assignment_outlined,
              child: _buildStepsList(scheme.applicationProcess!),
            ),

          // Open date
          if (scheme.openDate != null)
            _buildSection(
              title: 'Important Dates',
              icon: Icons.calendar_today_outlined,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Applications Open',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            scheme.openDate!,
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
              ),
            ),

          if ((scheme.applicationProcess == null || scheme.applicationProcess!.isEmpty) &&
              scheme.openDate == null)
            _buildEmptyState(
              icon: Icons.assignment_outlined,
              message: 'No application process information available',
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFaqsTab(SchemeDetailModel scheme) {
    if (scheme.faqs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.help_outline_rounded,
        message: 'No FAQs available for this scheme',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scheme.faqs.length + 1, // +1 for bottom padding
      itemBuilder: (context, index) {
        if (index == scheme.faqs.length) {
          return const SizedBox(height: 80);
        }

        final faq = scheme.faqs[index];
        return _buildFaqItem(faq, index + 1);
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.haraColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.haraColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckList(List<String> items, Color color) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  color == Colors.green ? Icons.check : Icons.close,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepsList(List<String> steps) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.haraColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: AppColors.haraColor.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDocumentsList(List<SchemeDocumentModel> documents) {
    return Column(
      children: documents.map((doc) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doc.document ?? 'Document',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReferencesList(List<String> references) {
    return Column(
      children: references.map((ref) {
        // Check if this reference contains a URL (either starts with http or contains ': http')
        final containsUrl = ref.contains('http://') || ref.contains('https://');
        String? url;
        String displayText = ref;
        
        if (containsUrl) {
          // Extract URL from format "Title: URL" or just "URL"
          final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(ref);
          if (urlMatch != null) {
            url = urlMatch.group(0);
          }
        }
        
        return GestureDetector(
          onTap: url != null ? () => _openUrl(url!) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: url != null ? Colors.blue.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  url != null ? Icons.link_rounded : Icons.article_outlined,
                  size: 18,
                  color: url != null ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 13,
                      color: url != null ? Colors.blue.shade700 : Colors.grey.shade700,
                      decoration: url != null ? TextDecoration.underline : null,
                    ),
                  ),
                ),
                if (url != null)
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFaqItem(SchemeFaqModel faq, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.haraColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.haraColor,
              ),
            ),
          ),
        ),
        title: Text(
          faq.question ?? 'Question',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlack,
          ),
        ),
        children: [
          Text(
            faq.answer ?? 'No answer available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
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

  void _openSchemeWebView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchemeWebViewScreen(
          slug: widget.slug,
          schemeName: widget.schemeName,
        ),
      ),
    );
  }

  void _shareScheme(SchemeDetailModel? scheme) {
    final text = '''
Check out this government scheme:

${scheme?.name ?? widget.schemeName}

${scheme?.briefDescription ?? ''}

Level: ${scheme?.level ?? 'N/A'}
Type: ${scheme?.schemeType ?? 'N/A'}

Learn more on the official portal!
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scheme details copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Tab bar delegate for pinned tab bar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF7F5E8),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
