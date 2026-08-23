import '../models/position_model.dart';
import '../models/bot_settings.dart';

/// Açık pozisyonları her fiyat güncellemesinde değerlendirir ve
/// çıkış (satış) gerekip gerekmediğine karar verir.
class RiskManagerService {
  final BotSettings settings;
  double dailyRealizedPnlSol = 0;

  RiskManagerService(this.settings);

  /// Günlük zarar limiti aşıldıysa bot yeni pozisyon açmamalı.
  bool get dailyLossLimitHit => dailyRealizedPnlSol <= -settings.dailyLossLimitSol;

  /// Pozisyonu değerlendirir; kapatılması gerekiyorsa sebebini döner, yoksa null.
  PositionCloseReason? evaluate(PositionModel position) {
    if (!position.isOpen) return null;

    if (position.pnlPercent <= -settings.stopLossPercent) {
      return PositionCloseReason.stopLoss;
    }

    if (position.pnlPercent >= settings.takeProfitPercent) {
      return PositionCloseReason.takeProfit;
    }

    // Trailing stop yalnızca bir miktar kâr oluştuktan sonra devreye girer
    if (position.highestPrice > position.entryPrice &&
        position.drawdownFromPeakPercent >= settings.trailingStopPercent) {
      return PositionCloseReason.trailingStop;
    }

    if (position.holdSeconds >= settings.maxHoldSeconds) {
      return PositionCloseReason.maxHoldTime;
    }

    return null;
  }

  bool canOpenNewPosition(int currentOpenPositionCount) {
    if (dailyLossLimitHit) return false;
    if (currentOpenPositionCount >= settings.maxConcurrentPositions) return false;
    return true;
  }

  void recordRealizedPnl(double pnlSol) {
    dailyRealizedPnlSol += pnlSol;
  }

  void resetDailyCounters() {
    dailyRealizedPnlSol = 0;
  }
}
