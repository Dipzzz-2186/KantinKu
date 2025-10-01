// file: lib/utils/image_picker_stub.dart

import 'package:flutter/widgets.dart';

// Widget untuk menampilkan gambar di Web.
Widget buildImagePreviewWidget(String path) {
  // Di Web, path dari XFile adalah URL blob sementara, jadi kita gunakan Image.network.
  return Image.network(path, height: 100, fit: BoxFit.cover);
}
