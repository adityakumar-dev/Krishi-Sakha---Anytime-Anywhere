import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:krishi_sakha/apis/app_global.dart';
import 'package:krishi_sakha/services/tflite_service.dart';
import 'package:krishi_sakha/services/app_logger.dart';

class GeminiResponse{
  final String possibleCauses;
  final String solutions;
  final String prevention;
  GeminiResponse({
    required this.possibleCauses,
    required this.solutions,
    required this.prevention,
  });

  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    return GeminiResponse(
      possibleCauses: json['possible_causes'] ?? '',
      solutions: json['solutions'] ?? '',
      prevention: json['prevention'] ?? '',
    );
  }
}

class PlantDiseaseProvider extends ChangeNotifier {
  // Image handling
  XFile? _selectedImage;
  File? _imageFile;
  XFile? get selectedImage => _selectedImage;
  File? get imageFile => _imageFile;

  final ImagePicker _picker = ImagePicker();
  

  // Model management
  final TfliteService _tfliteService = TfliteService();
  String? _currentModelPath;
  String? _currentClassesPath;
  Map<String, String>? _classesMap;
  bool _modelLoaded = false;
  bool _isLoadingModel = false;
  String? _modelError;

  String? get currentModelPath => _currentModelPath;
  String? get currentClassesPath => _currentClassesPath;
  Map<String, String>? get classesMap => _classesMap;
  bool get modelLoaded => _modelLoaded;
  bool get isLoadingModel => _isLoadingModel;
  String? get modelError => _modelError;

  // Detection results
  DiseaseDetectionResult? _detectionResult;
  List<Map<String, dynamic>>? _allScores;
  bool _isDetecting = false;
  String? _detectionError;

  DiseaseDetectionResult? get detectionResult => _detectionResult;
  List<Map<String, dynamic>>? get allScores => _allScores;
  bool get isDetecting => _isDetecting;
  String? get detectionError => _detectionError;

  // Gemini response
  GeminiResponse? _geminiResponse;
  GeminiResponse? get geminiResponse => _geminiResponse;
  
  // Gemini error tracking (separate from detection error)
  String? _geminiError;
  String? get geminiError => _geminiError;

  // Gatekeeper model (always loaded first)
  static const String gatekeeperModelPath = 'assets/model/gatekeeper/gatekeeper.tflite';
  static const String gatekeeperClassesPath = 'assets/model/gatekeeper/classes.json';
  static const double gatekeeperHighConfidenceThreshold = 0.7; // 70% - auto proceed
  static const double gatekeeperMediumConfidenceThreshold = 0.5; // 50% - ask user
  
  bool _isGatekeeperLoaded = false;
  Map<String, String>? _gatekeeperClassesMap;
  bool get isGatekeeperLoaded => _isGatekeeperLoaded;

  // Available models list
  final List<ModelConfig> availableModels = [
    ModelConfig(
      name: 'Tomato Disease',
      modelPath: 'assets/model/tamato/tomato_model.tflite',
      classesPath: 'assets/model/tamato/classes.json',
      description: '10 classes - 96% accuracy',
      icon: '🍅',
    ),
    ModelConfig(
      name: 'Tea Leaf Disease',
      modelPath: 'assets/model/tea_leaf/tea_disease_model.tflite',
      classesPath: 'assets/model/tea_leaf/classes.json',
      description: 'Tea leaf disease classification',
      icon: '🍵',
    ),
    // Add more models here in future
    // ModelConfig(
    //   name: 'Potato Disease',
    //   modelPath: 'assets/model/potato/potato_model.tflite',
    //   classesPath: 'assets/model/potato/classes.json',
    //   description: 'Potato disease detection',
    //   icon: '🥔',
    // ),
  ];

  /// Initialize model with paths from assets
  /// First closes any existing model, then loads new one


