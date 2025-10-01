// file: lib/utils/stub_html.dart

import 'dart:async';
import 'dart:typed_data';

// Define minimal interfaces for the html elements used in product_form.dart

class FileUploadInputElement {
  String accept = '';
  void click() {}
  // Menggunakan Stream.fromIterable([]) adalah yang paling aman
  Stream<dynamic> get onChange => Stream.fromIterable([]); 
  List<dynamic>? files;

  FileUploadInputElement(); // Tambahkan constructor eksplisit
}

class FileReader {
  void readAsArrayBuffer(dynamic file) {}
  Stream<dynamic> get onLoad => Stream.fromIterable([]);
  dynamic result;
}