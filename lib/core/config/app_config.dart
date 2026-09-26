import 'environment.dart';

class AppConfig {
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  final Environment environment;

  const AppConfig(this.environment);

  factory AppConfig.fromEnvironment() => AppConfig(Environment.values.byName(const String.fromEnvironment('SALLI_ENV', defaultValue: 'mock')));

  bool get usesMockApi => environment == Environment.mock;

  String get baseUrl => environment.baseUrl;
}
