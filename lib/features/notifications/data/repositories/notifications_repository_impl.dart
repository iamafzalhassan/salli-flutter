import '../../../../core/errors/result.dart';
import '../../../../core/events/app_event.dart';
import '../../../../core/events/app_events.dart';
import '../../../../core/network/api_guard.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final AppEvents _events;

  final NotificationsRemoteDataSource _remote;

  const NotificationsRepositoryImpl(this._events, this._remote);

  @override
  Stream<void> get changes => _events.stream.where((event) => event is NotificationsChanged);

  @override
  Future<Result<List<AppNotification>>> getNotifications() => guardApi(() async => [for (final item in await _remote.getNotifications()) item.toEntity()]);

  @override
  Future<Result<int>> getUnreadCount() => guardApi(_remote.getUnreadCount);

  @override
  Future<Result<void>> markAllRead() => guardApi(() async {
    await _remote.markAllRead();
    _events.publish(const NotificationsChanged());
  });

  @override
  Future<Result<void>> markRead(String id) => guardApi(() async {
    await _remote.markRead(id);
    _events.publish(const NotificationsChanged());
  });
}
