// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_list_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatListItemModel _$ChatListItemModelFromJson(Map<String, dynamic> json) =>
    ChatListItemModel(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String?,
      groupImage: json['groupImage'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      privatePartnerUser: json['privatePartnerUser'] == null
          ? null
          : UserModel.fromJson(
              json['privatePartnerUser'] as Map<String, dynamic>,
            ),
      lastMessage: json['lastMessage'] == null
          ? null
          : MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChatListItemModelToJson(ChatListItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'name': instance.name,
      'groupImage': instance.groupImage,
      'createdAt': instance.createdAt?.toIso8601String(),
      'privatePartnerUser': instance.privatePartnerUser,
      'lastMessage': instance.lastMessage,
      'participants': instance.participants,
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'unreadCount': instance.unreadCount,
    };
