import 'package:qr_code_scanner/qr_code_scanner.dart';
// Usa package:web e js_util só no build Web; nas outras plataformas usa stubs seguros.
import 'web_stub/web_compat.dart' as web
    if (dart.library.js_interop) 'package:web/web.dart';

import 'web_stub/js_util_compat.dart' as js_util
    if (dart.library.js_interop) 'dart:js_util';

@override
Future<SystemFeatures> getSystemFeatures() async {
  // Web platform has limited control over camera hardware features.
  // We report all optional features as unavailable.
  try {
    final devicesPromise = web.window.navigator.mediaDevices.enumerateDevices();

    final dynamic sources = await js_util.promiseToFuture(devicesPromise);
    bool hasCamera = false;
    if (sources is List) {
      for (final e in sources) {
        final kind = (e as dynamic).kind as String?;
        if (kind == 'videoinput') {
          hasCamera = true;
          break;
        }
      }
    }
    return SystemFeatures(
      hasCamera,
      hasCamera,
      false,
    );
  } catch (e) {
    // Return defaults if any failure occurs
    return SystemFeatures(
      false,
      false,
      false,
    );
  }
}
