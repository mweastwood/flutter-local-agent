import 'dart:async';
import 'model_database.dart';

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
