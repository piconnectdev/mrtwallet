import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:mrt_wallet/wroker/crypto/crypto.dart';
import 'package:mrt_wallet/wroker/models/response_message.dart';
import 'dart:js_interop';

@JS()
external set mrtJsHandler(JSFunction handler);

@JS()
external set mrtWalletActivation(JSFunction handler);

String _handler(String message) {
  final response = _cryptoHandler.sentResult(message);
  return BytesUtils.toHexString(response.toCbor().encode());
}

late _WebIsolateInitialData _cryptoHandler;
bool _init = false;

String _readKey() {
  if (_init) return "";
  _init = true;
  final key = QuickCrypto.generateRandom(32);
  _cryptoHandler = _WebIsolateInitialData(key: key);
  return BytesUtils.toHexString(key);
}

void main(List<String> args) {
  mrtJsHandler = _handler.toJS;
  mrtWalletActivation = _readKey.toJS;
}

class _WebIsolateInitialData {
  static const WalletCrypto crypto = WalletCrypto();
  final ChaCha20Poly1305 chacha;
  _WebIsolateInitialData({required List<int> key})
      : chacha = ChaCha20Poly1305(key);

  WorkerMessageResponse _getResult(List<int> message) {
    int? id;
    try {
      final encryptedMessage = WorkerEncryptedMessage.deserialize(message);
      id = encryptedMessage.id;
      final decode =
          chacha.decrypt(encryptedMessage.nonce, encryptedMessage.message);
      return crypto.handleMessage(decode!);
    } catch (e) {
      return WorkerMessageResponse(
          args: WalletCrypto.verificationFailed, id: id ?? -1);
    }
  }

  WorkerEncryptedMessage sentResult(String message) {
    final List<int>? messagesBytes = BytesUtils.tryFromHexString(message);
    WorkerMessageResponse? result;
    if (messagesBytes == null) {
      result = const WorkerMessageResponse(
          args: WalletCrypto.verificationFailed, id: -1);
    }
    result ??= _getResult(messagesBytes!);
    final encrypted = _toEncryptedMessage(result);
    return encrypted;
  }

  WorkerEncryptedMessage _toEncryptedMessage(WorkerMessageResponse request) {
    final nonce = QuickCrypto.generateRandom(16);
    final enc = chacha.encrypt(nonce, request.toCbor().encode());
    return WorkerEncryptedMessage(message: enc, nonce: nonce, id: request.id);
  }
}
