import '../models/token_model.dart';
import '../models/bot_settings.dart';

/// Aşama 2: Tarama filtresini geçmiş (watching) tokenlarda fiyat/hacim
/// verisini izleyerek alım sinyali üretir.
class AnalyzerService {
  final BotSettings settings;

  AnalyzerService(this.settings);

  /// Token'ın fiyat geçmişini analiz eder, hesaplanan metrikleri
  /// token nesnesine yazar ve alım sinyali olup olmadığını döner.
  bool analyze(TokenModel token) {
    if (token.priceHistory.length < 5) return false; // yeterli veri yok

    final windowStart = DateTime.now()
        .subtract(Duration(seconds: settings.priceWindowSeconds));
    final windowPoints =
        token.priceHistory.where((p) => p.time.isAfter(windowStart)).toList();

    if (windowPoints.length < 3) return false;

    // --- Momentum: pencere başı vs son fiyat ---
    final startPrice = windowPoints.first.price;
    final endPrice = windowPoints.last.price;
    final momentum = startPrice == 0
        ? 0.0
        : ((endPrice - startPrice) / startPrice) * 100;
    token.momentumPercent = momentum;

    // --- Hacim spike: pencere içi hacim vs önceki eşit uzunluktaki dönem ---
    final priorWindowStart =
        windowStart.subtract(Duration(seconds: settings.priceWindowSeconds));
    final priorPoints = token.priceHistory
        .where((p) => p.time.isAfter(priorWindowStart) && p.time.isBefore(windowStart))
        .toList();

    final windowVolume =
        windowPoints.fold<double>(0, (sum, p) => sum + p.volumeSol);
    final priorVolume =
        priorPoints.fold<double>(0, (sum, p) => sum + p.volumeSol);

    final volumeSpike = priorVolume <= 0
        ? (windowVolume > 0 ? double.infinity : 0.0)
        : windowVolume / priorVolume;
    token.volumeSpikeRatio = volumeSpike;

    // --- Alış / satış oranı ---
    final buyCount = windowPoints.where((p) => p.isBuy).length;
    final sellCount = windowPoints.where((p) => !p.isBuy).length;
    final buySellRatio = sellCount == 0
        ? (buyCount > 0 ? double.infinity : 0.0)
        : buyCount / sellCount;
    token.buySellRatio = buySellRatio;

    // --- Sinyal kararı ---
    final signal = momentum >= settings.minPriceIncreasePercent &&
        volumeSpike >= settings.minVolumeSpikeMultiplier &&
        buySellRatio >= settings.minBuySellRatio;

    if (signal) {
      token.status = TokenStatus.signaled;
    }
    return signal;
  }
}
