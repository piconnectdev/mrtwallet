import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/app/error/exception/app_exception.dart';
import 'package:mrt_wallet/provider/api/excepion/exception.dart';
import 'package:http/http.dart' as http;

class MethodCaller {
  static Future<void> wait({int milliseconds = 1000}) async {
    return await Future.delayed(Duration(milliseconds: milliseconds));
  }

  static Future<void> _callWithCanclable<T>(
    Future<T> Function() t,
    Cancelable canclable,
  ) async {
    try {
      canclable.success(await t());
    } catch (e) {
      canclable.cancel(e);
    }
  }

  static Future<MethodResult<T>> retryCall<T>(
      Future<T> Function() t, bool Function(Object?) onExceptionRetry,
      {Cancelable? canclable, Duration? delay, int retry = 3}) async {
    if (delay != null) {
      await Future.delayed(delay);
    }
    for (int i = 0; i < retry; i++) {
      final result = await call(t, cancelable: canclable, delay: null);
      if (result.hasError) {
        if (result.isCancel) return result;
        if (i + 1 == retry) return result;
        if (onExceptionRetry(result.exception)) {
          continue;
        }
      }
      return result;
    }
    return call(t, cancelable: canclable, delay: null);
  }

  static Future<MethodResult<T>> call<T>(Future<T> Function() t,
      {Cancelable? cancelable, Duration? delay}) async {
    try {
      if (delay != null) {
        await Future.delayed(delay);
      }
      Future<T> r;
      if (cancelable == null) {
        r = t();
      } else {
        Completer<T> completer = Completer<T>();
        cancelable.setup(<T>() {
          return completer;
        });
        _callWithCanclable(t, cancelable);

        r = completer.future;
      }
      return MethodResult.succsess(await r);
    } catch (e, stackTrace) {
      return MethodResult.error(e, stackTrace);
    }
  }

  static Future<MethodResult<T>> httpCaller<T>(
      Future<http.Response> Function() t,
      {Cancelable? cancelable,
      Duration? delay}) async {
    try {
      if (delay != null) {
        await Future.delayed(delay);
      }
      Future<http.Response> r;
      if (cancelable == null) {
        r = t();
      } else {
        Completer<http.Response> completer = Completer<http.Response>();
        cancelable.setup(<T>() {
          return completer;
        });
        _callWithCanclable(t, cancelable);

        r = completer.future;
      }
      final response = await r;
      if (response.statusCode == 200) {
        if (T == String) return MethodResult.succsess(response.body as T);
        final toJson = StringUtils.toJson(response.body);
        return MethodResult.succsess(toJson as T);
      }
      final errorJson =
          nullOnException(() => StringUtils.toJson(response.body));
      throw ApiProviderException(
          statusCode: response.statusCode, message: errorJson?.toString());
    } on http.ClientException catch (e) {
      throw ApiProviderException(message: e.message);
    } on FormatException {
      throw const ApiProviderException(message: "invalid_json_response");
    } on TimeoutException catch (e) {
      throw ApiProviderException(message: e.message);
    } catch (e, stackTrace) {
      return MethodResult.error(e, stackTrace);
    }
  }

  static Stream<T> prediocCaller<T>(Future<MethodResult<T>> Function() t,
      {Duration waitOnError = const Duration(seconds: 1),
      Duration waitOnSuccess = const Duration(seconds: 10),
      required Cancelable canclable,
      bool closeOnSuccess = false}) async* {
    bool run = true;
    while (run) {
      Completer<void> completer = Completer();
      canclable.setup(() => completer);
      final result = await t();
      try {
        if (result.hasError) {
          await completer.future.timeout(waitOnError).catchError((e) {
            if (e is CancelableExption) {
              run = false;
            }
            return null;
          });
          continue;
        }

        yield result.result;

        if (closeOnSuccess) {
          run = false;
        } else {
          await completer.future.timeout(waitOnSuccess).catchError((e) {
            if (e is CancelableExption) {
              run = false;
            }
            return null;
          });
        }
      } finally {
        canclable.cancel();
      }
    }
  }

  static T? nullOnException<T>(T? Function() t, {T? defaultValue}) {
    try {
      return t();
    } catch (e) {
      return defaultValue;
    }
  }
}

class MethodResult<T> {
  MethodResult.error(this.exception, this.trace);
  MethodResult.succsess(this._result)
      : exception = null,
        trace = null;
  late final T _result;
  String? get error {
    if (exception == null) return null;
    if (exception is AppException ||
        exception is BlockchainUtilsException ||
        exception is ApiProviderException ||
        exception is RPCError ||
        exception is ArgumentError) {
      return exception!.toString();
    }

    return "somthing_wrong";
  }

  final Object? exception;
  final StackTrace? trace;
  bool get hasError => error != null;
  bool get hasResult => error == null;
  bool get isCancel => exception is CancelableExption;
  T get result => hasError ? throw WalletException(error!) : _result;
  bool get isBadCondition => exception is BadCondition;
  @override
  String toString() {
    if (hasError) {
      return "Error $error";
    }
    return "Success $result";
  }

  void rethrowIfError() {
    if (hasError) {
      throw exception!;
    }
  }
}

typedef CompleterResult = Completer Function();

class Cancelable<T> {
  CompleterResult? _setup;
  bool cancel([Object? exception]) {
    final completer = _setup?.call();
    if (completer?.isCompleted ?? true) return false;
    completer!.completeError(exception ?? const CancelableExption());
    _setup = null;
    return false;
  }

  void success(T result) {
    final completer = _setup?.call();
    if (completer?.isCompleted ?? true) return;
    completer!.complete(result);
    _setup = null;
  }

  void setup(CompleterResult setup) {
    assert(_setup == null, "please first complete or cancel");
    _setup = setup;
  }
}
