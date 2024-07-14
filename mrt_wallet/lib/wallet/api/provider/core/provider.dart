import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/bitcoin/providers/provider.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/cardano.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/cosmos.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/ethereum.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/ripple.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/solana.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/substrate.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/ton.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/tron.dart';
import 'package:mrt_wallet/wallet/api/services/models/models.dart';
import 'package:mrt_wallet/wallet/models/network/network.dart';
import 'package:mrt_wallet/wroker/models/networks.dart';

abstract class APIProvider with Equatable, CborSerializable {
  const APIProvider(
      this.serviceName, this.websiteUri, this.protocol, this.auth);
  final ServiceProtocol protocol;
  final String serviceName;
  final String websiteUri;
  final ProviderAuth? auth;

  T toProvider<T extends APIProvider>() {
    if (this is! T) throw WalletExceptionConst.invalidProviderInformation;
    return this as T;
  }

  @override
  List get variabels => [serviceName, websiteUri, protocol];

  String get callUrl => websiteUri;

  factory APIProvider.fromCborBytesOrObject(WalletNetwork network,
      {List<int>? bytes, CborObject? obj}) {
    switch (network.type) {
      case NetworkType.ethereum:
        return EthereumAPIProvider.fromCborBytesOrObject(
            obj: obj, bytes: bytes);
      case NetworkType.tron:
        return TronAPIProvider.fromCborBytesOrObject(obj: obj, bytes: bytes);
      case NetworkType.solana:
        return SolanaAPIProvider.fromCborBytesOrObject(obj: obj, bytes: bytes);
      case NetworkType.bitcoinAndForked:
      case NetworkType.bitcoinCash:
        return BaseBitcoinAPIProvider.fromCborBytesOrObject(
            obj: obj, bytes: bytes);
      case NetworkType.cardano:
        return CardanoAPIProvider.fromCborBytesOrObject(obj: obj, bytes: bytes);
      case NetworkType.cosmos:
        return CosmosAPIProvider.fromCborBytesOrObject(obj: obj, bytes: bytes);
      case NetworkType.xrpl:
        return RippleAPIProvider.fromCborBytesOrObject(obj: obj, bytes: bytes);
      case NetworkType.ton:
        return TonAPIProvider.fromCborBytesOrObject(obj: obj, bytes: bytes);
      case NetworkType.polkadot:
      case NetworkType.kusama:
        return SubstrateAPIProvider.fromCborBytesOrObject(
            obj: obj, bytes: bytes);
      default:
        throw UnimplementedError(
            "Network does not exists ${network.type.name}");
    }
  }
}
