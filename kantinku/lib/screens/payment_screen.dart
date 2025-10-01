// file: screens/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/snackbar_utils.dart'; // <-- Gunakan package ini

class PaymentScreen extends StatefulWidget {
  final String redirectUrl;

  const PaymentScreen({super.key, required this.redirectUrl});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Gunakan GlobalKey untuk mengakses WebView jika diperlukan
  final GlobalKey webViewKey = GlobalKey(); 

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Mencegah pengguna menutup WebView tanpa menekan tombol kembali
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Pembayaran"),
          // Tombol kembali yang eksplisit menandakan pembatalan
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Kembali dengan hasil false (Pembayaran Dibatalkan)
              Navigator.pop(context, false);
            },
          ),
        ),
        body: InAppWebView(
          key: webViewKey,
          // Menggunakan WebUri untuk URL
          initialUrlRequest: URLRequest(url: WebUri(widget.redirectUrl)),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              javaScriptEnabled: true,
              // Penting untuk debugging
              useOnLoadResource: true, 
            ),
          ),
          onUpdateVisitedHistory: (controller, url, isReload) {
            // Logika Midtrans: Mendeteksi kata kunci status dari URL callback
            if (url != null) {
              final urlString = url.toString();
              
              if (urlString.contains("finish")) {
                // Pembayaran berhasil
                Navigator.pop(context, true); 
              } else if (urlString.contains("unfinish") || urlString.contains("error")) {
                // Pembayaran gagal/dibatalkan
                Navigator.pop(context, false);
              }
            }
          },
          onLoadError: (controller, url, code, message) {
            // Logika penanganan error loading
            SnackbarUtils.showMessage(context, 'Gagal memuat pembayaran: $message');
          }
        ),
      ),
    );
  }
}