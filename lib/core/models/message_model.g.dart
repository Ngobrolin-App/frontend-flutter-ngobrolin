// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  senderId: json['senderId'] as String,
  content: json['content'] as String,
  type: json['type'] as String? ?? 'text',
  isRead: json['isRead'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  sender: json['sender'] == null
      ? null
      : UserModel.fromJson(json['sender'] as Map<String, dynamic>),
  isSendByMe: json['isSendByMe'] as bool?,
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'content': instance.content,
      'type': instance.type,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
      'sender': instance.sender,
      'isSendByMe': instance.isSendByMe,
    };
