class ReloadRequestModel {
  final int amountCents;

  final String phone;

  final String? note;
  final String? planId;

  final Map<String, dynamic> approval;

  const ReloadRequestModel({required this.amountCents, required this.phone, this.note, this.planId, required this.approval});

  Map<String, dynamic> toJson() => {'amountCents': amountCents, 'phone': phone, 'note': ?note, 'planId': ?planId, 'approval': approval};
}
