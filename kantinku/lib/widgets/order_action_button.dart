// file: lib/widgets/order_action_button.dart

import 'package:flutter/material.dart';

class OrderActionButton extends StatelessWidget {
  final String newStatus;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const OrderActionButton({
    super.key,
    required this.newStatus,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
