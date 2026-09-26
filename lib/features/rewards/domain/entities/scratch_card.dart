import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

class ScratchCard extends Equatable {
  final String id;
  final String source;

  final DateTime earnedAt;

  final Money? prize;

  const ScratchCard({required this.id, required this.source, required this.earnedAt, this.prize});

  bool get isScratched => prize != null;
  bool get isWin => prize?.isPositive ?? false;

  @override
  List<Object?> get props => [id, source, earnedAt, prize];
}
