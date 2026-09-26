import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';

class AddCardState extends Equatable {
  final bool isAdded;
  final bool isSaving;

  final String cvv;
  final String expiry;
  final String number;

  final Failure? failure;

  const AddCardState({this.isAdded = false, this.isSaving = false, this.cvv = '', this.expiry = '', this.number = '', this.failure});

  AddCardState copyWith({bool? isAdded, bool? isSaving, String? cvv, String? expiry, String? number, Failure? Function()? failure}) =>
      AddCardState(isAdded: isAdded ?? this.isAdded, isSaving: isSaving ?? this.isSaving, cvv: cvv ?? this.cvv, expiry: expiry ?? this.expiry, number: number ?? this.number, failure: failure == null ? this.failure : failure());

  @override
  List<Object?> get props => [isAdded, isSaving, cvv, expiry, number, failure];
}
