import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kantinku/screens/product_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProductScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.jpeg', // FIX: Path aset diperbaiki
              width: 150, // Anda bisa sesuaikan ukurannya
              height: 150, // Anda bisa sesuaikan ukurannya
            ),
            const SizedBox(height: 20),
            const Text(
              "KantinKu",
              style: TextStyle(
                fontSize: 26,
                color: Colors.black54, // FIX: Warna teks diubah agar terlihat
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.green,
            ), // FIX: Warna indikator diubah
          ],
        ),
      ),
    );
  }
}
