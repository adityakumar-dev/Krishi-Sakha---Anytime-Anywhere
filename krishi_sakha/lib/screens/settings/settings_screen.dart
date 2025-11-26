import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krishi_sakha/providers/language_provider.dart';
import 'package:krishi_sakha/widgets/language_switcher.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Handle null localization gracefully
    if (l10n == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F5E8),
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFFF7F5E8),
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primaryBlack),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF7F5E8),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Section
            _buildSectionCard(
              context,
              title: l10n.language,
              icon: Icons.language,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.translate,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.selectLanguage,
                              style: const TextStyle(
                                color: AppColors.primaryBlack,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Consumer<LanguageProvider>(
                              builder: (context, languageProvider, child) {
                                return Text(
                                  languageProvider.currentLocale.languageCode == 'hi' 
                                    ? l10n.hindi 
                                    : l10n.english,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const LanguageSwitcher(),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // App Information Section
            // _buildSectionCard(
            //   context,
            //   title: l10n.appInfo,
            //   icon: Icons.info_outline,
            //   child: Column(
            //     children: [
            //       const SizedBox(height: 16),
            //       // _buildInfoRow(
            //       //   context,
            //       //   icon: Icons.agriculture,
            //       //   title: l10n.appTitle,
            //       //   subtitle: l10n.version + " 1.0.0",
            //       // ),
            //       const SizedBox(height: 12),
            //       // _buildInfoRow(
            //       //   context,
            //       //   icon: Icons.developer_mode,
            //       //   title: l10n.developer,
            //       //   subtitle: "Krishi Tech Solutions",
            //       // ),
            //       const SizedBox(height: 16),
            //     ],
            //   ),
            // ),
            
            const SizedBox(height: 20),
            
            // Support Section
            _buildSectionCard(
              context,
              title: l10n.support,
              icon: Icons.help_outline,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildActionRow(
                    context,
                    icon: Icons.feedback,
                    title: l10n.feedback,
                    onTap: () {
                      // TODO: Implement feedback functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.comingSoon),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    context,
                    icon: Icons.contact_support,
                    title: l10n.contactUs,
                    onTap: () {
                      // TODO: Implement contact functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.comingSoon),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.grey.withOpacity(0.2),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
