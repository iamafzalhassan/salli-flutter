import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/notifications/domain/entities/app_notification.dart';
import 'package:salli/features/notifications/domain/entities/notification_kind.dart';
import 'package:salli/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:salli/features/notifications/domain/usecases/get_notifications.dart';
import 'package:salli/features/notifications/domain/usecases/mark_all_notifications_read.dart';
import 'package:salli/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:salli/features/notifications/presentation/cubits/notifications_cubit.dart';
import 'package:salli/features/notifications/presentation/cubits/notifications_state.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  final List<String> read = [];

  int readAllCount = 0;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<Result<List<AppNotification>>> getNotifications() async => Ok([
    AppNotification(amount: const Money(50000), createdAt: DateTime.utc(2026, 9, 21, 9), id: 'n-1', isRead: false, kind: NotificationKind.moneyReceived, name: 'Nimal Perera', transactionId: 'txn-1'),
    AppNotification(createdAt: DateTime.utc(2026, 9, 20), id: 'n-2', isRead: false, kind: NotificationKind.welcome),
  ]);

  @override
  Future<Result<int>> getUnreadCount() async => const Ok(2);

  @override
  Future<Result<void>> markAllRead() async {
    readAllCount++;
    return const Ok(null);
  }

  @override
  Future<Result<void>> markRead(String id) async {
    read.add(id);
    return const Ok(null);
  }
}

void main() {
  late _FakeNotificationsRepository repository;

  NotificationsCubit cubit() => NotificationsCubit(GetNotifications(repository), MarkAllNotificationsRead(repository), MarkNotificationRead(repository));

  setUp(() => repository = _FakeNotificationsRepository());

  test('opening one marks only that one as read', () async {
    final notifications = cubit();
    await notifications.load();
    await notifications.open(notifications.state.items.first);
    expect(repository.read, ['n-1']);
    expect(notifications.state.items.map((item) => item.isRead), [true, false]);
    await notifications.open(notifications.state.items.first);
    expect(repository.read, ['n-1']);
  });

  test('marks everything as read once', () async {
    final notifications = cubit();
    await notifications.load();
    await notifications.markAllRead();
    expect(notifications.state.hasUnread, isFalse);
    await notifications.markAllRead();
    expect(repository.readAllCount, 1);
    expect(notifications.state.status, NotificationsStatus.ready);
  });
}
