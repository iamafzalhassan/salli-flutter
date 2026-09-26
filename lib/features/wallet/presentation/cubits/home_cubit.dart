import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../bills/domain/entities/bill_schedule.dart';
import '../../../bills/domain/usecases/get_bill_schedules.dart';
import '../../../notifications/domain/usecases/get_unread_count.dart';
import '../../../notifications/domain/usecases/watch_notification_changes.dart';
import '../../../profile/domain/usecases/get_profile.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/get_wallet.dart';
import '../../domain/usecases/watch_wallet_changes.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  static const int maxUpcomingBills = 3;
  static const int recentCount = 5;

  static const Duration upcomingWindow = Duration(days: 10);

  final GetBillSchedules _getBillSchedules;

  final GetProfile _getProfile;

  final GetTransactions _getTransactions;

  final GetUnreadCount _getUnreadCount;

  final GetWallet _getWallet;

  late final StreamSubscription<void> _notificationChanges;
  late final StreamSubscription<void> _walletChanges;

  HomeCubit(this._getBillSchedules, this._getProfile, this._getTransactions, this._getUnreadCount, this._getWallet, WatchNotificationChanges watchNotificationChanges, WatchWalletChanges watchWalletChanges) : super(const HomeState()) {
    _notificationChanges = watchNotificationChanges().listen((_) => unawaited(refreshUnread()));
    _walletChanges = watchWalletChanges().listen((_) => unawaited(load()));
  }

  Future<void> refreshUnread() async {
    final result = await _getUnreadCount();
    if (isClosed || result is! Ok<int>) return;
    emit(state.copyWith(unreadNotifications: result.value));
  }

  Future<void> load() async {
    final hasContent = state.wallet != null;
    emit(state.copyWith(failure: () => null, isRefreshing: hasContent, status: hasContent ? HomeStatus.ready : HomeStatus.loading));
    final (profile, wallet, transactions, schedules, unread) = await (_getProfile(), _getWallet(), _getTransactions(limit: recentCount), _getBillSchedules(), _getUnreadCount()).wait;
    if (isClosed) return;
    final unreadNotifications = unread is Ok<int> ? unread.value : state.unreadNotifications;
    switch ((profile, wallet, transactions)) {
      case (Ok(value: final profile), Ok(value: final wallet), Ok(value: final page)):
        emit(HomeState(isBalanceHidden: state.isBalanceHidden, profile: profile, recent: page.items, status: HomeStatus.ready, unreadNotifications: unreadNotifications, upcomingBills: _upcoming(schedules), wallet: wallet));
      case _:
        final failure = [profile, wallet, transactions].whereType<Err<Object?>>().first.failure;
        emit(state.copyWith(failure: () => failure, isRefreshing: false, status: hasContent ? HomeStatus.ready : HomeStatus.failure, unreadNotifications: unreadNotifications));
    }
  }

  void toggleBalance() => emit(state.copyWith(isBalanceHidden: !state.isBalanceHidden));

  List<BillSchedule> _upcoming(Result<List<BillSchedule>> schedules) {
    if (schedules is! Ok<List<BillSchedule>>) return const [];
    final horizon = DateTime.now().add(upcomingWindow);
    return schedules.value.where((schedule) => schedule.nextRunAt.isBefore(horizon)).take(maxUpcomingBills).toList();
  }

  @override
  Future<void> close() async {
    await _notificationChanges.cancel();
    await _walletChanges.cancel();
    return super.close();
  }
}
