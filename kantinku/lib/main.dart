// file: main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/product_screen.dart';

// HAPUS SEMUA IMPORT WEBVIEW_FLUTTER
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() async {
 // 1. Pastikan binding Flutter sudah diinisialisasi
 WidgetsFlutterBinding.ensureInitialized();

 // 2. HAPUS SEMUA KODE INISIALISASI WEBVIEW_FLUTTER
 // Jika Anda menggunakan flutter_inappwebview, inisialisasi ini TIDAK diperlukan dan dapat dihapus.
 // if (!kIsWeb) { ... }

 // 3. Logic splash screen dan shared preferences
 final prefs = await SharedPreferences.getInstance();
 final isFirstRun = prefs.getBool('first_run') ?? true;

 if (isFirstRun) {
  await prefs.setBool('first_run', false);
 }

 // 4. Jalankan aplikasi
 runApp(MyApp(isFirstRun: isFirstRun));
}

class MyApp extends StatelessWidget {
 final bool isFirstRun;
 const MyApp({super.key, required this.isFirstRun});

 @override
 Widget build(BuildContext context) {
  return MaterialApp(
   debugShowCheckedModeBanner: false,
   title: 'Kantinku',
   theme: ThemeData(
    primarySwatch: Colors.green,
    fontFamily: 'Poppins',
   ),
   home: isFirstRun ? const SplashScreen() : const ProductScreen(),
  );
 }
}