// file: utils/dialog_utils.dart

import 'package:flutter/material.dart';
import 'package:kantinku/models/user_model.dart';
import 'package:kantinku/services/api_service.dart';
import 'package:kantinku/utils/snackbar_utils.dart';

class DialogUtils {
  static Future<User?> showLoginDialog(BuildContext context, ApiService api) async {
    String name = '';
    String password = '';

    return await showDialog<User>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nama Pengguna'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => password = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  // Panggil fungsi loginUser yang menerima nama dan password
                  final user = await api.loginUser(name, password);
                  Navigator.pop(context, user);
                  SnackbarUtils.showMessage(context, 'Login berhasil');
                } catch (e) {
                  SnackbarUtils.showMessage(context, 'Login gagal: ${e.toString()}');
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final newUser = await showRegisterDialog(context, api);
                if (newUser != null) {
                  SnackbarUtils.showMessage(context, 'Registrasi berhasil! Silakan login.');
                }
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  static Future<User?> showRegisterDialog(BuildContext context, ApiService api) async {
    String name = '';
    String phone = '';
    String password = '';

    return await showDialog<User>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nama Pengguna'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                onChanged: (value) => phone = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => password = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (name.isNotEmpty && phone.isNotEmpty && password.isNotEmpty) {
                  try {
                    final newUser = await api.createUser(name, phone, 'customer', password);
                    Navigator.pop(context, newUser);
                  } catch (e) {
                    SnackbarUtils.showMessage(context, 'Registrasi gagal: ${e.toString()}');
                    Navigator.pop(context);
                  }
                } else {
                  SnackbarUtils.showMessage(context, 'Semua bidang harus diisi');
                }
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }
}