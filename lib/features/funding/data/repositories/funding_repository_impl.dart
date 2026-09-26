import '../../../../core/errors/result.dart';
import '../../../../core/network/api_guard.dart';
import '../../domain/entities/bank_link_challenge.dart';
import '../../domain/entities/card_details.dart';
import '../../domain/entities/funding_source.dart';
import '../../domain/repositories/funding_repository.dart';
import '../datasources/funding_remote_data_source.dart';

class FundingRepositoryImpl implements FundingRepository {
  final FundingRemoteDataSource _remote;

  const FundingRepositoryImpl(this._remote);

  @override
  Future<Result<FundingSource>> addCard(CardDetails details) => guardApi(() async => (await _remote.addCard(details)).toEntity());

  @override
  Future<Result<List<FundingSource>>> getSources() => guardApi(() async => [for (final source in await _remote.getSources()) source.toEntity()]);

  @override
  Future<Result<BankLinkChallenge>> linkBank(String bankCode, String accountNumber, {String? branchCode}) => guardApi(() => _remote.linkBank(bankCode, accountNumber, branchCode));

  @override
  Future<Result<void>> removeSource(String sourceId) => guardApi(() => _remote.removeSource(sourceId));

  @override
  Future<Result<FundingSource>> verifyBankLink(String challengeId, String code) => guardApi(() async => (await _remote.verifyBankLink(challengeId, code)).toEntity());
}
