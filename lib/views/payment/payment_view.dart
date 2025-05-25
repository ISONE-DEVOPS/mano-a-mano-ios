import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../profile/profile_view.dart';

class PaymentView extends StatefulWidget {
  final String eventId;
  final double amount;
  const PaymentView({
    super.key,
    required this.eventId,
    required this.amount,
  });

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  late final WebViewController _controller;
  late final String checkoutUrl;

  @override
  void initState() {
    super.initState();
    checkoutUrl = Uri.https(
      'pagali.cv',
      '/checkout',
      {
        'event': widget.eventId,
        'amount': widget.amount.toStringAsFixed(2),
      },
    ).toString();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('/success')) {
              Get.offAll(() => const ProfileView());
              return NavigationDecision.prevent;
            }
            if (url.contains('/cancel')) {
              Get.back();
              Get.snackbar('Pagamento', 'Pagamento cancelado.');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: WebViewWidget(controller: _controller),
    );
  }
}