class PositionModel {
  final String mint;
  final String symbol;
  final double entryPrice;
  final double solSpent;
  final double tokenAmount;
  final DateTime openedAt;

  double highestPrice;      // trailing stop hesabı için zirve fiyat
  double currentPrice;
  DateTime? closedAt;
  double? exitPrice;
  double? realizedPnlSol;
  PositionCloseReason? closeReason;
  bool isOpen;

  PositionModel({
    required this.mint,
    required this.symbol,
    required this.entryPrice,
    required this.solSpent,
    required this.tokenAmount,
    required this.openedAt,
    double? currentPrice,
  })  : highestPrice = entryPrice,
        currentPrice = currentPrice ?? entryPrice,
        isOpen = true;

  double get pnlPercent =>
      ((currentPrice - entryPrice) / entryPrice) * 100;

  double get unrealizedPnlSol =>
      solSpent * (currentPrice - entryPrice) / entryPrice;

  double get drawdownFromPeakPercent =>
      highestPrice == 0 ? 0 : ((highestPrice - currentPrice) / highestPrice) * 100;

  int get holdSeconds =>
      (closedAt ?? DateTime.now()).difference(openedAt).inSeconds;

  void updatePrice(double price) {
    currentPrice = price;
    if (price > highestPrice) highestPrice = price;
  }

  void close(double exitPriceValue, PositionCloseReason reason) {
    closedAt = DateTime.now();
    exitPrice = exitPriceValue;
    closeReason = reason;
    realizedPnlSol = solSpent * (exitPriceValue - entryPrice) / entryPrice;
    isOpen = false;
  }
}

enum PositionCloseReason {
  takeProfit,
  stopLoss,
  trailingStop,
  maxHoldTime,
  manual,
}

extension PositionCloseReasonLabel on PositionCloseReason {
  String get turkishLabel {
    switch (this) {
      case PositionCloseReason.takeProfit:
        return 'Kâr Al';
      case PositionCloseReason.stopLoss:
        return 'Zarar Durdur';
      case PositionCloseReason.trailingStop:
        return 'Trailing Stop';
      case PositionCloseReason.maxHoldTime:
        return 'Süre Doldu';
      case PositionCloseReason.manual:
        return 'Manuel';
    }
  }
}
