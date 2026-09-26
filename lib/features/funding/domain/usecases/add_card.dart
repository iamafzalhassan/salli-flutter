import '../../../../core/errors/result.dart';
import '../entities/card_details.dart';
import '../entities/funding_source.dart';
import '../repositories/funding_repository.dart';

class AddCard {
  final FundingRepository _repository;

  const AddCard(this._repository);

  Future<Result<FundingSource>> call(CardDetails details) => _repository.addCard(details);
}
