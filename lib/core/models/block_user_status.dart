import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'block_user_status.g.dart';

@JsonSerializable()
class BlockUserStatus extends Equatable {
  final bool isBlocked;
  final bool isBlockedByMe;
  final String blockedMessage;

  const BlockUserStatus({
    required this.isBlocked,
    required this.isBlockedByMe,
    required this.blockedMessage,
  });

  /// Creates an BlockUserStatus from JSON data
  factory BlockUserStatus.fromJson(Map<String, dynamic> json) =>
      _$BlockUserStatusFromJson(json);

  /// Converts BlockUserStatus to JSON
  Map<String, dynamic> toJson() => _$BlockUserStatusToJson(this);

  @override
  List<Object?> get props => [isBlocked, isBlockedByMe, blockedMessage];
}
