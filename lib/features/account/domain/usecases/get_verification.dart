import '../../../../core/errors/result.dart';
import '../entities/verification.dart';
import '../repositories/account_repository.dart';

class GetVerification {
  final AccountRepository _repository;

  const GetVerification(this._repository);

  Future<Result<Verification>> call() => _repository.getVerification();
}
