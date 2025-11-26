import 'dart:io';
import 'dart:typed_data';

import 'package:krishi_sakha/services/app_logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Prediction result from TFLite model
class DiseaseDetectionResult {
  final String className;
  final double confidence;
  final int classIndex;
  final String description;

  DiseaseDetectionResult({
    required this.className,
    required this.confidence,
    required this.classIndex,
    required this.description,
  });

  @override
  String toString() =>
      'Disease: $className, Confidence: ${(confidence * 100).toStringAsFixed(2)}%';
}

class TfliteResponse {
  bool status = false;
  String message = "";
  dynamic result;
  DiseaseDetectionResult? diseaseResult;

  TfliteResponse({
    required this.status,
    required this.message,
    this.result,
    this.diseaseResult,
  });
}

class TfliteService {
  static final TfliteService _instance = TfliteService._internal();
  factory TfliteService() => _instance;
  TfliteService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Check if the interpreter is initialized
  bool get isInitialized => _isInitialized;

  /// Get the current interpreter instance
  Interpreter? get interpreter => _interpreter;

  /// Load a TFLite model from assets or file path
  Future<TfliteResponse> initialize(
      {String path = "assets/model/cropnet.tflite"}) async {
    try {
      // Close existing interpreter if any
      if (_isInitialized) {
        await close();
      }

      if (path.startsWith("assets/")) {
        _interpreter = await Interpreter.fromAsset(path);
        AppLogger.info("Loaded model from assets: $path");
        _isInitialized = true;
        return TfliteResponse(
            status: true, message: "Loaded from assets successfully");
      } else {
        final file = File(path);
        if (!await file.exists()) {
          AppLogger.error("Model file not found at: $path");
          return TfliteResponse(
              status: false, message: "Model file not found");
        }
        _interpreter = await Interpreter.fromFile(file);
        AppLogger.info("Loaded model from file: $path");
        _isInitialized = true;
        return TfliteResponse(
            status: true, message: "Loaded from file path successfully");
      }
    } catch (e) {
      AppLogger.error("Error loading the model: $e");
      _isInitialized = false;
      return TfliteResponse(
          status: false, message: "Error loading the model: $e");
    }
  }

  /// Run inference on input data
  Future<TfliteResponse> runInference(dynamic input) async {
    try {
      if (!_isInitialized || _interpreter == null) {
        return TfliteResponse(
            status: false, message: "Interpreter not initialized");
      }

      final output = _getOutputTensor();
      _interpreter!.run(input, output);

      AppLogger.info("Inference completed successfully");
      return TfliteResponse(status: true, message: "Inference successful", result: output);
    } catch (e) {
      AppLogger.error("Error running inference: $e");
      return TfliteResponse(
          status: false, message: "Error running inference: $e");
    }
  }

  /// Run inference on image data
  Future<TfliteResponse> runInferenceOnImage(String imagePath) async {
    try {
      if (!_isInitialized || _interpreter == null) {
        return TfliteResponse(
            status: false, message: "Interpreter not initialized");
      }

      // Read and process image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return TfliteResponse(status: false, message: "Image file not found");
      }

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return TfliteResponse(status: false, message: "Failed to decode image");
      }

      // Get input tensor shape
      final inputShape = _interpreter!.getInputTensor(0).shape;

      // Resize image to model input size
      final resized = img.copyResize(
        image,
        width: inputShape[2],
        height: inputShape[1],
      );

      // Convert to input format
      final input = _imageToByteListFloat32(resized, inputShape[1], inputShape[2]);

      // Run inference
      final output = _getOutputTensor();
      _interpreter!.run(input, output);

