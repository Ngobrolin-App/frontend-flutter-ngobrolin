// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chat _$ChatFromJson(Map<String, dynamic> json) => Chat(
  id: json['id'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  lastMessage: json['lastMessage'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ChatToJson(Chat instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'username': instance.username,
  'avatarUrl': instance.avatarUrl,
  'lastMessage': instance.lastMessage,
  'timestamp': instance.timestamp.toIso8601String(),
  'unreadCount': instance.unreadCount,
};
