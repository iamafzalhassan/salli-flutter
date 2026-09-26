import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../bills/domain/entities/bill_schedule.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';

enum HomeStatus { failure, loading, ready }

class HomeState extends Equatable {
  final bool isBalanceHidden;
  final bool isRefreshing;

  final int unreadNotifications;

  final List<BillSchedule> upcomingBills;

  final List<WalletTransaction> recent;

  final Failure? failure;

  final HomeStatus status;

  final Profile? profile;

  final Wallet? wallet;

  const HomeState({this.isBalanceHidden = false, this.isRefreshing = false, this.unreadNotifications = 0, this.upcomingBills = const [], this.recent = const [], this.failure, this.status = HomeStatus.loading, this.profile, this.wallet});

  HomeState copyWith({
    bool? isBalanceHidden,
    bool? isRefreshing,
    int? unreadNotifications,
    List<BillSchedule>? upcomingBills,
    List<WalletTransaction>? recent,
    Failure? Function()? failure,
    HomeStatus? status,
    Profile? Function()? profile,
    Wallet? Function()? wallet,
  }) => HomeState(
    isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    unreadNotifications: unreadNotifications ?? this.unreadNotifications,
    upcomingBills: upcomingBills ?? this.upcomingBills,
    recent: recent ?? this.recent,
    failure: failure == null ? this.failure : failure(),
    status: status ?? this.status,
    profile: profile == null ? this.profile : profile(),
    wallet: wallet == null ? this.wallet : wallet(),
  );

  @override
  List<Object?> get props => [isBalanceHidden, isRefreshing, unreadNotifications, upcomingBills, recent, failure, status, profile, wallet];
}
