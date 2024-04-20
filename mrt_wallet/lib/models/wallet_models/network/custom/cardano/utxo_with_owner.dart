import 'package:mrt_wallet/models/wallet_models/network/custom/cardano/utxo.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:on_chain/ada/src/address/address.dart';
import 'account_utxos.dart';

class CardanoUtxoWithOwner {
  final ADAAddress owner;
  final List<CardanoUtxo>? utxos;
  final NoneDecimalBalance utxoAmounts;
  bool get hasUtxo => utxos != null;
  CardanoUtxoWithOwner._(
      {required this.owner,
      List<CardanoUtxo>? utxos,
      required this.utxoAmounts})
      : utxos = utxos == null ? null : List<CardanoUtxo>.unmodifiable(utxos);
  factory CardanoUtxoWithOwner(
      {required ADAAddress owner,
      List<ADAAccountUTXOs>? utxos,
      required APPCardanoNetwork network}) {
    final amount = (utxos?.isEmpty ?? true)
        ? NoneDecimalBalance.zero(network.coinParam.token.decimal!)
        : NoneDecimalBalance(
            utxos!.sumOflovelace, network.coinParam.token.decimal!);
    return CardanoUtxoWithOwner._(
        owner: owner,
        utxoAmounts: amount,
        utxos:
            utxos?.map((e) => CardanoUtxo(utxo: e, network: network)).toList());
  }
}
