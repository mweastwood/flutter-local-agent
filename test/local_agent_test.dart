import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:local_agent/local_agent.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest) handler;
  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    final stream = Stream.value(response.bodyBytes);
    return http.StreamedResponse(
      stream,
      response.statusCode,
      headers: response.headers,
    );
  }
}

class MockAiService implements AiService {
  final List<Map<String, dynamic>> responses;
  int callCount = 0;
  final List<String> capturedPrompts = [];

  MockAiService(this.responses);

  @override
  Future<AiCoreStatus> checkStatus() async => AiCoreStatus.available;

  @override
  Future<void> triggerDownload() async {}

  @override
  Future<void> setModelConfig({
    required String releaseStage,
    required String preference,
  }) async {}

  @override
  Future<String?> generateContent({
    required String prompt,
    Uint8List? imageBytes,
    double temperature = 1.0,
    int? maxOutputTokens,
  }) async {
    capturedPrompts.add(prompt);
    if (callCount < responses.length) {
      return jsonEncode(responses[callCount++]);
    }
    return jsonEncode({'tool': 'finish', 'reasoning': 'Done'});
  }
}

class MockTextAgentDelegate implements AgentDelegate {
  int counter = 0;
  final List<String> actionsApplied = [];

  @override
  String formatPrompt(String userPrompt, List<AgentStepResult> history) {
    final buffer = StringBuffer();
    buffer.write('Prompt: $userPrompt. History:');
    for (var res in history) {
      buffer.write(' [${res.tool}:${res.feedback}]');
    }
    return buffer.toString();
  }

  @override
  Uint8List? getVisualInput() => null;

  @override
  Future<String> applyAction(Map<String, dynamic> actionMap) async {
    final action = actionMap['action'] as String? ?? '';
    actionsApplied.add(action);
    if (action == 'increment') {
      counter++;
      return 'Counter is now $counter';
    }
    return 'Unknown action';
  }

  @override
  bool isFinishAction(Map<String, dynamic> actionMap) {
    return actionMap['action'] == 'stop';
  }
}

