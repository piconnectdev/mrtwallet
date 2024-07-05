import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:mrt_wallet/app/error/exception/wallet_ex.dart';

mixin CborSerializable {
  CborTagValue toCbor();
  static CborTagValue toTagValue<T extends CborObject>(List<int> bytes,
      {List<int>? tags}) {
    final cbor = CborObject.fromCbor(bytes);
    if (cbor is! CborTagValue) {
      throw WalletExceptionConst.invalidSerializationData;
    }
    if (tags != null && !BytesUtils.bytesEqual(cbor.tags, tags)) {
      throw WalletExceptionConst.invalidSerializationData;
    }
    return cbor;
  }

  static T decodeCborTags<T extends CborObject>(
      List<int>? cborBytes, CborObject? object, List<int>? tags) {
    assert(cborBytes != null || object != null,
        "cbor bytes or cbor object must not be null");

    final cbor = object ?? CborObject.fromCbor(cborBytes!);

    return validateCbor(cbor, tags);
  }

  static T cborTagValue<T extends CborObject>({
    List<int>? cborBytes,
    CborObject? object,
    String? hex,
    List<int>? tags,
  }) {
    assert(cborBytes != null || object != null || hex != null,
        "cbor bytes or cbor object must not be null");
    if (object == null) {
      cborBytes ??= BytesUtils.tryFromHexString(hex);
      if (cborBytes == null) {
        throw WalletException(
            "decoding cbor required object, bytes or hex. no value provided for decoding.");
      }
      object = CborObject.fromCbor(cborBytes);
    }

    return validateCbor(object, tags);
  }

  static T validateCbor<T extends CborObject>(
      CborObject cbor, List<int>? tags) {
    if (cbor is! CborTagValue || cbor.value is! T) {
      throw WalletExceptionConst.invalidSerializationData;
    }
    if (tags != null && !BytesUtils.bytesEqual(cbor.tags, tags)) {
      throw WalletExceptionConst.invalidSerializationData;
    }
    return cbor.value;
  }

  static T decode<T extends CborObject>(List<int> bytes) {
    try {
      final cborObject = CborObject.fromCbor(bytes);
      if (cborObject is! T) {
        throw WalletException.invalidArgruments(
            ["$T" "${cborObject.runtimeType}"]);
      }
      return cborObject;
    } catch (e) {
      throw WalletExceptionConst.dataVerificationFailed;
    }

    // if (tags != null && !BytesUtils.bytesEqual(cbor.tags, tags)) {
    //   throw WalletException(
    //       "invalid cbor tags got ${cbor.tags} excepted $tags");
    // }
    // return cbor.value;
  }
}

extension ExtractCborList on CborListValue {
  T elementAt<T>(int index) {
    if (index > value.length - 1) return null as T;
    final cborValue = value[index];
    final dynamic v;
    if (cborValue is CborObject) {
      v = cborValue.value;
    } else {
      v = cborValue;
    }
    if (v is! T) return null as T;
    return v;
  }

  CborTagValue? getCborTag(int index) {
    if (index > value.length - 1) return null;
    final cborValue = value[index];
    if (cborValue is! CborObject) return null;
    if (cborValue is CborTagValue) return cborValue;
    if (cborValue.value is CborTagValue) return cborValue.value;
    return null;
  }

  int? getInt(int index) {
    if (index > value.length - 1) return null;
    final cborValue = value[index];
    int? v;
    if (cborValue is CborIntValue) {
      v = cborValue.value;
    } else if (cborValue is int) {
      v = cborValue;
    }
    return v;
  }

  String? getString(int index) {
    if (index > value.length - 1) return null;
    final cborValue = value[index];
    String? v;
    if (cborValue is CborStringValue) {
      v = cborValue.value;
    } else if (cborValue is String) {
      v = cborValue;
    }
    return v;
  }

  /// Gets the value at the specified [index] in the [CborListValue].
  ///
  /// If [index] is out of bounds and [T] is nullable, returns null. Otherwise, throws a [WalletException].
  T getElement<T>(int index) {
    if (index >= value.length) {
      if (null is T) return null as T;
      throw WalletExceptionConst.invalidSerializationData;
    }

    final CborObject obj = value.elementAt(index);
    if (null is T && obj == const CborNullValue()) {
      return null as T;
    }
    if (obj is T) return obj as T;
    if (obj.value is! T) {
      throw WalletExceptionConst.invalidSerializationData;
    }
    return obj.value;
  }
}

extension QuickCbor on CborObject {
  /// Converts the value of the [CborObject] to the specified type [E] using the provided function [toe].
  ///
  /// Throws a [WalletException] if the value cannot be converted to type [T].
  E to<E, T>(E Function(T e) toe) {
    if (this is T) {
      return toe(this as T);
    }
    if (value is! T) {
      throw WalletExceptionConst.invalidSerializationData;
    }
    return toe(value as T);
  }
}

extension QuickCborTag on CborTagValue {
  CborListValue get getList {
    if (value is! CborListValue) {
      throw WalletExceptionConst.invalidSerializationData;
    }
    return value;
  }

  T valueAs<T extends CborObject>() {
    if (value is! T) {
      throw WalletExceptionConst.invalidSerializationData;
    }
    return value;
  }
}
