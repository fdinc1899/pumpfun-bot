import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bot_provider.dart';
import 'watchlist_screen.dart';
import 'positions_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final _screens = const [
    _DashboardTab(),
    WatchlistScreen(),
    PositionsScreen(),
    LogsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_tabIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Panel'),
          NavigationDestination(icon: Icon(Icons.radar), label: 'Tarama'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Pozisyonlar'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Loglar'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<BotProvider>(
      builder: (context, bot, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Pump.fun Bot'),
              floating: true,
              actions: [
                if (bot.settings.dryRun)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Chip(
                      label: const Text('DRY-RUN'),
                      backgroundColor: Colors.amber.shade100,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _RunControlCard(bot: bot),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        label: 'Açık Pozisyon',
                        value: '${bot.openPositions.length}',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                      StatCard(
                        label: 'İzlenen Token',
                        value: '${bot.watchedTokens.length}',
                        icon: Icons.visibility_outlined,
                        color: Colors.purple,
                      ),
                      StatCard(
                        label: 'Oturum P&L',
                        value: '${bot.sessionRealizedPnlSol.toStringAsFixed(4)} SOL',
                        icon: bot.sessionRealizedPnlSol >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: bot.sessionRealizedPnlSol >= 0 ? Colors.green : Colors.red,
                      ),
                      StatCard(
                        label: 'Reddedilen Token',
                        value: '${bot.rejectedTokenCount}',
                        icon: Icons.block,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!bot.walletService.isUnlocked)
                    Card(
                      color: Colors.orange.shade50,
                      child: const ListTile(
                        leading: Icon(Icons.warning_amber, color: Colors.orange),
                        title: Text('Cüzdan yüklenmedi'),
                        subtitle: Text(
                            'Gerçek işlem yapmak için Ayarlar > Cüzdan\'dan private key içe aktarın.'),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RunControlCard extends StatelessWidget {
  final BotProvider bot;
  const _RunControlCard({required this.bot});

  @override
  Widget build(BuildContext context) {
    final running = bot.isRunning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  running ? Icons.play_circle_fill : Icons.pause_circle_filled,
                  color: running ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  running ? 'Bot Çalışıyor' : 'Bot Durduruldu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Uygulamayı kapatırsan veya arka plana atarsan bot otomatik durur.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => running ? bot.stop() : bot.start(),
                icon: Icon(running ? Icons.stop : Icons.play_arrow),
                label: Text(running ? 'Durdur' : 'Başlat'),
                style: FilledButton.styleFrom(
                  backgroundColor: running ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