void main() {
  group('AgentHarness Generic ReAct Loop Tests', () {
    test('harness executes generic steps and updates environment', () async {
      final mockAi = MockAiService([
        {
          'action': 'increment',
          'understanding': 'incrementing count',
          'tool': 'inc',
          'params': [],
          'color': 0,
        },
        {
          'action': 'increment',
          'understanding': 'incrementing count again',
          'tool': 'inc',
          'params': [],
          'color': 0,
        },
        {
          'action': 'stop',
          'understanding': 'done now',
          'tool': 'finish',
          'params': [],
          'color': 0,
        },
      ]);
      final delegate = MockTextAgentDelegate();
      final harness = AgentHarness(aiService: mockAi, delegate: delegate);

      final steps = await harness.runDrawingLoop(
        userPrompt: 'count to 2',
        maxSteps: 5,
      );

      expect(steps.length, equals(3));
      expect(steps[0].tool, equals('inc'));
      expect(steps[0].feedback, equals('Counter is now 1'));
      expect(steps[0].isFinish, isFalse);

      expect(steps[1].tool, equals('inc'));
      expect(steps[1].feedback, equals('Counter is now 2'));
      expect(steps[1].isFinish, isFalse);

      expect(steps[2].isFinish, isTrue);

      expect(delegate.counter, equals(2));
      expect(delegate.actionsApplied, equals(['increment', 'increment']));
    });
  });

  group('AgentHistoryEntry Serialization Tests', () {
    test('toJson and fromJson work correctly with and without image', () {
      final timestamp = DateTime(2026, 7, 12, 12, 0, 0);
      final entry = AgentHistoryEntry(
        timestamp: timestamp,
        prompt: 'test prompt',
        response: 'test response',
        isError: false,
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );

      final jsonMap = entry.toJson();
      expect(jsonMap['timestamp'], equals(timestamp.toIso8601String()));
      expect(jsonMap['prompt'], equals('test prompt'));
      expect(jsonMap['response'], equals('test response'));
      expect(jsonMap['isError'], isFalse);
      expect(jsonMap['image']['mimeType'], equals('image/bmp'));
      expect(jsonMap['image']['base64'], equals(base64Encode([1, 2, 3])));

      final roundTrip = AgentHistoryEntry.fromJson(jsonMap);
      expect(roundTrip.timestamp, equals(timestamp));
      expect(roundTrip.prompt, equals('test prompt'));
      expect(roundTrip.response, equals('test response'));
      expect(roundTrip.isError, isFalse);
      expect(roundTrip.imageBytes, equals(Uint8List.fromList([1, 2, 3])));
      expect(roundTrip.imageMimeType, equals('image/bmp'));
    });

    test('serializeList formats valid JSON indent', () {
      final timestamp = DateTime(2026, 7, 12, 12, 0, 0);
      final entries = [
        AgentHistoryEntry(
          timestamp: timestamp,
          prompt: 'prompt 1',
          response: 'response 1',
          isError: false,
        ),
      ];

      final jsonStr = AgentHistoryEntry.serializeList(entries);
      expect(jsonStr, contains('"prompt": "prompt 1"'));
      expect(jsonStr, contains('"response": "response 1"'));
      expect(jsonStr, contains('"isError": false'));
    });
  });

  group('MethodChannelAiService Tests', () {
    const channel = MethodChannel('com.mweastwood.local_agent');
    final log = <MethodCall>[];

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'checkStatus') {
              return 'available';
            }
            return null;
          });
      log.clear();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('setModelConfig invokes method channel correctly', () async {
      final service = MethodChannelAiService();
      await service.setModelConfig(releaseStage: 'preview', preference: 'fast');

      expect(log.length, equals(1));
      expect(log.first.method, equals('setModelConfig'));
      expect(
        log.first.arguments,
        equals({'releaseStage': 'preview', 'preference': 'fast'}),
      );
    });
  });

  group('OllamaAiService Tests', () {
    test('checkStatus returns available if model is present', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/api/tags'));
        expect(request.method, equals('GET'));
        return http.Response(
          jsonEncode({
            'models': [
              {'name': 'gemma4:e4b'},
            ],
          }),
          200,
        );
      });

      final service = OllamaAiService(httpClient: mockClient);
      final status = await service.checkStatus();
      expect(status, equals(AiCoreStatus.available));
    });

    test('checkStatus returns downloadable if model is missing', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'models': [
              {'name': 'some-other-model:latest'},
            ],
          }),
          200,
        );
      });

      final service = OllamaAiService(httpClient: mockClient);
      final status = await service.checkStatus();
      expect(status, equals(AiCoreStatus.downloadable));
    });

    test('triggerDownload calls pull endpoint', () async {
      var pullCalled = false;
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/api/pull'));
        expect(request.method, equals('POST'));
        final body = jsonDecode(
          await request.finalize().transform(utf8.decoder).join(),
        );
        expect(body['name'], equals('gemma4:e4b'));
        pullCalled = true;
        return http.Response('{}', 200);
      });

      final service = OllamaAiService(httpClient: mockClient);
      await service.triggerDownload();
      expect(pullCalled, isTrue);
    });

    test(
      'generateContent calls generate endpoint and formats base64 image',
      () async {
        var generateCalled = false;
        final mockClient = MockHttpClient((request) async {
          expect(request.url.path, equals('/api/generate'));
          expect(request.method, equals('POST'));
          final body = jsonDecode(
            await request.finalize().transform(utf8.decoder).join(),
          );
          expect(body['model'], equals('gemma4:e4b'));
          expect(body['prompt'], equals('hello gemma'));
          expect(
            body['images'],
            equals([
              base64Encode([1, 2, 3]),
            ]),
          );
          expect(body['options']['temperature'], equals(0.8));
          generateCalled = true;
          return http.Response(jsonEncode({'response': 'hi there'}), 200);
        });

        final service = OllamaAiService(httpClient: mockClient);
        final response = await service.generateContent(
          prompt: 'hello gemma',
          imageBytes: Uint8List.fromList([1, 2, 3]),
          temperature: 0.8,
        );
        expect(response, equals('hi there'));
        expect(generateCalled, isTrue);
      },
    );
  });
}
