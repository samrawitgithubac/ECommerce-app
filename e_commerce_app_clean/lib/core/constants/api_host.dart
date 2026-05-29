import 'package:flutter/foundation.dart';

/// API server address
///
/// - **Chrome on PC:** `http://localhost:3000`
/// - **Phone browser** (same Wi‑Fi, open `http://YOUR_PC_IP:8080`): uses `http://YOUR_PC_IP:3000` automatically
/// - **Native Android app:** set [kMobileApiHost] to your PC IPv4 (`ipconfig`)
/// - **Android emulator:** `http://10.0.2.2:3000`
///
/// Phone and PC must be on the **same Wi‑Fi**. Backend: `npm start` in `backend/`.
const String kMobileApiHost = 'http://10.4.99.119:3000';

String get kApiHost {
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:3000';
    }
    return 'http://$host:3000';
  }
  return kMobileApiHost;
}
