import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/start_page/home.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/global_pages/address_derivation/setup_address_derivation_mode.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/global_pages/wallet_global_pages.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/main.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:mrt_wallet/types/typedef.dart';

typedef _OnChangeShellyAddrType = void Function(ADAAddressType? addrType);

enum _Bip32DerivationMode {
  customDerivation("custom_derivation"),
  standardDerivation("standard_derivation");

  const _Bip32DerivationMode(this.viewName);
  final String viewName;
  bool get isStandard => this == _Bip32DerivationMode.standardDerivation;
  bool get isCustom => this == _Bip32DerivationMode.customDerivation;
}

enum _AdaEra {
  shelly("shelly"),
  byron("byron");

  final String name;
  const _AdaEra(this.name);
  bool get isShelly => this == _AdaEra.shelly;
  CryptoCoins getRelatedIcarusCardanoCoin(APPCardanoNetwork network) {
    if (isShelly) {
      if (network.coinParam.mainnet) {
        return Cip1852Coins.cardanoIcarus;
      } else {
        return Cip1852Coins.cardanoIcarusTestnet;
      }
    } else {
      if (network.coinParam.mainnet) {
        return Bip44Coins.cardanoByronIcarus;
      } else {
        return Bip44Coins.cardanoByronIcarusTestnet;
      }
    }
  }

  CryptoCoins getRelatedLedgerCardanoCoin(APPCardanoNetwork network) {
    if (isShelly) {
      if (network.coinParam.mainnet) {
        return Cip1852Coins.cardanoLedger;
      } else {
        return Cip1852Coins.cardanoLedgerTestnet;
      }
    } else {
      if (network.coinParam.mainnet) {
        return Bip44Coins.cardanoByronLedger;
      } else {
        return Bip44Coins.cardanoByronLedgerTestnet;
      }
    }
  }

  CryptoCoins getRelatedByronLegacy(APPCardanoNetwork network) {
    if (isShelly) {
      throw WalletException.invalidArgruments(["byron", "shelly"]);
    }
    if (network.coinParam.mainnet) {
      return CustomCoins.byronLegacy;
    } else {
      return CustomCoins.byronLegacyTestnet;
    }
  }
}

enum _CardanoMasterKeyGenerationType {
  ledger("ledger"),
  icarus("icarus"),
  byronLegacy("byronLegacy");

  final String name;
  const _CardanoMasterKeyGenerationType(this.name);
  bool get isLegacy => this == _CardanoMasterKeyGenerationType.byronLegacy;
}

enum _GenerateAddressPage {
  seedGeneration,
  era,
  masterKeyGeneration,
  generateAddress
}

class SetupCardanoAddressView extends StatefulWidget {
  const SetupCardanoAddressView({super.key});

  @override
  State<SetupCardanoAddressView> createState() =>
      _SetupCardanoAddressViewState();
}

