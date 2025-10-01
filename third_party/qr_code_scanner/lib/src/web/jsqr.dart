@JS()
library jsqr;

import 'package:js/js.dart';

@JS('jsQR')
external Code jsQR(Object data, int? width, int? height);

@JS()
class Code {
  external String get data;
}
