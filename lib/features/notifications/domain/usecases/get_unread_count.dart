import '../../../../core/errors/result.dart';
import '../repositories/notifications_repository.dart';

class GetUnreadCount {
  final NotificationsRepository _repository;

  const GetUnreadCount(this._repository);

  Future<Result<int>> call() => _repository.getUnreadCount();
}
