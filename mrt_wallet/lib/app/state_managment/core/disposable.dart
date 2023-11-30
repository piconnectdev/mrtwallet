part of 'package:mrt_wallet/app/state_managment/state_managment.dart';

abstract class Core {}

abstract class BaseController extends Core {}

mixin ListenableX {
  final Map<String, DynamicVoid> _listeners = {};
  final Set<DynamicVoid> _noneIdsListeners = {};
  void addListener(String? id, DynamicVoid callBack) {
    if (id == null) {
      _noneIdsListeners.add(callBack);
      return;
    }
    _listeners[id] = callBack;
  }

  void removeListener(String? id, DynamicVoid callBack) {
    if (id != null) {
      _listeners.remove(id);
      return;
    }
    _noneIdsListeners.remove(callBack);
  }

  void notify([String? id]) {
    if (id != null) {
      _listeners[id]?.call();
      return;
    }
    for (DynamicVoid i in [..._noneIdsListeners]) {
      i();
    }
  }
}

abstract class Disposable extends BaseController with ListenableX {
  bool _inited = false;
  bool _deleted = false;
  void close() {}
  void _close() {
    if (_deleted) return;
    _deleted = true;
    close();
  }

  void _start() {
    if (_inited) return;
    _inited = true;
    init();
  }

  void init() {
    WidgetsFlutterBinding.ensureInitialized()
        .addPostFrameCallback((timeStamp) => ready());
  }

  void ready() {}
}

abstract class StateController extends Disposable {
  String get repositoryId;
}
