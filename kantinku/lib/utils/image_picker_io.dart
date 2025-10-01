// file: lib/utils/image_picker_io.dart

import 'package:flutter/widgets.dart';
import 'dart:io';

// Widget Image.file yang sebenarnya
Widget buildImagePreviewWidget(String path) {
  return Image.file(File(path), height: 100, fit: BoxFit.cover);
}
