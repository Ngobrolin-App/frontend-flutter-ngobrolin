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
  userId: json['userId'] as String,
  lastReadMessageId: json['lastReadMessageId'] as String?,
  joinedAt: json['joinedAt'] == null
      ? null
      : DateTime.parse(json['joinedAt'] as String),
  user: json['user'] == null
      ? null
      : UserModel.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ConversationParticipantModelToJson(
  ConversationParticipantModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'conversationId': instance.conversationId,
  'userId': instance.userId,
  'lastReadMessageId': instance.lastReadMessageId,
  'joinedAt': instance.joinedAt?.toIso8601String(),
  'user': instance.user,
};
