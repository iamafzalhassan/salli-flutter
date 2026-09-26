import '../../../../core/errors/result.dart';
import '../../../../core/network/api_guard.dart';
import '../../domain/entities/account_limits.dart';
import '../../domain/entities/kyc_submission.dart';
import '../../domain/entities/verification.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource _remote;

  const AccountRepositoryImpl(this._remote);

  @override
  Future<Result<AccountLimits>> getLimits() => guardApi(() async => (await _remote.getLimits()).toEntity());

  @override
  Future<Result<Verification>> getVerification() => guardApi(() async => (await _remote.getVerification()).toEntity());

  @override
  Future<Result<Verification>> submitKyc(KycSubmission submission) => guardApi(
    () async => (await _remote.submitKyc({
      'dateOfBirth': DateTime.utc(submission.dateOfBirth.year, submission.dateOfBirth.month, submission.dateOfBirth.day).toIso8601String(),
      'documents': {'nicBack': submission.nicBackDigest, 'nicFront': submission.nicFrontDigest, 'selfie': submission.selfieDigest},
      'fullName': submission.fullName,
      'gender': submission.gender.name,
      'liveness': {'challenges': submission.livenessChallenges, 'passed': true},
      'nic': submission.nic.number,
    })).toEntity(),
  );
}
