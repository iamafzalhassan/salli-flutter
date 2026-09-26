import '../../../../core/errors/result.dart';
import '../repositories/notifications_repository.dart';

class MarkAllNotificationsRead {
  final NotificationsRepository _repository;

  const MarkAllNotificationsRead(this._repository);

  Future<Result<void>> call() => _repository.markAllRead();
}