  Future<void> initializeModel({
    required String modelPath,
    required String classesPath,
    required BuildContext context,
  }) async {
    try {
      // Close previous model if loaded
      if (_modelLoaded) {
        await _tfliteService.close();
        _modelLoaded = false;
        AppLogger.info('Previous model closed');
      }

      setState(() {
        _isLoadingModel = true;
        _modelError = null;
      });

      // Load gatekeeper classes first
      if (!_isGatekeeperLoaded) {
        final gatekeeperClassesJson = await DefaultAssetBundle.of(context)
            .loadString(gatekeeperClassesPath);
        _gatekeeperClassesMap = Map<String, String>.from(jsonDecode(gatekeeperClassesJson));
        _isGatekeeperLoaded = true;
        AppLogger.info('Gatekeeper classes loaded');
      }

      // Load classes mapping
      final classesJson = await DefaultAssetBundle.of(context)
          .loadString(classesPath);
      _classesMap = Map<String, String>.from(jsonDecode(classesJson));

      // Initialize TFLite model
      final response = await _tfliteService.initialize(path: modelPath);

      if (response.status) {
        _currentModelPath = modelPath;
        _currentClassesPath = classesPath;
        _modelLoaded = true;
        _modelError = null;
        AppLogger.info('Model initialized: $modelPath');
      } else {
        _modelLoaded = false;
        _modelError = response.message;
        AppLogger.error('Model initialization failed: ${response.message}');
      }
    } catch (e) {
      _modelLoaded = false;
      _modelError = 'Error loading model: $e';
      AppLogger.error('Error initializing model: $e');
    } finally {
      setState(() => _isLoadingModel = false);
    }
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = image;
        _imageFile = File(image.path);
        _detectionResult = null;
        _allScores = null;
        _detectionError = null;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = image;
        _imageFile = File(image.path);
        _detectionResult = null;
        _allScores = null;
        _detectionError = null;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Validate image with gatekeeper model
  Future<Map<String, dynamic>> validateImageWithGatekeeper() async {
    if (!_isGatekeeperLoaded || _gatekeeperClassesMap == null || _imageFile == null) {
      return {
        'isValid': false,
        'error': 'Gatekeeper not initialized or no image selected',
      };
    }

    try {
      AppLogger.info('Running gatekeeper validation...');
      
      // Temporarily load gatekeeper model
      final initResponse = await _tfliteService.initialize(path: gatekeeperModelPath);
      if (!initResponse.status) {
        return {
          'isValid': false,
          'error': 'Failed to load gatekeeper model',
        };
      }

      // Run detection
      final response = await _tfliteService.detectDiseaseFromImage(
        _imageFile!.path,
        _gatekeeperClassesMap!,
      );

      // Close gatekeeper model
      await _tfliteService.close();

      if (response.status && response.diseaseResult != null) {
        final result = response.diseaseResult!;
        final isPlant = result.className.toLowerCase() == 'plant';
        final confidence = result.confidence;

        AppLogger.info(
          'Gatekeeper result: ${result.className} (${(confidence * 100).toStringAsFixed(1)}%)',
        );

        if (isPlant && confidence >= gatekeeperHighConfidenceThreshold) {
          // High confidence - auto proceed
          return {
            'isValid': true,
            'confidence': confidence,
            'needsConfirmation': false,
          };
        } else if (isPlant && confidence >= gatekeeperMediumConfidenceThreshold) {
          // Medium confidence - ask user
          return {
            'isValid': false,
            'needsConfirmation': true,
            'confidence': confidence,
            'message': 'The system is not sure if this is a plant image (${(confidence * 100).toStringAsFixed(1)}% confidence). Do you want to continue?',
          };
        } else {
          // Low confidence or not a plant
          return {
            'isValid': false,
            'needsConfirmation': false,
            'isPlant': isPlant,
            'confidence': confidence,
            'error': isPlant 
                ? 'Low confidence: Image might not contain a clear plant'
                : 'No plant detected: Please use an image of a plant',
          };
        }
      }

      return {
        'isValid': false,
        'error': 'Gatekeeper validation failed',
      };
    } catch (e) {
      AppLogger.error('Gatekeeper error: $e');
      return {
        'isValid': false,
        'error': 'Error validating image: $e',
      };
    }
  }

  /// Continue disease detection (called after user confirms medium confidence)
  Future<void> continueDetectionAfterConfirmation() async {
    if (!_modelLoaded || _classesMap == null || _imageFile == null) {
      _detectionError = 'Model not loaded or no image selected';
      notifyListeners();
      return;
    }

    try {
      setState(() {
        _isDetecting = true;
        _detectionError = null;
        _geminiResponse = null;
        _geminiError = null;
      });

      // Reload disease detection model
      AppLogger.info('User confirmed - proceeding with disease detection...');
      final reloadResponse = await _tfliteService.initialize(path: _currentModelPath!);
      if (!reloadResponse.status) {
        _detectionError = 'Failed to reload disease detection model';
        setState(() => _isDetecting = false);
        return;
      }

      // Run disease detection
      await _runDiseaseDetection();
    } catch (e) {
      _detectionError = 'Error detecting disease: $e';
      _detectionResult = null;
      _allScores = null;
      AppLogger.error('Error during detection: $e');
      notifyListeners();
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  /// Internal method to run disease detection
  Future<void> _runDiseaseDetection() async {
    // Step 3: Get main detection result
    AppLogger.info('Running disease detection...');
    final detectionResponse = await _tfliteService.detectDiseaseFromImage(
      _imageFile!.path,
      _classesMap!,
    );

    if (detectionResponse.status) {
      // Get all scores for detailed view
      final scoresResponse = await _tfliteService.getDiseaseScores(
        _imageFile!.path,
        _classesMap!,
      );

      _detectionResult = detectionResponse.diseaseResult;
      if (scoresResponse.status) {
        _allScores = List<Map<String, dynamic>>.from(
          scoresResponse.result as List<dynamic>,
        );
      }
      _detectionError = null;
      AppLogger.info(
        'Disease detected: ${_detectionResult?.className} (${(_detectionResult?.confidence ?? 0 * 100).toStringAsFixed(1)}%)',
      );

      // Notify listeners about detection results before calling Gemini
      notifyListeners();

      // Get Gemini advice
      String plantName = "Tomato"; // Assuming tomato model
      String diseaseName = _detectionResult!.className;
      await getGeminiAdvice(plantName, diseaseName);
    } else {
      _detectionError = detectionResponse.message;
      _detectionResult = null;
      _allScores = null;
      AppLogger.error('Detection failed: ${detectionResponse.message}');
      notifyListeners();
    }
  }

  /// Detect disease in selected image
  Future<void> detectDisease() async {
    if (!_modelLoaded || _classesMap == null || _imageFile == null) {
      _detectionError = 'Model not loaded or no image selected';
      notifyListeners();
      return;
    }

    try {
      setState(() {
        _isDetecting = true;
        _detectionError = null;
        _geminiResponse = null; // Clear previous Gemini response
        _geminiError = null;
      });

      // Step 1: Gatekeeper validation
      AppLogger.info('Step 1: Running gatekeeper validation...');
      final gatekeeperResult = await validateImageWithGatekeeper();
      
      if (gatekeeperResult['needsConfirmation'] == true) {
        // Medium confidence - need user confirmation
        _detectionError = gatekeeperResult['message'] ?? 'Please confirm to continue';
        _detectionResult = null;
        _allScores = null;
        AppLogger.info('Gatekeeper needs user confirmation: ${(gatekeeperResult["confidence"] * 100).toStringAsFixed(1)}%');
        setState(() => _isDetecting = false);
        // Error will trigger confirmation dialog in UI
        return;
      }
      
      if (!gatekeeperResult['isValid']) {
        // Image is not a plant or low confidence
        _detectionError = gatekeeperResult['error'] ?? 'Image validation failed';
        _detectionResult = null;
        _allScores = null;
        AppLogger.warning('Gatekeeper rejected image: ${_detectionError}');
        setState(() => _isDetecting = false);
        return;
      }

      AppLogger.info(
        'Gatekeeper passed with ${(gatekeeperResult["confidence"] * 100).toStringAsFixed(1)}% confidence',
      );

      // Step 2: Reload disease detection model
      final reloadResponse = await _tfliteService.initialize(path: _currentModelPath!);
      if (!reloadResponse.status) {
        _detectionError = 'Failed to reload disease detection model';
        setState(() => _isDetecting = false);
        return;
      }

      // Step 3: Run disease detection
      await _runDiseaseDetection();
    } catch (e) {
      _detectionError = 'Error detecting disease: $e';
      _detectionResult = null;
      _allScores = null;
      AppLogger.error('Error during detection: $e');
      notifyListeners();
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  /// Clear selected image
  void clearImage() {
    _selectedImage = null;
    _imageFile = null;
    _detectionResult = null;
    _allScores = null;
    _detectionError = null;
    _geminiResponse = null;
    notifyListeners();
  }

  /// Clear detection results
  void clearResults() {
    _detectionResult = null;
    _allScores = null;
    _detectionError = null;
    _geminiResponse = null;
    notifyListeners();
  }

  /// Unload current model
  Future<void> unloadModel() async {
    try {
      if (_modelLoaded) {
        await _tfliteService.close();
        _modelLoaded = false;
        _currentModelPath = null;
        _currentClassesPath = null;
        _classesMap = null;
        _detectionResult = null;
        _allScores = null;
        _geminiResponse = null;
        _detectionError = null;
        AppLogger.info('Model unloaded');
      }
    } catch (e) {
      AppLogger.error('Error unloading model: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Get model info
  ModelConfig? getModelConfig(String modelPath) {
    try {
      return availableModels.firstWhere(
        (model) => model.modelPath == modelPath,
      );
    } catch (e) {
      return null;
    }
  }

  /// Set notification listener helper
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  /// Get Gemini advice for detected disease
  Future<void> getGeminiAdvice(String plantName, String diseaseName) async {
    try {
      String userPrompt = "Plant name: $plantName\nDisease name: $diseaseName";
      var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${AppGlobal.GeminiApiKey}');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": "${AppGlobal.SYSTEM_PROMPT_GEMINI}\n\n$userPrompt"
            }]
          }]
        }),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        // Remove markdown code blocks if present
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        var jsonResponse = jsonDecode(text);
        _geminiResponse = GeminiResponse.fromJson(jsonResponse);
        _geminiError = null; // Clear error on success
        AppLogger.info('Gemini response parsed successfully');
      } else {
        _geminiError = 'Gemini API error: ${response.statusCode}';
        _geminiResponse = null;
        AppLogger.error('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      _geminiError = 'Unable to load AI insights. Please check your internet connection.';
      _geminiResponse = null;
      AppLogger.error('Error calling Gemini: $e');
    } finally {
      // Always notify listeners after Gemini API call completes
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tfliteService.close();
    super.dispose();
  }
}

/// Model configuration class
class ModelConfig {
  final String name;
  final String modelPath;
  final String classesPath;
  final String description;
  final String icon;

  ModelConfig({
    required this.name,
    required this.modelPath,
    required this.classesPath,
    required this.description,
    required this.icon,
  });

  @override
  String toString() => '$name - $description';
}