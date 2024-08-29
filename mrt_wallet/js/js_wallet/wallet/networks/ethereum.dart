import 'package:mrt_wallet/crypto/models/networks.dart';
import 'package:on_chain/on_chain.dart';
import 'dart:async';
import 'package:mrt_wallet/wallet/wallet.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/wallet/web3/web3.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../core/network_handler.dart';

class EthereumWeb3State
    extends ChainWeb3State<ETHAddress, EthereumChain, Web3EthereumChain> {
  final EthereumChain? chain;
  final String? defaultAddress;
  final EthereumClient? client;

  EthereumWeb3State._({
    super.permission,
    required super.chains,
    required super.state,
    required super.permissionAccounts,
    this.client,
    this.defaultAddress,
    this.chain,
  });
  factory EthereumWeb3State.init(
      {JSNetworkState state = JSNetworkState.disconnect}) {
    return EthereumWeb3State._(
        chains: const [], permissionAccounts: const [], state: state);
  }
  factory EthereumWeb3State(
      {required Web3APPAuthentication authenticated,
      required ChainsHandler chainHandler}) {
    final permission = authenticated
        .getChainFromNetworkType<Web3EthereumChain>(NetworkType.ethereum);
    if (permission == null) {
      return EthereumWeb3State.init(state: JSNetworkState.block);
    }
    final chains = chainHandler.chains().whereType<EthereumChain>().toList();
    final currentChain =
        chains.firstWhere((e) => e.chainId == permission.currentChain);
    final permissionAccounts = permission.currentChainAccounts(currentChain);
    final defaultAddress = permissionAccounts
        .firstWhereOrNull((e) => e.defaultAddress, orElse: () {
      if (permissionAccounts.isEmpty) return null;
      return permissionAccounts.first;
    });

    return EthereumWeb3State._(
        chains: chainHandler.chains().whereType<EthereumChain>().toList(),
        permission: permission,
        permissionAccounts: permissionAccounts.map((e) => e.addressStr).toList()
          ..sort(
            (a, b) {
              if (a == defaultAddress?.addressStr) {
                return -1;
              } else if (b == defaultAddress?.addressStr) {
                return 1;
              }
              return a.compareTo(b);
            },
          ),
        state: JSNetworkState.init,
        defaultAddress: defaultAddress?.addressStr,
        chain: currentChain,
        client: currentChain.getWeb3Provider(
            requestTimeout: ChainWeb3State.requestTimeout));
  }

  bool accountChanged(EthereumWeb3State other) {
    return !(CompareUtils.iterableIsEqual(
            permissionAccounts, other.permissionAccounts) &&
        defaultAddress == other.defaultAddress);
  }

  bool chainChanged(EthereumWeb3State other) {
    return other.chain?.chainId != chain?.chainId;
  }

  bool needToggle(EthereumWeb3State other) {
    return other.state != state;
  }

  EthereumAccountsChanged get accountsChange => EthereumAccountsChanged(
      accounts: permissionAccounts, defaultAddress: defaultAddress);
  ProviderConnectInfo get chainChangedEvent =>
      ProviderConnectInfo(chain!.chainId);

  bool get isConnect => chain != null;
}

