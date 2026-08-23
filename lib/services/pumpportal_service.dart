import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// PumpPortal (https://pumpportal.fun) üzerinden:
///  - Yeni token yaratma olaylarını (WebSocket)
///  - İlgili tokenlardaki alım/satım işlemlerini (WebSocket)
///  - Gerçek alım/satım emirlerini (Lightning Trade API, REST)
/// sağlar. Uygulama kapandığında/foreground'dan çıkıldığında bağlantı
/// kapanır — bu bot yalnızca uygulama açıkken çalışacak şekilde tasarlandı.
class PumpPortalService {
  static const _wsUrl = 'wss://pumpportal.fun/api/data';
  static const _tradeApiUrl = 'https://pumpportal.fun/api/trade-local';

  WebSocketChannel? _channel;
  final _newTokenController = StreamController<Map<String, dynamic>>.broadcast();
  final _tradeController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewToken => _newTokenController.stream;
  Stream<Map<String, dynamic>> get onTrade => _tradeController.stream;

  bool get isConnected => _channel != null;

  /// WebSocket bağlantısını açar ve yeni token yaratma olaylarına abone olur.
  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

    _channel!.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final txType = data['txType'] as String?;
          if (txType == 'create') {
            _newTokenController.add(data);
          } else if (txType == 'buy' || txType == 'sell') {
            _tradeController.add(data);
          }
        } catch (_) {
          // Bozuk/parse edilemeyen mesajları sessizce atla
        }
      },
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );

    // Yeni token yaratma olaylarına abone ol
    _channel!.sink.add(jsonEncode({'method': 'subscribeNewToken'}));
  }

  /// Belirli bir token'daki trade akışına abone olur (izleme listesine
  /// eklenen tokenlar için fiyat/hacim verisi toplamak amacıyla).
  void subscribeToToken(String mint) {
    _channel?.sink.add(jsonEncode({
      'method': 'subscribeTokenTrade',
      'keys': [mint],
    }));
  }

  void unsubscribeFromToken(String mint) {
    _channel?.sink.add(jsonEncode({
      'method': 'unsubscribeTokenTrade',
      'keys': [mint],
    }));
  }

  Timer? _reconnectTimer;
  void _scheduleReconnect() {
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  /// Local Trading API: imzasız işlem verisini alır, uygulama içinde
  /// cüzdanla imzalanır ve ağa gönderilir (private key PumpPortal'a
  /// asla gönderilmez — bu yaklaşım "local" API'nin tam amacı budur).
  Future<Map<String, dynamic>> buildTradeTransaction({
    required String publicKey,
    required String action, // 'buy' | 'sell'
    required String mint,
    required double amount, // buy: SOL miktarı, sell: token miktarı ya da "100%"
    required bool denominatedInSol,
    required int slippagePercent,
    required int priorityFeeLamports,
  }) async {
    final response = await http.post(
      Uri.parse(_tradeApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'publicKey': publicKey,
        'action': action,
        'mint': mint,
        'amount': amount,
        'denominatedInSol': denominatedInSol.toString(),
        'slippage': slippagePercent,
        'priorityFee': priorityFeeLamports / 1e9,
        'pool': 'pump',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'PumpPortal işlem oluşturma hatası: ${response.statusCode} ${response.body}');
    }
    // Yanıt, imzalanmamış serileştirilmiş işlem baytlarını içerir.
    return {'rawTransaction': response.bodyBytes};
  }

  void dispose() {
    disconnect();
    _newTokenController.close();
    _tradeController.close();
  }
}
