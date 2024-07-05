import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart'
    show QuickContextAccsess, Translate, WalletException;
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/wroker/utils/utils.dart';
import 'package:mrt_wallet/wallet/wallet.dart'
    show BlockchainConst, WalletNetwork;
import 'package:mrt_wallet/wroker/worker.dart'
    show SeedTypes, Bip32AddressIndex;

class Bip32KeyDerivationView extends StatefulWidget {
  const Bip32KeyDerivationView(
      {super.key,
      required this.coin,
      required this.curve,
      required this.network,
      required this.defaultPath,
      this.seedGeneration = SeedTypes.bip39});
  final CryptoCoins coin;
  final EllipticCurveTypes curve;
  final SeedTypes seedGeneration;
  final WalletNetwork network;
  final String? defaultPath;

  @override
  State<Bip32KeyDerivationView> createState() => _Bip32KeyDerivationViewState();
}

class _Bip32KeyDerivationViewState extends State<Bip32KeyDerivationView> {
  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "_Bip32KeyDerivationViewState_form");
  final GlobalKey<AppTextFieldState> pathTextFieldKey =
      GlobalKey<AppTextFieldState>(
          debugLabel: "_Bip32KeyDerivationViewState_pathTextFieldKey");
  late final bool isSupportNoneHardend;

  void onSubmit() {
    if (!(form.currentState?.validate() ?? false)) return;
    final keyIndex = Bip32AddressIndex.fromPath(
      path: path,
      currencyCoin: widget.coin,
      seedGeneration: widget.seedGeneration,
    );
    context.pop(keyIndex);
  }

  late String path = widget.defaultPath ?? "";

  @override
  void initState() {
    super.initState();
    isSupportNoneHardend = widget.curve != EllipticCurveTypes.ed25519;
  }

  void onChangePath(String v) {
    path = v;
  }

  String? validator(String? v) {
    if (path.trim().isEmpty) return null;
    try {
      final parse = BlockchainAddressUtils.praseBip32Path(path);
      if (parse.isEmpty) return null;
      if (!isSupportNoneHardend &&
          parse.any((element) => !element.isHardened)) {
        return "ed25519_support_derivation_desc".tr;
      }
      if (parse.length > BlockchainConst.maxBip32LevelIndex) {
        throw WalletException("hd_wallet_path_max_indeqxes"
            .tr
            .replaceOne(BlockchainConst.maxBip32LevelIndex.toString()));
      }
    } catch (e) {
      return "invalid_hd_wallet_derivation_path".tr;
    }
    return null;
  }

  void onPaste(String v) {
    pathTextFieldKey.currentState?.updateText(v);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "bip32_key_derivation".tr,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LargeTextView([
                    "bip32_derivation_desc".tr,
                    "bip32_derivation_desc2".tr,
                    "bip32_derivation_desc3".tr,
                    if (!isSupportNoneHardend)
                      "ed25519_support_derivation_desc".tr
                  ])
                ],
              )),
          Text("derivation_path".tr, style: context.textTheme.titleMedium),
          Text("hd_wallet_hardened_desc".tr),
          WidgetConstant.height8,
          AppTextField(
            onChanged: onChangePath,
            initialValue: path,
            suffixIcon: PasteTextIcon(onPaste: onPaste, isSensitive: false),
            validator: validator,
            key: pathTextFieldKey,
            label: "derivation_path".tr,
            hint: "derivation_path".tr,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: onSubmit,
                child: Text("setup_derivation_path".tr),
              ),
            ],
          )
        ],
      ),
    );
  }
}
