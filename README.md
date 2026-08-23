# Pump.fun Trading Bot (Flutter)

Pump.fun'da yeni çıkan tokenları tarayan, güvenlik kriterlerinden geçirip
teknik sinyal arayan ve otomatik alım/satım yapan bir mobil uygulama.
**Yalnızca uygulama açıkken (foreground) çalışır** — arka plana atınca
veya kapatınca bot otomatik durur.

## ⚠️ Önce oku

- Pump.fun tokenlarının **büyük çoğunluğu değersizleşiyor**. Rug pull,
  likidite çekme ve bot manipülasyonu bu ortamda çok yaygın. Buradaki
  filtreler riski azaltır ama **sıfırlamaz**.
- Uygulama **DRY_RUN modunda başlar** (`bot_settings.dart` → `dryRun: true`).
  Gerçek para ile denemeden önce en az birkaç gün simülasyon modunda
  çalıştır ve logları/sonuçları incele.
- Gerçek moda geçmeden önce cüzdanına **kaybetmeyi göze alabileceğin**
  küçük bir miktar SOL koy. `positionSizeSol` ve `dailyLossLimitSol`
  ayarlarını buna göre küçük tut.
- Private key cihazının güvenli deposunda (iOS Keychain / Android
  Keystore) şifreli tutulur ve hiçbir sunucuya gönderilmez — ama yine de
  bu cüzdanı **sadece bot için ayrılmış, ana varlıklarını barındırmayan
  bir cüzdan** olarak kullan.

## Mimari

```
lib/
  models/          Token, Pozisyon, Ayarlar veri modelleri
  services/
    wallet_service.dart       Cüzdan (private key) güvenli saklama/imzalama
    pumpportal_service.dart   PumpPortal WebSocket (yeni token akışı) + Trade API
    scanner_service.dart      Aşama 1: holder/likidite/dev-payı filtreleri
    analyzer_service.dart     Aşama 2: momentum, hacim spike, alış/satış oranı
    risk_manager_service.dart Stop-loss / take-profit / trailing stop / günlük limit
    trading_service.dart      Dry-run ve gerçek işlem yürütme
  providers/
    bot_provider.dart         Her şeyi birbirine bağlayan state yönetimi
  screens/         Panel, Tarama, Pozisyonlar, Loglar, Ayarlar
```

**Akış:** PumpPortal WebSocket'ten yeni token geldiğinde → Scanner
filtreleri uygulanır → geçerse izleme listesine alınır ve trade akışına
abone olunur → gelen her trade'de Analyzer momentum/hacim/alış-satış
oranını hesaplar → eşikler karşılanırsa RiskManager pozisyon açılıp
açılamayacağını kontrol eder → TradingService alımı gerçekleştirir →
açık pozisyon her fiyat güncellemesinde RiskManager tarafından
stop-loss/take-profit/trailing-stop/max-süre açısından değerlendirilir.

## Kurulum

```bash
flutter pub get
flutter run   # bağlı cihaz/emülatörde çalıştırır
```

Build almak için:
```bash
flutter build apk        # Android
flutter build ios        # iOS (Mac + Xcode gerekir)
```

## Yapman gerekenler (önemli, kod içinde TODO değil ama bilmen lazım)

1. **RPC endpoint**: `lib/main.dart` içindeki `kSolanaRpcUrl` genel
   mainnet-beta endpoint'i kullanıyor; bu sık istekte hız sınırına
   takılır. Helius, QuickNode veya Alchemy gibi bir sağlayıcıdan
   ücretsiz/ücretli bir RPC anahtarı alıp oraya değiştir.
2. **İşlem imzalama/gönderme** (`trading_service.dart` → `_signAndSend`):
   PumpPortal'ın döndürdüğü serileştirilmiş versioned transaction'ı
   `solana` paketiyle deserialize edip imzalama kısmı, paket
   versiyonuna göre küçük API farklılıkları gösterebilir. Gerçek moda
   geçmeden önce **testnet'te değil ama küçük mainnet miktarlarıyla**
   bu adımı mutlaka doğrula; pump.fun'ın kendi test ağı yok.
3. **PumpPortal API key**: Local Trading API (`/api/trade-local`)
   şu an key gerektirmeden çalışıyor ama PumpPortal bunu değiştirebilir;
   güncel dokümantasyonu kontrol et: https://pumpportal.fun

## Ayarları özelleştirme

Tüm parametreler uygulama içi **Ayarlar** sekmesinden değiştirilebilir
(bot çalışmıyorken). Varsayılanlar temkinlidir:

| Parametre | Varsayılan |
|---|---|
| Min. holder sayısı | 30 |
| Max. tek cüzdan payı | %15 |
| Max. geliştirici payı | %10 |
| Min. likidite | 5 SOL |
| Min. fiyat artışı (5 dk) | %8 |
| Min. hacim artış katsayısı | 2x |
| Pozisyon büyüklüğü | 0.05 SOL |
| Stop-Loss | %20 |
| Take-Profit | %50 |
| Trailing Stop | %15 |
| Günlük zarar limiti | 0.3 SOL |

## Sınırlamalar

- Bot sadece uygulama açıkken çalışır; telefon kilitlenir veya uygulama
  arka plana atılırsa bağlantı kesilir ve açık pozisyonlar **otomatik
  yönetilemez hale gelir**. Uygulamayı kapatmadan önce açık
  pozisyonlarını manuel kontrol et.
- Şu anki filtre ve sinyal mantığı basit/kural tabanlıdır; gelişmiş
  bir strateji değildir, başlangıç noktası olarak tasarlanmıştır.
