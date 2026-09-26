import '../../../../core/errors/result.dart';
import '../entities/bank_link_challenge.dart';
import '../repositories/funding_repository.dart';

class LinkBankAccount {
  final FundingRepository _repository;

  const LinkBankAccount(this._repository);

  Future<Result<BankLinkChallenge>> call(String bankCode, String accountNumber, {String? branchCode}) => _repository.linkBank(bankCode, accountNumber, branchCode: branchCode);
}
