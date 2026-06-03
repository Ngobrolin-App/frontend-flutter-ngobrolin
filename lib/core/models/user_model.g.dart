// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  username: json['username'] as String,
  email: json['email'] as String?,
  name: json['name'] as String,
  bio: json['bio'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  language: json['language'] as String,
  isPrivate: json['isPrivate'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'name': instance.name,
  'bio': instance.bio,
  'avatarUrl': instance.avatarUrl,
  'language': instance.language,
  'isPrivate': instance.isPrivate,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
