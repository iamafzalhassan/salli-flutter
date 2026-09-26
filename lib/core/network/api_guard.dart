import 'package:flutter/services.dart';

import '../errors/failure.dart';
import '../errors/failure_codes.dart';
import '../errors/result.dart';
import 'api_exception.dart';

Future<Result<T>> guardApi<T>(Future<T> Function() action) async {
  try {
    return Ok(await action());
  } on ApiException catch (exception) {
    return Err(exception.failure);
  } on PlatformException {
    return const Err(Failure(FailureCodes.deviceSecurityUnavailable));
  } on TypeError {
    return const Err(Failure(FailureCodes.malformedResponse));
  } on FormatException {
    return const Err(Failure(FailureCodes.malformedResponse));
  }
}
