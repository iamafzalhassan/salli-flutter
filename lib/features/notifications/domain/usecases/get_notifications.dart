import '../../../../core/errors/result.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotifications {
  final NotificationsRepository _repository;

  const GetNotifications(this._repository);

  Future<Result<List<AppNotification>>> call() => _repository.getNotifications();
}
