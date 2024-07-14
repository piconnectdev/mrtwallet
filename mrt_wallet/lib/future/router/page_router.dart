import 'package:flutter/material.dart';
import 'package:mrt_wallet/future/future.dart';
import 'package:mrt_wallet/future/wallet/setup/pages/setup_wallet.dart';
import 'package:mrt_wallet/wallet/models/network/core/network.dart';
import 'package:mrt_wallet/wroker/models/networks.dart';

class PageRouter {
  /// bitcoin casah
  static const String bitcoinCashTransaction = "/bitcoincash/transaction";

  static const String bitcoinTransaction = "/bitcoin/transaction";
  static const String rippleTransfer = "/ripple/transfer";
  static const String rippleAddToken = "/ripple/import_token";
  static const String rippleAddNfts = "/ripple/import_nfts";
  static const String rippleTransaction = "/ripple/transaction";
  static const String rippleMultisigAddress = "/ripple/setup_multisig_address";
  static const String rippleSettingPage = "setting/ripple";
  static const String rippleKeyConversion = "setting/ripple/key_conversion";

  static const String ethereumTransaction = "/ethereum/transfer";

  // tron
  static const String tronTransfer = "/tron/transfer";
  static const String tronTransaction = "/tron/transaction";
  static const String tronMultiSigAddress = "/tron/setup_multisig_address";
  // solana transfer
  static const String solanaTransfer = "/solana/transfer";
  static const String solanaTransaction = "/solana/transaction";

  // ton transfer
  static const String tonTransfer = "/ton/transfer";

  // substrate transfer
  static const String substrateTransfer = "/substrate/transfer";

  /// cardano
  static const String cardanoTransaction = "/cardano/transaction";
  static const String cosmosTransaction = "/cosmos/transaction";

  // static const String setupRippleAddress = "/ripple/setup_address";
  static const String setupGenericAddress = "/networks/setup_address";

  static const String setupBitcoinMultsig = "/bitcoin/setup_multisig_address";
  static const String createWallet = "/create_wallet";
  static const String setup = "/setup";
  static const String home = "/";

  static const String setting = "/setting";
  static const String updateSetting = "/setting/update";

  /// acccount
  static const String removeAccount = "/account/remove";
  static const String importAccount = "/account/import";
  static const String showPublicKey = "account/public_key";

  /// security
  static const String changePassword = "/security/password";
  static const String eraswWallet = "/security/erase";
  static const String backupWallet = "/security/backup";
  static const String exportPrivateKey = "/security/privateKey";
  static const String manageImportedKey = "/security/manageKeys";
  static const String exportSeed = "/security/seed";

  /// importnetworks
  static const String importEthereumNetwork = "/networks/import";
  static const String editEvmNetwork = "/networks/edit";
  static const String updateElectrumProviders = "/networks/bitcoin/providers";
  static const String editSolanaNetwork = "/networks/solana/providers";

  static const String importERC20Token = "ethereum/import_token";
  static const String importTRC20Token = "tron/import_token";
  static const String importTrc10Token = "tron/import_trc10_token";
  static const String importSPLTokens = "solana/import_spl_tokens";

  static const String tonSettings = "setting/ton";
  static const String tonMnemonic = "setting/ton/mnemonic";
  static const String importJettons = "ton/import_jettons";

  static const String barcodeScanner = "barcode_scanner";

