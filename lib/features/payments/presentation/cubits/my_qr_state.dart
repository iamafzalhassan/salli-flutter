import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/lanka_qr.dart';
import '../../../../core/utils/money.dart';
import '../../../profile/domain/entities/profile.dart';

class MyQrState extends Equatable {
  final bool isLoading;

  final Failure? failure;

  final Money? amount;

  final Profile? profile;

  const MyQrState({this.isLoading = true, this.failure, this.amount, this.profile});

  String? get payload {
    final profile = this.profile;
    if (profile == null) return null;
    return LankaQr.personal(amount: amount, name: profile.displayName ?? profile.phone.display, phone: profile.phone.e164).encode();
  }

  MyQrState copyWith({bool? isLoading, Failure? Function()? failure, Money? Function()? amount, Profile? Function()? profile}) =>
      MyQrState(isLoading: isLoading ?? this.isLoading, failure: failure == null ? this.failure : failure(), amount: amount == null ? this.amount : amount(), profile: profile == null ? this.profile : profile());

  @override
  List<Object?> get props => [isLoading, failure, amount, profile];
}
