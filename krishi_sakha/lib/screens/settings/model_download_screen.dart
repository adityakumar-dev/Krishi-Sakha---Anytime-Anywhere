import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/translation_model_info.dart';
import '../../providers/offline_translation_provider.dart';

class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _defaultLanguageCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDefaultLanguage();
  }

  Future<void> _loadDefaultLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultLanguageCode = prefs.getString('default_translation_language');
    });
  }

  Future<void> _setDefaultLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_translation_language', languageCode);
    setState(() {
      _defaultLanguageCode = languageCode;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default language set to ${_getLanguageName(languageCode)}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getLanguageName(String code) {
    final model = AvailableLanguages.getByCode(code);
    return model?.name ?? code;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfflineTranslationProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Download Languages'),
          centerTitle: true,
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Indian', icon: Icon(Icons.flag, size: 20)),
              Tab(text: 'International', icon: Icon(Icons.public, size: 20)),
            ],
          ),
        ),
        body: Consumer<OfflineTranslationProvider>(
          builder: (context, provider, child) {
            if (provider.isInitializing) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading models...'),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Info Banner
                _buildInfoBanner(provider),
                
                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildModelList(provider.indianModels, provider),
                      _buildModelList(provider.otherModels, provider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoBanner(OfflineTranslationProvider provider) {
    final downloadedCount = provider.downloadedModels.length;
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.translate, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Translation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$downloadedCount language${downloadedCount != 1 ? 's' : ''} ready for offline use',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                if (_defaultLanguageCode != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Default: ${_getLanguageName(_defaultLanguageCode!)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refreshModelStatuses(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildModelList(
    List<TranslationModelInfo> models,
    OfflineTranslationProvider provider,
  ) {
    if (models.isEmpty) {
      return const Center(child: Text('No models available'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshModelStatuses(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          final isDefault = _defaultLanguageCode == model.languageCode;
          
          return _ModelCard(
            model: model,
            isDefault: isDefault,
            onDownload: () => _downloadModel(provider, model.language),
            onDelete: () => _deleteModel(provider, model),
            onSetDefault: model.isDownloaded 
                ? () => _setDefaultLanguage(model.languageCode) 
                : null,
          );
        },
      ),
    );
  }

  Future<void> _downloadModel(
    OfflineTranslationProvider provider,
    TranslateLanguage language,
  ) async {
    final success = await provider.downloadModel(language);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Model downloaded successfully!' : 'Failed to download model',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteModel(
    OfflineTranslationProvider provider,
    TranslationModelInfo model,
  ) async {
    // Check if this is the default language
    if (_defaultLanguageCode == model.languageCode) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Default Language'),
          content: Text(
            '${model.name} is your default translation language. '
            'Deleting it will remove this setting. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      // Clear default
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('default_translation_language');
      setState(() {
        _defaultLanguageCode = null;
      });
    }

    final success = await provider.deleteModel(model.language);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Model deleted' : 'Failed to delete'),
          backgroundColor: success ? Colors.orange : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ModelCard extends StatelessWidget {
  final TranslationModelInfo model;
  final bool isDefault;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _ModelCard({
    required this.model,
    required this.isDefault,
    required this.onDownload,
    required this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isDefault ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDefault
            ? BorderSide(color: Colors.green.shade400, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Flag emoji
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(model.flagEmoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),

                // Language info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            model.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 12, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.nativeName,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Status icon
                _buildStatusIcon(),
              ],
            ),

            // Progress bar when downloading
            if (model.isDownloading) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use indeterminate progress since ML Kit doesn't provide progress
                  const LinearProgressIndicator(
                    backgroundColor: Colors.black12,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Downloading... This may take a moment',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            // Action buttons for downloaded models
            if (model.isDownloaded) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isDefault ? null : onSetDefault,
                      icon: Icon(
                        isDefault ? Icons.check : Icons.star_outline,
                        size: 18,
                      ),
                      label: Text(isDefault ? 'Current Default' : 'Set as Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDefault ? Colors.grey : Colors.green.shade700,
                        side: BorderSide(
                          color: isDefault ? Colors.grey.shade300 : Colors.green.shade300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                    tooltip: 'Delete model',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (model.status) {
      case ModelDownloadStatus.notDownloaded:
        return IconButton(
          icon: Icon(Icons.download_rounded, color: Colors.blue.shade600, size: 28),
          onPressed: onDownload,
          tooltip: 'Download',
        );
      case ModelDownloadStatus.downloading:
        return const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      case ModelDownloadStatus.downloaded:
        return Icon(Icons.check_circle, color: Colors.green.shade600, size: 28);
      case ModelDownloadStatus.failed:
        return IconButton(
          icon: Icon(Icons.error_outline, color: Colors.red.shade600, size: 28),
          onPressed: onDownload,
          tooltip: 'Retry download',
        );
    }
  }

  Color _getStatusColor() {
    switch (model.status) {
      case ModelDownloadStatus.notDownloaded:
        return Colors.grey;
      case ModelDownloadStatus.downloading:
        return Colors.blue;
      case ModelDownloadStatus.downloaded:
        return Colors.green;
      case ModelDownloadStatus.failed:
        return Colors.red;
    }
  }
}
