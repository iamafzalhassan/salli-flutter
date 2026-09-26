import 'package:equatable/equatable.dart';

class CardSecrets extends Equatable {
  final int expiryMonth;
  final int expiryYear;

  final String cvv;
  final String number;

  const CardSecrets({required this.expiryMonth, required this.expiryYear, required this.cvv, required this.number});

  @override
  List<Object?> get props => [expiryMonth, expiryYear, cvv, number];
}
