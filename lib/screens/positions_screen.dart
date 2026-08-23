import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bot_provider.dart';
import '../models/position_model.dart';

class PositionsScreen extends StatelessWidget {
  const PositionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            child: TabBar(
              tabs: [Tab(text: 'Açık'), Tab(text: 'Geçmiş')],
            ),
          ),
          Expanded(
            child: Consumer<BotProvider>(
              builder: (context, bot, _) {
                return TabBarView(
                  children: [
                    _PositionList(positions: bot.openPositions, bot: bot),
                    _PositionList(positions: bot.closedPositions, bot: bot),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionList extends StatelessWidget {
  final List<PositionModel> positions;
  final BotProvider bot;
  const _PositionList({required this.positions, required this.bot});

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) {
      return const Center(child: Text('Pozisyon yok'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: positions.length,
      itemBuilder: (context, i) {
        final p = positions[i];
        final isProfit = p.pnlPercent >= 0;
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
                      child: Text(p.symbol,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}${p.pnlPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isProfit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Giriş: ${p.entryPrice.toStringAsFixed(8)} SOL   '
                    'Şimdi: ${p.currentPrice.toStringAsFixed(8)} SOL'),
                Text('Miktar: ${p.solSpent.toStringAsFixed(3)} SOL'),
                if (!p.isOpen && p.closeReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Kapanış: ${p.closeReason!.turkishLabel} · '
                      'PNL: ${p.realizedPnlSol?.toStringAsFixed(4)} SOL',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ),
                if (p.isOpen)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => bot.manualClose(p),
                      icon: const Icon(Icons.sell_outlined, size: 18),
                      label: const Text('Şimdi Sat'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