class _SetupCardanoAddressViewState extends State<SetupCardanoAddressView>
    with SafeState {
  final GlobalKey<PageProgressState> pageProgressKey =
      GlobalKey<PageProgressState>(debugLabel: "SetupEthereumAddressView");
  final GlobalKey visibleGenerateAddress =
      GlobalKey(debugLabel: "visibleContinue");
  final GlobalKey visibleXAddressDetails =
      GlobalKey(debugLabel: "visibleContinue");
  final GlobalKey<FormState> form = GlobalKey<FormState>();
  final GlobalKey<AppTextFieldState> hdPathKeyKey =
      GlobalKey<AppTextFieldState>(debugLabel: "hdPathKey");
  final GlobalKey<AppTextFieldState> hdPathKey =
      GlobalKey<AppTextFieldState>(debugLabel: "hdPath");

  late final AppChain chainAccount;
  NetworkAccountCore get networkAccounts => chainAccount.account;
  APPCardanoNetwork get network => networkAccounts.network as APPCardanoNetwork;
  List<CryptoCoins> get coins => network.coins;
  late CryptoCoins coin = coins.first;

  bool inited = false;

  _AdaEra era = _AdaEra.shelly;
  _GenerateAddressPage page = _GenerateAddressPage.seedGeneration;
  _CardanoMasterKeyGenerationType keyGenerationType =
      _CardanoMasterKeyGenerationType.icarus;
  SeedGenerationType seedGenerationType = SeedGenerationType.icarus;

  ADAAddressType addrType = ADAAddressType.base;

  String? manuallyHdPath;
  String? manuallyHdPathKey;
  bool manuallySetLegacyHdPathKey = false;

  void onChangeManuallySetHdPathKey() {
    manuallySetLegacyHdPathKey = !manuallySetLegacyHdPathKey;
    if (!manuallySetLegacyHdPathKey) {
      manuallyHdPath = null;
      manuallyHdPathKey = null;
    }
    setState(() {});
  }

  void onChageHdPath(String path) {
    manuallyHdPath = path;
  }

  void onChangeHdPathKey(String v) {
    manuallyHdPathKey = v;
  }

  String? onValidateHdPath(String? v) {
    try {
      final parse = Bip32PathParser.parse(manuallyHdPath!);
      if (parse.elems.length !=
          BlockchainConstant.maxByronLegacyBip32LevelIndex) {
        return "byron_legacy_hd_wallet_length_desc".tr;
      }
    } catch (e) {
      return "invalid_byron_legacy_hd_path_key".tr;
    }
    return null;
  }

  String? onValidateHdPathKey(String? v) {
    try {
      final inBytes = BytesUtils.tryFromHexString(manuallyHdPathKey);
      if (inBytes == null) {
        return "byron_legacy_hd_path_key_desc".tr;
      }
      if (inBytes.length != CardanoUtils.byronAddressHdPathKeyLengthBytes) {
        return "byron_legacy_hd_path_key_length_desc".tr;
      }
    } catch (e) {
      return "byron_legacy_hd_path_key_desc".tr;
    }
    return null;
  }

  void onChangeEra(_AdaEra? e) {
    era = e ?? era;
    setState(() {});
  }

  void onContinueFromSeedGeneration() {
    page = _GenerateAddressPage.era;
    setState(() {});
  }

  void onContinueFromEra() {
    page = _GenerateAddressPage.masterKeyGeneration;
    if (era == _AdaEra.byron) {
      addrType = ADAAddressType.byron;
    } else {
      addrType = ADAAddressType.base;
      keyGenerationType = _CardanoMasterKeyGenerationType.icarus;
    }
    setState(() {});
  }

  bool get showLegacy =>
      !era.isShelly &&
      (seedGenerationType == SeedGenerationType.byronLegacySeed ||
          seedGenerationType == SeedGenerationType.none);
  void onChangeMasterKeyGeneration(
      _CardanoMasterKeyGenerationType? masterKeyGeneration) {
    if (masterKeyGeneration == null) return;
    if (era.isShelly && masterKeyGeneration.isLegacy) return;
    keyGenerationType = masterKeyGeneration;
    setState(() {});
  }

  void onChangeSeedGeneration(SeedGenerationType? seedType) {
    if (seedType == SeedGenerationType.bip39) return;
    seedGenerationType = seedType ?? seedGenerationType;
    setState(() {});
  }

  void onContinueFromMasterkeyGeneration() {
    switch (keyGenerationType) {
      case _CardanoMasterKeyGenerationType.icarus:
        coin = era.getRelatedIcarusCardanoCoin(network);
        break;
      case _CardanoMasterKeyGenerationType.byronLegacy:
        coin = era.getRelatedByronLegacy(network);
        break;
      default:
        coin = era.getRelatedLedgerCardanoCoin(network);
        break;
    }
    page = _GenerateAddressPage.generateAddress;
    setState(() {});
  }

  void onChangeShellyddrType(ADAAddressType? type) {
    if (type == null) return;
    if (era == _AdaEra.byron) return;
    if (type == ADAAddressType.pointer) return;
    addrType = type;
    setState(() {});
  }

  void _setupIAccount() {
    if (inited) return;
    final model = context.watch<WalletProvider>(StateIdsConst.main);
    chainAccount = model.chain;
  }

  void generateAddress() async {
    if (!(form.currentState?.validate() ?? false)) return;
    final result = await MethodCaller.call(() async {
      pageProgressKey.progressText("generating_new_addr".tr);
      final model = context.watch<WalletProvider>(StateIdsConst.main);
      Bip32AddressIndex? keyIndex = await context
          .openSliverBottomSheet<Bip32AddressIndex>("setup_derivation".tr,
              child: SetupDerivationModeView(
                coin: coin,
                chainAccout: chainAccount,
              ));
      if (keyIndex == null) {
        return null;
      }
      keyIndex = keyIndex.copyWith(keyName: "base_key");
      Bip32AddressIndex? stakeDerivation;
      if (addrType == ADAAddressType.base) {
        final defaultStakeKey = keyIndex.copyWith(
            changeLevel: CardanoUtils.bip32StakeChangeLevel,
            addressIndex: CardanoUtils.bip32StakeAddressLevel);
        // ignore: use_build_context_synchronously
        stakeDerivation = await context
            .openSliverBottomSheet<Bip32AddressIndex>("setup_derivation".tr,
                child: SetupDerivationModeView(
                  coin: coin,
                  chainAccout: chainAccount,
                  defaultDerivation: defaultStakeKey,
                  title: PageTitleSubtitle(
                      title: "derive_network_address"
                          .tr
                          .replaceOne(network.coinParam.token.name),
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("disable_standard_derivation".tr),
                          WidgetConstant.height8,
                          Text("stake_key_derivation".tr),
                          WidgetConstant.height8,
                          Text("ada_base_stake_key_same_error".tr)
                        ],
                      )),
                ));
        if (stakeDerivation == null) return null;
        stakeDerivation = stakeDerivation.copyWith(keyName: "stake_key");
      }
      if (addrType == ADAAddressType.base && keyIndex == stakeDerivation) {
        throw WalletException("ada_base_stake_key_same_error");
      }
      String? hdPath;
      List<int>? hdPathKey;
      if (keyGenerationType.isLegacy) {
        if (manuallySetLegacyHdPathKey) {
          hdPath = BlockchainUtils.validateHdPathKey(manuallyHdPath!,
              maxIndex: BlockchainConstant.maxByronLegacyBip32LevelIndex);
          hdPathKey = BytesUtils.tryFromHexString(manuallyHdPathKey!);
        } else {
          if (keyIndex.hdPath == null) {
            hdPath = "";
            hdPathKey = List<int>.filled(32, 0);
          }
        }
      }

      final newAccount = CardanoNewAddressParams(
        deriveIndex: keyIndex,
        addressType: addrType,
        rewardKeyIndex: stakeDerivation,
        customHdPath: hdPath,
        customHdPathKey: hdPathKey,
      );
      final result = await model.deriveNewAccount(newAccount);
      if (result.hasError) throw result.exception!;
      return result.result;
    });

    if (result.hasError) {
      pageProgressKey.errorText(result.error!.tr);
    } else if (result.result == null) {
      pageProgressKey.backToIdle();
    } else {
      pageProgressKey.success(
          backToIdle: false,
          progressWidget: SuccessWithButtomView(
            buttomWidget: ContainerWithBorder(
                margin: WidgetConstant.paddingVertical8,
                child: AddressDetailsView(address: result.result!)),
            buttomText: "generate_new_address".tr,
            onPressed: () {
              if (mounted) {
                pageProgressKey.backToIdle();
              }
            },
          ));
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    _setupIAccount();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        appBar: AppBar(title: Text("setup_address".tr)),
        body: PageProgress(
          key: pageProgressKey,
          backToIdle: AppGlobalConst.twoSecoundDuration,
          initialStatus: PageProgressStatus.idle,
          child: () => UnfocusableChild(
            child: Center(
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: [
                  SliverToBoxAdapter(
                      child: ConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal20,
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        key: const ValueKey<bool>(true),
                        children: [
                          PageTitleSubtitle(
                              title: "setup_network_address"
                                  .tr
                                  .replaceOne(network.coinParam.token.name),
                              body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("disable_standard_derivation".tr),
                                  WidgetConstant.height8,
                                  Text("setup_address_derivation_keys_desc".tr),
                                  WidgetConstant.height8,
                                  Text(
                                      "please_following_steps_to_generate_address"
                                          .tr),
                                ],
                              )),
                          AnimatedSwitcher(
                            duration: AppGlobalConst.animationDuraion,
                            child: page == _GenerateAddressPage.seedGeneration
                                ? _SelectSeedGenerationType(
                                    seedGenerationType: seedGenerationType,
                                    onChageSeedGeneration:
                                        onChangeSeedGeneration,
                                    onContinue: onContinueFromSeedGeneration)
                                : page == _GenerateAddressPage.era
                                    ? _SelectEra(
                                        era: era,
                                        onChangeEra: onChangeEra,
                                        onContinue: onContinueFromEra)
                                    : page ==
                                            _GenerateAddressPage
                                                .masterKeyGeneration
                                        ? _SelectMasterKeyGeneration(
                                            keyGenerationType:
                                                keyGenerationType,
                                            era: era,
                                            onChangeKeyGeneration:
                                                onChangeMasterKeyGeneration,
                                            onContinue:
                                                onContinueFromMasterkeyGeneration,
                                            seedGeneration: seedGenerationType,
                                          )
                                        : _GenerateAddress(
                                            network: network,
                                            addrType: addrType,
                                            generateAddress: generateAddress,
                                            coin: coin,
                                            era: era,
                                            hdPathKeyKey: hdPathKeyKey,
                                            keyGeneratorType: keyGenerationType,
                                            hdpathKey: hdPathKey,
                                            onChangedHdPath: onChageHdPath,
                                            onChangedHdPathKey:
                                                onChangeHdPathKey,
                                            validatorHdPath: onValidateHdPath,
                                            validatorHdPathKey:
                                                onValidateHdPathKey,
                                            onChangeShellyddrType:
                                                onChangeShellyddrType,
                                            hdPath: manuallyHdPath,
                                            hdPathKey: manuallyHdPathKey,
                                            manuallySetHdPathKey:
                                                manuallySetLegacyHdPathKey,
                                            onChangeManuallySetHdPathKey:
                                                onChangeManuallySetHdPathKey,
                                          ),
                          ),
                        ],
                      ),
                    ),
                  ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _OnChangeEra = void Function(_AdaEra? era);

class _SelectEra extends StatelessWidget {
  const _SelectEra(
      {required this.era, required this.onChangeEra, required this.onContinue});
  final _AdaEra era;
  final _OnChangeEra onChangeEra;
  final DynamicVoid onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "cardano_era".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("select_era_for_generate_addr".tr),
                WidgetConstant.height8,
                Text("recommended_address_type".tr)
              ],
            )),
        AppRadioListTile(
          groupValue: era,
          title: Text("shelly".tr),
          value: _AdaEra.shelly,
          onChanged: onChangeEra,
        ),
        AppRadioListTile(
          groupValue: era,
          value: _AdaEra.byron,
          title: Text("byron".tr),
          onChanged: onChangeEra,
        ),
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                onPressed: onContinue, child: Text("continue".tr)),
          ],
        )
      ],
    );
  }
}

