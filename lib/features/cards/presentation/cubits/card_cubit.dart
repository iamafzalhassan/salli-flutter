import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/domain/usecases/get_biometric_status.dart';
import '../../domain/entities/virtual_card.dart';
import '../../domain/usecases/freeze_card.dart';
import '../../domain/usecases/get_card.dart';
import '../../domain/usecases/get_card_transactions.dart';
import '../../domain/usecases/make_test_purchase.dart';
import '../../domain/usecases/reveal_card.dart';
import '../../domain/usecases/set_card_limit.dart';
import 'card_state.dart';

class CardCubit extends Cubit<CardState> {
  static const Set<String> pinFallbackCodes = {
    FailureCodes.approvalInvalid,
    FailureCodes.biometricCancelled,
    FailureCodes.biometricInvalidated,
    FailureCodes.biometricLockout,
    FailureCodes.biometricNotEnrolled,
    FailureCodes.biometricUnavailable,
  };

  static const Duration defaultRevealDuration = Duration(seconds: 30);

  final Duration _revealDuration;

  final FreezeCard _freezeCard;

  final GetBiometricStatus _getBiometricStatus;

  final GetCard _getCard;

  final GetCardTransactions _getCardTransactions;

  final MakeTestPurchase _makeTestPurchase;

  final RevealCard _revealCard;

  final SetCardLimit _setCardLimit;

  Timer? _hideTimer;

  CardCubit(this._freezeCard, this._getBiometricStatus, this._getCard, this._getCardTransactions, this._makeTestPurchase, this._revealCard, this._setCardLimit, [this._revealDuration = defaultRevealDuration]) : super(const CardState());

  void hide() {
    _hideTimer?.cancel();
    emit(state.copyWith(secrets: () => null));
  }

  Future<void> load() async {
    final (card, biometrics) = await (_getCard(), _getBiometricStatus()).wait;
    if (isClosed) return;
    switch (card) {
      case Ok(:final value):
        final transactions = await _getCardTransactions(value.id);
        if (isClosed) return;
        emit(
          state.copyWith(
            canUseBiometrics: biometrics.canUse,
            card: () => value,
            failure: () => null,
            status: CardLoadStatus.ready,
            transactions: switch (transactions) {
              Ok(:final value) => value,
              Err() => state.transactions,
            },
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(failure: () => failure, status: state.card == null ? CardLoadStatus.failure : CardLoadStatus.ready));
    }
  }

  Future<Failure?> reveal(Authorization authorization) async {
    final card = state.card;
    if (card == null || state.isBusy) return null;
    emit(state.copyWith(failure: () => null, isBusy: true));
    final result = await _revealCard(card.id, authorization);
    if (isClosed) return null;
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(isBusy: false, secrets: () => value));
        _hideTimer?.cancel();
        _hideTimer = Timer(_revealDuration, () {
          if (!isClosed) emit(state.copyWith(secrets: () => null));
        });
        return null;
      case Err(:final failure):
        final isSilent = failure.code == FailureCodes.biometricCancelled;
        emit(state.copyWith(canUseBiometrics: state.canUseBiometrics && failure.code != FailureCodes.biometricInvalidated, failure: () => isSilent ? null : failure, isBusy: false));
        return failure;
    }
  }

  Future<void> setFrozen(bool isFrozen) => _update((card) => _freezeCard(card.id, isFrozen: isFrozen));

  Future<void> setLimit(Money limit) => _update((card) => _setCardLimit(card.id, limit));

  Future<void> testPurchase() async {
    final card = state.card;
    if (card == null || state.isBusy) return;
    emit(state.copyWith(failure: () => null, isBusy: true));
    final result = await _makeTestPurchase(card.id);
    if (isClosed) return;
    emit(
      state.copyWith(
        failure: () => switch (result) {
          Ok() => null,
          Err(:final failure) => failure,
        },
        isBusy: false,
      ),
    );
    await load();
  }

  Future<void> _update(Future<Result<VirtualCard>> Function(VirtualCard card) action) async {
    final card = state.card;
    if (card == null || state.isBusy) return;
    emit(state.copyWith(failure: () => null, isBusy: true));
    final result = await action(card);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(card: () => value, isBusy: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isBusy: false),
    });
  }

  @override
  Future<void> close() {
    _hideTimer?.cancel();
    return super.close();
  }
}
