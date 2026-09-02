import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/solana.dart';
import 'package:bs58/bs58.dart' as bs58;

class WalletService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyStorageKey = 'pumpfun_wallet_private_key';

  Ed25519HDKeyPair? _keyPair;
  String? _publicAddress;

  bool get isUnlocked => _keyPair != null;
  String? get publicAddress => _publicAddress;

  Future<void> importPrivateKey(String base58PrivateKey) async {
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: _decodeBase58(base58PrivateKey),
    );
    await _storage.write(key: _keyStorageKey, value: base58PrivateKey);
    _keyPair = keyPair;
    _publicAddress = await keyPair.address;
  }

  Future<bool> tryLoadSavedWallet() async {
    final saved = await _storage.read(key: _keyStorageKey);
    if (saved == null) return false;
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: _decodeBase58(saved),
    );
    _keyPair = keyPair;
    _publicAddress = await keyPair.address;
    return true;
  }

  Future<void> deleteWallet() async {
    await _storage.delete(key: _keyStorageKey);
    _keyPair = null;
    _publicAddress = null;
  }

  Ed25519HDKeyPair get keyPairOrThrow {
    if (_keyPair == null) {
      throw StateError('Cuzdan yuklenmedi. Once cuzdani ice aktarin.');
    }
    return _keyPair!;
  }
List<int> _decodeBase58(String value) {
    return bs58.base58decode(value);
  }
  
  }
}
