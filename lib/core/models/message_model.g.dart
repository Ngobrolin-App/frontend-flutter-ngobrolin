// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  senderId: json['senderId'] as String,
  content: json['content'] as String?,
  type: json['type'] as String? ?? 'text',
  isRead: json['isRead'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  mediaUrl: json['mediaUrl'] as String?,
  mediaFileType: json['mediaFileType'] as String?,
  mediaSize: (json['mediaSize'] as num?)?.toInt(),
  mediaFileName: json['mediaFileName'] as String?,
  sender: json['sender'] == null
      ? null
      : UserModel.fromJson(json['sender'] as Map<String, dynamic>),
  isSendByMe: json['isSendByMe'] as bool?,
  repliedMessage: json['repliedMessage'] == null
      ? null
      : MessageModel.fromJson(json['repliedMessage'] as Map<String, dynamic>),
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
      'mediaUrl': instance.mediaUrl,
      'mediaFileType': instance.mediaFileType,
      'mediaSize': instance.mediaSize,
      'mediaFileName': instance.mediaFileName,
      'sender': instance.sender,
      'isSendByMe': instance.isSendByMe,
      'repliedMessage': instance.repliedMessage,
    };
