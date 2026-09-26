import '../../../../core/utils/money.dart';

abstract final class PaymentLimits {
  static const int maxNoteLength = 60;

  static const Money perPayment = Money.rupees(200000);
}
