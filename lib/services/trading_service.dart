import 'dart:typed_data';
import 'package:solana/solana.dart';
import 'pumpportal_service.dart';
import 'wallet_service.dart';

class TradeResult {
  final bool success;
  final String? signature;
  final String? error;
  final bool wasDryRun;

  TradeResult({
    required this.success,
    this.signature,
    this.error,
    required this.wasDryRun,
  });
}

class TradingService {
  final PumpPortalService pumpPortal;
  final WalletService wallet;
  final SolanaClient solanaClient;

  TradingService({
    required this.pumpPortal,
    required this.wallet,
    required this.solanaClient,
  });

  Future<TradeResult> buy({
    required String mint,
    required double amountSol,
    required int slippagePercent,
    required int priorityFeeLamports,
    required bool dryRun,
  }) async {
    if (dryRun) {
      return TradeResult(success: true, wasDryRun: true, signature: 'DRY_RUN');
    }

    try {
      final keyPair = wallet.keyPairOrThrow;
      final publicKey = await keyPair.address;

      await pumpPortal.buildTradeTransaction(
        publicKey: publicKey,
        action: 'buy',
        mint: mint,
        amount: amountSol,
        denominatedInSol: true,
        slippagePercent: slippagePercent,
        priorityFeeLamports: priorityFeeLamports,
      );

      throw UnimplementedError(
        'Gercek islem imzalama henuz tamamlanmadi. Once Dry-Run modunda test edin.',
      );
    } catch (e) {
      return TradeResult(success: false, error: e.toString(), wasDryRun: false);
    }
  }

  Future<TradeResult> sell({
    required String mint,
    required double tokenAmount,
    required int slippagePercent,
    required int priorityFeeLamports,
    required bool dryRun,
  }) async {
    if (dryRun) {
      return TradeResult(success: true, wasDryRun: true, signature: 'DRY_RUN');
    }

    try {
      final keyPair = wallet.keyPairOrThrow;
      final publicKey = await keyPair.address;

      await pumpPortal.buildTradeTransaction(
        publicKey: publicKey,
        action: 'sell',
        mint: mint,
        amount: tokenAmount,
        denominatedInSol: false,
        slippagePercent: slippagePercent,
        priorityFeeLamports: priorityFeeLamports,
      );

      throw UnimplementedError(
        'Gercek islem imzalama henuz tamamlanmadi. Once Dry-Run modunda test edin.',
      );
    } catch (e) {
      return TradeResult(success: false, error: e.toString(), wasDryRun: false);
    }
  }

  Future<double> getSolBalance(String publicAddress) async {
    final balance = await solanaClient.rpcClient.getBalance(publicAddress);
    return balance.value / 1e9;
  }
}
