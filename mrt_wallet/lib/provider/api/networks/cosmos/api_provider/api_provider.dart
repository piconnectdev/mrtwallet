import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/types.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/models/serializable/serializable.dart';
import 'package:mrt_wallet/models/wallet_models/chain/utils.dart';
import 'package:mrt_wallet/models/wallet_models/network/core/network.dart';
import 'package:mrt_wallet/provider/api/api_provider.dart';
import 'package:mrt_wallet/provider/wallet/constant/constant.dart';

class CosmosAPIProviderService extends ApiProviderService {
  const CosmosAPIProviderService._(
      {required String serviceName,
      required String websiteUri,
      required ProviderProtocol protocol,
      required this.uri,
      required this.nodeUri})
      : super(serviceName, websiteUri, protocol);
  factory CosmosAPIProviderService(
      {required String serviceName,
      required String websiteUri,
      required String uri,
      String? nodeUri,
      String? projectId}) {
    return CosmosAPIProviderService._(
        serviceName: serviceName,
        websiteUri: websiteUri,
        protocol: ProviderProtocol.fromURI(uri),
        uri: uri,
        nodeUri: nodeUri);
  }
  final String uri;
  final String? nodeUri;
  @override
  String get callUrl => uri;

  factory CosmosAPIProviderService.fromCborBytesOrObject(
      {List<int>? bytes, CborObject? obj}) {
    final CborListValue cbor = CborSerializable.decodeCborTags(
        bytes, obj, WalletModelCborTagsConst.cosmosApiServiceProvider);
    final int? protocolId = cbor.elementAt(3);
    return CosmosAPIProviderService._(
        serviceName: cbor.elementAt(0),
        websiteUri: cbor.elementAt(1),
        uri: cbor.elementAt(2),
        protocol: ProviderProtocol.fromID(protocolId ?? 0),
        nodeUri: cbor.elementAt(4));
  }

  @override
  CborTagValue toCbor() {
    return CborTagValue(
        CborListValue.fixedLength([
          serviceName,
          websiteUri,
          uri,
          protocol.id,
          nodeUri == null ? const CborNullValue() : CborStringValue(nodeUri!)
        ]),
        WalletModelCborTagsConst.cosmosApiServiceProvider);
  }

  @override
  List get variabels => [serviceName, websiteUri, uri, protocol];

  @override
  NetworkApiProvider toProvider(AppNetworkImpl network) {
    return ChainUtils.buildTendermintProvider(this, network.toNetwork());
  }
}
