import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse extends Equatable {
  final String token;
  final User user;

  const AuthResponse({
    required this.token,
    required this.user,
  });

  /// Creates an AuthResponse from JSON data
  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);

  /// Converts AuthResponse to JSON
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  @override
  List<Object?> get props => [token, user];
}