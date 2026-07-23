enum CloudProvider { gemini, zhipu }

class CloudModelInfo {
  final String modelName;
  final CloudProvider provider;
  final bool isVision;
  final int? limitRpm;
  final int? limitTpm;
  final int? limitRpd;
  final int? limitRps;
  final String description;

  const CloudModelInfo({
    required this.modelName,
    required this.provider,
    this.isVision = false,
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
      modelName: 'gemini-3.6-flash',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 5,
      limitTpm: 250000,
      limitRpd: 20,
      description: 'Free Tier Limits: 5 RPM / 250k TPM / 20 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3.5-flash',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 5,
      limitTpm: 250000,
      limitRpd: 20,
      description: 'Free Tier Limits: 5 RPM / 250k TPM / 20 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3.5-flash-lite',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 15,
      limitTpm: 250000,
      limitRpd: 500,
      description: 'Free Tier Limits: 15 RPM / 250k TPM / 500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3.1-pro',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: null,
      limitTpm: null,
      limitRpd: null,
      description: 'Paid Tier Only (No free tier)',
    ),
    CloudModelInfo(
      modelName: 'gemini-3-flash',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 5,
      limitTpm: 250000,
      limitRpd: 20,
      description: 'Free Tier Limits: 5 RPM / 250k TPM / 20 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-3.1-flash-lite',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 15,
      limitTpm: 250000,
      limitRpd: 500,
      description: 'Free Tier Limits: 15 RPM / 250k TPM / 500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemma-4-31b-it',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 15,
      limitTpm: 250000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 250k TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemma-4-26b-it',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 15,
      limitTpm: 250000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 250k TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemma-4-12b-it',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 15,
      limitTpm: 250000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 250k TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemma-4-4b-it',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 15,
      limitTpm: 250000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 250k TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemma-4-2b-it',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 15,
      limitTpm: 250000,
      limitRpd: 1500,
      description: 'Free Tier Limits: 15 RPM / 250k TPM / 1,500 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-2.5-pro',
      provider: CloudProvider.gemini,
      isVision: true,
      limitRpm: 2,
      limitTpm: 32000,
      limitRpd: 50,
      description: 'Free Tier Limits: 2 RPM / 32k TPM / 50 RPD',
    ),
    CloudModelInfo(
      modelName: 'gemini-2.5-flash',
      provider: CloudProvider.gemini,
      isVision: true,
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
      isVision: false,
      limitRps: 2,
      description: 'Commercial: 2 RPS (Approx. \$1.40 / 1M input tokens)',
    ),
    CloudModelInfo(
      modelName: 'glm-5v-turbo',
      provider: CloudProvider.zhipu,
      isVision: true,
      limitRps: 2,
      description: 'Commercial: 2 RPS (Flagship Vision Model)',
    ),
    CloudModelInfo(
      modelName: 'glm-4v-flash',
      provider: CloudProvider.zhipu,
      isVision: true,
      limitRps: 2,
      description: 'Free Tier Limits: 2 RPS (Zero cost vision model)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.7-flash',
      provider: CloudProvider.zhipu,
      isVision: false,
      limitRps: 2,
      description: 'Free Tier Limits: 2 RPS (zero cost, completely free)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.7',
      provider: CloudProvider.zhipu,
      isVision: false,
      limitRps: 2,
      description: 'Commercial: 2 RPS (Standard capability)',
    ),
    CloudModelInfo(
      modelName: 'glm-4.5-air',
      provider: CloudProvider.zhipu,
      isVision: false,
      limitRps: 2,
      description: 'Commercial: 2 RPS (Light, balanced)',
    ),
  ];

  static final Map<String, CloudModelInfo> _modelsMap = {
    for (final model in [...geminiModels, ...zhipuModels])
      model.modelName: model,
  };

  /// Query which models are available, optionally filtering by provider and vision support.
  static List<CloudModelInfo> getAvailableModels({
    CloudProvider? provider,
    bool? isVision,
  }) {
    Iterable<CloudModelInfo> list;
    if (provider == CloudProvider.gemini) {
      list = geminiModels;
    } else if (provider == CloudProvider.zhipu) {
      list = zhipuModels;
    } else {
      list = [...geminiModels, ...zhipuModels];
    }
    if (isVision != null) {
      list = list.where((m) => m.isVision == isVision);
    }
    return list.toList();
  }

  /// Query model names, optionally filtering by provider and vision support.
  static List<String> getAvailableModelNames({
    CloudProvider? provider,
    bool? isVision,
  }) {
    return getAvailableModels(
      provider: provider,
      isVision: isVision,
    ).map((m) => m.modelName).toList();
  }

  /// Retrieve model details/limits by name in O(1) time.
  static CloudModelInfo? getModelInfo(String modelName) {
    return _modelsMap[modelName];
  }
}
