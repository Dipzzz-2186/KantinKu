// file: lib/utils/image_picker_utils.dart (File Jembatan)

// Ekspor implementasi yang benar berdasarkan platform.
export 'image_picker_stub.dart' // Implementasi untuk Web
    if (dart.library.io) 'image_picker_io.dart'; // Implementasi untuk Mobile/Desktop
