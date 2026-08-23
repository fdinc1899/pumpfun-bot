/// Pump.fun üzerinde taranan bir token'ı ve onunla ilgili
/// tüm filtre/analiz verilerini tutan model.
class TokenModel {
  final String mint;              // token mint adresi
  final String symbol;
  final String name;
  final DateTime createdAt;

  // Tarama (scanner) aşaması verileri
  int holderCount;
  double topHolderPercent;
  double devHoldingPercent;
  double liquiditySol;

  // Fiyat / hacim geçmişi (basit zaman serisi, analiz için)
  final List<PricePoint> priceHistory;

  // Analiz sonuçları
  double? momentumPercent;        // son X dakikadaki fiyat değişimi
  double? volumeSpikeRatio;       // hacim artış oranı
  double? buySellRatio;           // alış/satış oranı

  TokenStatus status;

  TokenModel({
    required this.mint,
    required this.symbol,
    required this.name,
    required this.createdAt,
    this.holderCount = 0,
    this.topHolderPercent = 0,
    this.devHoldingPercent = 0,
    this.liquiditySol = 0,
    List<PricePoint>? priceHistory,
    this.momentumPercent,
    this.volumeSpikeRatio,
    this.buySellRatio,
    this.status = TokenStatus.scanning,
  }) : priceHistory = priceHistory ?? [];

  double get ageSeconds =>
      DateTime.now().difference(createdAt).inSeconds.toDouble();

  double get currentPrice =>
      priceHistory.isNotEmpty ? priceHistory.last.price : 0;

  void addPricePoint(double price, double volumeSol, bool isBuy) {
    priceHistory.add(PricePoint(
      time: DateTime.now(),
      price: price,
      volumeSol: volumeSol,
      isBuy: isBuy,
    ));
    // Belleği şişirmemek için son 500 noktayı tut
    if (priceHistory.length > 500) {
      priceHistory.removeAt(0);
    }
  }
}

class PricePoint {
  final DateTime time;
  final double price;
  final double volumeSol;
  final bool isBuy;

  PricePoint({
    required this.time,
    required this.price,
    required this.volumeSol,
    required this.isBuy,
  });
}

enum TokenStatus {
  scanning,   // filtre kriterleri henüz değerlendiriliyor
  watching,   // filtreyi geçti, teknik sinyal bekleniyor
  signaled,   // alım sinyali oluştu
  rejected,   // filtreyi geçemedi
  bought,     // pozisyon açıldı
}
