class FundingRequestModel {
  final int amountCents;

  final String sourceId;

  final Map<String, dynamic> approval;

  const FundingRequestModel({required this.amountCents, required this.sourceId, required this.approval});

  Map<String, dynamic> toJson() => {'amountCents': amountCents, 'sourceId': sourceId, 'approval': approval};
}
