import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'ai_service.dart';

abstract class AgentDelegate {
  /// Formats the prompt for the next step, incorporating loop history.
  String formatPrompt(String userPrompt, List<AgentStepResult> history);

  /// Provides the visual/image input for the next step, if any.
  Uint8List? getVisualInput();

  /// Applies the action represented by the parsed map and returns feedback.
  Future<String> applyAction(Map<String, dynamic> actionMap);

  /// Checks if the action represents a termination/finish action.
  bool isFinishAction(Map<String, dynamic> actionMap);
}

class AgentStepResult {
  final String thought;
  final String tool;
  final List<int> params;
  final int colorIndex;
  final String feedback;
  final bool isFinish;

  AgentStepResult({
    required this.thought,
    required this.tool,
    required this.params,
    required this.colorIndex,
    required this.feedback,
    this.isFinish = false,
  });
}

class AgentHarness {
  final AiService aiService;
  final AgentDelegate delegate;

  AgentHarness({required this.aiService, required this.delegate});

  /// Runs the agent reasoning-action loop.
  Future<List<AgentStepResult>> runDrawingLoop({
    required String userPrompt,
    int maxSteps = 5,
    Function(AgentStepResult stepResult, int currentStep)? onStep,
  }) async {
    final List<AgentStepResult> results = [];

    for (int step = 1; step <= maxSteps; step++) {
      // 1. Get the combined image input from the delegate
      final visualInput = delegate.getVisualInput();

      // 2. Format the prompt with history
      final prompt = delegate.formatPrompt(userPrompt, results);

      // 3. Query LLM model
      final responseText = await aiService.generateContent(
        prompt: prompt,
        imageBytes: visualInput,
      );

      if (responseText == null) {
        final errorResult = AgentStepResult(
          thought: 'Encountered error: AI service returned empty response',
          tool: 'finish',
          params: [],
          colorIndex: 0,
          feedback: 'Error: Empty response',
          isFinish: true,
        );
        results.add(errorResult);
        if (onStep != null) {
          onStep(errorResult, step);
        }
        break;
      }

      // Parse JSON from response (clean markdown if present)
      var cleanedString = responseText.trim();
      if (cleanedString.startsWith('```')) {
        final lines = cleanedString.split('\n');
        if (lines.first.startsWith('```')) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        cleanedString = lines.join('\n').trim();
      }

      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(cleanedString) as Map<String, dynamic>;
      } catch (e) {
        parsed = {'error': e.toString(), 'rawResponse': responseText};
      }

      if (parsed.containsKey('error')) {
        final errorMsg = parsed['error'] ?? 'AI service returned error';
        final errorResult = AgentStepResult(
          thought: 'Encountered error: $errorMsg',
          tool: 'finish',
          params: [],
          colorIndex: 0,
          feedback: 'Error: $errorMsg',
          isFinish: true,
        );
        results.add(errorResult);
        if (onStep != null) {
          onStep(errorResult, step);
        }
        break;
      }

      final thought = parsed['understanding'] ?? parsed['reasoning'] ?? '';
      final tool = parsed['tool'] as String?;
      final paramsRaw = parsed['params'];
      final List<int> params = paramsRaw is List
          ? List<int>.from(paramsRaw.map((x) => x as int))
          : [];
      final colorIndex = parsed['color'] as int? ?? 0;

      if (tool == null || delegate.isFinishAction(parsed)) {
        final finishResult = AgentStepResult(
          thought: thought,
          tool: 'finish',
          params: [],
          colorIndex: 0,
          feedback: 'Agent finished drawing.',
          isFinish: true,
        );
        results.add(finishResult);
        if (onStep != null) {
          onStep(finishResult, step);
        }
        break;
      }

      // Apply command to environment
      final stepFeedback = await delegate.applyAction(parsed);

      final stepResult = AgentStepResult(
        thought: thought,
        tool: tool,
        params: params,
        colorIndex: colorIndex,
        feedback: stepFeedback,
      );

      results.add(stepResult);
      if (onStep != null) {
        onStep(stepResult, step);
      }
    }

    return results;
  }
}

class AgentHistoryEntry {
  final DateTime timestamp;
  final String prompt;
  final String response;
  final bool isError;
  final Uint8List? imageBytes;
  final String imageMimeType;

  AgentHistoryEntry({
    required this.timestamp,
    required this.prompt,
    required this.response,
    required this.isError,
    this.imageBytes,
    this.imageMimeType = 'image/bmp',
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'prompt': prompt,
      'response': response,
      'isError': isError,
      if (imageBytes != null)
        'image': {
          'mimeType': imageMimeType,
          'base64': base64Encode(imageBytes!),
        },
    };
  }

  factory AgentHistoryEntry.fromJson(Map<String, dynamic> json) {
    final imageMap = json['image'] as Map<String, dynamic>?;
    return AgentHistoryEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      prompt: json['prompt'] as String,
      response: json['response'] as String,
      isError: json['isError'] as bool? ?? false,
      imageBytes: imageMap != null
          ? base64Decode(imageMap['base64'] as String)
          : null,
      imageMimeType: imageMap != null
          ? (imageMap['mimeType'] as String? ?? 'image/bmp')
          : 'image/bmp',
    );
  }

  static String serializeList(List<AgentHistoryEntry> entries) {
    final list = entries.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }
}
