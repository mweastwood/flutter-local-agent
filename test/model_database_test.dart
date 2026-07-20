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
        provider: 'geminiCloud',
      );
      expect(geminiOnly.every((m) => m.providerName == 'geminiCloud'), isTrue);
      expect(geminiOnly.any((m) => m.modelName == 'gemini-3.5-flash'), isTrue);
      expect(geminiOnly.any((m) => m.modelName == 'glm-4.7-flash'), isFalse);

      final zhipuOnly = CloudModelDatabase.getAvailableModels(
        provider: 'zhipuCloud',
      );
      expect(zhipuOnly.every((m) => m.providerName == 'zhipuCloud'), isTrue);
      expect(zhipuOnly.any((m) => m.modelName == 'glm-4.7-flash'), isTrue);
      expect(zhipuOnly.any((m) => m.modelName == 'gemini-3.5-flash'), isFalse);
    });

    test('CloudModelDatabase getAvailableModelNames returns names', () {
      final allNames = CloudModelDatabase.getAvailableModelNames();
      expect(allNames, contains('gemini-3.5-flash'));
      expect(allNames, contains('glm-4.7-flash'));

      final geminiNames = CloudModelDatabase.getAvailableModelNames(
        provider: 'geminiCloud',
      );
      expect(geminiNames, contains('gemini-3.5-flash'));
      expect(geminiNames, isNot(contains('glm-4.7-flash')));
    });

    test('CloudModelDatabase getModelInfo retrieves details', () {
      final info = CloudModelDatabase.getModelInfo('gemini-3.5-flash');
      expect(info, isNotNull);
      expect(info!.providerName, equals('geminiCloud'));
      expect(info.limitRpm, equals(15));

      final nonExistent = CloudModelDatabase.getModelInfo('some-fake-model');
      expect(nonExistent, isNull);
    });
  });
}
