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

  // Available models list
  final List<ModelConfig> availableModels = [
    ModelConfig(
      name: 'Tomato Disease',
      modelPath: 'assets/model/tamato/tomato_model.tflite',
      classesPath: 'assets/model/tamato/classes.json',
      description: '10 classes - 96% accuracy',
      icon: '🍅',
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
      });

      // Get main detection result
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