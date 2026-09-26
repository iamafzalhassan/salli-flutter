class TransferRequestModel {
  final int amountCents;

  final String recipientPhone;

  final String? note;
  final String? requestId;

  final Map<String, dynamic> approval;

  const TransferRequestModel({required this.amountCents, required this.recipientPhone, this.note, this.requestId, required this.approval});

  Map<String, dynamic> toJson() => {'amountCents': amountCents, 'recipientPhone': recipientPhone, 'note': ?note, 'requestId': ?requestId, 'approval': approval};
}
