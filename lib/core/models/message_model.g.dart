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
  isUnsent: json['isUnsent'] as bool? ?? false,
  isEdited: json['isEdited'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  mediaUrl: json['mediaUrl'] as String?,
  mediaFileName: json['mediaFileName'] as String?,
  mediaFileType: json['mediaFileType'] as String?,
  mediaSize: (json['mediaSize'] as num?)?.toInt(),
  forwardedFromMessageId: json['forwardedFromMessageId'] as String?,
  forwardedCount: (json['forwardedCount'] as num?)?.toInt(),
  systemEventType: json['systemEventType'] as String?,
  systemMetadata: json['systemMetadata'] as Map<String, dynamic>?,
  sender: json['sender'] == null
      ? null
      : UserModel.fromJson(json['sender'] as Map<String, dynamic>),
  repliedMessage: json['repliedMessage'] == null
      ? null
      : MessageModel.fromJson(json['repliedMessage'] as Map<String, dynamic>),
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
      'isUnsent': instance.isUnsent,
      'isEdited': instance.isEdited,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'mediaUrl': instance.mediaUrl,
      'mediaFileName': instance.mediaFileName,
      'mediaFileType': instance.mediaFileType,
      'mediaSize': instance.mediaSize,
      'forwardedFromMessageId': instance.forwardedFromMessageId,
      'forwardedCount': instance.forwardedCount,
      'systemEventType': instance.systemEventType,
      'systemMetadata': instance.systemMetadata,
      'sender': instance.sender,
      'repliedMessage': instance.repliedMessage,
      'isSendByMe': instance.isSendByMe,
    };
