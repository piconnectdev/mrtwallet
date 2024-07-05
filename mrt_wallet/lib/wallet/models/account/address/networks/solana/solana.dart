import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/wallet/models/account/address/core/address.dart';

import 'package:mrt_wallet/wallet/models/account/address/balance/balance.dart';
import 'package:mrt_wallet/wroker/derivation/derivation.dart';
import 'package:mrt_wallet/wallet/models/account/address/new/new_address.dart';
import 'package:mrt_wallet/wallet/models/balance/balance.dart';
import 'package:mrt_wallet/wallet/models/network/network.dart';
import 'package:mrt_wallet/wallet/constant/tags/constant.dart';
import 'package:mrt_wallet/wallet/models/token/token.dart';
import 'package:mrt_wallet/wallet/models/nfts/core/core.dart';
import 'package:on_chain/solana/solana.dart';

class ISolanaAddress extends CryptoAddress<BigInt, SolAddress> with Equatable {
  ISolanaAddress._(
      {required this.keyIndex,
      required this.coin,
      required this.address,
      required this.network,
      required this.networkAddress,
      required List<SolanaSPLToken> tokens,
      required List<NFTCore> nfts,
      String? accountName})
      : _tokens = List.unmodifiable(tokens),
        _nfts = List.unmodifiable(nfts),
        _accountName = accountName;

  factory ISolanaAddress.newAccount(
      {required SolanaNewAddressParam accountParams,
      required List<int> publicKey,
      required WalletNetwork network}) {
    final ethAddress = SolAddress.fromPublicKey(publicKey);
    final addressDetauls = IntegerAddressBalance(
        address: ethAddress.address,
        balance: IntegerBalance.zero(network.coinParam.decimal));
    return ISolanaAddress._(
      coin: accountParams.coin,
      address: addressDetauls,
      keyIndex: accountParams.deriveIndex,
      networkAddress: ethAddress,
      network: network.value,
      tokens: const [],
      nfts: const [],
    );
  }
  factory ISolanaAddress.fromCbsorHex(String hex, WalletNetwork network) {
    return ISolanaAddress.fromCborBytesOrObject(network,
        bytes: BytesUtils.fromHexString(hex));
  }
  factory ISolanaAddress.fromCborBytesOrObject(WalletNetwork network,
      {List<int>? bytes, CborObject? obj}) {
    final toCborTag = (obj ?? CborObject.fromCbor(bytes!)) as CborTagValue;

    final CborListValue cbor = CborSerializable.decodeCborTags(
        null, toCborTag, CborTagsConst.solAccount);
    final CryptoProposal proposal = CryptoProposal.fromName(cbor.elementAt(0));
    final CryptoCoins coin = CryptoCoins.getCoin(cbor.elementAt(1), proposal)!;
    final keyIndex =
        AddressDerivationIndex.fromCborBytesOrObject(obj: cbor.getCborTag(2));
    final networkId = cbor.elementAt(6);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final IntegerAddressBalance address =
        IntegerAddressBalance.fromCborBytesOrObject(network.coinParam.decimal,
            obj: cbor.getCborTag(4));

    final SolAddress ethAddress = SolAddress(cbor.elementAt(5));

    final List<SolanaSPLToken> splTokens = [];
    final List<dynamic>? tokens = cbor.elementAt(7);
    if (tokens != null) {
      for (final i in tokens) {
        splTokens.add(SolanaSPLToken.fromCborBytesOrObject(obj: i));
      }
    }

    final String? accountName = cbor.elementAt(9);
    return ISolanaAddress._(
        coin: coin,
        address: address,
        keyIndex: keyIndex,
        networkAddress: ethAddress,
        network: networkId,
        tokens: splTokens,
        nfts: [],
        accountName: accountName);
  }

  @override
  String accountToString() {
    return address.toAddress;
  }

  @override
  final AddressBalanceCore<BigInt> address;

  @override
  final CryptoCoins coin;

  @override
  final AddressDerivationIndex keyIndex;

  @override
  final int network;

  @override
  CborTagValue toCbor() {
    return CborTagValue(
        CborListValue.fixedLength([
          coin.proposal.specName,
          coin.coinName,
          keyIndex.toCbor(),
          const CborNullValue(),
          address.toCbor(),
          networkAddress.address,
          network,
          CborListValue.fixedLength(_tokens.map((e) => e.toCbor()).toList()),
          CborListValue.fixedLength(_nfts.map((e) => e.toCbor()).toList()),
          accountName ?? const CborNullValue()
        ]),
        CborTagsConst.solAccount);
  }

  @override
  List get variabels {
    return [keyIndex, network];
  }

  @override
  final SolAddress networkAddress;

  @override
  String? get type => null;

  List<SolanaSPLToken> _tokens;
  @override
  List<SolanaSPLToken> get tokens => _tokens;

  List<NFTCore> _nfts;
  @override
  List<NFTCore> get nfts => _nfts;

  @override
  void addToken(TokenCore<BigInt> newToken) {
    if (newToken is! SolanaSPLToken) {
      throw WalletExceptionConst.invalidArgruments(
          "SolanaSPLToken", "${newToken.runtimeType}");
    }
    if (_tokens.contains(newToken)) {
      throw WalletExceptionConst.tokenAlreadyExist;
    }
    _tokens = List.unmodifiable([newToken, ..._tokens]);
  }

  @override
  void updateToken(TokenCore<BigInt> token, Token updatedToken) {
    if (!tokens.contains(token)) return;
    if (token is! SolanaSPLToken) {
      throw WalletExceptionConst.invalidArgruments(
          "SolanaSPLToken", "${token.runtimeType}");
    }
    List<SolanaSPLToken> existTokens = List<SolanaSPLToken>.from(_tokens);
    existTokens.removeWhere((element) => element == token);
    existTokens = [token.updateToken(updatedToken), ...existTokens];
    _tokens = List.unmodifiable(existTokens);
  }

  @override
  void removeToken(TokenCore<BigInt> token) {
    if (!tokens.contains(token)) return;
    final existTokens = List.from(_tokens);
    existTokens.removeWhere((element) => element == token);
    _tokens = List.unmodifiable(existTokens);
  }

  @override
  void addNFT(NFTCore newNft) {}

  @override
  void removeNFT(NFTCore nft) {}

  @override
  bool get multiSigAccount => false;

  String? _accountName;
  @override
  String? get accountName => _accountName;

  @override
  void setAccountName(String? name) {
    _accountName = name;
  }

  @override
  String get orginalAddress => networkAddress.address;

  SolAddress associatedTokenAccount(
          {required SolAddress mint,
          SolAddress tokenProgramId = SPLTokenProgramConst.tokenProgramId}) =>
      AssociatedTokenAccountProgramUtils.associatedTokenAccount(
              mint: mint, owner: networkAddress, tokenProgramId: tokenProgramId)
          .address;

  // @override
  // List<AddressDerivationIndex> get keyIndexes => [keyIndex];

  @override
  bool isEqual(CryptoAddress<BigInt, SolAddress> other) {
    return other.networkAddress.address == networkAddress.address;
  }

  @override
  SolanaNewAddressParam toAccountParams() {
    return SolanaNewAddressParam(deriveIndex: keyIndex, coin: coin);
  }
}
