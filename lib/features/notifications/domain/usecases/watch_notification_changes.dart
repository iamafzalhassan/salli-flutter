import '../repositories/notifications_repository.dart';

class WatchNotificationChanges {
  final NotificationsRepository _repository;

  const WatchNotificationChanges(this._repository);

  Stream<void> call() => _repository.changes;
}