class JSEthereumHandler extends JSNetworkHandler<ETHAddress, EthereumChain,
    Web3EthereumChain, ClientMessageEthereum, EthereumWeb3State> {
  @override
  EthereumWeb3State state = EthereumWeb3State.init();
  JSEthereumHandler({required super.sendMessageToClient});

  void _onSubscribe(EthereumSubscribeResult result) {
    sendMessageToClient(JSWalletMessageResponseEthereum(
        event: EthereumEvnetTypes.message, data: result.toJson()));
  }

  void initChain(
      {required Web3APPAuthentication authenticated,
      required ChainsHandler chainHandler}) {
    lock.synchronized(() async {
      final currentState = state;
      state = EthereumWeb3State(
          authenticated: authenticated, chainHandler: chainHandler);
      if (state.needToggle(currentState)) {
        _toggleEthereum(state);
        _disconnect();
        if (state.isConnect) {
          _connect(state);
          _chainChanged(state);
          if (state.client!.supportSubscribe) {
            state.client!.addSubscriptionListener(_onSubscribe);
          }
        }
        _accountChanged(state);
        return;
      }
      if (state.chainChanged(currentState)) {
        _disconnect();
        if (state.isConnect) {
          _connect(state);
          if (state.client!.supportSubscribe) {
            state.client!.addSubscriptionListener(_onSubscribe);
          }
        }
        _chainChanged(state);
      }
      if (state.accountChanged(currentState)) {
        _accountChanged(state);
      }
    });
  }

  void _disconnect() {
    sendMessageToClient(JSWalletMessageResponseEthereum(
        event: EthereumEvnetTypes.disconnect,
        data: Web3RequestExceptionConst.disconnectedChain.toJson()));
  }

  void _connect(EthereumWeb3State state) async {
    if (state.chain == null) return;
    sendMessageToClient(JSWalletMessageResponseEthereum(
        event: EthereumEvnetTypes.connect,
        data: state.chainChangedEvent.toJson()));
  }

  void _accountChanged(EthereumWeb3State state) async {
    sendMessageToClient(JSWalletMessageResponseEthereum(
        event: EthereumEvnetTypes.accountsChanged,
        data: state.accountsChange.toJson()));
  }

  void _chainChanged(EthereumWeb3State state) async {
    if (state.chain == null) return;
    sendMessageToClient(JSWalletMessageResponseEthereum(
        event: EthereumEvnetTypes.chainChanged,
        data: state.chainChangedEvent.toJson()));
  }

  void _toggleEthereum(EthereumWeb3State state) {
    if (state.chain != null) {
      sendMessageToClient(JSWalletMessageResponseEthereum(
          event: EthereumEvnetTypes.active, data: null));
    } else {
      sendMessageToClient(JSWalletMessageResponseEthereum(
          event: EthereumEvnetTypes.disable,
          data: Web3RequestExceptionConst.bannedHost.data));
    }
  }

  Web3MessageCore _eventMessage(
      EthereumEvnetTypes type, EthereumWeb3State state) {
    switch (type) {
      case EthereumEvnetTypes.accountsChanged:
        _accountChanged(state);
        break;
      case EthereumEvnetTypes.chainChanged:
        _chainChanged(state);
        break;
      default:
        break;
    }
    return buildResponse(null);
  }

  @override
  Future<Web3MessageCore> request(ClientMessageEthereum params) async {
    final state = this.state;
    final isEvent = EthereumEvnetTypes.fromName(params.method);
    if (isEvent != null) {
      return _eventMessage(isEvent, state);
    }
    final method = Web3EthereumRequestMethods.fromName(params.method);
    if (method == null) return _rpcCall(params, state);
    switch (method) {
      case Web3EthereumRequestMethods.requestAccounts:
        if (state.permissionAccounts.isNotEmpty) {
          return buildResponse(state.permissionAccounts);
        }
        return Web3EthreumRequestAccounts();
      case Web3EthereumRequestMethods.switchEthereumChain:
        final parse = _parseSwitchEthereumChain(params);
        if (parse.chainId == state.chain?.chainId) {
          return buildResponse(parse.chainId.toRadix16);
        }
        final chain =
            state.chains.firstWhereOrNull((e) => e.chainId == parse.chainId);
        if (chain == null) {
          throw Web3RequestExceptionConst.ethereumNetworkDoesNotExist;
        }
        return parse;
      case Web3EthereumRequestMethods.persoalSign:
        return _personalSign(params);
      case Web3EthereumRequestMethods.addEthereumChain:
        return _parseAddEthereumChain(params);
      case Web3EthereumRequestMethods.typedData:
        return _parseTypedData(params, state.chain!.chainId);
      case Web3EthereumRequestMethods.sendTransaction:
        final transaction = _parseTransaction(params, state.chain!.chainId);
        if (transaction.transactionType == ETHTransactionType.eip1559 &&
            !state.chain!.network.coinParam.supportEIP1559) {
          throw Web3RequestExceptionConst.invalidParameters(
              Web3RequestExceptionConst.eip1559NotSupported);
        }
        return transaction;
      case Web3EthereumRequestMethods.ethAccounts:
        return buildResponse(state.permissionAccounts);
      case Web3EthereumRequestMethods.ethChainId:
        return buildResponse(state.chain!.chainId.toRadix16);
      default:
        throw UnimplementedError();
    }
  }

  Future<Web3MessageCore> _rpcCall(
      ClientMessageEthereum params, EthereumWeb3State state) async {
    final cl = state.client;
    if (cl == null) {
      throw Web3RequestExceptionConst.disconnected();
    }
    await cl.init();
    if (!cl.isConnect) {
      throw Web3RequestExceptionConst.disconnectedChain;
    }

    final method = EthereumMethods.fromName(params.method);
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    try {
      if (method == EthereumMethods.subscribe) {
        if (!cl.supportSubscribe) {
          throw Web3RequestExceptionConst.methodDoesNotSupport;
        }
        final result =
            await cl.subscribe(params: params.paramsAsList() ?? const []);
        return buildResponse(result);
      }
      final call = await cl.dynamicCall(method.value, params.params);
      return buildResponse(call);
    } on Web3RequestException {
      rethrow;
    } on RPCError catch (e) {
      throw Web3RequestExceptionConst.fromException(e);
    } on ApiProviderException catch (e) {
      if (e.isTimeout) {
        throw Web3RequestExceptionConst.disconnected(
            message: Web3RequestExceptionConst.requestTimeoutMessage);
      } else {
        throw Web3RequestExceptionConst.disconnected();
      }
    } catch (e) {
      throw Web3RequestExceptionConst.disconnected();
    }
  }

  static EIP712Version _typedDataVersion(String methodName) {
    final version = int.tryParse(methodName[methodName.length - 1]) ?? 1;
    return EIP712Version.fromVersion(version);
  }

  static Web3EthreumTypdedData _parseTypedData(
      ClientMessageEthereum params, BigInt chainId) {
    try {
      final toList = params.paramsAsList(length: 2);
      if (toList == null) {
        throw Web3RequestExceptionConst.ethTypedData;
      }
      final EIP712Version version = _typedDataVersion(params.method);
      final String address;
      EIP712Base data;
      if (version == EIP712Version.v1) {
        address = toList[1];
        data = EIP712Legacy.fromJson(JsUtils.toList(toList[0])
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
      } else {
        address = toList[0];
        data = Eip712TypedData.fromJson(JsUtils.toMap(toList[1]),
            version: version);
      }
      final typdedDataParams = Web3EthreumTypdedData.fromJson({
        "address": address,
        "typedData": StringUtils.fromJson(data.toJson())
      });

      return typdedDataParams;
    } on Web3RequestException {
      rethrow;
    } catch (e) {
      throw Web3RequestExceptionConst.ethTypedData;
    }
  }

  static Web3EthreumSwitchChain _parseSwitchEthereumChain(
      ClientMessageEthereum params) {
    final toList = params.paramsAsList(length: 1);
    if (toList == null) {
      throw Web3RequestExceptionConst.invalidList(params.method);
    }
    final toObject = JsUtils.toMap<String, dynamic>(toList[0],
        error:
            Web3RequestExceptionConst.invalidMethodArgruments(params.method));
    return Web3EthreumSwitchChain.fromJson(toObject);
  }

  Future<Web3EthereumAddNewChain> _parseAddEthereumChain(
      ClientMessageEthereum params) async {
    final toList = params.paramsAsList(length: 1);
    if (toList == null) {
      throw Web3RequestExceptionConst.invalidMethodArgruments(params.method);
    }
    final toObject = JsUtils.toMap<String, dynamic>(toList[0],
        error:
            Web3RequestExceptionConst.invalidMethodArgruments(params.method));

    final newChain = Web3EthereumAddNewChain.fromJson(toObject);
    final network = newChain.toNewNetwork();
    List<String> rpcsUrls = [];
    bool hasWrongChainId = false;
    for (final i in network.coinParam.providers) {
      final chainId = await MethodUtils.call(() async {
        final client = APIUtils.buildEthereumProvider(i, network);
        return await client.getChainId();
      });

      if (chainId.hasResult) {
        if (chainId.result == newChain.newChainId) {
          rpcsUrls.add(i.callUrl);
        } else {
          hasWrongChainId = true;
        }
      }
    }
    if (rpcsUrls.isEmpty) {
      if (hasWrongChainId) {
        throw Web3RequestExceptionConst.ethereumRpcWrongChainId;
      } else {
        throw Web3RequestExceptionConst.rpcConnection;
      }
    }
    return newChain.updateRpcUrl(rpcsUrls);
  }

  static Web3EthreumSendTransaction _parseTransaction(
      ClientMessageEthereum params, BigInt chainId) {
    final toList = params.paramsAsList(length: 1);
    if (toList == null) {
      throw Web3RequestExceptionConst.invalidMethodArgruments(params.method);
    }
    final transactionParam = toList[0];
    final Map<String, dynamic>? toJson = MethodUtils.nullOnException(() {
      if (transactionParam is String) {
        return StringUtils.tryToJson(transactionParam);
      } else {
        return Map<String, dynamic>.from(transactionParam);
      }
    });
    if (toJson == null) {
      throw Web3RequestExceptionConst.invalidMethodArgruments(params.method);
    }
    return Web3EthreumSendTransaction.fromJson(toJson);
  }

  Web3EthreumPersonalSign _personalSign(ClientMessageEthereum params) {
    try {
      final toList = params.paramsAsList(length: 2);
      if (toList == null) {
        throw Web3RequestExceptionConst.invalidMethodArgruments(params.method);
      }
      final Map<String, dynamic> message = {
        "address": toList[0],
        "challeng": toList[1]
      };
      return Web3EthreumPersonalSign.fromJson(message);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void onRequestDone(ClientMessageEthereum message) {
    final method = Web3EthereumRequestMethods.fromName(message.method);
    switch (method) {
      case Web3EthereumRequestMethods.addEthereumChain:
      case Web3EthereumRequestMethods.switchEthereumChain:
      case Web3EthereumRequestMethods.ethChainId:
        _chainChanged(state);
        break;
      case Web3EthereumRequestMethods.requestAccounts:
      case Web3EthereumRequestMethods.ethAccounts:
        _accountChanged(state);
        break;
      default:
    }
  }

  @override
  NetworkType get networkType => NetworkType.ethereum;
}
