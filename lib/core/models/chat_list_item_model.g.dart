// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_list_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatListItemModel _$ChatListItemModelFromJson(Map<String, dynamic> json) =>
    ChatListItemModel(
      id: json['id'] as String,
      type: json['type'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String,
      lastMessageId: json['lastMessageId'] as String?,
      lastMessageType: json['lastMessageType'] as String? ?? 'text',
      timestamp: DateTime.parse(json['timestamp'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ChatListItemModelToJson(ChatListItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'userId': instance.userId,
      'name': instance.name,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'lastMessage': instance.lastMessage,
      'lastMessageId': instance.lastMessageId,
      'lastMessageType': instance.lastMessageType,
      'timestamp': instance.timestamp.toIso8601String(),
      'unreadCount': instance.unreadCount,
    };
