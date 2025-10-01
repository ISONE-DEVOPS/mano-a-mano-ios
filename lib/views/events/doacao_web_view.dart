import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DoacaoWebView extends StatefulWidget {
  const DoacaoWebView({super.key});

  @override
  State<DoacaoWebView> createState() => _DoacaoWebViewState();
}

class _DoacaoWebViewState extends State<DoacaoWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(
            Uri.parse(
              'https://www.pagali.cv/pagali/index.php?r=pgPaymentInterface/donatepaymentpage&id=3BC563D2-F9BB-BFAA-6B66-DD6B46DC0A00',
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doação')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
