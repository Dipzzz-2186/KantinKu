import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.blur = 10.0,
    this.color = Colors.white,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(1.0), // Tingkat transparansi kaca
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor.withOpacity(0.5), // Warna outline/border
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}