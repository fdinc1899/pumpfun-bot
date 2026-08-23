/// Tüm bot parametreleri. Varsayılanlar temkinli seçilmiştir;
/// gerçek para ile denemeden önce mutlaka Dry-Run modunda test et.
class BotSettings {
  // --- Genel ---
  bool dryRun;

  // --- Tarama filtreleri (Aşama 1) ---
  int minHolderCount;
  double maxTopHolderPercent;
  double minLiquiditySol;
  double maxDevHoldingPercent;
  int minTokenAgeSeconds;
  int maxTokenAgeSeconds;

  // --- Teknik analiz (Aşama 2) ---
  int priceWindowSeconds;
  double minPriceIncreasePercent;
  double minVolumeSpikeMultiplier;
  double minBuySellRatio;

  // --- Risk yönetimi ---
  double positionSizeSol;
  int maxConcurrentPositions;
  double stopLossPercent;
  double takeProfitPercent;
  double trailingStopPercent;
  int maxHoldSeconds;
  double dailyLossLimitSol;

  // --- İşlem ayarları ---
  int buySlippagePercent;
  int sellSlippagePercent;

  BotSettings({
    this.dryRun = true,
    this.minHolderCount = 30,
    this.maxTopHolderPercent = 15.0,
    this.minLiquiditySol = 5.0,
    this.maxDevHoldingPercent = 10.0,
    this.minTokenAgeSeconds = 60,
    this.maxTokenAgeSeconds = 3600,
    this.priceWindowSeconds = 300,
    this.minPriceIncreasePercent = 8.0,
    this.minVolumeSpikeMultiplier = 2.0,
    this.minBuySellRatio = 1.3,
    this.positionSizeSol = 0.05,
    this.maxConcurrentPositions = 3,
    this.stopLossPercent = 20.0,
    this.takeProfitPercent = 50.0,
    this.trailingStopPercent = 15.0,
    this.maxHoldSeconds = 1800,
    this.dailyLossLimitSol = 0.3,
    this.buySlippagePercent = 10,
    this.sellSlippagePercent = 15,
  });

  Map<String, dynamic> toJson() => {
        'dryRun': dryRun,
        'minHolderCount': minHolderCount,
        'maxTopHolderPercent': maxTopHolderPercent,
        'minLiquiditySol': minLiquiditySol,
        'maxDevHoldingPercent': maxDevHoldingPercent,
        'minTokenAgeSeconds': minTokenAgeSeconds,
        'maxTokenAgeSeconds': maxTokenAgeSeconds,
        'priceWindowSeconds': priceWindowSeconds,
        'minPriceIncreasePercent': minPriceIncreasePercent,
        'minVolumeSpikeMultiplier': minVolumeSpikeMultiplier,
        'minBuySellRatio': minBuySellRatio,
        'positionSizeSol': positionSizeSol,
        'maxConcurrentPositions': maxConcurrentPositions,
        'stopLossPercent': stopLossPercent,
        'takeProfitPercent': takeProfitPercent,
        'trailingStopPercent': trailingStopPercent,
        'maxHoldSeconds': maxHoldSeconds,
        'dailyLossLimitSol': dailyLossLimitSol,
        'buySlippagePercent': buySlippagePercent,
        'sellSlippagePercent': sellSlippagePercent,
      };

  factory BotSettings.fromJson(Map<String, dynamic> json) => BotSettings(
        dryRun: json['dryRun'] ?? true,
        minHolderCount: json['minHolderCount'] ?? 30,
        maxTopHolderPercent: (json['maxTopHolderPercent'] ?? 15.0).toDouble(),
        minLiquiditySol: (json['minLiquiditySol'] ?? 5.0).toDouble(),
        maxDevHoldingPercent: (json['maxDevHoldingPercent'] ?? 10.0).toDouble(),
        minTokenAgeSeconds: json['minTokenAgeSeconds'] ?? 60,
        maxTokenAgeSeconds: json['maxTokenAgeSeconds'] ?? 3600,
        priceWindowSeconds: json['priceWindowSeconds'] ?? 300,
        minPriceIncreasePercent:
            (json['minPriceIncreasePercent'] ?? 8.0).toDouble(),
        minVolumeSpikeMultiplier:
            (json['minVolumeSpikeMultiplier'] ?? 2.0).toDouble(),
        minBuySellRatio: (json['minBuySellRatio'] ?? 1.3).toDouble(),
        positionSizeSol: (json['positionSizeSol'] ?? 0.05).toDouble(),
        maxConcurrentPositions: json['maxConcurrentPositions'] ?? 3,
        stopLossPercent: (json['stopLossPercent'] ?? 20.0).toDouble(),
        takeProfitPercent: (json['takeProfitPercent'] ?? 50.0).toDouble(),
        trailingStopPercent: (json['trailingStopPercent'] ?? 15.0).toDouble(),
        maxHoldSeconds: json['maxHoldSeconds'] ?? 1800,
        dailyLossLimitSol: (json['dailyLossLimitSol'] ?? 0.3).toDouble(),
        buySlippagePercent: json['buySlippagePercent'] ?? 10,
        sellSlippagePercent: json['sellSlippagePercent'] ?? 15,
      );
}
