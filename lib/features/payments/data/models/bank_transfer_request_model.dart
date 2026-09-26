class BankTransferRequestModel {
  final int amountCents;

  final String accountNumber;
  final String bankCode;

  final String? branchCode;
  final String? note;

  final Map<String, dynamic> approval;

  const BankTransferRequestModel({required this.amountCents, required this.accountNumber, required this.bankCode, this.branchCode, this.note, required this.approval});

  Map<String, dynamic> toJson() => {'amountCents': amountCents, 'accountNumber': accountNumber, 'bankCode': bankCode, 'branchCode': ?branchCode, 'note': ?note, 'approval': approval};
}
