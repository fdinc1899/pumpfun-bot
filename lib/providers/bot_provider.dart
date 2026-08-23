import 'package:flutter/foundation.dart';
import 'package:solana/solana.dart';
import '../models/token_model.dart';
import '../models/position_model.dart';
import '../models/bot_settings.dart';
import '../services/pumpportal_service.dart';
import '../services/scanner_service.dart';
import '../services/analyzer_service.dart';
import '../services/risk_manager_service.dart';
import '../services/trading_service.dart';
import '../services/wallet_service.dart';

enum BotRunState { stopped, running }

/// Uygulamanın kalbi. Bot yalnızca bu provider "running" durumdayken
/// ve uygulama foreground'dayken çalışır. Uygulama arka plana
/// atıldığında ya da kapatıldığında WebSocket bağlantısı kesilir ve
/// bot otomatik olarak durur (bu, kullanıcının seçtiği "sadece
/// uygulama açıkken çalışsın" davranışıdır).
class BotProvider extends ChangeNotifier {
  final BotSettings settings = BotSettings();
  final WalletService walletService = WalletService();
  late final PumpPortalService _pumpPortal;
  late final ScannerService _scanner;
  late final AnalyzerService _analyzer;
  late final RiskManagerService _riskManager;
  TradingService? _tradingService;

  BotRunState runState = BotRunState.stopped;

  final Map<String, TokenModel> watchedTokens = {};
  final List<PositionModel> positions = [];
  final List<String> activityLog = [];

  double sessionRealizedPnlSol = 0;
  int rejectedTokenCount = 0;

  BotProvider() {
    _scanner = ScannerService(settings);
    _analyzer = AnalyzerService(settings);
    _riskManager = RiskManagerService(settings);
    _pumpPortal = PumpPortalService();
  }

