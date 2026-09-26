import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/scratch_card.dart';
import '../../domain/usecases/claim_referral.dart';
import '../../domain/usecases/get_offers.dart';
import '../../domain/usecases/get_rewards.dart';
import '../../domain/usecases/redeem_points.dart';
import '../../domain/usecases/reveal_scratch_card.dart';
import 'rewards_state.dart';

class RewardsCubit extends Cubit<RewardsState> {
  final ClaimReferral _claimReferral;

  final GetOffers _getOffers;

  final GetRewards _getRewards;

  final RedeemPoints _redeemPoints;

  final RevealScratchCard _revealScratchCard;

  RewardsCubit(this._claimReferral, this._getOffers, this._getRewards, this._redeemPoints, this._revealScratchCard) : super(const RewardsState());

  Future<Failure?> claimReferral(String code) async {
    if (state.isClaiming) return null;
    emit(state.copyWith(isClaiming: true));
    final result = await _claimReferral(code);
    if (isClosed) return null;
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(isClaiming: false, summary: () => value));
        return null;
      case Err(:final failure):
        emit(state.copyWith(isClaiming: false));
        return failure;
    }
  }

  Future<Failure?> redeem() async {
    final summary = state.summary;
    if (summary == null || summary.redeemablePoints == 0 || state.isRedeeming) return null;
    emit(state.copyWith(isRedeeming: true));
    final result = await _redeemPoints(summary.redeemablePoints, IdGenerator.next());
    if (isClosed) return null;
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(isRedeeming: false, summary: () => value));
        return null;
      case Err(:final failure):
        emit(state.copyWith(isRedeeming: false));
        return failure;
    }
  }

  Future<Result<ScratchCard>?> scratch(String cardId) async {
    if (state.scratchingId != null) return null;
    emit(state.copyWith(scratchingId: () => cardId));
    final result = await _revealScratchCard(cardId);
    if (isClosed) return result;
    emit(state.copyWith(scratchingId: () => null));
    if (result is Ok<ScratchCard>) await load();
    return result;
  }

  Future<void> load() async {
    if (state.summary == null) emit(state.copyWith(failure: () => null, status: RewardsStatus.loading));
    final (summary, offers) = await (_getRewards(), _getOffers()).wait;
    if (isClosed) return;
    emit(switch (summary) {
      Ok(:final value) => state.copyWith(
        failure: () => null,
        offers: switch (offers) {
          Ok(value: final offers) => offers,
          Err() => state.offers,
        },
        status: RewardsStatus.ready,
        summary: () => value,
      ),
      Err(:final failure) => state.copyWith(failure: () => failure, status: state.summary == null ? RewardsStatus.failure : RewardsStatus.ready),
    });
  }
}
