import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
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
  final String userName = "Farmer"; // This would come from user data
  
  @override
  void initState() {
    super.initState();
    
    setSystemUIOverlayStyle();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
   
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      body: SafeArea(
        child: Column(
          children: [
            // Clean Header
            _buildHeader(profileProvider.userProfile?.name , profileProvider.userProfile?.role),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Hero Section
                    _buildHeroSection(),
                    
                   
                    
                    // Main Features
                    _buildMainFeatures(),
                    
                    // Quick Stats
                    // _buildQuickStats(),
                    
                    // Bottom spacing
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? name, String? role) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/krishi_logo.png', height: 24, width: 24),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context)!.hello}, ${name ?? userName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.smartFarmingBegins,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (role == 'normal') ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => context.push(AppRoutes.leaderboard),
                    icon: const Icon(
                      Icons.leaderboard_outlined,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => context.push(AppRoutes.profile),
                  icon: const Icon(
                    Icons.person,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

 

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.search),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
            //  Image.asset(
            //     'assets/images/krishi_logo.png',
            //     width: 24,
            //     height: 24,
            //   ),
            //   const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.searchForCrops,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Could implement voice search here
                  context.push(AppRoutes.voiceChat);
                },
                icon: Icon(
                  Icons.mic,
                  color: AppColors.haraColor,
                  size: 24,
                ),
              ),

               IconButton(
                onPressed: () {
                  // Could implement voice search here
                  context.push(AppRoutes.plantDisease);
                },
                icon: Icon(
                  Icons.camera,
                  color: AppColors.haraColor,
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Could implement voice search here
                  context.push(AppRoutes.chatHistory);
                },
                icon: Icon(
                  Icons.chat,
                  color: AppColors.haraColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),

            ],
          ),
        ),
      ),
    );
  }

 
  Widget _buildMainFeatures() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.yourFarmTools,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.aiPoweredInsights,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 20),
          
          // Grid with 3 columns per row
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, // 3 items per row
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85, // Increase height (lower ratio = taller cards)
            children: [
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.weather,
                subtitle: AppLocalizations.of(context)!.forecasts,
                icon: Icons.wb_sunny,
                color: const Color(0xFF2196F3),
                onTap: () => context.push(AppRoutes.weather),
              ),
              // /card for create post scree
               _buildFeatureCard(
                title: AppLocalizations.of(context)!.sharePost,
                subtitle: AppLocalizations.of(context)!.addYourPost,
                icon: Icons.post_add,
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.createPost),
              ),
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.posts,
                subtitle: AppLocalizations.of(context)!.communityPosts,
                icon: Icons.forum,
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.posts),
              ),

               _buildFeatureCard(
                title: AppLocalizations.of(context)!.myScheme,
                subtitle: AppLocalizations.of(context)!.governmentSchemes,
                icon: Icons.forum,
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.schemes),
              ),
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.imd,
                subtitle: AppLocalizations.of(context)!.weatherForecasts,
                icon: Icons.support_agent,
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.imdWeather),
              ),


              _buildFeatureCard(
                title: AppLocalizations.of(context)!.disease,
                subtitle: AppLocalizations.of(context)!.detector,
                icon: Icons.bug_report,
                color: const Color(0xFF66BB6A),
                onTap: () => context.push(AppRoutes.plantDisease),
              ),
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.offlineAI,
                subtitle: '',
                icon: Icons.chat_bubble,
                color: const Color(0xFF5C7C8A),
                onTap: () => context.push(AppRoutes.selector),
              ),
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.savedPosts,
                subtitle: '',
                icon: Icons.bookmark,
                color: const Color(0xFF5C7C8A),
                onTap: () => context.push(AppRoutes.savedPosts),
              ),
         
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.satellite,
                subtitle: AppLocalizations.of(context)!.view,
                icon: Icons.satellite_alt,
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.satteliteView),
              ),
              _buildFeatureCard(
                title: AppLocalizations.of(context)!.testTranslation,
                subtitle: AppLocalizations.of(context)!.offlineML,
                icon: Icons.translate,
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.test_translation),
              ),
                _buildFeatureCard(
                title: AppLocalizations.of(context)!.translation,
                subtitle: AppLocalizations.of(context)!.allLanguages,
                icon: Icons.translate,
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.test_offline_translation),
              ),
               _buildFeatureCard(
                title: AppLocalizations.of(context)!.mandiPricesList,
                subtitle: AppLocalizations.of(context)!.price,
                icon: Icons.currency_rupee,
                color: const Color(0xFFD4A259),
                onTap: () => context.push(AppRoutes.mandiPrice),
              ),
              
            ],
          ),
        ],
      ),
    );
  }
  
  // New method for horizontal sensor metrics
 
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            // Title and subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlack,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlack,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}