typedef _OnChangeMasterKeyGeneration = void Function(
    _CardanoMasterKeyGenerationType? era);

class _SelectMasterKeyGeneration extends StatelessWidget {
  const _SelectMasterKeyGeneration(
      {required this.keyGenerationType,
      required this.onChangeKeyGeneration,
      required this.onContinue,
      required this.era,
      required this.seedGeneration});
  final _CardanoMasterKeyGenerationType keyGenerationType;
  final _OnChangeMasterKeyGeneration onChangeKeyGeneration;
  final DynamicVoid onContinue;
  final _AdaEra era;
  final SeedGenerationType seedGeneration;
  bool get showLegacy =>
      !era.isShelly &&
      (seedGeneration == SeedGenerationType.byronLegacySeed ||
          seedGeneration == SeedGenerationType.none);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "master_key_generation".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("cardano_bip32_master_key".tr),
                WidgetConstant.height8,
                Text("choose_master_key_gen".tr)
              ],
            )),
        AppRadioListTile(
          groupValue: keyGenerationType,
          title: Text("ledger".tr),
          value: _CardanoMasterKeyGenerationType.ledger,
          onChanged: onChangeKeyGeneration,
        ),
        AppRadioListTile(
          groupValue: keyGenerationType,
          value: _CardanoMasterKeyGenerationType.icarus,
          title: Text("icarus".tr),
          onChanged: onChangeKeyGeneration,
        ),
        if (showLegacy)
          AppRadioListTile(
            groupValue: keyGenerationType,
            value: _CardanoMasterKeyGenerationType.byronLegacy,
            title: Text("byron_legacy".tr),
            onChanged: onChangeKeyGeneration,
          ),
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                onPressed: onContinue, child: Text("continue".tr)),
          ],
        )
      ],
    );
  }
}

