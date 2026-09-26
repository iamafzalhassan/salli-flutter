import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../errors/failure.dart';
import 'locale_keys.dart';

extension FailureMessage on BuildContext {
  String failureMessage(Failure failure) {
    final key = '${LocaleKeys.errorsPrefix}.${failure.code}';
    return this.tr(this.trExists(key) ? key : LocaleKeys.errorsUnknown);
  }
}
