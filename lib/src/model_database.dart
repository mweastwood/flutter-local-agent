enum CloudProvider { gemini, zhipu }

class CloudModelInfo {
  final String modelName;
  final CloudProvider provider;
  final int? limitRpm;
  final int? limitTpm;
  final int? limitRpd;
  final int? limitRps;
  final String description;

  const CloudModelInfo({
    required this.modelName,
    required this.provider,
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
      provider: CloudProvider.gemini,
      limitRpm: 15,
      limitTpm: 1000000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 1M TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3.1-pro',
      provider: CloudProvider.gemini,
      limitRpm: 2,
      limitTpm: 32000,
      limitRpd: 50,
      description: 'Free Tier Limits: 2 RPM / 32k TPM / 50 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3-flash',
      provider: CloudProvider.gemini,
      limitRpm: 15,
      limitTpm: 1000000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 1M TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3.1-flash-lite',
      provider: CloudProvider.gemini,
      limitRpm: 15,
      limitTpm: 1000000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 1M TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-2.5-pro',
      provider: CloudProvider.gemini,
      limitRpm: 2,
      limitTpm: 32000,
      limitRpd: 50,
      description: 'Free Tier Limits: 2 RPM / 32k TPM / 50 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-2.5-flash',
      provider: CloudProvider.gemini,
      limitRpm: 15,
      limitTpm: 1000000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 1M TPM / 1,500 RPD',
    ),
  ];

  static const List<CloudModelInfo> zhipuModels = [
    CloudModelInfo(
      modelName: 'glm-5.2',
      provider: CloudProvider.zhipu,
      limitRps: 2,
      description: 'Commercial: 2 RPS (Approx. \$1.40 / 1M input tokens)',
    ),
    CloudModelInfo(
      modelName: 'glm-5v-turbo',
      provider: CloudProvider.zhipu,
      limitRps: 2,
      description: 'Commercial: 2 RPS (Flagship Vision Model)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.7-flash',
      provider: CloudProvider.zhipu,
      limitRps: 2,
      description: 'Free Tier Limits: 2 RPS (zero cost, completely free)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.7',
      provider: CloudProvider.zhipu,
      limitRps: 2,
      description: 'Commercial: 2 RPS (Standard capability)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.5-air',
      provider: CloudProvider.zhipu,
      limitRps: 2,
      description: 'Commercial: 2 RPS (Light, balanced)',
    ),
  ];

  static final Map<String, CloudModelInfo> _modelsMap = {
    for (final model in [...geminiModels, ...zhipuModels])
      model.modelName: model,
  };

  /// Query which models are available, optionally filtering by provider (gemini or zhipu).
  static List<CloudModelInfo> getAvailableModels({CloudProvider? provider}) {
    if (provider == CloudProvider.gemini) return geminiModels;
    if (provider == CloudProvider.zhipu) return zhipuModels;
    if (provider != null) return [];
    return [...geminiModels, ...zhipuModels];
  }

  /// Query the model names of all available models, optionally filtering by provider.
  static List<String> getAvailableModelNames({CloudProvider? provider}) {
    return getAvailableModels(
      provider: provider,
    ).map((m) => m.modelName).toList();
  }

  /// Retrieve model details/limits by name in O(1) time.
  static CloudModelInfo? getModelInfo(String modelName) {
    return _modelsMap[modelName];
  }
}
