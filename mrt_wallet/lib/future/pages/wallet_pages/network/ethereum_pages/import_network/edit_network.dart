import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/pages/start_page/controller/wallet_provider.dart';
import 'package:mrt_wallet/future/pages/wallet_pages/wallet_pages.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/main.dart';
import 'package:mrt_wallet/models/api/api_provider_tracker.dart';
import 'package:mrt_wallet/models/wallet_models/chain/defauilt_node_providers.dart';
import 'package:mrt_wallet/models/wallet_models/wallet_models.dart';

import 'package:mrt_wallet/provider/api/api_provider.dart';
import 'package:on_chain/on_chain.dart';

class EditEVMNetwork extends StatelessWidget {
  const EditEVMNetwork({super.key});

  @override
  Widget build(BuildContext context) {
    final APPEVMNetwork network = context.getArgruments();
    return _ImportEVMNetwork(network);
  }
}

class _ImportEVMNetwork extends StatefulWidget {
  const _ImportEVMNetwork(this.network);
  final APPEVMNetwork network;

  @override
  State<_ImportEVMNetwork> createState() => __ImportEVMNetworkState();
}

class __ImportEVMNetworkState extends State<_ImportEVMNetwork> {
  late APPEVMNetwork network = widget.network.copyWith();
  late final bool isDefaultNetwork = network.coinParam.defaultNetwork;
  late final List<EVMApiProvider> defaultProviders = List.unmodifiable(
      DefaultNodeProviders.getDefaultServices(network)
          .map((e) => ChainUtils.buildApiProvider(network) as EVMApiProvider)
          .toList());
  late final List<EVMApiProvider> providers = [
    ...widget.network.coinParam.providers
        .map((e) =>
            ChainUtils.buildApiProvider(network, service: e) as EVMApiProvider)
        .toList()
  ];

  EVMApiProvider? selectedProvider;

  void onSelectProvider(EVMApiProvider? provider) {
    if (defaultProviders.contains(provider)) {
      context.showAlert("network_unbale_change_providers".tr);
      return;
    }
    selectedProvider = provider;
    setState(() {});
  }

  void discardChange() {
    selectedProvider = null;
    setState(() {});
  }

  void deleteProvider() {
    providers.removeWhere((element) => element == selectedProvider);
    selectedProvider = null;
    setState(() {});
  }

  void createNewRPC() {
    if (selectedProvider != null) return;
    final evmServiceProvider = EVMApiProviderService(
      serviceName: "",
      websiteUri: "",
      uri: "https://",
    );
    final tracker = ApiProviderTracker(provider: evmServiceProvider);
    selectedProvider = EVMApiProvider(
        provider: EVMRPC(EthereumHTTPRPCService("", tracker)),
        network: widget.network);

    setState(() {});
  }

  final GlobalKey<FormState> formKey = GlobalKey();
  final GlobalKey<PageProgressState> pageProgressKey = GlobalKey();
  final GlobalKey<AppTextFieldState> uriFieldKey = GlobalKey();
  final GlobalKey<AppTextFieldState> explorerFieldKey = GlobalKey();
  final GlobalKey<AppTextFieldState> transactionFieldKey = GlobalKey();
  late List<APPEVMNetwork> evmNetworks;
  late String symbol = widget.network.coinParam.token.symbol;
  late String networkName = widget.network.coinParam.token.name;

  late String explorerAddressLink =
      widget.network.coinParam.addressExplorer ?? "";
  late String explorerTransaction =
      widget.network.coinParam.transactionExplorer ?? "";
  String rpcUrl = "";

  void onPasteUri(String v) {
    uriFieldKey.currentState?.updateText(v);
  }

  void onPasteExplorerAddres(String v) {
    explorerFieldKey.currentState?.updateText(v);
  }

  void onPasteExplorerTransaction(String v) {
    transactionFieldKey.currentState?.updateText(v);
  }

  void onChangeSymbol(String v) {
    symbol = v;
  }

  void onChageUrl(String v) {
    rpcUrl = v;
  }

  void onChangeNetworkName(String v) {
    networkName = v;
  }

  void onChangeExplorerAddress(String v) {
    explorerAddressLink = v;
  }

  void onChangeExplorerTransaction(String v) {
    explorerTransaction = v;
  }

  String? chainError;

  String? validateNetworkName(String? v) {
    if ((v?.isEmpty ?? true) || v!.length < 2 || v.length > 25) {
      return "network_name_validator".tr;
    }
    return null;
  }

  String? validateRpcUrl(String? v) {
    final path =
        AppStringUtility.validateUri(v, schame: ['http', 'https', 'wss', 'ws']);
    if (path == null) return "rpc_url_validator".tr;
    final exists = MethodCaller.nullOnException(() => providers
        .firstWhere((element) => element.serviceProvider.provider.uri == v));
    if (exists != null) {
      return "rpc_url_already_exists".tr;
    }

    return null;
  }

  String? validateAddressLink(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final link = AppStringUtility.validateUri(v);
    if (link == null) return "validate_link_desc".tr;
    return null;
  }

