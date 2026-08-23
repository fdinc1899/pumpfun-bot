import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bot_provider.dart';
import '../models/token_model.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BotProvider>(
      builder: (context, bot, _) {
        final tokens = bot.watchedTokens.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (tokens.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Henüz izlenen token yok.\nBotu başlattığında filtreyi geçen '
                'yeni tokenlar burada listelenecek.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tokens.length,
          itemBuilder: (context, i) => _TokenCard(token: tokens[i]),
        );
      },
    );
  }
}

class _TokenCard extends StatelessWidget {
  final TokenModel token;
  const _TokenCard({required this.token});

  Color _statusColor() {
    switch (token.status) {
      case TokenStatus.watching:
        return Colors.blue;
      case TokenStatus.signaled:
        return Colors.orange;
      case TokenStatus.bought:
        return Colors.green;
      case TokenStatus.rejected:
        return Colors.grey;
      case TokenStatus.scanning:
        return Colors.grey.shade400;
    }
  }

  String _statusLabel() {
    switch (token.status) {
      case TokenStatus.watching:
        return 'İzleniyor';
      case TokenStatus.signaled:
        return 'Sinyal';
      case TokenStatus.bought:
        return 'Alındı';
      case TokenStatus.rejected:
        return 'Reddedildi';
      case TokenStatus.scanning:
        return 'Taranıyor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${token.symbol} · ${token.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
                Chip(
                  label: Text(_statusLabel(), style: const TextStyle(fontSize: 11)),
                  backgroundColor: _statusColor().withOpacity(0.15),
                  labelStyle: TextStyle(color: _statusColor()),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _MiniStat('Holder', '${token.holderCount}'),
                _MiniStat('Top holder', '%${token.topHolderPercent.toStringAsFixed(1)}'),
                _MiniStat('Likidite', '${token.liquiditySol.toStringAsFixed(1)} SOL'),
                if (token.momentumPercent != null)
                  _MiniStat('Momentum', '%${token.momentumPercent!.toStringAsFixed(1)}'),
                if (token.volumeSpikeRatio != null)
                  _MiniStat('Hacim', '${token.volumeSpikeRatio!.toStringAsFixed(1)}x'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
