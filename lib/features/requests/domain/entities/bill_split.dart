import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'request_status.dart';
import 'split_share.dart';

class BillSplit extends Equatable {
  final String id;

  final String? note;

  final List<SplitShare> shares;

  final DateTime createdAt;

  final Money total;

  const BillSplit({required this.id, this.note, required this.shares, required this.createdAt, required this.total});

  int get paidCount => shares.where((share) => !share.isSelf && share.status == RequestStatus.paid).length;
  int get requestCount => shares.where((share) => !share.isSelf).length;

  @override
  List<Object?> get props => [id, note, shares, createdAt, total];
}
