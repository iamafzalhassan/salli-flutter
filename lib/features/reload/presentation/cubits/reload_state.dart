import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/payment_draft.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../domain/entities/recent_reload.dart';
import '../../domain/entities/reload_catalog.dart';
import '../../domain/entities/reload_kind.dart';

class ReloadState extends Equatable {
  final bool isLoadingCatalog;

  final List<RecentReload> recents;

  final Failure? failure;

  final PaymentDraft? draft;

  final PhoneNumber? ownPhone;
  final PhoneNumber? phone;

  final Recipient? recipient;

  final ReloadCatalog? catalog;

  final ReloadKind? kind;

  const ReloadState({this.isLoadingCatalog = false, this.recents = const [], this.failure, this.draft, this.ownPhone, this.phone, this.recipient, this.catalog, this.kind});

  bool get hasResult => draft != null || recipient != null;

  ReloadState copyWith({
    bool? isLoadingCatalog,
    List<RecentReload>? recents,
    Failure? Function()? failure,
    PaymentDraft? Function()? draft,
    PhoneNumber? Function()? ownPhone,
    PhoneNumber? Function()? phone,
    Recipient? Function()? recipient,
    ReloadCatalog? Function()? catalog,
    ReloadKind? Function()? kind,
  }) => ReloadState(
    isLoadingCatalog: isLoadingCatalog ?? this.isLoadingCatalog,
    recents: recents ?? this.recents,
    failure: failure == null ? this.failure : failure(),
    draft: draft == null ? this.draft : draft(),
    ownPhone: ownPhone == null ? this.ownPhone : ownPhone(),
    phone: phone == null ? this.phone : phone(),
    recipient: recipient == null ? this.recipient : recipient(),
    catalog: catalog == null ? this.catalog : catalog(),
    kind: kind == null ? this.kind : kind(),
  );

  @override
  List<Object?> get props => [isLoadingCatalog, recents, failure, draft, ownPhone, phone, recipient, catalog, kind];
}
