import 'package:flutter/material.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';
import 'package:krishi_sakha/utils/ui/markdown_helper.dart';
import 'package:provider/provider.dart';
import 'package:krishi_sakha/providers/plant_disease_provider.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';

class PlantDiseaseScreen extends StatefulWidget {
  const PlantDiseaseScreen({super.key});

  @override
  State<PlantDiseaseScreen> createState() => _PlantDiseaseScreenState();
}

class _PlantDiseaseScreenState extends State<PlantDiseaseScreen> {
  int? _selectedModelIndex;
  bool _showModelSelector = true;

  // Expandable sections state
  bool _expandGeminiCauses = false;
  bool _expandGeminiSolutions = false;
  bool _expandDiseaseScores = false;
  bool _expandGeminiPrevention = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantDiseaseProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F5E8),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F5E8),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.diseaseDetection,
                  style: const TextStyle(
                    color: AppColors.primaryBlack,
                    fontSize: 18,
                  ),
                ),
                if (provider.modelLoaded)
                  Text(
                    'Model: ${provider.getModelConfig(provider.currentModelPath ?? '')?.name ?? 'Unknown'}',
                    style: TextStyle(
                      color: AppColors.primaryBlack.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            elevation: 0,
            actions: [
              if (provider.modelLoaded)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'change') {
                      await provider.unloadModel();
                      setState(() => _showModelSelector = true);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'change',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 18),
                          SizedBox(width: 8),
                          Text('Change Model'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
            ],
          ),
          body: SafeArea(
            child: _showModelSelector && !provider.modelLoaded
                ? _buildModelSelector(provider)
                : _buildDetectionScreen(provider),
          ),
        );
      },
    );
  }

  /// Model Selection Screen
  Widget _buildModelSelector(PlantDiseaseProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.selectModel,
            style: const TextStyle(
              color: AppColors.primaryBlack,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.chooseModel,
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: provider.availableModels.length,
              itemBuilder: (context, index) {
                final model = provider.availableModels[index];
                final isSelected = _selectedModelIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedModelIndex = index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            model.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.name,
                                style: const TextStyle(
                                  color: AppColors.primaryBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                model.description,
                                style: TextStyle(
                                  color: AppColors.primaryBlack.withOpacity(
                                    0.6,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryGreen,
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedModelIndex == null || provider.isLoadingModel
                  ? null
                  : () async {
                      final model =
                          provider.availableModels[_selectedModelIndex!];
                      await provider.initializeModel(
                        modelPath: model.modelPath,
                        classesPath: model.classesPath,
                        context: context,
                      );
                      if (provider.modelLoaded) {
                        setState(() => _showModelSelector = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.primaryBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: provider.isLoadingModel
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlack,
                        ),
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.loadModel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          if (provider.modelError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF44336).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFF44336),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.modelError ?? 'Unknown error',
                      style: const TextStyle(
                        color: Color(0xFFF44336),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Main Detection Screen
  Widget _buildDetectionScreen(PlantDiseaseProvider provider) {
    return Column(
      children: [
        // Main Content - Scrollable
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  // Helper Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primaryGreen,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.howToUse,
                          style: const TextStyle(
                            color: AppColors.primaryBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)!.step1}\n${AppLocalizations.of(context)!.step2}\n${AppLocalizations.of(context)!.step3}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryBlack.withOpacity(0.6),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Image Display or Placeholder
                  if (provider.imageFile == null)
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: AppColors.primaryBlack.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No image selected',
                            style: TextStyle(
                              color: AppColors.primaryBlack.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          provider.imageFile!,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Loading State
                  if (provider.isDetecting)
                    Column(
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Analyzing image...',
                          style: TextStyle(
                            color: AppColors.primaryBlack,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),

                  // Detection Error (including Gatekeeper errors)
                  if (provider.detectionError != null &&
                      !provider.isDetecting &&
                      !provider.detectionError!.contains('not sure'))
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF44336).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF44336).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                provider.detectionError!.contains('plant')
                                    ? Icons.image_not_supported
                                    : Icons.error_outline,
                                color: const Color(0xFFF44336),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.detectionError!.contains('plant')
                                    ? AppLocalizations.of(
                                        context,
                                      )!.plantNotDetected
                                    : AppLocalizations.of(
                                        context,
                                      )!.detectionError,
                                style: const TextStyle(
                                  color: AppColors.primaryBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.detectionError ?? 'Unknown error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.primaryBlack,
                                  fontSize: 14,
                                ),
                              ),
                              if (provider.detectionError!.contains(
                                'plant',
                              )) ...[
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.usePlantImage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.primaryBlack.withOpacity(
                                      0.7,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),

                  // Detection Result
                  if (provider.detectionResult != null && !provider.isDetecting)
                    _buildResultCard(provider),

                  // All Scores
                  if (provider.allScores != null && !provider.isDetecting)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildAllScoresSection(provider),
                      ],
                    ),

                  // Gemini Response - Only show if no Gemini error
                  if (provider.geminiResponse != null &&
                      provider.geminiError == null &&
                      !provider.isDetecting)
                    Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildGeminiResponseCard(provider),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Image Picker - Fixed at bottom
        _buildBottomImagePicker(provider),
      ],
    );
  }

  /// Bottom Image Picker
  Widget _buildBottomImagePicker(PlantDiseaseProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildImagePickerButton(
            icon: Icons.camera_alt_outlined,
            label: AppLocalizations.of(context)!.camera,
            onTap: provider.isDetecting
                ? null
                : () async {
                    await provider.pickImageFromCamera();
                  },
          ),
          _buildImagePickerButton(
            icon: Icons.image_outlined,
            label: AppLocalizations.of(context)!.gallery,
            onTap: provider.isDetecting
                ? null
                : () async {
                    await provider.pickImageFromGallery();
                  },
          ),
          if (provider.imageFile != null)
            _buildImagePickerButton(
              icon: Icons.check_circle,
              label: AppLocalizations.of(context)!.detect,
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.primaryBlack,
              onTap: provider.isDetecting
                  ? null
                  : () async {
                      await provider.detectDisease();
                      // Check if we need to show confirmation dialog
                      if (provider.detectionError != null &&
                          provider.detectionError!.contains('not sure')) {
                        _showConfirmationDialog(context, provider);
                      }
                    },
            ),
        ],
      ),
    );
  }

  /// Image Picker Button
  /// Show confirmation dialog for medium confidence detection
  void _showConfirmationDialog(
    BuildContext context,
    PlantDiseaseProvider provider,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.uncertainDetection,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.detectionError ??
                    'The system is not sure if this is a plant image.',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.resultsNotAccurate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Clear the error so it doesn't show again
                provider.clearResults();
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Continue with detection
                await provider.continueDetectionAfterConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.primaryBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.continueAnyway,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color backgroundColor = Colors.white,
    Color foregroundColor = AppColors.primaryBlack,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: foregroundColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Result Card
  Widget _buildResultCard(PlantDiseaseProvider provider) {
    final result = provider.detectionResult!;
    final isHealthy = result.className.contains('healthy');
    final resultColor = isHealthy
        ? const Color(0xFF4CAF50)
        : const Color(0xFFF44336);
    final resultBgColor = isHealthy
        ? const Color(0xFF4CAF50).withOpacity(0.15)
        : const Color(0xFFF44336).withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resultColor.withOpacity(0.3), width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: resultBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHealthy ? Icons.check_circle : Icons.warning_rounded,
                  color: resultColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detection Result',
                      style: TextStyle(
                        color: AppColors.primaryBlack.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.className
                          .replaceAll('_', ' ')
                          .replaceAll('Tomato', '')
                          .trim(),
                      style: const TextStyle(
                        color: AppColors.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.confidence,
                  style: TextStyle(
                    color: AppColors.primaryBlack.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(result.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.description,
            style: TextStyle(
              color: AppColors.primaryBlack.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.description,
            style: const TextStyle(
              color: AppColors.primaryBlack,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Gemini Response Card
  Widget _buildGeminiResponseCard(PlantDiseaseProvider provider) {
    final geminiResponse = provider.geminiResponse!;
    const maxPreviewLength = 150;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.aiRecommendations,
                  style: const TextStyle(
                    color: AppColors.primaryBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Possible Causes
          if (geminiResponse.possibleCauses.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.possibleCauses,
              style: TextStyle(
                color: AppColors.primaryBlack.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildMarkdownText(
                    _expandGeminiCauses
                        ? geminiResponse.possibleCauses
                        : geminiResponse.possibleCauses.length >
                              maxPreviewLength
                        ? '${geminiResponse.possibleCauses.substring(0, maxPreviewLength)}...'
                        : geminiResponse.possibleCauses,
                  ),
                  if (geminiResponse.possibleCauses.length >
                      maxPreviewLength) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(
                          () => _expandGeminiCauses = !_expandGeminiCauses,
                        );
                      },
                      child: Text(
                        _expandGeminiCauses
                            ? AppLocalizations.of(context)!.seeLess
                            : AppLocalizations.of(context)!.seeMore,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Solutions
          if (geminiResponse.solutions.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.recommendedSolutions,
              style: TextStyle(
                color: AppColors.primaryBlack.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildMarkdownText(
                    _expandGeminiSolutions
                        ? geminiResponse.solutions
                        : geminiResponse.solutions.length > maxPreviewLength
                        ? '${geminiResponse.solutions.substring(0, maxPreviewLength)}...'
                        : geminiResponse.solutions,
                  ),
                  if (geminiResponse.solutions.length > maxPreviewLength) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(
                          () =>
                              _expandGeminiSolutions = !_expandGeminiSolutions,
                        );
                      },
                      child: Text(
                        _expandGeminiSolutions
                            ? AppLocalizations.of(context)!.seeLess
                            : AppLocalizations.of(context)!.seeMore,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

          if (geminiResponse.prevention.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.preventiveMeasures,
              style: TextStyle(
                color: AppColors.primaryBlack.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildMarkdownText(
                    _expandGeminiPrevention
                        ? geminiResponse.prevention
                        : geminiResponse.prevention.length > maxPreviewLength
                        ? '${geminiResponse.prevention.substring(0, maxPreviewLength)}...'
                        : geminiResponse.prevention,
                  ),
                  if (geminiResponse.prevention.length > maxPreviewLength) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(
                          () => _expandGeminiPrevention =
                              !_expandGeminiPrevention,
                        );
                      },
                      child: Text(
                        _expandGeminiPrevention
                            ? AppLocalizations.of(context)!.seeLess
                            : AppLocalizations.of(context)!.seeMore,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// All Scores Section
  Widget _buildAllScoresSection(PlantDiseaseProvider provider) {
    final allScores = provider.allScores ?? [];
    final topScores = allScores.length > 3
        ? allScores.sublist(0, 3)
        : allScores;
    final itemsToShow = _expandDiseaseScores ? allScores : topScores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.diseaseScores,
              style: const TextStyle(
                color: AppColors.primaryBlack,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_expandDiseaseScores && allScores.length > 3)
              Text(
                AppLocalizations.of(context)!.topThree,
                style: TextStyle(
                  color: AppColors.primaryBlack.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          constraints: BoxConstraints(
            maxHeight: _expandDiseaseScores
                ? 400
                : (itemsToShow.length * 50 + 40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itemsToShow.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.grey.withOpacity(0.1),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final score = itemsToShow[index];
                    final confidence = (score['confidence'] as double) * 100;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: AppColors.primaryBlack.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (score['name'] as String)
                                      .replaceAll('Tomato___', '')
                                      .replaceAll('_', ' '),
                                  style: const TextStyle(
                                    color: AppColors.primaryBlack,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (score['confidence'] as double)
                                        .clamp(0.0, 1.0),
                                    minHeight: 5,
                                    backgroundColor: Colors.grey.withOpacity(
                                      0.2,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      confidence > 50
                                          ? const Color(0xFF4CAF50)
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${confidence.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // See More / See Less Button
              if (allScores.length > 3)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        setState(
                          () => _expandDiseaseScores = !_expandDiseaseScores,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _expandDiseaseScores
                                ? AppLocalizations.of(context)!.seeLess
                                : AppLocalizations.of(context)!.seeMore,
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expandDiseaseScores
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.primaryGreen,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
