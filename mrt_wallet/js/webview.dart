import 'dart:async';
import 'dart:js_interop';
import 'package:mrt_native_support/models/models.dart';
import 'package:mrt_wallet/wallet/web3/constant/constant/exception.dart';
import 'package:mrt_wallet/wallet/web3/core/messages/models/models/exception.dart';
import 'package:mrt_wallet/wallet/web3/core/permission/models/authenticated.dart';
import 'js_wallet/js_wallet.dart';
import 'package:mrt_native_support/web/mrt_native_web.dart';

@JS("#OnBackgroundListener_")
external set OnContentListener(JSFunction? f);

void main(List<String> args) async {
  if (mrtNull == null) {
    mrt = MRTWallet(JSObject());
  }
  final applicationId =
      Web3APPAuthentication.toApplicationId(jsWindow.location.origin);
  if (applicationId == null) {
    throw Web3RequestExceptionConst.invalidHost;
  }

  final completer = Completer<JSWebviewWallet>();
  bool onActivation(JSWalletEvent data) {
    try {
      final String clientId = mrt.scriptId;
      final walletEvent = data.toEvent();
      if (walletEvent == null || walletEvent.clientId != clientId) return false;
      if (walletEvent.type == WalletEventTypes.exception) {
        final message =
            Web3ExceptionMessage.deserialize(bytes: walletEvent.data);
        completer.completeError(message.toWalletError());
        return false;
      }
      if (walletEvent.type != WalletEventTypes.activation) {
        return false;
      }
      final wallet =
          JSWebviewWallet.initialize(request: walletEvent, clientId: clientId);
      completer.complete(wallet);
    } catch (e, s) {}
    return true;
  }

  mrt.onMrtMessage = onActivation.toJS;

  await completer.future;
}
