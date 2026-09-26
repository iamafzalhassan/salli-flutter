import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/monthly_insights.dart';

enum InsightsStatus { failure, loading, ready }

class InsightsState extends Equatable {
  final bool canGoForward;

  final DateTime month;

  final Failure? failure;

  final InsightsStatus status;

  final MonthlyInsights? insights;

  const InsightsState({this.canGoForward = false, required this.month, this.failure, this.status = InsightsStatus.loading, this.insights});

  InsightsState copyWith({bool? canGoForward, DateTime? month, Failure? Function()? failure, InsightsStatus? status, MonthlyInsights? Function()? insights}) =>
      InsightsState(canGoForward: canGoForward ?? this.canGoForward, month: month ?? this.month, failure: failure == null ? this.failure : failure(), status: status ?? this.status, insights: insights == null ? this.insights : insights());

  @override
  List<Object?> get props => [canGoForward, month, failure, status, insights];
}
