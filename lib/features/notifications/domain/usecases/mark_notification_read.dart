import '../../../../core/errors/result.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationRead {
  final NotificationsRepository _repository;

  const MarkNotificationRead(this._repository);

  Future<Result<void>> call(String id) => _repository.markRead(id);
}