  bool get isRunning => runState == BotRunState.running;
  List<PositionModel> get openPositions =>
      positions.where((p) => p.isOpen).toList();
  List<PositionModel> get closedPositions =>
      positions.where((p) => !p.isOpen).toList();

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    activityLog.insert(0, '[$timestamp] $message');
    if (activityLog.length > 300) activityLog.removeLast();
    notifyListeners();
  }

  /// Cüzdan hazır olduğunda çağrılır (RPC client burada kurulur).
  void initTradingService(SolanaClient client) {
    _tradingService = TradingService(
      pumpPortal: _pumpPortal,
      wallet: walletService,
      solanaClient: client,
    );
  }

  void start() {
    if (isRunning) return;
    if (!walletService.isUnlocked && !settings.dryRun) {
      _log('HATA: Cüzdan yüklenmeden gerçek modda başlatılamaz.');
      return;
    }
    runState = BotRunState.running;
    _pumpPortal.connect();
    _pumpPortal.onNewToken.listen(_handleNewToken);
    _pumpPortal.onTrade.listen(_handleTradeUpdate);
    _log(settings.dryRun
        ? 'Bot başlatıldı (DRY-RUN modu — gerçek işlem yapılmayacak)'
        : 'Bot başlatıldı (GERÇEK MOD — gerçek SOL kullanılacak)');
    notifyListeners();
  }

  void stop() {
    runState = BotRunState.stopped;
    _pumpPortal.disconnect();
    _log('Bot durduruldu.');
    notifyListeners();
  }

  void _handleNewToken(Map<String, dynamic> data) {
    if (!isRunning) return;
    final mint = data['mint'] as String?;
    if (mint == null || watchedTokens.containsKey(mint)) return;

    final token = TokenModel(
      mint: mint,
      symbol: (data['symbol'] as String?) ?? '???',
      name: (data['name'] as String?) ?? 'Bilinmeyen',
      createdAt: DateTime.now(),
      holderCount: (data['holderCount'] as num?)?.toInt() ?? 0,
      topHolderPercent: (data['topHolderPercent'] as num?)?.toDouble() ?? 100,
      devHoldingPercent: (data['devHoldingPercent'] as num?)?.toDouble() ?? 100,
      liquiditySol: (data['vSolInBondingCurve'] as num?)?.toDouble() ?? 0,
    );

    watchedTokens[mint] = token;

    if (_scanner.evaluate(token)) {
      _pumpPortal.subscribeToToken(mint);
      _log('İzlemeye alındı: ${token.symbol} (${mint.substring(0, 6)}...)');
    } else {
      rejectedTokenCount++;
    }
    notifyListeners();
  }

  void _handleTradeUpdate(Map<String, dynamic> data) {
    if (!isRunning) return;
    final mint = data['mint'] as String?;
    final token = watchedTokens[mint];
    if (token == null) return;

    final price = (data['price'] as num?)?.toDouble() ??
        (data['marketCapSol'] as num?)?.toDouble() ??
        token.currentPrice;
    final volume = (data['solAmount'] as num?)?.toDouble() ?? 0;
    final isBuy = data['txType'] == 'buy';

    token.addPricePoint(price, volume, isBuy);

    // Açık pozisyon varsa güncelle ve risk kontrolü yap
    final position = openPositions.where((p) => p.mint == mint).firstOrNull;
    if (position != null) {
      position.updatePrice(price);
      final closeReason = _riskManager.evaluate(position);
      if (closeReason != null) {
        _closePosition(position, closeReason);
      }
      notifyListeners();
      return;
    }

    // Pozisyon yoksa ve token izleniyorsa analiz et
    if (token.status == TokenStatus.watching) {
      if (_analyzer.analyze(token)) {
        _tryOpenPosition(token);
      }
    }
    notifyListeners();
  }

  Future<void> _tryOpenPosition(TokenModel token) async {
    if (!_riskManager.canOpenNewPosition(openPositions.length)) {
      _log('Sinyal var ama risk limiti nedeniyle atlandı: ${token.symbol}');
      return;
    }
    if (_tradingService == null) {
      _log('HATA: Trading servisi hazır değil.');
      return;
    }

    final result = await _tradingService!.buy(
      mint: token.mint,
      amountSol: settings.positionSizeSol,
      slippagePercent: settings.buySlippagePercent,
      priorityFeeLamports: 100000,
      dryRun: settings.dryRun,
    );

    if (result.success) {
      final position = PositionModel(
        mint: token.mint,
        symbol: token.symbol,
        entryPrice: token.currentPrice,
        solSpent: settings.positionSizeSol,
        tokenAmount: settings.positionSizeSol / token.currentPrice,
        openedAt: DateTime.now(),
      );
      positions.add(position);
      token.status = TokenStatus.bought;
      _log('${result.wasDryRun ? "[DRY-RUN] " : ""}ALIM: ${token.symbol} @ ${token.currentPrice.toStringAsFixed(8)} SOL');
    } else {
      _log('ALIM HATASI (${token.symbol}): ${result.error}');
    }
    notifyListeners();
  }

  Future<void> _closePosition(
      PositionModel position, PositionCloseReason reason) async {
    if (_tradingService == null) return;

    final result = await _tradingService!.sell(
      mint: position.mint,
      tokenAmount: position.tokenAmount,
      slippagePercent: settings.sellSlippagePercent,
      priorityFeeLamports: 100000,
      dryRun: settings.dryRun,
    );

    if (result.success) {
      position.close(position.currentPrice, reason);
      _riskManager.recordRealizedPnl(position.realizedPnlSol ?? 0);
      sessionRealizedPnlSol += position.realizedPnlSol ?? 0;
      _log('${result.wasDryRun ? "[DRY-RUN] " : ""}SATIM: ${position.symbol} '
          '(${reason.turkishLabel}) PNL: ${position.realizedPnlSol?.toStringAsFixed(4)} SOL');
    } else {
      _log('SATIM HATASI (${position.symbol}): ${result.error}');
    }
    notifyListeners();
  }

  /// Kullanıcı elle kapatmak isterse (pozisyon kartındaki "Şimdi Sat" butonu).
  void manualClose(PositionModel position) {
    _closePosition(position, PositionCloseReason.manual);
  }

  @override
  void dispose() {
    _pumpPortal.dispose();
    super.dispose();
  }
}
