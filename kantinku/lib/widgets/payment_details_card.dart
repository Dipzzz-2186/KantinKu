// file: lib/widgets/payment_details_card.dart

import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class PaymentDetailsCard extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Text('Metode: ${payment.paymentType}'),
        Text(
          'Status Pembayaran: ${payment.transactionStatus}',
          style: TextStyle(
            color:
                payment.transactionStatus.toLowerCase() == 'settlement' ||
                    payment.transactionStatus.toLowerCase() == 'paid'
                ? Colors.green
                : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('Jumlah Dibayar: Rp ${payment.grossAmount.toStringAsFixed(0)}'),
        if (payment.qrCodeUrl != null && payment.qrCodeUrl!.isNotEmpty) ...[
          Text('QR Code: ${payment.qrCodeUrl!}'),
        ],
        if (payment.settlementTime != null &&
            payment.settlementTime!.isNotEmpty)
          Text('Waktu Selesai: ${payment.settlementTime!}'),
      ],
    );
  }
}
