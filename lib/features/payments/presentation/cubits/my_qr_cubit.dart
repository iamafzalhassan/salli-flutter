import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/money.dart';
import '../../../profile/domain/usecases/get_profile.dart';
import 'my_qr_state.dart';

class MyQrCubit extends Cubit<MyQrState> {
  final GetProfile _getProfile;

  MyQrCubit(this._getProfile) : super(const MyQrState());

  void amountChanged(Money? amount) => emit(state.copyWith(amount: () => amount != null && amount.isPositive ? amount : null));

  Future<void> load() async {
    emit(state.copyWith(failure: () => null, isLoading: true));
    final result = await _getProfile();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(isLoading: false, profile: () => value),
      Err(:final failure) => state.copyWith(failure: () => failure, isLoading: false),
    });
  }
}
