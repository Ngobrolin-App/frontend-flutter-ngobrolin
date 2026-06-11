import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';

part 'conversation_model.g.dart';

@JsonSerializable()
class ConversationModel extends Equatable {
  final String id;
  final String type;
  final String? name;
  final String? groupImage;
  final List<UserModel>? participants;
  final DateTime? createdAt;

  const ConversationModel({
    required this.id,
    required this.type,
    this.name,
    this.groupImage,
    this.participants,
    this.createdAt,
  });

  /// Creates a ConversationModel from JSON data
  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  /// Converts ConversationModel to JSON
  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);

  /// Creates a copy of ConversationModel with specified fields replaced
  ConversationModel copyWith({
    String? id,
    String? type,
    String? name,
    String? groupImage,
    List<UserModel>? participants,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      groupImage: groupImage ?? this.groupImage,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    name,
    groupImage,
    participants,
    createdAt,
  ];
}
