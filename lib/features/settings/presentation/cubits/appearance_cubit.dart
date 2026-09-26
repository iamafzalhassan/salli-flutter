import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_theme_mode.dart';
import '../../domain/usecases/get_theme_mode.dart';
import '../../domain/usecases/watch_theme_mode.dart';

class AppearanceCubit extends Cubit<AppThemeMode> {
  late final StreamSubscription<AppThemeMode> _subscription;

  AppearanceCubit(GetThemeMode getThemeMode, WatchThemeMode watchThemeMode) : super(getThemeMode()) {
    _subscription = watchThemeMode().listen(emit);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
