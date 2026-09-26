import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_collections.dart';
import 'package:salli/core/mock/mock_ledger.dart';
import 'package:salli/core/mock/mock_notifier.dart';
import 'package:salli/core/mock/mock_offers.dart';
import 'package:salli/core/mock/mock_qr_codes.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/mock_rewards.dart';
import 'package:salli/core/mock/mock_wallet_seeder.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/utils/lanka_qr.dart';
import 'package:salli/core/utils/path_template.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const friendPhone = '+94719998877';
  const javaLounge = 'LKQR00000004';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  String userIdOf(Map<String, dynamic> session) => (session['user'] as Map<String, dynamic>)['id'] as String;

  int balanceOf(String userId) => MockLedger(harness.store).balanceOf(MockWalletSeeder.walletAccount(userId));

  Future<Map<String, dynamic>> rewards() async => (await harness.authorized('GET', ApiPaths.rewards, session)).body;

  Future<MockResponse> payMerchant(String merchantId, int amountCents, String key) => harness.authorized(
    'POST',
    ApiPaths.merchantPayments,
    session,
    body: {
      'amountCents': amountCents,
      'approval': {'method': Approver.pinMethod, 'pinHash': 'hash-a'},
      'qr': MockQrCodes.merchant(merchantId),
    },
    headers: {ApiHeaders.idempotencyKey: key},
  );

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  group('GET /v1/rewards', () {
    test('starts a new member with welcome points, two hidden cards and a referral code', () async {
      final body = await rewards();
      expect(body['points'], MockRewards.welcomePoints);
      expect(body['cashbackCents'], 0);
      final cards = (body['scratchCards'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(cards, hasLength(MockRewards.welcomeCards));
      expect(cards.every((card) => card['status'] == MockRewards.unscratched && card['amountCents'] == null), isTrue);
      final referral = body['referral'] as Map<String, dynamic>;
      expect(referral['code'], MockRewards.referralCodeOf(userIdOf(session)));
      expect(referral['canClaim'], isTrue);
    });
  });

  group('POST /v1/rewards/scratch-cards/:id/scratch', () {
    test('reveals the prize once and pays it into the wallet once', () async {
      final card = ((await rewards())['scratchCards'] as List<dynamic>).first as Map<String, dynamic>;
      await harness.authorized('GET', ApiPaths.wallet, session);
      final before = balanceOf(userIdOf(session));
      final path = ApiPaths.scratchCard.withId(card['id'] as String);
      final first = await harness.authorized('POST', path, session);
      final prize = first.body['amountCents'] as int;
      expect(first.body['status'], MockRewards.scratched);
      expect(MockRewards.cardPrizesCents, contains(prize));
      final again = await harness.authorized('POST', path, session);
      expect(again.body['amountCents'], prize);
      expect(balanceOf(userIdOf(session)), before + prize);
      expect((await rewards())['cashbackCents'], prize);
    });

    test('will not scratch a card that belongs to someone else', () async {
      final card = ((await rewards())['scratchCards'] as List<dynamic>).first as Map<String, dynamic>;
      final other = await harness.register(phone: friendPhone);
      expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.scratchCard.withId(card['id'] as String), other)), FailureCodes.notFound);
    });
  });

  group('earning', () {
    test('a shop payment earns points, a card and the offer cashback once', () async {
      await rewards();
      final offer = MockOffers.forMerchant(javaLounge)!;
      const amountCents = 150000;
      expect((await payMerchant(javaLounge, amountCents, 'key-1')).statusCode, 201);
      final cashbackCents = (amountCents * offer.cashbackPercent ~/ 100).clamp(0, offer.maxCashbackCents);
      final body = await rewards();
      expect(body['points'], MockRewards.welcomePoints + amountCents ~/ MockRewards.spendPerPointCents);
      expect(body['cashbackCents'], cashbackCents);
      expect(body['scratchCards'], hasLength(MockRewards.welcomeCards + 1));
      final kinds = harness.store.all(MockCollections.notifications).map((item) => item['kind']);
      expect(kinds, containsAll([MockNotifier.scratchCardEarned, MockNotifier.cashbackEarned]));
      expect((await payMerchant(javaLounge, amountCents, 'key-2')).statusCode, 201);
      expect((await rewards())['cashbackCents'], cashbackCents);
    });

    test('lists every offer with a code that pays that merchant', () async {
      final items = ((await harness.authorized('GET', ApiPaths.offers, session)).body['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(items, hasLength(MockOffers.all.length));
      for (final item in items) {
        expect(LankaQr.parse(item['qr'] as String).accountId, (item['merchant'] as Map<String, dynamic>)['id']);
        expect(item['isUsed'], isFalse);
      }
    });
  });

  group('POST /v1/rewards/points/redeem', () {
    Future<MockResponse> redeem(Object? points, {String? key = 'redeem-1'}) => harness.authorized('POST', ApiPaths.redeemPoints, session, body: {'points': points}, headers: {ApiHeaders.idempotencyKey: ?key});

    test('turns points into cashback', () async {
      final userId = userIdOf(session);
      await rewards();
      final account = harness.store.find(MockCollections.rewardAccounts, userId)!;
      await harness.store.put(MockCollections.rewardAccounts, userId, {...account, 'points': 740});
      await harness.authorized('GET', ApiPaths.wallet, session);
      final before = balanceOf(userId);
      final response = await redeem(700);
      expect(response.statusCode, 200);
      expect(response.body['points'], 40);
      expect(balanceOf(userId), before + 700 * MockRewards.pointValueCents);
    });

    test('rejects too few points, odd amounts and more than the balance', () async {
      expect(MockApiHarness.errorCode(await redeem(MockRewards.minRedeemPoints - MockRewards.pointStep)), FailureCodes.invalidRequest);
      expect(MockApiHarness.errorCode(await redeem(MockRewards.minRedeemPoints + 1, key: 'redeem-2')), FailureCodes.invalidRequest);
      expect(MockApiHarness.errorCode(await redeem(MockRewards.minRedeemPoints, key: 'redeem-3')), FailureCodes.insufficientPoints);
      expect(MockApiHarness.errorCode(await redeem(MockRewards.minRedeemPoints, key: null)), FailureCodes.idempotencyKeyRequired);
    });
  });

  group('POST /v1/referrals/claim', () {
    test('pays both friends once and tells the one who invited', () async {
      final inviterId = userIdOf(session);
      final code = ((await rewards())['referral'] as Map<String, dynamic>)['code'] as String;
      final friend = await harness.register(phone: friendPhone);
      final friendId = userIdOf(friend);
      await harness.authorized('GET', ApiPaths.wallet, friend);
      final inviterBefore = balanceOf(inviterId);
      final friendBefore = balanceOf(friendId);
      final response = await harness.authorized('POST', ApiPaths.referralClaim, friend, body: {'code': code.toLowerCase()});
      expect(response.statusCode, 200);
      expect((response.body['referral'] as Map<String, dynamic>)['canClaim'], isFalse);
      expect(balanceOf(inviterId), inviterBefore + MockRewards.referralRewardCents);
      expect(balanceOf(friendId), friendBefore + MockRewards.referralRewardCents);
      expect(harness.store.all(MockCollections.notifications).any((item) => item['userId'] == inviterId && item['kind'] == MockNotifier.referralJoined), isTrue);
      expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.referralClaim, friend, body: {'code': code})), FailureCodes.referralUnavailable);
    });

    test('rejects an unknown code and your own code', () async {
      final code = ((await rewards())['referral'] as Map<String, dynamic>)['code'] as String;
      expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.referralClaim, session, body: {'code': 'SALLI0000'})), FailureCodes.referralInvalid);
      expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.referralClaim, session, body: {'code': code})), FailureCodes.referralInvalid);
    });

    test('closes the window 30 days after joining', () async {
      final code = ((await rewards())['referral'] as Map<String, dynamic>)['code'] as String;
      await harness.register(phone: friendPhone);
      harness.now = harness.now.add(MockRewards.referralWindow);
      final friend = await harness.login(phone: friendPhone);
      expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.referralClaim, friend, body: {'code': code})), FailureCodes.referralUnavailable);
    });
  });
}