  String? validateSymbol(String? v) {
    if ((v?.isEmpty ?? true) || v!.isEmpty || v.length > 6) {
      return "symbol_validator".tr;
    }
    return null;
  }

  void onAddChain() async {
    if (providers.isEmpty || selectedProvider != null) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    pageProgressKey.progressText("updating_network".tr);
    final result = await MethodCaller.call(() async {
      final wallet = context.watch<WalletProvider>(StateIdsConst.main);
      final services =
          providers.map((e) => e.serviceProvider.provider).toList();
      final updatedNetwork = network.copyWith(
          coinParam: network.coinParam.copyWith(
              providers: services,
              addressExplorer:
                  isDefaultNetwork ? null : explorerAddressLink.nullOnEmpty,
              transactionExplorer:
                  isDefaultNetwork ? null : explorerTransaction.nullOnEmpty,
              token: isDefaultNetwork
                  ? null
                  : network.coinParam.token
                      .copyWith(name: networkName, symbol: symbol)));
      return await wallet.updateImportNetwork(updatedNetwork);
    });
    if (result.hasError) {
      pageProgressKey.errorText(result.error!.tr);
    } else {
      pageProgressKey.successText("network_updated_successfully".tr,
          backToIdle: false);
    }
  }

  void onUpdate() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    pageProgressKey.progressText("checking_rpc_network_info".tr);
    final result = await MethodCaller.call(() async {
      final uri = Uri.parse(rpcUrl.trim()).normalizePath();

      final serviceProvider = EVMApiProviderService(
          serviceName: AppStringUtility.addNumberToMakeUnique(
              providers
                  .map((e) => e.serviceProvider.provider.serviceName)
                  .toList()
                ..addAll(defaultProviders
                    .map((e) => e.serviceProvider.provider.serviceName))
                ..removeWhere((element) =>
                    element ==
                    selectedProvider!.serviceProvider.provider.serviceName),
              uri.toString()),
          websiteUri: AppStringUtility.removeSchame(uri.host),
          uri: uri.toString());
      final rpc = ChainUtils.buildEVMProvider(serviceProvider, widget.network);
      final info = await rpc.getNetworkInfo();
      if (info.$1 != network.coinParam.chainId) {
        throw WalletException("invalid_chain_id");
      }
      return rpc;
    });
    if (result.hasError) {
      pageProgressKey.errorText(result.error!.tr);
    } else {
      final index = providers.indexOf(selectedProvider!);
      if (index < 0) {
        providers.add(result.result);
      } else {
        providers[index] = result.result;
      }
      rpcUrl = "";
      selectedProvider = null;
      setState(() {});
      pageProgressKey.successText("rpc_url_has_been_updated".tr);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MethodCaller.call(() async {
      for (final i in providers) {
        await i.getNetworkInfo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedProvider == null || pageProgressKey.isSuccess,
      onPopInvoked: (didPop) {
        if (!didPop) {
          discardChange();
        }
      },
      child: ScaffolPageView(
        appBar: AppBar(
          title: Text("update_network".tr),
        ),
        child: PageProgress(
          key: pageProgressKey,
          backToIdle: AppGlobalConst.twoSecoundDuration,
          child: () => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ConstraintsBoxView(
                    padding: WidgetConstant.padding20,
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSize(
                            duration: AppGlobalConst.animationDuraion,
                            child: selectedProvider == null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("chain_id".tr,
                                          style: context.textTheme.titleMedium),
                                      Text("chain_id_of_network".tr),
                                      WidgetConstant.height8,
                                      ContainerWithBorder(
                                          child: Text(widget
                                              .network.coinParam.chainId
                                              .toString())),
                                      WidgetConstant.height20,
                                      Text("network_name".tr,
                                          style: context.textTheme.titleMedium),
                                      Text("network_name_desc".tr),
                                      WidgetConstant.height8,
                                      AppTextField(
                                        initialValue: networkName,
                                        readOnly: isDefaultNetwork,
                                        onChanged: onChangeNetworkName,
                                        validator: validateNetworkName,
                                        label: "network_name".tr,
                                      ),
                                      WidgetConstant.height20,
                                      Text("symbol".tr,
                                          style: context.textTheme.titleMedium),
                                      Text("symbol_desc".tr),
                                      WidgetConstant.height8,
                                      AppTextField(
                                        initialValue: symbol,
                                        readOnly: isDefaultNetwork,
                                        onChanged: onChangeSymbol,
                                        validator: validateSymbol,
                                        label: "symbol".tr,
                                      ),

                                      ///
                                      WidgetConstant.height20,
                                      Text("network_explorer_address_link".tr,
                                          style: context.textTheme.titleMedium),
                                      Text("network_evm_explorer_address_desc"
                                          .tr),
                                      WidgetConstant.height8,
                                      AppTextField(
                                        key: explorerFieldKey,
                                        initialValue: explorerAddressLink,
                                        readOnly: isDefaultNetwork,
                                        onChanged: onChangeExplorerAddress,
                                        validator: validateAddressLink,
                                        label:
                                            "network_explorer_address_link".tr,
                                        suffixIcon: isDefaultNetwork
                                            ? null
                                            : PasteTextIcon(
                                                onPaste: onPasteExplorerAddres),
                                      ),
                                      WidgetConstant.height20,
                                      Text(
                                          "network_explorer_transaction_link"
                                              .tr,
                                          style: context.textTheme.titleMedium),
                                      Text(
                                          "network_evm_explorer_transaction_desc"
                                              .tr),
                                      WidgetConstant.height8,
                                      AppTextField(
                                        key: transactionFieldKey,
                                        initialValue: explorerAddressLink,
                                        readOnly: isDefaultNetwork,
                                        onChanged: onChangeExplorerTransaction,
                                        validator: validateAddressLink,
                                        label:
                                            "network_explorer_transaction_link"
                                                .tr,
                                        suffixIcon: isDefaultNetwork
                                            ? null
                                            : PasteTextIcon(
                                                onPaste:
                                                    onPasteExplorerTransaction),
                                      ),

                                      if (defaultProviders.isNotEmpty) ...[
                                        WidgetConstant.height20,
                                        Text("default_providers".tr,
                                            style:
                                                context.textTheme.titleMedium),
                                        WidgetConstant.height8,
                                        ...List.generate(
                                            defaultProviders.length, (index) {
                                          final provider =
                                              defaultProviders[index];
                                          return ContainerWithBorder(
                                              onTapWhenOnRemove: false,
                                              onRemove: () {},
                                              onRemoveIcon:
                                                  ProviderTrackerStatusView(
                                                      provider: provider
                                                          .serviceProvider),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(provider.serviceProvider
                                                      .provider.serviceName),
                                                  Text(provider.serviceProvider
                                                      .provider.websiteUri),
                                                ],
                                              ));
                                        }),
                                      ],

                                      WidgetConstant.height20,
                                      Text("providers".tr,
                                          style: context.textTheme.titleMedium),
                                      Text("edit_or_add_evm_provider_desc".tr),
                                      WidgetConstant.height8,
                                      ...List.generate(providers.length,
                                          (index) {
                                        final provider = providers[index];
                                        return ContainerWithBorder(
                                            onRemove: () {
                                              onSelectProvider(provider);
                                            },
                                            onRemoveIcon:
                                                ProviderTrackerStatusView(
                                                    provider: provider
                                                        .serviceProvider),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(provider.serviceProvider
                                                    .provider.serviceName),
                                                Text(provider.serviceProvider
                                                    .provider.websiteUri),
                                                Text(provider.serviceProvider
                                                    .provider.protocol.value.tr)
                                              ],
                                            ));
                                      }),
                                      ContainerWithBorder(
                                        onRemove: createNewRPC,
                                        validate: providers.isNotEmpty,
                                        onRemoveIcon: const Icon(Icons.add_box),
                                        child: Text(
                                            "tap_to_add_new_service_provider"
                                                .tr),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          FixedElevatedButton(
                                            padding: WidgetConstant
                                                .paddingVertical20,
                                            onPressed: providers.isEmpty
                                                ? null
                                                : onAddChain,
                                            child: Text("update_network".tr),
                                          )
                                        ],
                                      )
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (providers
                                          .contains(selectedProvider)) ...[
                                        Text("edit_provider_rpc_url".tr,
                                            style:
                                                context.textTheme.titleMedium),
                                        Text(
                                            "edit_or_add_evm_provider_desc".tr),
                                        WidgetConstant.height8,
                                        ContainerWithBorder(
                                            onRemove: () {},
                                            onRemoveIcon:
                                                ProviderTrackerStatusView(
                                                    provider: selectedProvider!
                                                        .serviceProvider),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(selectedProvider!
                                                    .serviceProvider
                                                    .provider
                                                    .serviceName),
                                                Text(selectedProvider!
                                                    .serviceProvider
                                                    .provider
                                                    .websiteUri)
                                              ],
                                            )),
                                        WidgetConstant.height20,
                                      ],
                                      Text("rpc_url".tr,
                                          style: context.textTheme.titleMedium),
                                      Text("rpc_url_desc".tr),
                                      WidgetConstant.height8,
                                      AppTextField(
                                        key: uriFieldKey,
                                        initialValue: rpcUrl,
                                        onChanged: onChageUrl,
                                        validator: validateRpcUrl,
                                        suffixIcon:
                                            PasteTextIcon(onPaste: onPasteUri),
                                        label: "rpc_url".tr,
                                      ),
                                      Padding(
                                        padding:
                                            WidgetConstant.paddingVertical20,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FixedElevatedButton.icon(
                                              label: Text(
                                                  "network_verify_server_status"
                                                      .tr),
                                              onPressed: onUpdate,
                                              icon: const Icon(Icons.update),
                                            ),
                                            WidgetConstant.width8,
                                            IconButton(
                                                tooltip: "discard_changes".tr,
                                                icon: const Icon(Icons.cancel),
                                                onPressed: discardChange),
                                            WidgetConstant.width8,
                                            IconButton(
                                                tooltip: "remove".tr,
                                                icon: const Icon(Icons.delete),
                                                onPressed: deleteProvider),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                          )
                        ],
                      ),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
