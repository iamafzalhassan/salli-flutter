import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'recipient.dart';

class ScannedCode extends Equatable {
  final Money? amount;

  final Recipient recipient;

  const ScannedCode({this.amount, required this.recipient});

  @override
  List<Object?> get props => [amount, recipient];
}
