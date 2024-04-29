import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';

import 'access_key_response.dart';

class AccessMnemonicResponse implements AccessKeyResponse {
  final Mnemonic mnemonic;
  const AccessMnemonicResponse(this.mnemonic);
}
