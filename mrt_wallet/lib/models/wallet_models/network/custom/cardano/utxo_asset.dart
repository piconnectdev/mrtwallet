import 'package:blockchain_utils/binary/binary.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:on_chain/ada/src/models/ada_models.dart';

class UtxoAssets {
  final Map<AssetName, NoneDecimalBalance> assets;

  UtxoAssets._(Map<AssetName, NoneDecimalBalance> assets)
      : assets = Map<AssetName, NoneDecimalBalance>.unmodifiable(assets);
  factory UtxoAssets(Map<AssetName, NoneDecimalBalance> assets,
      {int? decimal}) {
    final keys = assets.keys.toList()..sort();
    return UtxoAssets._({for (final i in keys) i: assets[i]!});
  }

  UtxoAssets copyWith({
    Map<AssetName, NoneDecimalBalance>? assets,
  }) {
    return UtxoAssets(assets ?? this.assets);
  }

  UtxoAssets operator +(UtxoAssets other) {
    final values = Map<AssetName, NoneDecimalBalance>.from(assets);
    for (final i in other.assets.entries) {
      if (values.containsKey(i.key)) {
        values[i.key] = values[i.key]! + i.value;
      } else {
        values[i.key] = i.value;
      }
    }
    return UtxoAssets(values);
  }

  UtxoAssets operator -(UtxoAssets other) {
    final values = Map<AssetName, NoneDecimalBalance>.from(assets);
    for (final i in other.assets.entries) {
      if (!values.containsKey(i.key)) continue;
      final val = values[i.key]! - i.value;
      if (val <= BigInt.zero) {
        values.remove(i.key);
      } else {
        values[i.key] = val;
      }
    }
    return UtxoAssets(values);
  }

  Assets toAssets() {
    return Assets({for (final i in assets.entries) i.key: i.value.balance});
  }

  @override
  operator ==(other) {
    if (other is! UtxoAssets) return false;
    if (other.assets.length != assets.length) return false;
    for (final i in other.assets.entries) {
      if (other.assets[i.key] != assets[i.key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => assets.entries.fold(
      mask32,
      (previousValue, element) =>
          previousValue ^ (element.key.hashCode ^ element.value.hashCode));

  @override
  String toString() {
    return "UtxoAssets{$assets}";
  }
}
