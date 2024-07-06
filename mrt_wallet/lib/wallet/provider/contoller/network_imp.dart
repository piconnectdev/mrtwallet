part of 'package:mrt_wallet/wallet/provider/wallet_provider.dart';

mixin WalletNetworkManager2 on WalletStorageManger2 {
  ChainsHandler _appChains = ChainsHandler.setup();
  ChainHandler get chain => _appChains.chain;
  WalletNetwork get network => chain.network;
  bool get isOpen;

  List<String> coinIds() {
    final ids = _appChains
        .chains()
        .map((e) => e.account.tokens())
        .expand((e) => e)
        .map((e) => e.token.market?.apiId)
        .where((element) => element != null);
    final networkIds = _appChains
        .networks()
        .map((e) => e.token.market?.apiId)
        .where((element) => element != null);
    return List<String>.from([...ids, ...networkIds]);
  }

  Future<void> _updateImportNetwork(WalletNetwork network) async {
    final newChain = _appChains.updateImportNetwork(network);
    await _saveAccount(newChain);
  }

  Future<void> _switchAccount(CryptoAddress account) async {
    final acc = chain;
    acc.account.switchAccount(account);
    await _saveAccount(acc);
  }

  Future<void> _removeAccount(CryptoAddress account) async {
    final acc = chain;
    acc.account.removeAccount(account);
    await _saveAccount(acc);
  }

  Future<CryptoAddress> _addNewAccountToNetwork(
      NewAccountParams accountParams, List<int> publicKey) async {
    final acc = chain;
    final address = acc.account.addNewAddress(publicKey, accountParams);
    await _saveAccount(acc);
    _updateAccountBalance(acc, address: address);
    await MethodUtils.wait();
    return address;
  }

  Future<void> _addNewContact(ContactCore newContact) async {
    final acc = chain;
    acc.account.addContact(newContact);
    await _saveAccount(acc);
  }

  Future<void> _addNewToken(TokenCore token, CryptoAddress address) async {
    final acc = chain;
    final currentAccount = acc.account;
    if (!currentAccount.addresses.contains(address)) {
      throw WalletExceptionConst.accountDoesNotFound;
    }
    address.addToken(token);
    await _saveAccount(acc);
  }

  Future<void> _removeToken(TokenCore token, CryptoAddress address) async {
    final acc = chain;
    final currentAccount = acc.account;
    if (!currentAccount.addresses.contains(address)) {
      throw WalletExceptionConst.accountDoesNotFound;
    }
    address.removeToken(token);
    await _saveAccount(acc);
  }

  Future<void> _updateToken({
    required TokenCore token,
    required Token updatedToken,
    required CryptoAddress address,
  }) async {
    final acc = chain;
    final currentAccount = acc.account;
    if (!currentAccount.addresses.contains(address)) {
      throw WalletExceptionConst.accountDoesNotFound;
    }
    address.updateToken(token, updatedToken);
    await _saveAccount(acc);
  }

  Future<void> _addNewNFT(NFTCore nft, CryptoAddress address) async {
    final acc = chain;
    final currentAccount = acc.account;
    if (!currentAccount.addresses.contains(address)) {
      throw WalletExceptionConst.accountDoesNotFound;
    }
    address.addNFT(nft);
    await _saveAccount(acc);
  }

  Future<void> _removeNFT(NFTCore nft, CryptoAddress address) async {
    final acc = chain;
    final currentAccount = acc.account;
    if (!currentAccount.addresses.contains(address)) {
      throw WalletExceptionConst.accountDoesNotFound;
    }
    address.removeNFT(nft);
    await _saveAccount(acc);
  }

  Future<void> _setAccountName(String? name, CryptoAddress address) async {
    final acc = chain;
    final currentAccount = acc.account;
    if (!currentAccount.addresses.contains(address)) {
      throw WalletExceptionConst.accountDoesNotFound;
    }
    address.setAccountName(name);
    await _saveAccount(acc);
  }

  Future<void> _updateAccountBalance(ChainHandler? account,
      {CryptoAddress? address}) async {
    if (account == null || !account.haveAddress) return;
    if (address != null && !account.account.addresses.contains(address)) return;
    await account
        .provider()
        ?.updateBalance(address ?? account.account.address)
        .catchError((e) {});
    account.account.refreshTotalBalance();
    await _saveAccount(account);
  }

  Future<void> _updateAccountsBalance(ChainHandler? account) async {
    if (account == null || !account.haveAddress) return;
    final provider = account.provider();
    for (final i in account.account.addresses) {
      try {
        await provider?.updateBalance(i);
      } catch (e) {
        continue;
      }
    }
    account.account.refreshTotalBalance();
    await _saveAccount(account);
  }

  Future<void> _setupNetwork() async {
    List<ChainHandler> chains = [];
    final keys = await _readAccounts();
    for (final i in keys) {
      try {
        final chain = ChainHandler.fromCborBytesOrObject(hex: i);
        chains.add(chain);
      } catch (e) {
        // rethrow;
        continue;
      }
    }
    _appChains = ChainsHandler(chains, currentNetwork: _wallet.network);
  }

  Future<void> _switchNetwork(int changeNetwork) async {
    if (network.value == changeNetwork ||
        !_appChains.hasNetwork(changeNetwork)) {
      return;
    }
    _appChains.setNetwork(changeNetwork);
    await _saveNetworkId(_appChains.network.value);
  }

  Future<void> _changeNetworkApiProvider(APIProvider provider) async {
    final currentNetwork = chain;
    currentNetwork.setProvider(provider);
    await _saveAccount(currentNetwork);
  }

  Future<void> _cleanUpdateRemovedKeyAccounts(String removedKey) async {
    List<CryptoAddress> removeList = [];
    final List<CryptoAddress<dynamic, dynamic>> accs = _appChains.accounts;
    for (final address in accs) {
      if (address.multiSigAccount) {
        final multiSigAccount = address as MultiSigCryptoAccountAddress;
        for (final i in multiSigAccount.keyDetails) {
          if (i.$2.importedKeyId == removedKey) {
            removeList.add(address);
            break;
          }
        }
      } else {
        if (address.keyIndex.importedKeyId == removedKey) {
          removeList.add(address);
        }
      }
    }
    if (removeList.isEmpty) return;
    for (final address in removeList) {
      final account = _appChains.fromAddress(address);
      MethodUtils.nullOnException(() => account.account.removeAccount(address));
      await _saveAccount(account);
    }
  }

  final Cancelable _balanceUpdaterCancelable = Cancelable();
  StreamSubscription<void>? _balanceUpdaterStream;
  void _streamBalances() {
    _disposeBalanceUpdater();
    final chains = _appChains.chains();
    _balanceUpdaterStream = MethodUtils.prediocCaller(
            () => MethodUtils.call(() async {
                  for (final chain in chains) {
                    bool hasUpdate = false;
                    final provider = chain.provider();
                    if (provider == null) continue;
                    for (final i in chain.account.addresses) {
                      final update = await MethodUtils.call(
                          () async => provider.updateBalance(i));
                      if (update.hasResult) hasUpdate = true;
                    }
                    if (hasUpdate) {
                      await _saveAccount(chain);
                    }
                    if (chain.network != network) {
                      provider.service.disposeService();
                    }
                  }
                }),
            canclable: _balanceUpdaterCancelable,
            waitOnSuccess: const Duration(minutes: 10))
        .listen((s) {});
  }

  void _disposeBalanceUpdater() {
    MethodUtils.nullOnException(() {
      _balanceUpdaterStream?.cancel();
      _balanceUpdaterStream = null;
      _balanceUpdaterCancelable.cancel();
    });
  }
}
