import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/usecases/get_security_events.dart';
import '../../domain/usecases/get_trusted_devices.dart';
import 'security_state.dart';

class SecurityCubit extends Cubit<SecurityState> {
  final GetSecurityEvents _getEvents;

  final GetTrustedDevices _getDevices;

  SecurityCubit(this._getEvents, this._getDevices) : super(const SecurityState());

  Future<void> load() async {
    final (events, devices) = await (_getEvents(), _getDevices()).wait;
    if (isClosed) return;
    emit(switch ((events, devices)) {
      (Ok(value: final events), Ok(value: final devices)) => SecurityState(devices: devices, events: events, status: SecurityStatus.ready),
      _ => SecurityState(devices: state.devices, events: state.events, failure: [events, devices].whereType<Err<Object?>>().first.failure, status: state.status == SecurityStatus.ready ? SecurityStatus.ready : SecurityStatus.failure),
    });
  }
}
