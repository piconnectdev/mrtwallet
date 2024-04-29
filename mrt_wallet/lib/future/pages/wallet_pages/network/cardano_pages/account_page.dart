import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/models/wallet_models/address/network_address/cardano/cardano.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';
import 'package:on_chain/on_chain.dart';

class CardanoAccountPage extends StatelessWidget {
  const CardanoAccountPage({required this.chainAccount, super.key});
  final AppChain chainAccount;
  @override
  Widget build(BuildContext context) {
    return TabBarView(children: [
      _CardanoAccountPage(
          chainAccount: chainAccount.account.address as ICardanoAddress),
    ]);
  }
}

class _CardanoAccountPage extends StatelessWidget {
  const _CardanoAccountPage({required this.chainAccount});
  final ICardanoAddress chainAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_ShowRewardAddress(chainAccount: chainAccount)],
    );
  }
}

class _ShowRewardAddress extends StatelessWidget {
  const _ShowRewardAddress({required this.chainAccount});
  final ICardanoAddress chainAccount;
  @override
  Widget build(BuildContext context) {
    final ADARewardAddress? rewardAddress = chainAccount.rewardAddress;
    if (rewardAddress == null) return WidgetConstant.sizedBox;

    return ContainerWithBorder(
      onRemove: () {},
      onTapWhenOnRemove: false,
      onRemoveWidget: CopyTextIcon(dataToCopy: rewardAddress.address),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rewardAddress.addressType.name,
              style: context.textTheme.labelLarge),
          Text(
            rewardAddress.address,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
