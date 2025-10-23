// file: lib/utils/dialog_utils.dart

import 'package:flutter/material.dart';
import 'package:kantinku/models/user_model.dart';
import 'package:kantinku/services/api_service.dart';
import 'package:kantinku/utils/snackbar_utils.dart';

class DialogUtils {
  static Future<User?> showLoginDialog(
    BuildContext context,
    ApiService api,
  ) async {
    return await showDialog<User>(
      context: context,
      builder: (context) {
        return _AuthDialog(apiService: api);
      },
    );
  }
}

// WIDGET KUSTOM UNTUK DIALOG (PRIVATE)
class _AuthDialog extends StatefulWidget {
  final ApiService apiService;
  const _AuthDialog({required this.apiService});

  @override
  State<_AuthDialog> createState() => __AuthDialogState();
}

class __AuthDialogState extends State<_AuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF3F4F6), // Sedikit lebih terang
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }

  void _switchAuthMode() {
    _formKey.currentState?.reset();
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  Future<void> _submit() async {
     if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // Logika untuk Login
        final user = await widget.apiService.loginUser(
          _nameController.text,
          _passwordController.text,
        );
        if (mounted) Navigator.pop(context, user);
      } else {
        // Logika untuk Registrasi
        final newUser = await widget.apiService.registerUser(
          _nameController.text,
          _phoneController.text,
          _passwordController.text,
        );
        if (mounted) {
          SnackbarUtils.showMessage(context, 'Registrasi berhasil! Silakan login.');
          _switchAuthMode(); // Otomatis kembali ke mode login setelah sukses register
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst("Exception: ", "");
        SnackbarUtils.showMessage(context, 'Gagal: $errorMessage');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    // ============================================
    // PALET WARNA TEMA UNTUK DIALOG
    // ============================================
    const dialogBackgroundColor = Color(0xFFFAF8F1); // Krem sangat pucat
    const textFieldFillColor = Color(0xFFF3EFEA);    // Krem muda
    const accentColor = Color(0xFF6D4C41);           // Cokelat tua sebagai aksen
    const textColor = Color(0xFF4E342E);  // Abu-abu tua untuk teks
    // ============================================

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      // PERBAIKAN WARNA: Terapkan warna latar belakang dialog
      backgroundColor: dialogBackgroundColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLoginMode ? 'Selamat Datang' : 'Buat Akun Baru',
                      // PERBAIKAN WARNA: Terapkan warna teks
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Pengguna',
                      icon: Icons.person_outline,
                    ),
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Nomor Telepon',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // PERBAIKAN WARNA: Terapkan warna aksen
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isLoginMode ? 'Login' : 'Register'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _switchAuthMode,
                      style: TextButton.styleFrom(
                        // PERBAIKAN WARNA: Terapkan warna aksen
                        foregroundColor: accentColor,
                      ),
                      child: Text(
                        _isLoginMode
                            ? 'Belum punya akun? Daftar di sini'
                            : 'Sudah punya akun? Login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}