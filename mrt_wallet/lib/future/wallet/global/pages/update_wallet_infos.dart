import 'package:flutter/widgets.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/wallet/models/setting/setting.dart';

typedef OnUpdateWidget = void Function(WalletUpdateInfosData);

class UpdateWalletInfosWidget extends StatefulWidget {
  const UpdateWalletInfosWidget(
      {required this.name,
      required this.locktime,
      required this.requrmentPassword,
      this.setupButtonTitle,
      required this.exitsIds,
      required this.onUpdate,
      required this.asDefaultWallet,
      Key? key})
      : super(key: key);
  final String name;
  final WalletLockTime locktime;
  final bool requrmentPassword;
  final bool asDefaultWallet;
  final String? setupButtonTitle;
  final List<String> exitsIds;
  final OnUpdateWidget onUpdate;

  @override
  State<UpdateWalletInfosWidget> createState() =>
      _UpdateWalletInfosWidgetState();
}

class _UpdateWalletInfosWidgetState extends State<UpdateWalletInfosWidget>
    with SafeState {
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(debugLabel: "SetupWalletPassword");
  final GlobalKey<PageProgressState> progressKey = GlobalKey();
  late String name = widget.name;
  late bool reqPassword = widget.requrmentPassword;
  late bool defaultWallet = widget.asDefaultWallet;

  late WalletLockTime locktime = widget.locktime;

  late final Map<WalletLockTime, Widget> lockTimeWidget = {
    for (final i in WalletLockTime.values)
      if (i.value != 0) i: Text(i.viewName.tr)
  };

  void onChangeName(String v) {
    name = v;
  }

  void onChangeReqPassword(bool? v) {
    reqPassword = v ?? reqPassword;
    updateState();
    if (reqPassword) {
      locktime = WalletLockTime.fiveMinute;
    }
  }

  void onChangeReqDefault(bool? v) {
    defaultWallet = v ?? defaultWallet;
    updateState();
  }

  String? onValidateWalletName(String? v) {
    if (v == null || v.trim().isEmpty || v.length < 3 || v.length > 15) {
      return "wallet_name_validator".tr;
    }
    if (widget.exitsIds.contains(v)) {
      return "wallet_name_validator2".tr;
    }
    return null;
  }

  void setup() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    widget.onUpdate(WalletUpdateInfosData(
        name: name,
        lockTime: reqPassword ? locktime : WalletLockTime.never,
        requirmentPassword: reqPassword,
        asDefaultWallet: defaultWallet));
  }

  void onChangeLockTime(WalletLockTime? time) {
    if (time == null || !reqPassword) return;
    locktime = time;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitleSubtitle(
                title: "wallet_settings".tr,
                body: Text("wallet_settings_desc".tr)),
            Text("wallet_name".tr, style: context.textTheme.titleMedium),
            Text("wallet_identifier_name".tr),
            WidgetConstant.height8,
            AppTextField(
              initialValue: name,
              label: "wallet_name".tr,
              onChanged: onChangeName,
              validator: onValidateWalletName,
            ),
            WidgetConstant.height20,
            AppCheckListTile(
              contentPadding: EdgeInsets.zero,
              value: defaultWallet,
              onChanged: onChangeReqDefault,
              title: Text("default_wallet".tr,
                  style: context.textTheme.titleMedium),
              subtitle: Text("default_wallet_desc".tr),
            ),
            WidgetConstant.height20,
            AppCheckListTile(
              contentPadding: EdgeInsets.zero,
              value: reqPassword,
              onChanged: onChangeReqPassword,
              title: Text("password_requirement".tr,
                  style: context.textTheme.titleMedium),
              subtitle: Text("wallet_password_requirement_desc".tr),
            ),
            APPAnimatedSize(
                isActive: reqPassword,
                onActive: (c) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WidgetConstant.height8,
                        AppDropDownBottom(
                          items: lockTimeWidget,
                          label: "automatic_loc".tr,
                          value: locktime,
                          onChanged: onChangeLockTime,
                        ),
                      ],
                    ),
                onDeactive: (c) => WidgetConstant.sizedBox),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: setup,
                  child: Text(widget.setupButtonTitle ?? "setup".tr),
                ),
              ],
            )
          ],
        ));
  }
}
