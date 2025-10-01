class Payment {
  final int? id;
  final int orderId;
  final String? transaksiId;
  final String? statusCode;
  final String transactionStatus;
  final double grossAmount;
  final String paymentType;
  final String? qrCodeUrl;
  final String? transactionTime;
  final String? settlementTime;
  final String? signatureKey;

  Payment({
    this.id,
    required this.orderId,
    this.transaksiId,
    this.statusCode,
    required this.transactionStatus,
    required this.grossAmount,
    required this.paymentType,
    this.qrCodeUrl,
    this.transactionTime,
    this.settlementTime,
    this.signatureKey,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['order_id'],
      transaksiId: json['transaksi_id'],
      statusCode: json['status_code'],
      transactionStatus: json['transaction_status'],
      grossAmount: (json['gross_amount'] as num).toDouble(),
      paymentType: json['payment_type'],
      qrCodeUrl: json['qr_code_url'],
      transactionTime: json['transaction_time'],
      settlementTime: json['settlement_time'],
      signatureKey: json['signature_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "order_id": orderId,
      "transaksi_id": transaksiId,
      "status_code": statusCode,
      "transaction_status": transactionStatus,
      "gross_amount": grossAmount,
      "payment_type": paymentType,
      "qr_code_url": qrCodeUrl,
      "transaction_time": transactionTime,
      "settlement_time": settlementTime,
      "signature_key": signatureKey,
    };
  }
}
