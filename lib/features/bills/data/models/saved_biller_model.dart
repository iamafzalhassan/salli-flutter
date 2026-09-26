import '../../domain/entities/saved_biller.dart';
import 'biller_model.dart';

class SavedBillerModel {
  final String accountNumber;
  final String id;
  final String nickname;

  final BillerModel biller;

  const SavedBillerModel({required this.accountNumber, required this.id, required this.nickname, required this.biller});

  factory SavedBillerModel.fromJson(Map<String, dynamic> json) =>
      SavedBillerModel(accountNumber: json['accountNumber'] as String, id: json['id'] as String, nickname: json['nickname'] as String? ?? '', biller: BillerModel.fromJson(json['biller'] as Map<String, dynamic>));

  SavedBiller toEntity() => SavedBiller(accountNumber: accountNumber, biller: biller.toEntity(), id: id, nickname: nickname);
}
