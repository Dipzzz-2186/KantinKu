import 'package:flutter/material.dart';
import '../widgets/custom_notification.dart';

class SnackbarUtils {
  static OverlayEntry? _overlayEntry;
  static void showMessage(BuildContext context, String message) {
    // FIX: Cek apakah context masih valid sebelum melakukan apapun.
    if (!context.mounted) return;

    // FIX: Hanya hapus overlay jika benar-benar ada.
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    // Buat OverlayEntry baru
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // Posisi di bawah AppBar
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
        right: 16, // FIX: Posisikan di kanan
        // left tidak di-set agar lebarnya sesuai konten
        child: Material(
          color: Colors.transparent,
          child: CustomNotification(
            message: message,
            onDismiss: () {
              if (_overlayEntry != null) {
                _overlayEntry?.remove();
                _overlayEntry = null;
              }
            },
          ),
        ),
      ),
    );

    // Tampilkan Overlay
    // FIX: Gunakan Overlay.of(context) yang aman
    final overlay = Overlay.of(context);
    overlay.insert(_overlayEntry!);

    // Atur timer untuk menghapus overlay jika tidak hilang sendiri
    Future.delayed(const Duration(seconds: 4), () {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }
}
