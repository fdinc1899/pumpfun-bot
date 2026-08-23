import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bot_provider.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BotProvider>(
      builder: (context, bot, _) {
        if (bot.activityLog.isEmpty) {
          return const Center(child: Text('Henüz log yok'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bot.activityLog.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              bot.activityLog[i],
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
        );
      },
    );
  }
}
