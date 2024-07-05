import 'dart:async';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:mrt_wallet/wallet/api/provider/networks/bitcoin/providers/electrum.dart';
import 'package:mrt_wallet/wallet/api/services/impl/protocols.dart';
import 'package:mrt_wallet/wallet/api/services/models/models.dart';
import 'electrum_service.dart';

class ElectrumSSLSocketService extends SSLService<ElectrumAPIProvider>
    implements ElectrumService {
  ElectrumSSLSocketService({
    required super.url,
    required super.provider,
    this.defaultRequestTimeOut = const Duration(seconds: 30),
  });
  final Duration defaultRequestTimeOut;
  @override
  Future<Map<String, dynamic>> call(ElectrumRequestDetails params,
      [Duration? timeout]) async {
    final SocketRequestCompeleter message =
        SocketRequestCompeleter(StringUtils.fromJson(params.params), params.id);
    return await post(message, timeout ?? defaultRequestTimeOut);
  }
}
