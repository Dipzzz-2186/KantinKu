// file: lib/widgets/product_image_display.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProductImageDisplay extends StatelessWidget {
  final String? imageString;
  final double width;
  final double height;
  final BoxFit fit;
  final IconData placeholderIcon;
  final double iconSize;

  const ProductImageDisplay({
    super.key,
    this.imageString,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.fastfood,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (imageString == null || imageString!.isEmpty) {
      return Icon(placeholderIcon, size: iconSize, color: Colors.grey);
    }

    // FIX: Perbaiki deteksi Base64.
    // URL bisa jadi sangat panjang, jadi jangan andalkan panjangnya.
    // Cukup cek apakah string diawali dengan 'data:image' atau tidak mengandung karakter URL umum.
    // Heuristik yang lebih baik: jika tidak dimulai dengan http, anggap itu base64.
    final isUrl =
        imageString!.startsWith('http://') ||
        imageString!.startsWith('https://');
    final isBase64 = !isUrl;

    if (isBase64) {
      try {
        String cleanBase64 = imageString!.startsWith('data:image')
            ? imageString!.split(',').last
            : imageString!;
        Uint8List bytes = base64Decode(cleanBase64);

        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image, size: iconSize, color: Colors.red),
        );
      } catch (e) {
        // Fallback if Base64 decoding fails
        return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
      }
    } else {
      // Assume it's a URL
      return Image.network(
        imageString!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.image_not_supported, size: iconSize, color: Colors.grey),
      );
    }
  }
}
