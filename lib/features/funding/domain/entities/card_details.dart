import 'package:equatable/equatable.dart';

class CardDetails extends Equatable {
  final int expiryMonth;
  final int expiryYear;

  final String cvv;
  final String number;

  const CardDetails({required this.expiryMonth, required this.expiryYear, required this.cvv, required this.number});

  @override
  List<Object?> get props => [expiryMonth, expiryYear, cvv, number];
}
