import 'package:web/web.dart' as web;
import 'dart:typed_data';
import 'dart:convert';

Future<void> saveBytesWeb(String filename, Uint8List bytes) async {
  // Usa Data URL para evitar interop com TypedArray / Blob JS diretamente
  final b64 = base64Encode(bytes);
  final dataUrl =
      'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$b64';

  final anchor =
      web.HTMLAnchorElement()
        ..href = dataUrl
        ..download = filename
        ..style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
