import '../../../../core/errors/result.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Stream<void> get changes;

  Future<Result<List<AppNotification>>> getNotifications();

  Future<Result<int>> getUnreadCount();

  Future<Result<void>> markAllRead();

  Future<Result<void>> markRead(String id);
}
