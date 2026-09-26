import 'package:get_it/get_it.dart';

import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/domain/usecases/get_unread_count.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read.dart';
import '../../features/notifications/domain/usecases/mark_notification_read.dart';
import '../../features/notifications/domain/usecases/watch_notification_changes.dart';
import '../../features/notifications/presentation/cubits/notifications_cubit.dart';

void registerNotificationsModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => NotificationsRemoteDataSource(injector()))
    ..registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(injector(), injector()))
    ..registerLazySingleton(() => GetNotifications(injector()))
    ..registerLazySingleton(() => GetUnreadCount(injector()))
    ..registerLazySingleton(() => MarkAllNotificationsRead(injector()))
    ..registerLazySingleton(() => MarkNotificationRead(injector()))
    ..registerLazySingleton(() => WatchNotificationChanges(injector()))
    ..registerFactory(() => NotificationsCubit(injector(), injector(), injector()));
}
