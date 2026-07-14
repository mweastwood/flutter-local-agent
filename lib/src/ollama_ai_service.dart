import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class OllamaAiService implements AiService {
  final String baseUrl;
  final String modelName;
  final http.Client _client;
  bool _isMultimodal = false;

  OllamaAiService({
    this.baseUrl = 'http://127.0.0.1:11434',
    this.modelName = 'gemma4:e4b',
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  @override
  Future<AiCoreStatus> checkStatus() async {
    debugPrint('Ollama: checkStatus() called for model: $modelName on $baseUrl');
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 10));
      debugPrint('Ollama: checkStatus() response code: ${response.statusCode}');
      if (response.statusCode != 200) {
        return AiCoreStatus.unavailable;
      }
      final data = jsonDecode(response.body);
      final List models = data['models'] ?? [];
      
      var foundModel = false;
      _isMultimodal = false;

      for (final m in models) {
        final name = m['name'] as String;
        // Match base name or exact name (e.g. gemma4:e4b or gemma4:e4b-latest)
        if (name == modelName || name.startsWith('$modelName:')) {
          foundModel = true;
          final List capabilities = m['capabilities'] ?? [];
          _isMultimodal = capabilities.contains('vision');
          break;
        }
      }

      debugPrint('Ollama: checkStatus() foundModel: $foundModel, isMultimodal: $_isMultimodal');
      return foundModel ? AiCoreStatus.available : AiCoreStatus.downloadable;
    } catch (e) {
      debugPrint('Ollama: checkStatus() error: $e');
      return AiCoreStatus.unavailable;
    }
  }

  @override
  Future<void> triggerDownload() async {
    debugPrint('Ollama: triggerDownload() pulling model: $modelName');
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/pull'),
        body: jsonEncode({'name': modelName, 'stream': false}),
      ).timeout(const Duration(minutes: 5));
      debugPrint('Ollama: triggerDownload() response code: ${response.statusCode}');
    } catch (e) {
      debugPrint('Ollama: triggerDownload() error: $e');
    }
  }

  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) async {
    // Model configuration is managed by the modelName selected in Ollama.
  }

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    debugPrint('Ollama: generateContent() starting for model $modelName. Prompt length: ${prompt.length}, image present: ${imageBytes != null}, isMultimodal: $_isMultimodal');
    try {
      // Ollama support for multimodal (like images) expects base64 encoded strings in the "images" field
      final List<String> imagesList = [];
      if (_isMultimodal && imageBytes != null && imageBytes.isNotEmpty) {
        imagesList.add(base64Encode(imageBytes));
      } else if (imageBytes != null && imageBytes.isNotEmpty) {
        debugPrint('Ollama: generateContent() warning - image was provided but model does not support vision. Image omitted.');
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': modelName,
          'prompt': prompt,
          if (imagesList.isNotEmpty) 'images': imagesList,
          'stream': false,
          'options': {
            'temperature': temperature,
            'num_predict': maxOutputTokens ?? 256,
          },
        }),
      );

      debugPrint('Ollama: generateContent() response code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['response'] as String?;
        debugPrint('Ollama: generateContent() success. Response length: ${result?.length}');
        return result;
      }
      debugPrint('Ollama: generateContent() failed. Body: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Ollama: generateContent() error: $e');
      return null;
    }
  }
}