  static Widget _page(String? name) {
    switch (name) {
      case setup:
        return const SetupWallet();
      case solanaTransfer:
        return const SolanaTransferTransactionView();
      case tonTransfer:
        return const TonTransferTransactionView();
      case bitcoinTransaction:
        return const SendBitcoinTransactionView();
      case bitcoinCashTransaction:
        return const SendBitcoinCashTransactionView();
      case setupBitcoinMultsig:
        return const SetupBitcoinMultiSigAddressView();
      case exportSeed:
        return const ExportSeedView();
      case changePassword:
        return const ChangeWalletPasswordView();
      case eraswWallet:
        return const EraseWalletView();
      case exportPrivateKey:
        return const AccountPrivteKeyView();
      case removeAccount:
        return const DeleteAccountView();
      case importAccount:
        return const ImportAccountView();
      case setting:
        return const AppSettingView();
      case updateSetting:
        return const UpdateWalletSettingView();
      case backupWallet:
        return const BackupWalletView();
      case manageImportedKey:
        return const ManageImportedKeysView();

      case setupGenericAddress:
        return const NetworkGenericAddressDerivationView();
      case rippleTransfer:
        return const RippleTransferTransactionView();
      case ethereumTransaction:
        return const EthereumTransferTransactionView();
      case tronTransfer:
        return const TronTransferTransactionView();
      case rippleAddToken:
        return const MonitorRippleTokenView();
      case rippleAddNfts:
        return const MonitorRippleNFTsView();
      case rippleTransaction:
        return const RippleTransactionFieldsView();
      case rippleMultisigAddress:
        return const SetupRippleMutlisigAddressView();
      case importERC20Token:
        return const ImportERC20TokenView();
      case importTRC20Token:
        return const ImportTRC20TokenView();
      case importTrc10Token:
        return const MonitorTronTRC10TokenView();
      case tronMultiSigAddress:
        return const SetupTronMultiSigAddressView();
      case tronTransaction:
        return const TronTransactionFieldsView();
      case importEthereumNetwork:
        return const ImportEthereumNetwork();
      case editEvmNetwork:
        return const EditEthereumNetwork();
      case updateElectrumProviders:
        return const ImportElectrumProviderView();
      case importSPLTokens:
        return const SolanaImportSPLTokensView();
      case importJettons:
        return const TonImportJettonsView();
      case cardanoTransaction:
        return const SendCardanoTransactionView();
      case cosmosTransaction:
        return const CosmosTransferTransactionView();
      case solanaTransaction:
        return const SolanaTransactionFieldsView();
      case editSolanaNetwork:
        return const ImportSolanaProviderView();
      case tonSettings:
        return const TonSettingsView();
      case tonMnemonic:
        return const GenerateTonMnemonicView();
      case rippleSettingPage:
        return const RippleFeaturePageView();
      case rippleKeyConversion:
        return const RippleKeyConversionView();
      case showPublicKey:
        return const AccountPublicKeyView();
      case createWallet:
        return const WalletSetupPageWidget();
      case barcodeScanner:
        return const BarcodeScannerView();
      case substrateTransfer:
        return const SubstrateTransferTransactionView();
      default:
        return const HomeScreen();
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return MaterialPageView(child: _page(settings.name));
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        settings: settings,
        reverseTransitionDuration: const Duration(milliseconds: 300),
        allowSnapshotting: false,
        fullscreenDialog: false,
        opaque: false);
  }

  static String providerDetails(WalletNetwork network) {
    switch (network.type) {
      case NetworkType.ethereum:
        return editEvmNetwork;
      case NetworkType.solana:
        return editSolanaNetwork;
      default:
        return updateElectrumProviders;
    }
  }

  static String transactionPage(WalletNetwork network) {
    switch (network.type) {
      case NetworkType.bitcoinCash:
      case NetworkType.bitcoinAndForked:
        return bitcoinTransaction;
      case NetworkType.ethereum:
        return ethereumTransaction;
      case NetworkType.tron:
        return tronTransfer;
      case NetworkType.solana:
        return solanaTransfer;
      case NetworkType.ton:
        return tonTransfer;
      case NetworkType.cardano:
        return cardanoTransaction;
      case NetworkType.cosmos:
        return cosmosTransaction;
      case NetworkType.polkadot:
      case NetworkType.kusama:
        return substrateTransfer;
      default:
        return rippleTransfer;
    }
  }

  static String? networkSettings(WalletNetwork network) {
    switch (network.type) {
      case NetworkType.ton:
        return tonSettings;
      case NetworkType.xrpl:
        return rippleSettingPage;
      default:
        return null;
    }
  }
}
