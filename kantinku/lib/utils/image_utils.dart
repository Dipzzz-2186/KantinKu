import 'dart:convert';
import 'package:flutter/material.dart';

class ImageUtils {
  static ImageProvider? decodeBase64(String? base64String){
    if(base64String == null || base64String.isEmpty) return null;
    try{
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch(_){
      return null;
    }
  }
}