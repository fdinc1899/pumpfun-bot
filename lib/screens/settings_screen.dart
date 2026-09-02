import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bot_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BotProvider>(
      builder: (context, bot, _) {
        final s = bot.settings;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionTitle('Cüzdan'),
            _WalletCard(bot: bot),
            const SizedBox(height: 20),

            const _SectionTitle('Genel'),
            SwitchListTile(
              title: const Text('Dry-Run Modu'),
              subtitle: const Text('Açıkken bot gerçek işlem yapmaz, sadece simüle eder.'),
              value: s.dryRun,
              onChanged: bot.isRunning
                  ? null
                  : (v) {
                      s.dryRun = v;
                      bot.notifyListeners();
                    },
            ),
            if (bot.isRunning)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Ayarları değiştirmek için önce botu durdur.',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
              ),

            const SizedBox(height: 12),
            const _SectionTitle('Tarama Filtreleri (Aşama 1)'),
            _NumberSetting(
              label: 'Min. holder sayısı',
              value: s.minHolderCount.toDouble(),
              min: 0, max: 200, divisions: 40,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.minHolderCount = v.toInt()),
            ),
            _NumberSetting(
              label: 'Max. tek cüzdan payı (%)',
              value: s.maxTopHolderPercent,
              min: 1, max: 50, divisions: 49,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.maxTopHolderPercent = v),
            ),
            _NumberSetting(
              label: 'Max. geliştirici payı (%)',
              value: s.maxDevHoldingPercent,
              min: 0, max: 50, divisions: 50,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.maxDevHoldingPercent = v),
            ),
            _NumberSetting(
              label: 'Min. likidite (SOL)',
              value: s.minLiquiditySol,
              min: 0, max: 50, divisions: 50,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.minLiquiditySol = v),
            ),

            const SizedBox(height: 12),
            const _SectionTitle('Teknik Analiz (Aşama 2)'),
            _NumberSetting(
              label: 'Analiz penceresi (saniye)',
              value: s.priceWindowSeconds.toDouble(),
              min: 30, max: 900, divisions: 29,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.priceWindowSeconds = v.toInt()),
            ),
            _NumberSetting(
              label: 'Min. fiyat artışı (%)',
              value: s.minPriceIncreasePercent,
              min: 1, max: 50, divisions: 49,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.minPriceIncreasePercent = v),
            ),
            _NumberSetting(
              label: 'Min. hacim artış katsayısı',
              value: s.minVolumeSpikeMultiplier,
              min: 1, max: 10, divisions: 18,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.minVolumeSpikeMultiplier = v),
            ),

            const SizedBox(height: 12),
            const _SectionTitle('Risk Yönetimi'),
            _NumberSetting(
              label: 'Pozisyon büyüklüğü (SOL)',
              value: s.positionSizeSol,
              min: 0.01, max: 1, divisions: 99,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.positionSizeSol = v),
            ),
            _NumberSetting(
              label: 'Max. eşzamanlı pozisyon',
              value: s.maxConcurrentPositions.toDouble(),
              min: 1, max: 10, divisions: 9,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.maxConcurrentPositions = v.toInt()),
            ),
            _NumberSetting(
              label: 'Stop-Loss (%)',
              value: s.stopLossPercent,
              min: 5, max: 50, divisions: 45,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.stopLossPercent = v),
            ),
            _NumberSetting(
              label: 'Take-Profit (%)',
              value: s.takeProfitPercent,
              min: 10, max: 200, divisions: 38,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.takeProfitPercent = v),
            ),
            _NumberSetting(
              label: 'Trailing Stop (%)',
              value: s.trailingStopPercent,
              min: 5, max: 50, divisions: 45,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.trailingStopPercent = v),
            ),
            _NumberSetting(
              label: 'Max. tutma süresi (dakika)',
              value: s.maxHoldSeconds / 60,
              min: 1, max: 120, divisions: 119,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.maxHoldSeconds = (v * 60).toInt()),
            ),
            _NumberSetting(
              label: 'Günlük zarar limiti (SOL)',
              value: s.dailyLossLimitSol,
              min: 0.05, max: 5, divisions: 99,
              enabled: !bot.isRunning,
              onChanged: (v) => _update(bot, () => s.dailyLossLimitSol = v),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _update(BotProvider bot, VoidCallback fn) {
    fn();
    bot.notifyListeners();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

class _NumberSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _NumberSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 4,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              label: value.toStringAsFixed(value < 10 ? 2 : 0),
              onChanged: enabled ? onChanged : null,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(value.toStringAsFixed(value < 10 ? 2 : 0),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatefulWidget {
  final BotProvider bot;
  const _WalletCard({required this.bot});

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  final _controller = TextEditingController();
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final wallet = widget.bot.walletService;

    if (wallet.isUnlocked) {
      return Card(
        color: Colors.green.shade50,
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(
            '${wallet.publicAddress!.substring(0, 6)}...'
            '${wallet.publicAddress!.substring(wallet.publicAddress!.length - 4)}',
          ),
          subtitle: const Text('Cüzdan yüklendi'),
          trailing: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await wallet.deleteWallet();
              (context as Element).markNeedsBuild();
            },
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Private key'inizi (Base58 formatında) girin. Bu bilgi yalnızca "
"cihazınızın güvenli deposunda (Keychain/Keystore) şifreli olarak "
"tutulur, hiçbir sunucuya gönderilmez.",
              
      
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Private Key (Base58)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _importing
                    ? null
                    : () async {
                        setState(() => _importing = true);
                        try {
                          await wallet.importPrivateKey(_controller.text.trim());
                          _controller.clear();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: geçersiz key ($e)')),
                            );
                          }
                        } finally {
                          setState(() => _importing = false);
                        }
                      },
                child: _importing
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Cüzdanı İçe Aktar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
