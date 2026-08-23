import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';
import 'providers/bot_provider.dart';
import 'screens/home_screen.dart';

// Kendi RPC endpoint'ini kullanman önerilir (Helius, QuickNode vb.)
// Genel mainnet-beta endpoint'i sık istek atınca hız sınırına takılabilir.
const String kSolanaRpcUrl = 'https://api.mainnet-beta.solana.com';
const String kSolanaWsUrl = 'wss://api.mainnet-beta.solana.com';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PumpFunBotApp());
}

class PumpFunBotApp extends StatefulWidget {
  const PumpFunBotApp({super.key});

  @override
  State<PumpFunBotApp> createState() => _PumpFunBotAppState();
}

class _PumpFunBotAppState extends State<PumpFunBotApp> with WidgetsBindingObserver {
  late final BotProvider _botProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _botProvider = BotProvider();
    _botProvider.initTradingService(
      SolanaClient(
        rpcUrl: Uri.parse(kSolanaRpcUrl),
        websocketUrl: Uri.parse(kSolanaWsUrl),
      ),
    );
    _botProvider.walletService.tryLoadSavedWallet();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcının seçimi gereği bot yalnızca uygulama foreground'dayken
    // çalışmalı. Uygulama arka plana/pasif duruma geçtiğinde botu durdur.
    if (state != AppLifecycleState.resumed && _botProvider.isRunning) {
      _botProvider.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _botProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _botProvider,
      child: MaterialApp(
        title: 'Pump.fun Bot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF14F195), // Solana yeşili
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF14F195),
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
