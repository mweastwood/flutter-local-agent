import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class CloudModelInfo {
  final String modelName;
  final String providerName; // e.g. 'geminiCloud', 'zhipuCloud'
  final int? limitRpm;
  final int? limitTpm;
  final int? limitRpd;
  final int? limitRps;
  final String description;

  const CloudModelInfo({
    required this.modelName,
    required this.providerName,
    this.limitRpm,
    this.limitTpm,
    this.limitRpd,
    this.limitRps,
    required this.description,
  });
}

class CloudModelDatabase {
  static const List<CloudModelInfo> geminiModels = [
    CloudModelInfo(
      modelName: 'gemini-3.5-flash',
      providerName: 'geminiCloud',
      limitRpm: 15,
      limitTpm: 1000000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 1M TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3.1-pro',
      providerName: 'geminiCloud',
      limitRpm: 2,
      limitTpm: 32000,
      limitRpd: 50,
      description: 'Free Tier Limits: 2 RPM / 32k TPM / 50 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3-flash',
      providerName: 'geminiCloud',
      limitRpm: 15,
      limitTpm: 1000000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 1M TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3.1-flash-lite',
      providerName: 'geminiCloud',
      limitRpm: 15,
      limitTpm: 1000000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 1M TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-2.5-pro',
      providerName: 'geminiCloud',
      limitRpm: 2,
      limitTpm: 32000,
      limitRpd: 50,
      description: 'Free Tier Limits: 2 RPM / 32k TPM / 50 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-2.5-flash',
      providerName: 'geminiCloud',
      limitRpm: 15,
      limitTpm: 1000000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 1M TPM / 1,500 RPD',
    ),
  ];

  static const List<CloudModelInfo> zhipuModels = [
    CloudModelInfo(
      modelName: 'glm-5.2',
      providerName: 'zhipuCloud',
      limitRps: 2,
      description: 'Commercial: 2 RPS (Approx. \$1.40 / 1M input tokens)',
    ),
    CloudModelInfo(
      modelName: 'glm-5v-turbo',
      providerName: 'zhipuCloud',
      limitRps: 2,
      description: 'Commercial: 2 RPS (Flagship Vision Model)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.7-flash',
      providerName: 'zhipuCloud',
      limitRps: 2,
      description: 'Free Tier Limits: 2 RPS (zero cost, completely free)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.7',
      providerName: 'zhipuCloud',
      limitRps: 2,
      description: 'Commercial: 2 RPS (Standard capability)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.5-air',
      providerName: 'zhipuCloud',
      limitRps: 2,
      description: 'Commercial: 2 RPS (Light, balanced)',
    ),
  ];

  static CloudModelInfo? getModelInfo(String modelName) {
    for (final model in geminiModels) {
      if (model.modelName == modelName) return model;
    }
    for (final model in zhipuModels) {
      if (model.modelName == modelName) return model;
    }
    return null;
  }
}

class RateLimiter {
  final double throttlePercentage;
  final CloudModelInfo modelInfo;

  final List<DateTime> _requestTimestamps = [];
  final List<({DateTime timestamp, int tokenCount})> _tokenUsage = [];

  RateLimiter({required this.modelInfo, this.throttlePercentage = 100.0});

