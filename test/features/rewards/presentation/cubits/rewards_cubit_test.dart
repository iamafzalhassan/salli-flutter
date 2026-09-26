import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/payments/domain/entities/merchant.dart';
import 'package:salli/features/payments/domain/entities/merchant_category.dart';
import 'package:salli/features/rewards/domain/entities/offer.dart';
import 'package:salli/features/rewards/domain/entities/referral.dart';
import 'package:salli/features/rewards/domain/entities/rewards_summary.dart';
import 'package:salli/features/rewards/domain/entities/scratch_card.dart';
import 'package:salli/features/rewards/domain/repositories/rewards_repository.dart';
import 'package:salli/features/rewards/domain/usecases/claim_referral.dart';
import 'package:salli/features/rewards/domain/usecases/get_offers.dart';
import 'package:salli/features/rewards/domain/usecases/get_rewards.dart';
import 'package:salli/features/rewards/domain/usecases/redeem_points.dart';
import 'package:salli/features/rewards/domain/usecases/reveal_scratch_card.dart';
import 'package:salli/features/rewards/presentation/cubits/rewards_cubit.dart';
import 'package:salli/features/rewards/presentation/cubits/rewards_state.dart';

final ScratchCard _card = ScratchCard(earnedAt: DateTime.utc(2026, 9, 21), id: 'card-1', source: 'Salli Rewards');

RewardsSummary _summary({int points = 740, List<ScratchCard>? cards}) => RewardsSummary(
  cashback: Money.zero,
  minRedeemPoints: 500,
  points: points,
  pointStep: 100,
  pointValue: const Money(10),
  referral: const Referral(canClaim: true, code: 'SALLIABCD', joinedCount: 0, reward: Money.rupees(250)),
  scratchCards: cards ?? [_card],
);

class _FakeRewardsRepository implements RewardsRepository {
  final List<(int, String)> redemptions = [];

  final List<String> claims = [];
  final List<String> scratched = [];

  Result<RewardsSummary> claim = Ok(_summary());
  Result<RewardsSummary> summary = Ok(_summary());

  Result<ScratchCard> scratchResult = Ok(ScratchCard(earnedAt: DateTime.utc(2026, 9, 21), id: 'card-1', prize: const Money(2500), source: 'Salli Rewards'));

  @override
  Future<Result<RewardsSummary>> claimReferral(String code) async {
    claims.add(code);
    return claim;
  }

  @override
  Future<Result<List<Offer>>> getOffers() async => Ok([
    Offer(
      cashbackPercent: 10,
      expiresAt: DateTime.utc(2026, 10),
      id: 'offer-java',
      isUsed: false,
      maxCashback: const Money.rupees(300),
      merchant: const Merchant(category: MerchantCategory.dining, city: 'Colombo 03', id: 'LKQR00000004', name: 'Java Lounge'),
      minSpend: const Money.rupees(1000),
      qr: 'qr',
    ),
  ]);

  @override
  Future<Result<RewardsSummary>> getRewards() async => summary;

  @override
  Future<Result<RewardsSummary>> redeemPoints(int points, String idempotencyKey) async {
    redemptions.add((points, idempotencyKey));
    return Ok(_summary(points: 40));
  }

  @override
  Future<Result<ScratchCard>> scratch(String cardId) async {
    scratched.add(cardId);
    return scratchResult;
  }
}

void main() {
  late _FakeRewardsRepository repository;

  RewardsCubit cubit() => RewardsCubit(ClaimReferral(repository), GetOffers(repository), GetRewards(repository), RedeemPoints(repository), RevealScratchCard(repository));

  setUp(() => repository = _FakeRewardsRepository());

  test('loads the summary and the offers together', () async {
    final rewards = cubit();
    await rewards.load();
    expect(rewards.state.status, RewardsStatus.ready);
    expect(rewards.state.summary?.points, 740);
    expect(rewards.state.offers, hasLength(1));
  });

  test('redeems whole steps of points only', () async {
    final rewards = cubit();
    await rewards.load();
    expect(rewards.state.summary?.redeemablePoints, 700);
    expect(await rewards.redeem(), isNull);
    expect(repository.redemptions.single.$1, 700);
    expect(rewards.state.summary?.points, 40);
    expect(rewards.state.isRedeeming, isFalse);
  });

  test('does not redeem below the minimum', () async {
    repository.summary = Ok(_summary(points: 450));
    final rewards = cubit();
    await rewards.load();
    expect(await rewards.redeem(), isNull);
    expect(repository.redemptions, isEmpty);
  });

  test('scratching returns the prize and refreshes the summary', () async {
    final rewards = cubit();
    await rewards.load();
    final result = await rewards.scratch('card-1');
    expect(result, isA<Ok<ScratchCard>>());
    expect((result! as Ok<ScratchCard>).value.prize, const Money(2500));
    expect(rewards.state.scratchingId, isNull);
  });

  test('upper-cases and trims a referral code and reports a rejection', () async {
    repository.claim = const Err(Failure(FailureCodes.referralInvalid));
    final rewards = cubit();
    await rewards.load();
    final failure = await rewards.claimReferral(' salliabcd ');
    expect(repository.claims.single, 'SALLIABCD');
    expect(failure?.code, FailureCodes.referralInvalid);
    expect(rewards.state.isClaiming, isFalse);
  });

  test('shows a failure when rewards cannot load', () async {
    repository.summary = const Err(Failure(FailureCodes.network));
    final rewards = cubit();
    await rewards.load();
    expect(rewards.state.status, RewardsStatus.failure);
  });
}
