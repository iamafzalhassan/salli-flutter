class BillPaymentRequestModel {
  final int amountCents;

  final String accountNumber;
  final String billerId;

  final String? note;

  final Map<String, dynamic> approval;

  const BillPaymentRequestModel({required this.amountCents, required this.accountNumber, required this.billerId, this.note, required this.approval});

  Map<String, dynamic> toJson() => {'amountCents': amountCents, 'accountNumber': accountNumber, 'billerId': billerId, 'note': ?note, 'approval': approval};
}
