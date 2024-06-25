import 'package:mrt_wallet/models/app/app_image.dart';

class CoinGeckoUtils {
  static const String _coingeckoPublicCurrenciesAPI =
      "https://api.coingecko.com/api/v3/simple/price?ids=#ids&vs_currencies=#currencies";
  static const String coinGeckoCoinURL =
      "https://www.coingecko.com/en/coins/#id";
  static const String coinGeckoCoinListURL =
      "https://api.coingecko.com/api/v3/coins/list";
  static const AppImage logo = AppImage.local("assets/image/coingeko.png");
  static String? getTokenCoinGeckoURL(String id) {
    return coinGeckoCoinURL.replaceFirst("#id", id);
  }

  static String toCoingeckoPriceUri(String currencies, String ids) {
    return _coingeckoPublicCurrenciesAPI
        .replaceFirst("#currencies", currencies)
        .replaceFirst("#ids", ids);
  }
}
