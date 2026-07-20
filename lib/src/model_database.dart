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

  /// Query which models are available, optionally filtering by provider (e.g. 'geminiCloud' or 'zhipuCloud').
  static List<CloudModelInfo> getAvailableModels({String? provider}) {
    if (provider == 'geminiCloud') return geminiModels;
    if (provider == 'zhipuCloud') return zhipuModels;
    if (provider != null) return [];
    return [...geminiModels, ...zhipuModels];
  }

  /// Query the model names of all available models, optionally filtering by provider.
  static List<String> getAvailableModelNames({String? provider}) {
    return getAvailableModels(
      provider: provider,
    ).map((m) => m.modelName).toList();
  }

  /// Retrieve model details/limits by name.
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
