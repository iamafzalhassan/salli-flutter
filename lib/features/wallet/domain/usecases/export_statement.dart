import 'dart:typed_data';

import '../../../../core/errors/result.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../repositories/wallet_repository.dart';

class ExportStatement {
  final ProfileRepository _profiles;

  final WalletRepository _wallet;

  const ExportStatement(this._profiles, this._wallet);

  Future<Result<Uint8List>> call(DateTime from, DateTime to) async => switch (await _profiles.getProfile()) {
    Ok(:final value) => await _wallet.exportStatement(from, to, holder: value.displayName ?? value.phone.display, phone: value.phone.display),
    Err(:final failure) => Err(failure),
  };
}
