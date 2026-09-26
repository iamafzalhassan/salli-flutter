import '../../../../core/errors/result.dart';
import '../entities/scanned_code.dart';
import '../repositories/payments_repository.dart';

class ResolveCode {
  final PaymentsRepository _repository;

  const ResolveCode(this._repository);

  Future<Result<ScannedCode>> call(String payload) => _repository.resolveCode(payload);
}
