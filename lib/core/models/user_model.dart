import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String username;
  final String? email;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final String language;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    required this.name,
    this.bio,
    this.avatarUrl,
    required this.language,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  /// Converts UserModel to JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Creates a copy of UserModel with specified fields replaced
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    String? bio,
    String? avatarUrl,
    String? language,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Safely creates a UserModel from a minimal JSON (timestamps optional)
  static UserModel fromMinimalJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt'] as String?;
    final updatedAtStr = json['updatedAt'] as String?;
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      language: json['language'] as String,
      isPrivate: (json['isPrivate'] as bool?) ?? false,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    name,
    bio,
    avatarUrl,
    language,
    isPrivate,
    createdAt,
    updatedAt,
  ];
}
