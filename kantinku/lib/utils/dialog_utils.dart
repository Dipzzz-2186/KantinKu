// file: utils/dialog_utils.dart

import 'package:flutter/material.dart';
import 'package:kantinku/models/user_model.dart';
import 'package:kantinku/services/api_service.dart';
import 'package:kantinku/utils/snackbar_utils.dart';

class DialogUtils {
  static Future<User?> showLoginDialog(
    BuildContext context,
    ApiService api,
  ) async {
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
                  if (context.mounted) Navigator.pop(context, user);
                } catch (e) {
                  SnackbarUtils.showMessage(
                    context,
                    'Login gagal: ${e.toString()}',
                  );
                  // FIX: Jangan pop dialog saat gagal, biarkan user melihat error.
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () async {
                // FIX: Simpan BuildContext dari LoginDialog sebelum menutupnya.
                final loginDialogContext = context;
                Navigator.pop(loginDialogContext); // Tutup dialog login

                // Panggil dialog registrasi
                final newUser = await showRegisterDialog(context, api);

                // Setelah dialog registrasi ditutup, jika berhasil,
                // tampilkan kembali dialog login agar pengguna bisa langsung login.
                // Pesan sukses sudah ditangani di dalam showRegisterDialog.
                if (newUser != null) await showLoginDialog(context, api);
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  static Future<User?> showRegisterDialog(
    BuildContext context,
    ApiService api,
  ) async {
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
                if (name.isNotEmpty &&
                    phone.isNotEmpty &&
                    password.isNotEmpty) {
                  try {
                    // FIX: Gunakan registerUser yang endpointnya lebih sesuai
                    final newUser = await api.registerUser(
                      name,
                      phone,
                      password,
                    );
                    // FIX: Cek apakah context masih valid sebelum menampilkan Snackbar dan pop.
                    // 'mounted' adalah cara standar untuk memeriksa ini di dalam State object,
                    // tapi karena ini di dalam builder, kita perlu memastikan context-nya masih di tree.
                    if (context.mounted) {
                      SnackbarUtils.showMessage(
                        context,
                        'Registrasi berhasil! Silakan login.',
                      );
                      // Tunggu sebentar agar pesan terlihat, lalu tutup.
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (context.mounted) {
                        Navigator.pop(context, newUser);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarUtils.showMessage(
                        context,
                        // 'Registrasi gagal: ${e.toString().replaceFirst("Exception: ", "")}',
                        'Sudah ada pengguna dengan nama tersebut.',
                      );
                    }
                    // FIX: Jangan pop dialog saat gagal.
                  }
                } else {
                  SnackbarUtils.showMessage(
                    context,
                    'Semua bidang harus diisi',
                  );
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
