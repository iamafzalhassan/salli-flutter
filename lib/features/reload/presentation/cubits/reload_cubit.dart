import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/mobile_operator.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/payment_draft.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../../profile/domain/usecases/get_profile.dart';
import '../../domain/entities/reload_catalog.dart';
import '../../domain/entities/reload_kind.dart';
import '../../domain/entities/reload_plan.dart';
import '../../domain/usecases/get_recent_reloads.dart';
import '../../domain/usecases/get_reload_catalog.dart';
import 'reload_state.dart';

class ReloadCubit extends Cubit<ReloadState> {
  final Map<MobileOperator, ReloadCatalog> _catalogs = {};

  final GetProfile _getProfile;

  final GetRecentReloads _getRecentReloads;

  final GetReloadCatalog _getReloadCatalog;

  ReloadCubit(this._getProfile, this._getRecentReloads, this._getReloadCatalog) : super(const ReloadState());

  void amountChosen(Money amount) => _chooseDraft(amount, null);

  void clearResult() => emit(state.copyWith(draft: () => null, recipient: () => null));

  void kindSelected(ReloadKind? kind) => emit(state.copyWith(kind: () => kind));

  Future<void> load() async {
    final (profile, recents) = await (_getProfile(), _getRecentReloads()).wait;
    if (isClosed) return;
    final ownPhone = switch (profile) {
      Ok(:final value) => value.phone,
      Err() => null,
    };
    emit(
      state.copyWith(
        ownPhone: () => ownPhone,
        recents: switch (recents) {
          Ok(:final value) => value,
          Err() => const [],
        },
      ),
    );
    if (state.phone == null && ownPhone != null) await numberChosen(ownPhone);
  }

  Future<void> numberChosen(PhoneNumber phone) async {
    emit(state.copyWith(failure: () => null, phone: () => phone));
    await _loadCatalog(phone.carrier);
  }

  void otherAmount() {
    final phone = state.phone;
    if (phone != null) emit(state.copyWith(recipient: () => ReloadRecipient(phone: phone)));
  }

  Future<void> phoneChanged(String input) async {
    final phone = PhoneNumber.tryParse(input);
    if (phone == state.phone) return;
    if (phone == null) {
      emit(state.copyWith(catalog: () => null, phone: () => null));
      return;
    }
    await numberChosen(phone);
  }

  void planChosen(ReloadPlan plan) => _chooseDraft(plan.amount, plan);

  Future<void> _loadCatalog(MobileOperator operator) async {
    final cached = _catalogs[operator];
    if (cached != null) {
      emit(state.copyWith(catalog: () => cached, isLoadingCatalog: false));
      return;
    }
    emit(state.copyWith(catalog: () => null, isLoadingCatalog: true));
    final result = await _getReloadCatalog(operator);
    if (isClosed || state.phone?.carrier != operator) return;
    switch (result) {
      case Ok(:final value):
        _catalogs[operator] = value;
        emit(state.copyWith(catalog: () => value, isLoadingCatalog: false));
      case Err(:final failure):
        emit(state.copyWith(failure: () => failure, isLoadingCatalog: false));
    }
  }

  void _chooseDraft(Money amount, ReloadPlan? plan) {
    final phone = state.phone;
    if (phone == null) return;
    final recipient = ReloadRecipient(phone: phone, planId: plan?.id, planName: plan?.name);
    emit(
      state.copyWith(
        draft: () => PaymentDraft(amount: amount, idempotencyKey: IdGenerator.next(), recipient: recipient),
      ),
    );
  }
}
