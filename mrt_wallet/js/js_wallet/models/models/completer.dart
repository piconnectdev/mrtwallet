import 'dart:async';
import 'package:blockchain_utils/uuid/uuid.dart';
import 'package:mrt_wallet/wallet/web3/web3.dart';
import 'dart:js_interop';
import 'exception.dart';

class MessageCompleterHandler {
  final Map<String, MessageCompleter> _awaitingMessages = {};

  MessageCompleter createRequest() {
    final requestId = UUID.generateUUIDv4();
    final completer = MessageCompleter(requestId);
    _awaitingMessages[requestId] = completer;
    return completer;
  }

  bool hasRequest(String id) {
    return _awaitingMessages.containsKey(id);
  }

  void complete(
      {required Web3MessageCore response, required String? requestId}) {
    final completer = _awaitingMessages.remove(requestId);
    completer?.complete(response);
  }
}

class MessageCompleter {
  final String id;
  MessageCompleter(this.id);
  final Completer<Web3MessageCore> completer = Completer();

  void complete(Web3MessageCore value) {
    completer.complete(value);
  }
}

class PageRequestCompeleter {
  final String id;
  PageRequestCompeleter(this.id);
  final Completer<JSAny?> completer = Completer();
  void completeMessage(Object? object) {
    completer.complete(object.jsify());
  }

  void completerError(Map<String, dynamic> error) {
    final walletError = JSWalletError.fromJson(message: error);
    completer.completeError(walletError);
  }
}
