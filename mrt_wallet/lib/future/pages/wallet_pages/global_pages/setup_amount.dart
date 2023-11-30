import 'package:flutter/material.dart';

import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';

class SetupNetworkAmount extends StatefulWidget {
  const SetupNetworkAmount(
      {super.key,
      required this.network,
      this.subtitle,
      this.subtitleText,
      this.max,
      this.min,
      this.buttonText});
  final Widget? subtitle;
  final String? subtitleText;
  final BigInt? max;
  final BigInt? min;
  final AppNetworkImpl network;
  final String? buttonText;

  @override
  State<SetupNetworkAmount> createState() => _SetupNetworkAmountState();
}

class _SetupNetworkAmountState extends State<SetupNetworkAmount>
    with SafeState {
  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "SetupNetworkAmount");
  late final String? maxString =
      PriceUtils.tryEncodePrice(widget.max, widget.network.coinParam.decimal);
  late final String? minString =
      PriceUtils.tryEncodePrice(widget.min, widget.network.coinParam.decimal);
  String? validator(String? v) {
    if (v == null) return "decimal_int_validator".tr;
    final toBigit =
        PriceUtils.tryDecodePrice(v, widget.network.coinParam.decimal);
    if (toBigit == null) {
      return "decimal_int_validator".tr;
    }
    if (widget.max != null && toBigit > widget.max) {
      return "price_less_than".tr.replaceOne(PriceUtils.priceWithCoinName(
          maxString!, widget.network.coinParam.coinSymbol));
    } else if (widget.min != null && toBigit < widget.min) {
      return "price_greather_than".tr.replaceOne(PriceUtils.priceWithCoinName(
          minString!, widget.network.coinParam.coinSymbol));
    }
    return null;
  }

  String price = "0.0";
  void onChaanged(String v) {
    price = v;
  }

  void onSetup() {
    if (!(form.currentState?.validate() ?? false)) return;
    final toBigit =
        PriceUtils.tryDecodePrice(price, widget.network.coinParam.decimal);
    if (toBigit == null) return;
    if (mounted) {
      context.pop(toBigit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null || widget.subtitleText != null)
            widget.subtitle ?? Text(widget.subtitleText ?? ""),
          WidgetConstant.height20,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  CircleAssetsImgaeView(widget.network.coinParam.logo,
                      radius: 60),
                  Text(widget.network.coinParam.coinName,
                      style: context.textTheme.labelLarge)
                ],
              ),
            ],
          ),
          WidgetConstant.height20,
          Theme(
            data: context.theme.copyWith(
              inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                borderRadius: WidgetConstant.border25,
              )),
            ),
            child: Align(
              alignment: Alignment.center,
              child: ConstraintsBoxView(
                maxWidth: 350,
                child: AppTextField(
                  style: context.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  textAlign: TextAlign.center,
                  validator: validator,
                  initialValue: price,
                  onChanged: onChaanged,
                  suffixIcon: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: WidgetConstant.padding20,
                        child: Text(
                          widget.network.coinParam.coinSymbol,
                          style: context.textTheme.labelLarge?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical20,
                  onPressed: onSetup,
                  child: Text(widget.buttonText ?? "setup_output_amount".tr))
            ],
          )
        ],
      ),
    );
  }
}
