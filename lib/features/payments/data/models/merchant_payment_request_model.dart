class MerchantPaymentRequestModel {
  final int amountCents;

  final String qr;

  final String? note;

  final Map<String, dynamic> approval;

  const MerchantPaymentRequestModel({required this.amountCents, required this.qr, this.note, required this.approval});

  Map<String, dynamic> toJson() => {'amountCents': amountCents, 'qr': qr, 'note': ?note, 'approval': approval};
}
