import 'package:flutter/material.dart';
import 'package:krishi_sakha/services/OpusOnnxTranslater.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';

class TestTranslationScreen extends StatefulWidget {
  const TestTranslationScreen({super.key});

  @override
  State<TestTranslationScreen> createState() => _TestTranslationScreenState();
}

class _TestTranslationScreenState extends State<TestTranslationScreen> {
  final _inputController = TextEditingController();
  final _translator = OpusOnnxTranslator();
  
  String _translatedText = '';
  bool _isLoading = false;
  bool _isInitializing = false;
  String? _error;
  String _statusMessage = 'Model not loaded';

  @override
  void initState() {
    super.initState();
    _initTranslator();
  }

  Future<void> _initTranslator() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Loading ONNX model...';
      _error = null;
    });

    try {
      await _translator.init();
      setState(() {
        _statusMessage = 'Model ready ✓';
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load model: $e';
        _statusMessage = 'Model failed to load ✗';
        _isInitializing = false;
      });
    }
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _translatedText = '';
    });

    try {
      final startTime = DateTime.now();
      final result = await _translator.translate(text);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      
      setState(() {
        _translatedText = result;
        _statusMessage = 'Translated in ${elapsed}ms';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Translation failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _translator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E8),
      appBar: AppBar(
        backgroundColor: AppColors.haraColor,
        title: const Text(
          'Translation Test',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _error != null 
                    ? Colors.red.shade50 
                    : _translator.isReady 
                        ? Colors.green.shade50 
                        : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _error != null 
                      ? Colors.red.shade200 
                      : _translator.isReady 
                          ? Colors.green.shade200 
                          : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  if (_isInitializing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _error != null 
                          ? Icons.error_outline 
                          : _translator.isReady 
                              ? Icons.check_circle_outline 
                              : Icons.hourglass_empty,
                      color: _error != null 
                          ? Colors.red 
                          : _translator.isReady 
                              ? Colors.green 
                              : Colors.orange,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _error != null 
                            ? Colors.red.shade700 
                            : _translator.isReady 
                                ? Colors.green.shade700 
                                : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!_translator.isReady && !_isInitializing)
                    TextButton(
                      onPressed: _initTranslator,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input field
            TextField(
              controller: _inputController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter English text to translate...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.haraColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Translate button
            ElevatedButton(
              onPressed: _translator.isReady && !_isLoading ? _translate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.haraColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.translate),
                        SizedBox(width: 8),
                        Text(
                          'Translate to Malayalam',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Error display
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),

            // Result display
            if (_translatedText.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Malayalam Translation:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.haraColor.withValues(alpha: 0.3)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _translatedText,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Quick test buttons
            if (_translator.isReady && _translatedText.isEmpty) ...[
              const Spacer(),
              const Text(
                'Quick Test:',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickTestChip('Hello'),
                  _buildQuickTestChip('Good morning'),
                  _buildQuickTestChip('How are you?'),
                  _buildQuickTestChip('Welcome to our app'),
                  _buildQuickTestChip('Farming is important'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _inputController.text = text;
        _translate();
      },
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.haraColor.withValues(alpha: 0.3)),
    );
  }
}
