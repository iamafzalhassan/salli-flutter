import 'package:equatable/equatable.dart';

class BiometricPromptText extends Equatable {
  final String cancel;
  final String title;

  const BiometricPromptText({required this.cancel, required this.title});

  @override
  List<Object?> get props => [cancel, title];
}
