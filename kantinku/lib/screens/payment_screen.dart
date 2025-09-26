import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatelessWidget {
  final String redirectUrl;
  const PaymentScreen({super.key, required this.redirectUrl});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // ✅ Midtrans redirect URL biasanya punya path: finish, unfinish, error
            if (url.contains("finish")) {
              Navigator.pop(context, true); // bayar berhasil
            } else if (url.contains("unfinish") || url.contains("error")) {
              Navigator.pop(context, false); // batal/gagal
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(redirectUrl));

    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: WebViewWidget(controller: controller),
    );
  }
}
