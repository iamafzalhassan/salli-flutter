import '../../../../core/utils/money.dart';
import '../../domain/entities/scratch_card.dart';

class ScratchCardModel {
  final int? amountCents;

  final String id;
  final String source;

  final DateTime earnedAt;

  const ScratchCardModel({this.amountCents, required this.id, required this.source, required this.earnedAt});

  factory ScratchCardModel.fromJson(Map<String, dynamic> json) => ScratchCardModel(amountCents: json['amountCents'] as int?, id: json['id'] as String, source: json['source'] as String, earnedAt: DateTime.parse(json['earnedAt'] as String));

  ScratchCard toEntity() {
    final amountCents = this.amountCents;
    return ScratchCard(earnedAt: earnedAt, id: id, prize: amountCents == null ? null : Money(amountCents), source: source);
  }
}
