// file: lib/utils/stub_io.dart

import 'dart:typed_data';

// HANYA definisikan class File (yang digunakan di _convertImageToBase64)

class File {
  final String path;
  File(this.path);

  Future<Uint8List> readAsBytes() async => Uint8List(0);
}
