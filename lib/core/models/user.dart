import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String username;
  final String? email;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    this.email,
    required this.name,
    this.bio,
    this.avatarUrl,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a User from JSON data
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Converts User to JSON
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Creates a copy of User with specified fields replaced
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Safely creates a User from a minimal JSON (timestamps optional)
  static User fromMinimalJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt'] as String?;
    final updatedAtStr = json['updatedAt'] as String?;
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
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
    isPrivate,
    createdAt,
    updatedAt,
  ];
}
