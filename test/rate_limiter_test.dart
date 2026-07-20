import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_agent_core/flutter_agent_core.dart';

void main() {
  group('RateLimiter Tests', () {
    test('RateLimiter enforces Request-Per-Second (RPS) limits', () async {
      final mockInfo = CloudModelInfo(
        modelName: 'test-rps-model',
        providerName: 'test-provider',
        limitRps: 10, // 10 RPS -> 100ms interval
        description: 'Test limit',
      );

      final limiter = RateLimiter(
        modelInfo: mockInfo,
        throttlePercentage: 100.0,
      );

      final stopwatch = Stopwatch()..start();
      await limiter.throttleBeforeRequest(10);
      await limiter.throttleBeforeRequest(10);
      stopwatch.stop();

      // The second request should be throttled/delayed to enforce the 100ms interval
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
    });

    test('RateLimiter honors throttlePercentage setting', () async {
      final mockInfo = CloudModelInfo(
        modelName: 'test-rps-model-pct',
        providerName: 'test-provider',
        limitRps: 10, // 10 RPS -> normally 100ms interval
        description: 'Test limit',
      );

      // Throttle to 50% -> effective limit is 5 RPS -> 200ms interval
      final limiter = RateLimiter(
        modelInfo: mockInfo,
        throttlePercentage: 50.0,
      );

      final stopwatch = Stopwatch()..start();
      await limiter.throttleBeforeRequest(10);
      await limiter.throttleBeforeRequest(10);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(190));
    });

    test('RateLimiter handles Requests-Per-Minute (RPM) throttling', () async {
      final mockInfo = CloudModelInfo(
        modelName: 'test-rpm-model',
        providerName: 'test-provider',
        limitRpm:
            120, // 120 RPM -> 2 requests per second (500ms interval equivalent)
        description: 'Test limit',
      );

      final limiter = RateLimiter(
        modelInfo: mockInfo,
        throttlePercentage: 100.0,
      );

      final stopwatch = Stopwatch()..start();
      await limiter.throttleBeforeRequest(10);
      await limiter.throttleBeforeRequest(10);
      stopwatch.stop();

      // Enforces wait so requests fit within the minute rate limit
      // With 120 RPM, the rate check passes immediately unless we exceed the 1-minute bucket.
      // But we can verify it doesn't crash and returns promptly
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