      AppLogger.info("Image inference completed successfully");
      return TfliteResponse(
          status: true, message: "Image inference successful", result: output);
    } catch (e) {
      AppLogger.error("Error running image inference: $e");
      return TfliteResponse(
          status: false, message: "Error running image inference: $e");
    }
  }

  /// Get model input details
  TfliteResponse getInputDetails() {
    try {
      if (!_isInitialized || _interpreter == null) {
        return TfliteResponse(
            status: false, message: "Interpreter not initialized");
      }

      final inputTensor = _interpreter!.getInputTensor(0);
      final details = {
        'shape': inputTensor.shape,
        'type': inputTensor.type.toString(),
      };

      return TfliteResponse(
          status: true, message: "Input details retrieved", result: details);
    } catch (e) {
      AppLogger.error("Error getting input details: $e");
      return TfliteResponse(status: false, message: "Error getting input details");
    }
  }

  /// Get model output details
  TfliteResponse getOutputDetails() {
    try {
      if (!_isInitialized || _interpreter == null) {
        return TfliteResponse(
            status: false, message: "Interpreter not initialized");
      }

      final outputTensor = _interpreter!.getOutputTensor(0);
      final details = {
        'shape': outputTensor.shape,
        'type': outputTensor.type.toString(),
      };

      return TfliteResponse(
          status: true, message: "Output details retrieved", result: details);
    } catch (e) {
      AppLogger.error("Error getting output details: $e");
      return TfliteResponse(status: false, message: "Error getting output details");
    }
  }

  /// Detect tomato disease from image
  Future<TfliteResponse> detectDiseaseFromImage(
    String imagePath,
    Map<String, String> classesMap,
  ) async {
    try {
      if (!_isInitialized || _interpreter == null) {
        return TfliteResponse(
            status: false, message: "Interpreter not initialized");
      }

      // Read and process image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return TfliteResponse(status: false, message: "Image file not found");
      }

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return TfliteResponse(status: false, message: "Failed to decode image");
      }

      // Get input tensor shape (expected: 256x256 for tomato model)
      final inputShape = _interpreter!.getInputTensor(0).shape;

      // Resize image to model input size
      final resized = img.copyResize(
        image,
        width: inputShape[2],
        height: inputShape[1],
      );

      // Convert to input format (normalized float32)
      final input = _imageToByteListFloat32(resized, inputShape[1], inputShape[2]);

      // Get output tensor and run inference
      final output = _getOutputTensor();
      _interpreter!.run(input, output);

      // Parse results - output should be [1, 10] for 10 classes
      final predictions = output[0] as List<dynamic>;
      
      // Find the class with highest confidence
      int maxIndex = 0;
      double maxConfidence = 0.0;
      
      for (int i = 0; i < predictions.length; i++) {
        final conf = (predictions[i] as num).toDouble();
        if (conf > maxConfidence) {
          maxConfidence = conf;
          maxIndex = i;
        }
      }

      // Get disease name from classes map
      final diseaseName = classesMap[maxIndex.toString()] ?? "Unknown";
      
      final diseaseResult = DiseaseDetectionResult(
        className: diseaseName,
        confidence: maxConfidence,
        classIndex: maxIndex,
        description: _getDiseaseDescription(diseaseName),
      );

      AppLogger.info(
        "Disease detected: $diseaseName with confidence: ${(maxConfidence * 100).toStringAsFixed(2)}%",
      );

      return TfliteResponse(
        status: true,
        message: "Disease detection successful",
        result: predictions,
        diseaseResult: diseaseResult,
      );
    } catch (e) {
      AppLogger.error("Error detecting disease: $e");
      return TfliteResponse(
          status: false, message: "Error detecting disease: $e");
    }
  }

  /// Get all predictions with confidence scores
  Future<TfliteResponse> getDiseaseScores(
    String imagePath,
    Map<String, String> classesMap,
  ) async {
    try {
      if (!_isInitialized || _interpreter == null) {
        return TfliteResponse(
            status: false, message: "Interpreter not initialized");
      }

      // Read and process image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return TfliteResponse(status: false, message: "Image file not found");
      }

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return TfliteResponse(status: false, message: "Failed to decode image");
      }

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final resized = img.copyResize(
        image,
        width: inputShape[2],
        height: inputShape[1],
      );

      final input = _imageToByteListFloat32(resized, inputShape[1], inputShape[2]);
      final output = _getOutputTensor();
      _interpreter!.run(input, output);

      // Create detailed results for all classes
      final predictions = output[0] as List<dynamic>;
      final detailedResults = <Map<String, dynamic>>[];

      for (int i = 0; i < predictions.length; i++) {
        final confidence = (predictions[i] as num).toDouble();
        final diseaseName = classesMap[i.toString()] ?? "Unknown";
        
        detailedResults.add({
          'index': i,
          'name': diseaseName,
          'confidence': confidence,
          'percentge': (confidence * 100).toStringAsFixed(2),
          'description': _getDiseaseDescription(diseaseName),
        });
      }

      // Sort by confidence descending
      detailedResults.sort((a, b) => (b['confidence'] as double)
          .compareTo(a['confidence'] as double));

      return TfliteResponse(
        status: true,
        message: "Disease scores retrieved",
        result: detailedResults,
      );
    } catch (e) {
      AppLogger.error("Error getting disease scores: $e");
      return TfliteResponse(
          status: false, message: "Error getting disease scores: $e");
    }
  }

  /// Get disease description and treatment recommendations
  String _getDiseaseDescription(String diseaseName) {
    const diseaseDescriptions = {
      'Tomato___Bacterial_spot':
          'Bacterial leaf spot causes small, dark, greasy spots on leaves and fruit.',
      'Tomato___Early_blight':
          'Early blight appears as brown spots with concentric rings on lower leaves.',
      'Tomato___Late_blight':
          'Late blight causes water-soaked spots on leaves and stems, often with white mold underneath.',
      'Tomato___Leaf_Mold':
          'Leaf mold creates yellow blotches on upper leaf surface with gray mold underneath.',
      'Tomato___Septoria_leaf_spot':
          'Septoria leaf spot shows small circular lesions with dark borders and gray centers.',
      'Tomato___Spider_mites Two-spotted_spider_mite':
          'Spider mites cause stippling (tiny dots) on leaves, often with webbing.',
      'Tomato___Target_Spot':
          'Target spot displays concentric rings creating a target-like pattern on leaves.',
      'Tomato___Tomato_Yellow_Leaf_Curl_Virus':
          'TYLCV causes yellowing and curling of leaves, stunted growth.',
      'Tomato___Tomato_mosaic_virus':
          'Tomato mosaic virus creates mottled, mosaic-like patterns on leaves.',
      'Tomato___healthy': 'Plant is healthy with no visible disease symptoms.',
    };

    return diseaseDescriptions[diseaseName] ?? 'Unknown disease detected.';
  }

  /// Close the interpreter and cleanup resources
  Future<void> close() async {
    try {
      if (_interpreter != null) {
        _interpreter!.close();
        _interpreter = null;
        _isInitialized = false;
        AppLogger.info("Interpreter closed successfully");
      }
    } catch (e) {
      AppLogger.error("Error closing interpreter: $e");
    }
  }

  /// Get output tensor with proper shape
  List<dynamic> _getOutputTensor() {
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;

    // Initialize output based on shape
    if (outputShape.length == 1) {
      return List.filled(outputShape[0], 0.0);
    } else if (outputShape.length == 2) {
      return List.generate(
        outputShape[0],
        (i) => List.filled(outputShape[1], 0.0),
      );
    } else if (outputShape.length == 3) {
      return List.generate(
        outputShape[0],
        (i) => List.generate(
          outputShape[1],
          (j) => List.filled(outputShape[2], 0.0),
        ),
      );
    } else {
      return List.filled(outputShape[0], 0.0);
    }
  }

  /// Convert image to Float32 byte list for model input
  List<int> _imageToByteListFloat32(
    img.Image image,
    int inputHeight,
    int inputWidth,
  ) {
    final convertedBytes = Float32List(1 * inputHeight * inputWidth * 3);
    int pixel = 0;

    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        final imagePixel = image.getPixelSafe(x, y);
        
        int r = imagePixel.r.toInt();
        int g = imagePixel.g.toInt();
        int b = imagePixel.b.toInt();
        
        convertedBytes[pixel++] = r / 255.0;
        convertedBytes[pixel++] = g / 255.0;
        convertedBytes[pixel++] = b / 255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}