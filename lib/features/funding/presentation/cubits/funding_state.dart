import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../domain/entities/funding_source.dart';

enum FundingStatus { failure, loading, ready }

class FundingState extends Equatable {
  final bool isBusy;
  final bool isWithdrawal;

  final List<FundingSource> sources;

  final Failure? failure;

  final FundingStatus status;

  final Recipient? recipient;

  const FundingState({this.isBusy = false, required this.isWithdrawal, this.sources = const [], this.failure, this.status = FundingStatus.loading, this.recipient});

  FundingState copyWith({bool? isBusy, List<FundingSource>? sources, Failure? Function()? failure, FundingStatus? status, Recipient? Function()? recipient}) => FundingState(
    isBusy: isBusy ?? this.isBusy,
    isWithdrawal: isWithdrawal,
    sources: sources ?? this.sources,
    failure: failure == null ? this.failure : failure(),
    status: status ?? this.status,
    recipient: recipient == null ? this.recipient : recipient(),
  );

  @override
  List<Object?> get props => [isBusy, isWithdrawal, sources, failure, status, recipient];
}
