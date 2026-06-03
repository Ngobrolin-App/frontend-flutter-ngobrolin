// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_participant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationParticipantModel _$ConversationParticipantModelFromJson(
  Map<String, dynamic> json,
) => ConversationParticipantModel(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  name: json['name'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  lastReadMessageId: json['lastReadMessageId'] as String?,
  joinedAt: json['joinedAt'] == null
      ? null
      : DateTime.parse(json['joinedAt'] as String),
);

Map<String, dynamic> _$ConversationParticipantModelToJson(
  ConversationParticipantModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'conversationId': instance.conversationId,
  'name': instance.name,
  'username': instance.username,
  'avatarUrl': instance.avatarUrl,
  'lastReadMessageId': instance.lastReadMessageId,
  'joinedAt': instance.joinedAt?.toIso8601String(),
};
