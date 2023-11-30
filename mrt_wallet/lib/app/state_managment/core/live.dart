part of 'package:mrt_wallet/app/state_managment/state_managment.dart';

mixin _LiveListenable {
  final Set<DynamicVoid> _noneIdsListeners = {};

  void addListener(DynamicVoid callBack) {
    _noneIdsListeners.add(callBack);
  }

  void removeListener(DynamicVoid callBack) {
    _noneIdsListeners.remove(callBack);
  }

  void notify() {
    for (DynamicVoid i in [..._noneIdsListeners]) {
      i();
    }
  }
}

/// a Component that can track changes in a reactive variable
mixin StatelessObserver on StatelessElement {
  void _update() {
    if (mounted) {
      scheduleMicrotask(markNeedsBuild);
    }
  }

  @override
  Widget build() {
    return LiveListenable._sycronizedBuld(_update, super.build);
  }
}

class LiveElement extends StatelessElement with StatelessObserver {
  LiveElement(super.widget);
}

abstract class LiveStatelessWidget extends StatelessWidget {
  const LiveStatelessWidget({Key? key}) : super(key: key);
  @override
  StatelessElement createElement() => LiveElement(this);
}

class LiveListenable<T> with _LiveListenable {
  LiveListenable(T val) : _value = val;

  static DynamicVoid? _listener;

  static void _addListener(_LiveListenable listenable) {
    final listener = _listener;
    if (listener != null) {
      listenable.addListener(listener);
    }
  }

  static Widget _sycronizedBuld(
      DynamicVoid listener, Widget Function() builder) {
    _listener = listener;
    final build = builder();

    _listener = null;
    return build;
  }

  void dispose() {
    _noneIdsListeners.clear();
  }

  T _value;

  T get value {
    _addListener(this);
    return _value;
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notify();
  }
}

abstract class _Live<T> extends LiveListenable<T> {
  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object o) {
    if (o is T) return value == o;
    if (o is LiveListenable<T>) return value == o.value;
    return false;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  set value(T val) {
    super.value = val;
  }

  _Live(T initial) : super(initial);
}

class Live<T> extends _Live<T> {
  Live(T initial) : super(initial);
}
