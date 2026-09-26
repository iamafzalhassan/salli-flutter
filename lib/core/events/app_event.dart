sealed class AppEvent {
  const AppEvent();
}

final class NotificationsChanged extends AppEvent {
  const NotificationsChanged();
}

final class WalletChanged extends AppEvent {
  const WalletChanged();
}
