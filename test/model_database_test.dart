import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';

void main() {
  group('CloudModelDatabase Tests', () {
    test('CloudModelDatabase query APIs return expected models', () {
      final allModels = CloudModelDatabase.getAvailableModels();
      expect(allModels, isNotEmpty);
      expect(allModels.any((m) => m.modelName == 'gemini-3.5-flash'), isTrue);
      expect(allModels.any((m) => m.modelName == 'glm-4.7-flash'), isTrue);

      final geminiOnly = CloudModelDatabase.getAvailableModels(
        provider: CloudProvider.gemini,
      );
      expect(
        geminiOnly.every((m) => m.provider == CloudProvider.gemini),
        isTrue,
      );
      expect(geminiOnly.any((m) => m.modelName == 'gemini-3.5-flash'), isTrue);
      expect(geminiOnly.any((m) => m.modelName == 'glm-4.7-flash'), isFalse);

      final zhipuOnly = CloudModelDatabase.getAvailableModels(
        provider: CloudProvider.zhipu,
      );
      expect(zhipuOnly.every((m) => m.provider == CloudProvider.zhipu), isTrue);
      expect(zhipuOnly.any((m) => m.modelName == 'glm-4.7-flash'), isTrue);
      expect(zhipuOnly.any((m) => m.modelName == 'gemini-3.5-flash'), isFalse);
    });

    test('CloudModelDatabase getAvailableModelNames returns names', () {
      final allNames = CloudModelDatabase.getAvailableModelNames();
      expect(allNames, contains('gemini-3.5-flash'));
      expect(allNames, contains('glm-4.7-flash'));

      final geminiNames = CloudModelDatabase.getAvailableModelNames(
        provider: CloudProvider.gemini,
      );
      expect(geminiNames, contains('gemini-3.5-flash'));
      expect(geminiNames, isNot(contains('glm-4.7-flash')));
    });

    test('CloudModelDatabase getModelInfo retrieves details', () {
      final info36 = CloudModelDatabase.getModelInfo('gemini-3.6-flash');
      expect(info36, isNotNull);
      expect(info36!.provider, equals(CloudProvider.gemini));
      expect(info36.isVision, isTrue);
      expect(info36.limitRpm, equals(5));

      final info35Lite = CloudModelDatabase.getModelInfo('gemini-3.5-flash-lite');
      expect(info35Lite, isNotNull);
      expect(info35Lite!.limitRpm, equals(15));
      expect(info35Lite.limitRpd, equals(500));

      final flashLite = CloudModelDatabase.getModelInfo('gemini-3.1-flash-lite');
      expect(flashLite, isNotNull);
      expect(flashLite!.limitRpm, equals(15));
      expect(flashLite.limitRpd, equals(500));

      final zhipuText = CloudModelDatabase.getModelInfo('glm-4.7-flash');
      expect(zhipuText, isNotNull);
      expect(zhipuText!.isVision, isFalse);

      final nonExistent = CloudModelDatabase.getModelInfo('some-fake-model');
      expect(nonExistent, isNull);
    });

    test('CloudModelDatabase supports filtering by isVision', () {
      final visionModels = CloudModelDatabase.getAvailableModels(
        isVision: true,
      );
      expect(visionModels.every((m) => m.isVision), isTrue);
      expect(visionModels.any((m) => m.modelName == 'glm-4v-flash'), isTrue);
      expect(visionModels.any((m) => m.modelName == 'glm-4.7-flash'), isFalse);

      final zhipuVisionNames = CloudModelDatabase.getAvailableModelNames(
        provider: CloudProvider.zhipu,
        isVision: true,
      );
      expect(zhipuVisionNames, contains('glm-4v-flash'));
      expect(zhipuVisionNames, contains('glm-5v-turbo'));
      expect(zhipuVisionNames, isNot(contains('glm-4.7-flash')));
    });
  });
}
