import '../models/token_model.dart';
import '../models/bot_settings.dart';

/// Aşama 1: Yeni gelen her token'ı temel güvenlik/sağlık kriterlerinden
/// geçirir. Bu filtreyi geçemeyen tokenlar hiçbir zaman teknik analize
/// alınmaz — amaç, belli ki rug-pull olacak ya da tamamen manipülatif
/// tokenları en baştan elemek.
class ScannerService {
  final BotSettings settings;

  ScannerService(this.settings);

  /// Token'ı değerlendirir ve durumunu günceller.
  /// true dönerse token izleme listesine (watching) alınabilir.
  bool evaluate(TokenModel token) {
    final reasons = <String>[];

    if (token.ageSeconds < settings.minTokenAgeSeconds) {
      // Henüz kararı vermek için çok erken; reddetme, sadece bekle
      return false;
    }

    if (token.ageSeconds > settings.maxTokenAgeSeconds) {
      reasons.add('Token çok eski (${token.ageSeconds.toInt()} sn)');
    }
    if (token.holderCount < settings.minHolderCount) {
      reasons.add('Holder sayısı yetersiz (${token.holderCount})');
    }
    if (token.topHolderPercent > settings.maxTopHolderPercent) {
      reasons.add(
          'Tek cüzdan payı çok yüksek (%${token.topHolderPercent.toStringAsFixed(1)})');
    }
    if (token.devHoldingPercent > settings.maxDevHoldingPercent) {
      reasons.add(
          'Geliştirici payı çok yüksek (%${token.devHoldingPercent.toStringAsFixed(1)})');
    }
    if (token.liquiditySol < settings.minLiquiditySol) {
      reasons.add(
          'Likidite yetersiz (${token.liquiditySol.toStringAsFixed(2)} SOL)');
    }

    if (reasons.isNotEmpty) {
      token.status = TokenStatus.rejected;
      return false;
    }

    token.status = TokenStatus.watching;
    return true;
  }

  /// Reddedilme sebeplerini kullanıcıya göstermek için ayrıca çağrılabilir.
  List<String> rejectionReasons(TokenModel token) {
    final reasons = <String>[];
    if (token.holderCount < settings.minHolderCount) {
      reasons.add('Holder sayısı: ${token.holderCount} (min ${settings.minHolderCount})');
    }
    if (token.topHolderPercent > settings.maxTopHolderPercent) {
      reasons.add(
          'Top holder: %${token.topHolderPercent.toStringAsFixed(1)} (max %${settings.maxTopHolderPercent})');
    }
    if (token.devHoldingPercent > settings.maxDevHoldingPercent) {
      reasons.add(
          'Dev payı: %${token.devHoldingPercent.toStringAsFixed(1)} (max %${settings.maxDevHoldingPercent})');
    }
    if (token.liquiditySol < settings.minLiquiditySol) {
      reasons.add(
          'Likidite: ${token.liquiditySol.toStringAsFixed(2)} SOL (min ${settings.minLiquiditySol})');
    }
    return reasons;
  }
}
