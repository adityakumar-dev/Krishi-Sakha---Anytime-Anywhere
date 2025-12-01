import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';
import '../../providers/offline_translation_provider.dart';

class TestOfflineTranslationScreen extends StatefulWidget {
  const TestOfflineTranslationScreen({super.key});

  @override
  State<TestOfflineTranslationScreen> createState() => _TestOfflineTranslationScreenState();
}

class _TestOfflineTranslationScreenState extends State<TestOfflineTranslationScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = '';
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _inputController.text = 'Hello, how are you? The weather is nice today.';
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _translate(OfflineTranslationProvider provider) async {
    if (_inputController.text.trim().isEmpty) return;
    
    setState(() {
      _isTranslating = true;
      _translatedText = '';
    });

    try {
      final result = await provider.translate(_inputController.text.trim());
      setState(() {
        _translatedText = result;
      });
    } catch (e) {
      setState(() {
        _translatedText = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfflineTranslationProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Offline Translation Test'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
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
                    Text('Initializing...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Language selection
                  _buildLanguageSelector(provider),
                  const SizedBox(height: 16),

                  // Input field
                  TextField(
                    controller: _inputController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'English Text',
                      hintText: 'Enter text to translate...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Translate button
                  ElevatedButton.icon(
                    onPressed: provider.canTranslate && !_isTranslating
                        ? () => _translate(provider)
                        : null,
                    icon: _isTranslating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.translate),
                    label: Text(_isTranslating ? 'Translating...' : 'Translate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  if (!provider.canTranslate) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please download the selected language model first',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Output section
                  if (_translatedText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.blue.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Translation (${provider.currentTargetModel?.name ?? 'Unknown'})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          SelectableText(
                            _translatedText,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Downloaded models info
                  _buildDownloadedModelsInfo(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(OfflineTranslationProvider provider) {
    final downloadedModels = provider.downloadedModels
        .where((m) => m.language != TranslateLanguage.english)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Target Language',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (downloadedModels.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('No languages downloaded. Go to Profile → Translation Models to download.'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<TranslateLanguage>(
                value: provider.targetLanguage,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: downloadedModels.map((model) {
                  return DropdownMenuItem(
                    value: model.language,
                    child: Row(
                      children: [
                        Text(model.flagEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text('${model.name} (${model.nativeName})'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.setTargetLanguage(value);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadedModelsInfo(OfflineTranslationProvider provider) {
    final downloaded = provider.downloadedModels;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download_done, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Downloaded Models (${downloaded.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (downloaded.isEmpty)
              const Text('No models downloaded yet')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: downloaded.map((model) {
                  return Chip(
                    avatar: Text(model.flagEmoji),
                    label: Text(model.name),
                    backgroundColor: Colors.green.shade50,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
