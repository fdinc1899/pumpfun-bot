import 'dart:typed_data';
import 'package:solana/solana.dart';
import 'package:solana/encoder.dart';
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

      final built = await pumpPortal.buildTradeTransaction(
        publicKey: publicKey,
        action: 'buy',
        mint: mint,
        amount: amountSol,
        denominatedInSol: true,
        slippagePercent: slippagePercent,
        priorityFeeLamports: priorityFeeLamports,
      );

      final signature = await _signAndSend(built['rawTransaction'] as Uint8List, keyPair);
      return TradeResult(success: true, signature: signature, wasDryRun: false);
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

      final built = await pumpPortal.buildTradeTransaction(
        publicKey: publicKey,
        action: 'sell',
        mint: mint,
        amount: tokenAmount,
        denominatedInSol: false,
        slippagePercent: slippagePercent,
        priorityFeeLamports: priorityFeeLamports,
      );

      final signature = await _signAndSend(built['rawTransaction'] as Uint8List, keyPair);
      return TradeResult(success: true, signature: signature, wasDryRun: false);
    } catch (e) {
      return TradeResult(success: false, error: e.toString(), wasDryRun: false);
    }
  }

  Future<String> _signAndSend(Uint8List rawTx, Ed25519HDKeyPair keyPair) async {
    final signedTx = await keyPair.signMessage(message: rawTx);
    final signature = await solanaClient.rpcClient.sendTransaction(
      SignedTx.fromBytes(rawTx).encode(),
      preflightCommitment: Commitment.confirmed,
    );
    return signature;
  }

  Future<double> getSolBalance(String publicAddress) async {
    final balance = await solanaClient.rpcClient.getBalance(publicAddress);
    return balance.value / 1e9;
  }
}
