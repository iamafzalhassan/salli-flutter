import '../../../payments/domain/entities/funding_source_type.dart';
import '../../domain/entities/funding_source.dart';

class FundingSourceModel {
  final String id;
  final String label;
  final String last4;
  final String type;

  final String? bankCode;
  final String? brand;

  const FundingSourceModel({required this.id, required this.label, required this.last4, required this.type, this.bankCode, this.brand});

  factory FundingSourceModel.fromJson(Map<String, dynamic> json) =>
      FundingSourceModel(id: json['id'] as String, label: json['label'] as String, last4: json['last4'] as String, type: json['type'] as String, bankCode: json['bankCode'] as String?, brand: json['brand'] as String?);

  FundingSource toEntity() => FundingSource(bankCode: bankCode, brand: brand, id: id, label: label, last4: last4, type: FundingSourceType.values.asNameMap()[type] ?? FundingSourceType.bank);
}
