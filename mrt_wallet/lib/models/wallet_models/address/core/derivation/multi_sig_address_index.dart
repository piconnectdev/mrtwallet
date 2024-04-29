import 'package:blockchain_utils/bip/bip/bip32/base/bip32_base.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:mrt_wallet/provider/wallet/constant/constant.dart';

class MultiSigAddressIndex implements AddressDerivationIndex {
  @override
  final String? hdPath = null;
  final String? keyName;
  const MultiSigAddressIndex({this.keyName});

  @override
  CborTagValue toCbor() {
    return CborTagValue(CborListValue.fixedLength([keyName]),
        WalletModelCborTagsConst.multiSigAccountKeyIndex);
  }

  @override
  T derive<T extends Bip32Base>(T derivator,
      {Bip44Levels maxLevel = Bip44Levels.addressIndex}) {
    throw WalletExceptionConst.multiSigDerivationNotSuported;
  }

  @override
  List get variabels => [];

  @override
  CryptoCoins get currencyCoin =>
      throw WalletExceptionConst.inaccessibleKeyAlgorithm;

  @override
  SeedGenerationType get seedGeneration =>
      throw WalletExceptionConst.unsuportedFeature;

  @override
  AddressDerivationType get derivationType => AddressDerivationType.multisig;

  @override
  bool get isImportedKey => false;

  @override
  String get name => "multi_signature".tr;

  @override
  String toString() {
    return name;
  }
}
