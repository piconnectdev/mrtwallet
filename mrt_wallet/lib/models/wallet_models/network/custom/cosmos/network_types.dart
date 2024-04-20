import 'package:blockchain_utils/exception/exception.dart';

class CosmosNetworkTypes {
  final int value;
  const CosmosNetworkTypes._(this.value);
  static const CosmosNetworkTypes main = CosmosNetworkTypes._(0);
  static const CosmosNetworkTypes forked = CosmosNetworkTypes._(1);
  static const CosmosNetworkTypes thorAndForked = CosmosNetworkTypes._(2);
  static const List<CosmosNetworkTypes> values = [main, forked, thorAndForked];
  factory CosmosNetworkTypes.fromValue(int value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw MessageException(
          "No CosmosNetworkTypes element found for the given value.",
          details: {"value": value}),
    );
  }
}
