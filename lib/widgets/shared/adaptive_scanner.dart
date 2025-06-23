import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

/// Só importa se Android
import 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.io) 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.html) 'mobile_scanner_placeholder.dart';

class AdaptiveScanner extends StatelessWidget {
  final void Function(BarcodeCapture) onDetect;
  final MobileScannerController controller;

  const AdaptiveScanner({
    super.key,
    required this.onDetect,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return MobileScanner(controller: controller, onDetect: onDetect);
    } else {
      return const Center(
        child: Text("Scanner indisponível neste dispositivo."),
      );
    }
  }
}
