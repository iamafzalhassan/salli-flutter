import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/rewards_summary.dart';

enum RewardsStatus { failure, loading, ready }

class RewardsState extends Equatable {
  final bool isClaiming;
  final bool isRedeeming;

  final String? scratchingId;

  final List<Offer> offers;

  final Failure? failure;

  final RewardsStatus status;

  final RewardsSummary? summary;

  const RewardsState({this.isClaiming = false, this.isRedeeming = false, this.scratchingId, this.offers = const [], this.failure, this.status = RewardsStatus.loading, this.summary});

  RewardsState copyWith({bool? isClaiming, bool? isRedeeming, String? Function()? scratchingId, List<Offer>? offers, Failure? Function()? failure, RewardsStatus? status, RewardsSummary? Function()? summary}) => RewardsState(
    isClaiming: isClaiming ?? this.isClaiming,
    isRedeeming: isRedeeming ?? this.isRedeeming,
    scratchingId: scratchingId == null ? this.scratchingId : scratchingId(),
    offers: offers ?? this.offers,
    failure: failure == null ? this.failure : failure(),
    status: status ?? this.status,
    summary: summary == null ? this.summary : summary(),
  );

  @override
  List<Object?> get props => [isClaiming, isRedeeming, scratchingId, offers, failure, status, summary];
}
