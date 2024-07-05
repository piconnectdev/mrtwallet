import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:mrt_wallet/app/euqatable/equatable.dart';
import 'package:mrt_wallet/app/serialization/serialization.dart';
import 'package:mrt_wallet/wroker/coins/custom_coins/coins.dart';
import 'package:mrt_wallet/wroker/constant/const.dart';
import 'package:mrt_wallet/wroker/keys/models/key_type.dart';

class EncryptedCustomKey with Equatable, CborSerializable {
  final String publicKey;
  final String id;
  final CryptoCoins coin;
  final DateTime created;
  final String? name;
  final CustomKeyType keyType;
  const EncryptedCustomKey(
      {required this.publicKey,
      required this.coin,
      required this.id,
      required this.created,
      required this.name,
      required this.keyType});
  factory EncryptedCustomKey.fromCborBytesOrObject(
      {List<int>? bytes, CborObject? obj}) {
    final CborListValue cbor = CborSerializable.decodeCborTags(
        bytes, obj, CryptoKeyConst.encryptedCustomKey);

    final CryptoProposal proposal = CustomProposal.fromName(cbor.elementAt(2));
    final CryptoCoins coin = CustomCoins.getCoin(cbor.elementAt(3), proposal)!;
    return EncryptedCustomKey(
        publicKey: cbor.elementAt(0),
        id: cbor.elementAt(1),
        coin: coin,
        created: cbor.elementAt(4),
        name: cbor.elementAt(5),
        keyType: CustomKeyType.fromName(cbor.elementAt(6)));
  }

  @override
  List get variabels => [publicKey, id, coin, keyType.name];

  @override
  CborTagValue toCbor() {
    return CborTagValue(
        CborListValue.fixedLength([
          publicKey,
          id,
          coin.proposal.specName,
          coin.coinName,
          CborEpochIntValue(created),
          name ?? const CborNullValue(),
          keyType.name,
        ]),
        CryptoKeyConst.encryptedCustomKey);
  }
}