typedef _OnChangeSeedGeneration = void Function(SeedGenerationType? era);

class _SelectSeedGenerationType extends StatelessWidget {
  const _SelectSeedGenerationType(
      {required this.seedGenerationType,
      required this.onChageSeedGeneration,
      required this.onContinue});
  final SeedGenerationType seedGenerationType;
  final _OnChangeSeedGeneration onChageSeedGeneration;
  final DynamicVoid onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "seed_generation".tr,
            body: Column(
              children: [
                Text("seed_generation_type".tr),
              ],
            )),
        AppRadioListTile(
          groupValue: seedGenerationType,
          title: Text("byron_legacy_seed".tr),
          value: SeedGenerationType.byronLegacySeed,
          onChanged: onChageSeedGeneration,
        ),
        AppRadioListTile(
          groupValue: seedGenerationType,
          value: SeedGenerationType.icarus,
          title: Text("icarus".tr),
          onChanged: onChageSeedGeneration,
        ),
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                onPressed: onContinue, child: Text("continue".tr)),
          ],
        )
      ],
    );
  }
}

class _GenerateAddress extends StatelessWidget {
  const _GenerateAddress(
      {required this.network,
      required this.addrType,
      required this.generateAddress,
      required this.coin,
      required this.era,
      required this.onChangeShellyddrType,
      required this.hdpathKey,
      required this.hdPathKeyKey,
      required this.onChangedHdPath,
      required this.validatorHdPath,
      required this.onChangedHdPathKey,
      required this.validatorHdPathKey,
      required this.keyGeneratorType,
      required this.hdPath,
      required this.hdPathKey,
      required this.manuallySetHdPathKey,
      required this.onChangeManuallySetHdPathKey});
  final APPCardanoNetwork network;
  final _AdaEra era;
  final ADAAddressType addrType;
  final CryptoCoins coin;
  final _OnChangeShellyAddrType onChangeShellyddrType;
  final DynamicVoid generateAddress;
  final GlobalKey<AppTextFieldState> hdpathKey;
  final GlobalKey<AppTextFieldState> hdPathKeyKey;
  final StringVoid onChangedHdPath;
  final NullStringString validatorHdPath;
  final StringVoid onChangedHdPathKey;
  final NullStringString validatorHdPathKey;
  final _CardanoMasterKeyGenerationType keyGeneratorType;
  final String? hdPath;
  final String? hdPathKey;
  final bool manuallySetHdPathKey;
  final DynamicVoid onChangeManuallySetHdPathKey;
  bool get isBaseAddress => addrType == ADAAddressType.base;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (era.isShelly) ...[
          WidgetConstant.height20,
          Text("shelley_address_format".tr,
              style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AppDropDownBottom(
              items: {
                ADAAddressType.base: Text("base".tr),
                ADAAddressType.reward: Text("reward".tr),
                ADAAddressType.enterprise: Text("enterprise".tr),
              },
              value: addrType,
              onChanged: onChangeShellyddrType,
              label: "shelley_address_format".tr),
          WidgetConstant.height20,
        ] else if (keyGeneratorType.isLegacy) ...[
          AppSwitchListTile(
            value: manuallySetHdPathKey,
            title: Text("manually_set_hd_path".tr),
            subtitle:
                Text("byron_legacy_hd_path_generate_from_master_key_desc".tr),
            onChanged: (p0) => onChangeManuallySetHdPathKey(),
          ),
          AnimatedSize(
            duration: AppGlobalConst.animationDuraion,
            alignment: Alignment.topCenter,
            child: manuallySetHdPathKey
                ? Column(
                    children: [
                      WidgetConstant.height8,
                      AppTextField(
                        label: "hd_path".tr,
                        key: hdpathKey,
                        onChanged: onChangedHdPath,
                        validator: validatorHdPath,
                        hint: CardanoUtils.hdPathHint,
                        initialValue: hdPath,
                      ),
                      AppTextField(
                        label: "hd_path_key".tr,
                        key: hdPathKeyKey,
                        onChanged: onChangedHdPathKey,
                        validator: validatorHdPathKey,
                        helperText: "byron_legacy_hd_path_key_desc2".tr,
                        hint: "0x950163...",
                        initialValue: hdPathKey,
                      ),
                    ],
                  )
                : WidgetConstant.sizedBox,
          )
        ],
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical20,
              onPressed: generateAddress,
              child: Text("setup_derivation".tr),
            ),
          ],
        )
      ],
    );
  }
}
