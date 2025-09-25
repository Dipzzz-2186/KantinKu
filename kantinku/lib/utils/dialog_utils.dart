// The existing DialogUtils class
import 'package:flutter/material.dart';
import 'package:kantinku/models/user_model.dart';
import 'package:kantinku/services/api_service.dart';
import 'package:kantinku/utils/snackbar_utils.dart';

class DialogUtils {
  static Future<User?> showLoginDialog(BuildContext context, ApiService api) async {
    String name = '';
    String phone = '';
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
                decoration: const InputDecoration(labelText: 'Nama'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                onChanged: (value) => phone = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => password = value,
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final users = await api.fetchUsers();
                final user = users.firstWhere(
                  (u) => u.nomorTelepon == phone && u.password == password,
                  orElse: () => User(
                    id: 0,
                    namaPengguna: '',
                    nomorTelepon: '',
                    role: '',
                    password: '',
                  ),
                );
                if (user.id != 0) {
                  Navigator.pop(context, user);
                  SnackbarUtils.showMessage(context, 'Login berhasil');
                } else {
                  SnackbarUtils.showMessage(context, 'Login gagal');
                }
              },
              child: const Text('Login'),
            ),
            TextButton( // Add a new button for registration
              onPressed: () async {
                Navigator.pop(context); // Close the login dialog
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

  // New method for the registration dialog
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
                decoration: const InputDecoration(labelText: 'Nama'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                onChanged: (value) => phone = value,
              ),
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
                    Navigator.pop(context); // Close the dialog on failure
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