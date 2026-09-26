import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/utils/path_template.dart';
import '../models/app_notification_model.dart';

class NotificationsRemoteDataSource {
  final ApiClient _client;

  const NotificationsRemoteDataSource(this._client);

  Future<List<AppNotificationModel>> getNotifications() async => [for (final item in (await _client.get(ApiPaths.notifications))['items'] as List<dynamic>) AppNotificationModel.fromJson(item as Map<String, dynamic>)];

  Future<int> getUnreadCount() async => (await _client.get(ApiPaths.unreadNotifications))['unreadCount'] as int;

  Future<void> markAllRead() => _client.post(ApiPaths.notificationsReadAll);

  Future<void> markRead(String id) => _client.post(ApiPaths.notificationRead.withId(id));
}