  Future<void> throttleBeforeRequest(int estimatedTokens) async {
    final now = DateTime.now();
    final double pctFactor = throttlePercentage / 100.0;

    _requestTimestamps.removeWhere(
      (dt) => now.difference(dt) > const Duration(days: 1),
    );
    _tokenUsage.removeWhere(
      (item) => now.difference(item.timestamp) > const Duration(minutes: 1),
    );

    if (modelInfo.limitRps != null && modelInfo.limitRps! > 0) {
      final double effectiveRps = modelInfo.limitRps! * pctFactor;
      final requiredInterval = Duration(
        milliseconds: (1000 / effectiveRps).round(),
      );
      if (_requestTimestamps.isNotEmpty) {
        final lastRequestTime = _requestTimestamps.last;
        final elapsed = now.difference(lastRequestTime);
        if (elapsed < requiredInterval) {
          final waitDuration = requiredInterval - elapsed;
          await Future.delayed(waitDuration);
        }
      }
    }

    if (modelInfo.limitRpm != null && modelInfo.limitRpm! > 0) {
      final double effectiveRpm = modelInfo.limitRpm! * pctFactor;
      while (true) {
        final checkTime = DateTime.now();
        final recentRequests = _requestTimestamps
            .where(
              (dt) => checkTime.difference(dt) <= const Duration(minutes: 1),
            )
            .length;
        if (recentRequests < effectiveRpm) {
          break;
        }
        final oldestInWindow = _requestTimestamps.firstWhere(
          (dt) => checkTime.difference(dt) <= const Duration(minutes: 1),
        );
        final waitDuration =
            const Duration(minutes: 1) -
            checkTime.difference(oldestInWindow) +
            const Duration(milliseconds: 100);
        await Future.delayed(waitDuration);
      }
    }

    if (modelInfo.limitTpm != null && modelInfo.limitTpm! > 0) {
      final double effectiveTpm = modelInfo.limitTpm! * pctFactor;
      while (true) {
        final checkTime = DateTime.now();
        final recentTokens = _tokenUsage
            .where(
              (item) =>
                  checkTime.difference(item.timestamp) <=
                  const Duration(minutes: 1),
            )
            .fold<int>(0, (sum, item) => sum + item.tokenCount);

        if (recentTokens + estimatedTokens <= effectiveTpm) {
          break;
        }
        if (_tokenUsage.isEmpty) break;
        final oldestInWindow = _tokenUsage.firstWhere(
          (item) =>
              checkTime.difference(item.timestamp) <=
              const Duration(minutes: 1),
        );
        final waitDuration =
            const Duration(minutes: 1) -
            checkTime.difference(oldestInWindow.timestamp) +
            const Duration(milliseconds: 100);
        await Future.delayed(waitDuration);
      }
    }

    final actualRequestTime = DateTime.now();
    _requestTimestamps.add(actualRequestTime);
    _tokenUsage.add((
      timestamp: actualRequestTime,
      tokenCount: estimatedTokens,
    ));
  }
}

class CloudAiService extends AiService {
  final String baseUrl;
  final String apiKey;
  final String modelName;
  final double throttlePercentage;
  final http.Client _httpClient;
  final RateLimiter? _rateLimiter;

  CloudAiService({
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
    this.throttlePercentage = 100.0,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client(),
       _rateLimiter = (() {
         final info = CloudModelDatabase.getModelInfo(modelName);
         return info != null
             ? RateLimiter(
                 modelInfo: info,
                 throttlePercentage: throttlePercentage,
               )
             : null;
       })();

  @override
  Future<AiCoreStatus> checkStatus() async {
    return AiCoreStatus.available;
  }

  @override
  Future<void> triggerDownload() async {}

  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) async {}

  @override
  Future<int> countTokens({
    required String prompt,
    Uint8List? imageBytes,
  }) async {
    // Estimator: 1 token is roughly 4 characters
    int count = (prompt.length / 4).round();
    if (imageBytes != null && imageBytes.isNotEmpty) {
      count += 256;
    }
    return count;
  }

  @override
  Future<AiResponse?> generateContentRaw({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    if (_rateLimiter != null) {
      final estimatedTokens = await countTokens(
        prompt: prompt,
        imageBytes: imageBytes,
      );
      await _rateLimiter.throttleBeforeRequest(estimatedTokens);
    }

    final url = Uri.parse('$baseUrl/chat/completions');

    final List<Map<String, dynamic>> messages = [];
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final base64Image = base64Encode(imageBytes);
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/png;base64,$base64Image'},
          },
        ],
      });
    } else {
      messages.add({'role': 'user', 'content': prompt});
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': modelName,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': ?maxOutputTokens,
    });

    try {
      final response = await _httpClient.post(
        url,
        headers: headers,
        body: body,
      );
      if (response.statusCode != 200) {
        debugPrint(
          'CloudAiService error response: ${response.statusCode} - ${response.body}',
        );
        return AiResponse(
          text: '{"error": "Server returned code ${response.statusCode}"}',
          isTruncated: false,
        );
      }

      final data = jsonDecode(response.body);
      final choice = data['choices']?[0];
      final text = choice?['message']?['content'] as String?;
      final finishReason = choice?['finish_reason'] as String?;
      final isTruncated = finishReason == 'length';

      if (text == null) return null;
      return AiResponse(text: text, isTruncated: isTruncated);
    } catch (e, stack) {
      debugPrint('Error in CloudAiService post request: $e\n$stack');
      return AiResponse(
        text: '{"error": "${e.toString().replaceAll('"', '\\"')}"}',
        isTruncated: false,
      );
    }
  }

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    final res = await generateContentRaw(
      prompt: prompt,
      imageBytes: imageBytes,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
    return res?.text;
  }
}
