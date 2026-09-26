import '../../../../core/errors/result.dart';
import '../entities/bank_link_challenge.dart';
import '../entities/card_details.dart';
import '../entities/funding_source.dart';

abstract interface class FundingRepository {
  Future<Result<FundingSource>> addCard(CardDetails details);

  Future<Result<List<FundingSource>>> getSources();

  Future<Result<BankLinkChallenge>> linkBank(String bankCode, String accountNumber, {String? branchCode});

  Future<Result<void>> removeSource(String sourceId);

  Future<Result<FundingSource>> verifyBankLink(String challengeId, String code);
}
