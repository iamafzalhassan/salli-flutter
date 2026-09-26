import '../../../../core/errors/result.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/security/pin_credential.dart';
import '../../domain/entities/security_event.dart';
import '../../domain/entities/trusted_device.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/security_remote_data_source.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  final PinCredential _pinCredential;

  final SecurityRemoteDataSource _remote;

  const SecurityRepositoryImpl(this._pinCredential, this._remote);

  @override
  Future<Result<void>> changePin(String currentPin, String newPin) => guardApi(() async => _remote.changePin(newPinHash: await _pinCredential.hash(newPin), pinHash: await _pinCredential.hash(currentPin)));

  @override
  Future<Result<List<TrustedDevice>>> getDevices() => guardApi(() async => [for (final device in await _remote.getDevices()) device.toEntity()]);

  @override
  Future<Result<List<SecurityEvent>>> getEvents() => guardApi(() async => [for (final event in await _remote.getEvents()) event.toEntity()]);
}
