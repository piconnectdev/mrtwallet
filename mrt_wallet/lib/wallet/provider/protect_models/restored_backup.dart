part of 'package:mrt_wallet/wallet/provider/wallet_provider.dart';

class WalletRestoreV2 {
  WalletRestoreV2._({
    required this.masterKeys,
    required List<ChainHandler> chains,
    required List<CryptoAddress> invalidAddresses,
    required this.wallet,
    this.verifiedChecksum,
  })  : chains = List.unmodifiable(chains),
        invalidAddresses = List.unmodifiable(invalidAddresses),
        totalAccounts =
            chains.fold(0, (e, l) => e + l.account.addresses.length) +
                invalidAddresses.length;
  final WalletMasterKeys masterKeys;
  final List<ChainHandler> chains;
  final List<CryptoAddress> invalidAddresses;
  final HDWallet wallet;
  final bool? verifiedChecksum;
  final int totalAccounts;
  bool get hasFailedAccount => invalidAddresses.isNotEmpty;
}
