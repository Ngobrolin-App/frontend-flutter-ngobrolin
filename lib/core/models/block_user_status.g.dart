// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_user_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockUserStatus _$BlockUserStatusFromJson(Map<String, dynamic> json) =>
    BlockUserStatus(
      isBlocked: json['isBlocked'] as bool,
      isBlockedByMe: json['isBlockedByMe'] as bool,
      blockedMessage: json['blockedMessage'] as String,
    );

Map<String, dynamic> _$BlockUserStatusToJson(BlockUserStatus instance) =>
    <String, dynamic>{
      'isBlocked': instance.isBlocked,
      'isBlockedByMe': instance.isBlockedByMe,
      'blockedMessage': instance.blockedMessage,
    };
