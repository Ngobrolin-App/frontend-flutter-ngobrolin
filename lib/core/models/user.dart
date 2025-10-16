import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String username;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
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
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        name,
        bio,
        avatarUrl,
        isPrivate,
        createdAt,
        updatedAt,
      ];
}