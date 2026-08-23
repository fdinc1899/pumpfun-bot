import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/solana.dart';

/// Cüzdanı cihazın güvenli deposunda (Keychain / Keystore) saklar.
/// ÖNEMLİ: Private key hiçbir zaman düz metin olarak dosyaya, loga
/// veya herhangi bir sunucuya gönderilmez. Sadece bu servis içinde,
/// imzalama anında kullanılır.
class WalletService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyStorageKey = 'pumpfun_wallet_private_key';

  Ed25519HDKeyPair? _keyPair;
  String? _publicAddress;

  bool get isUnlocked => _keyPair != null;
  String? get publicAddress => _publicAddress;

  /// Base58 formatındaki private key'i güvenli depoya kaydeder.
  Future<void> importPrivateKey(String base58PrivateKey) async {
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: _decodeBase58(base58PrivateKey),
    );
    await _storage.write(key: _keyStorageKey, value: base58PrivateKey);
    _keyPair = keyPair;
    _publicAddress = await keyPair.extract().then((k) => k.address);
  }

  /// Uygulama açılışında, daha önce kaydedilmiş cüzdan varsa yükler.
  /// Kullanıcı her açılışta bir PIN/biyometrik onay vermeli (bkz. main.dart).
  Future<bool> tryLoadSavedWallet() async {
    final saved = await _storage.read(key: _keyStorageKey);
    if (saved == null) return false;
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: _decodeBase58(saved),
    );
    _keyPair = keyPair;
    _publicAddress = await keyPair.extract().then((k) => k.address);
    return true;
  }

  Future<void> deleteWallet() async {
    await _storage.delete(key: _keyStorageKey);
    _keyPair = null;
    _publicAddress = null;
  }

  Ed25519HDKeyPair get keyPairOrThrow {
    if (_keyPair == null) {
      throw StateError('Cüzdan yüklenmedi. Önce cüzdanı içe aktarın.');
    }
    return _keyPair!;
  }

  List<int> _decodeBase58(String value) {
    // solana paketindeki base58 decoder'ı kullanıyoruz
    return base58decode(value);
  }
}
