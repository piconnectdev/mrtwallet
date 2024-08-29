part of 'package:mrt_wallet/wallet/provider/wallet_provider.dart';

mixin Web3Impl on WalletManager, Web3EthereumImpl, Web3TronImpl {
  Chain _getWeb3ChainId(
      {required Web3RequestParams param,
      required Web3APPAuthentication authenticated}) {
    switch (param.method.network) {
      case NetworkType.ethereum:
        final web3Chain = authenticated
            .getChainFromNetworkType<Web3EthereumChain>(param.method.network);
        if (param.account != null && web3Chain == null) {
          throw Web3RequestExceptionConst.missingPermission;
        }
        return _appChains._networks.values
            .whereType<EthereumChain>()
            .firstWhere(
                (e) => e.chainId == (web3Chain?.currentChain ?? BigInt.one),
                orElse: () => throw Web3RequestExceptionConst.invalidNetwork);
      case NetworkType.tron:
        final web3Chain = authenticated
            .getChainFromNetworkType<Web3TronChain>(param.method.network);
        if (param.account != null && web3Chain == null) {
          throw Web3RequestExceptionConst.missingPermission;
        }
        return _appChains._networks.values.whereType<TronChain>().firstWhere(
            (e) =>
                e.network.tronNetworkType ==
                (web3Chain?.currentChain ?? TronChainType.mainnet),
            orElse: () => throw Web3RequestExceptionConst.invalidNetwork);
      default:
        throw Web3RequestExceptionConst.networkNotSupported;
    }
  }

  Future<Web3EncryptedMessage> _getWeb3Authenticated(
      Web3ClientInfo info) async {
    final auth = await _getOrCreateAppAuthenticated(info);
    final sha256 = await crypto.generateHash(
        type: CryptoRequestHashingType.sha256,
        dataBytes: StringUtils.encode(info.clientId));
    final message = Web3ChainMessage(
        authenticated: auth,
        message: _appChains.toCbor().encode(),
        type: Web3MessageTypes.chains);
    final encryptedKey = await crypto.cryptoRequest(CryptoRequestEncryptChacha(
        message: message.toCbor().encode(), key: sha256));
    return Web3EncryptedMessage(
        message: encryptedKey.encrypted, nonce: encryptedKey.nonce);
  }

  Future<Web3EncryptedMessage> _getWeb3Permission(Web3ClientInfo info) async {
    final auth = await _getOrCreateAppAuthenticated(info);
    final message = Web3ChainMessage(
        authenticated: auth,
        message: _appChains.toCbor().encode(),
        type: Web3MessageTypes.chains);
    final encryptedKey = await crypto.cryptoRequest(CryptoRequestEncryptChacha(
        message: message.toCbor().encode(), key: auth.token));
    return Web3EncryptedMessage(
        message: encryptedKey.encrypted, nonce: encryptedKey.nonce);
  }

  Future<Web3APPAuthentication> _getOrCreateAppAuthenticated(
      Web3ClientInfo info) async {
    final permission = await _core._readWeb3Permission(
      applicationId: info.applicationId,
      wallet: _wallet,
    );

    final toPermission = MethodUtils.nullOnException(() {
      return Web3APPAuthentication.deserialize(hex: permission);
    });
    if (toPermission == null) {
      final token = await crypto.generateRandomBytes();
      final applicationKey = await crypto.generateHashString(
          type: CryptoRequestHashingType.md4,
          dataBytes: info.applicationId.codeUnits);
      final permission = Web3APPAuthentication(
          name: info.name,
          applicationKey: applicationKey,
          applicationId: info.applicationId,
          icon: info.image,
          token: token);
      await _core._savePermission(permission: permission, wallet: _wallet);
      return permission;
    }

    return toPermission;
  }

  @override
  Future<dynamic> _getWalletOwnerResult(Web3Request request) async {
    final push = _core.onWeb3Request(request);
    if (!(push)) {
      throw Web3RequestExceptionConst.internalError;
    }
    return await request.getResponse();
  }

  Future<dynamic> _getWeb3Result({required Web3Request request}) async {
    if (request.isPermissionRequest && request.hasAnyPermission) {
      return request.currentPermission!;
    }
    switch (request.chain.network.type) {
      case NetworkType.ethereum:
        return await _getEthereumWeb3Result(request as Web3EthereumRequest);
      case NetworkType.tron:
        return await _getTronWeb3Result(request as Web3TronRequest);
      default:
        throw Web3RequestExceptionConst.networkNotSupported;
    }
  }

  Future<Web3MessageCore> _handleGlobalRequest({
    required Web3GlobalRequestParams requestParams,
    required Web3APPAuthentication authenticated,
    required Web3RequestApplicationInformation walletRequest,
  }) async {
    throw UnimplementedError();
    // Object? result;
    // switch (requestParams.method) {
    //   case Web3GlobalRequestMethods.disconnect:
    //     final requestMessage = requestParams.cast<Web3DisconnectApplication>();
    //     authenticated.disconnect(requestMessage.chain);
    //     result = true;
    //     break;
    //   default:
    //     throw Web3RequestExceptionConst.invalidRequest;
    // }
    // await _core._savePermission(wallet: _wallet, permission: authenticated);
    // return Web3WalletResponseMessage(
    //   authenticated: authenticated,
    //   result: result,

    // );
  }

  Future<Web3MessageCore> _handleChainRequest(
      {required Web3RequestParams requestParams,
      required Web3APPAuthentication authenticated,
      required Web3RequestApplicationInformation walletRequest}) async {
    final chain =
        _getWeb3ChainId(authenticated: authenticated, param: requestParams);
    final request = requestParams.toRequest(
        request: walletRequest, chain: chain, authenticated: authenticated);
    request.verifyPermissioon();
    final params = request.params;
    Object? result = await _getWeb3Result(request: request);

    if (params.isPermissionRequest) {
      request.authenticated.updateChainAccount(result as Web3Chain);
      result = request.currentPermission!
          .currentChainAccounts(chain)
          .map((e) => e.addressStr)
          .toList();
    }
    request.authenticated
        .addActivity(param: request.params, url: request.info.info.url);
    await _core._savePermission(wallet: _wallet, permission: authenticated);
    if (params.isPermissionRequest) {
      if (!request.hasAnyPermission) {
        throw Web3RequestExceptionConst.rejectedByUser;
      }
    }
    if (params.isPermissionRequest) {
      return Web3ChainMessage(
          type: Web3MessageTypes.chains,
          authenticated: authenticated,
          message: _appChains.toCbor().encode(),
          response:
              Web3ResponseMessage(result: result, network: chain.network.type));
    }
    return Web3WalletResponseMessage(
        result: result,
        authenticated: authenticated,
        network: chain.network.type);
  }

  Future<Web3EncryptedMessage> _web3Request(
      Web3RequestApplicationInformation walletRequest) async {
    final authenticated =
        await _getOrCreateAppAuthenticated(walletRequest.info);
    if (!authenticated.active) {
      throw Web3RequestExceptionConst.bannedHost;
    }
    Web3EncryptedMessage encryotedMessage =
        Web3EncryptedMessage.deserialize(bytes: walletRequest.request.data);
    final CryptoDecryptChachaResponse decrypt = await crypto
        .cryptoRequest(CryptoRequestDecryptChacha(
            key: authenticated.token,
            nonce: encryotedMessage.nonce,
            message: encryotedMessage.message))
        .catchError((e) => throw Web3RequestExceptionConst.invalidRequest);
    Web3MessageCore response;
    try {
      final requestParams =
          Web3MessageCore.deserialize(bytes: decrypt.decrypted);
      switch (requestParams.type) {
        case Web3MessageTypes.walletRequest:
          response = await _handleChainRequest(
              authenticated: authenticated,
              requestParams: requestParams.cast<Web3RequestParams>(),
              walletRequest: walletRequest);

          break;
        case Web3MessageTypes.walletGlobalRequest:
          response = await _handleGlobalRequest(
              requestParams: requestParams.cast<Web3GlobalRequestParams>(),
              authenticated: authenticated,
              walletRequest: walletRequest);
          break;
        default:
          throw Web3RequestExceptionConst.invalidRequest;
      }
    } on Web3RejectException {
      rethrow;
    } on Web3RequestException catch (e) {
      response =
          e.toResponseMessage(requestId: walletRequest.request.requestId);
    } catch (e) {
      const exception = Web3RequestExceptionConst.internalError;
      response = exception.toResponseMessage(
          requestId: walletRequest.request.requestId);
    }
    final CryptoEncryptChachaResponse encryptResponse =
        await crypto.cryptoRequest(CryptoRequestEncryptChacha(
            key: authenticated.token, message: response.toCbor().encode()));
    return Web3EncryptedMessage(
        message: encryptResponse.encrypted, nonce: encryptResponse.nonce);
  }

  Future<Web3EncryptedMessage> _updateWeb3Application(
      Web3APPAuthentication application) async {
    await _core._savePermission(wallet: _wallet, permission: application);
    final message = Web3ChainMessage(
        type: Web3MessageTypes.chains,
        authenticated: application,
        message: _appChains.toCbor().encode());
    final CryptoEncryptChachaResponse encryptResponse =
        await crypto.cryptoRequest(CryptoRequestEncryptChacha(
            key: application.token, message: message.toCbor().encode()));
    return Web3EncryptedMessage(
        message: encryptResponse.encrypted, nonce: encryptResponse.nonce);
  }
}
