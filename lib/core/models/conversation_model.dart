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

  final String? groupDescription;
  final String? createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final UserModel? createdByUser;

  const ConversationModel({
    required this.id,
    required this.type,
    this.name,
    this.groupImage,
    this.participants,
    this.groupDescription,
    this.createdByUserId,
    this.createdAt,
    this.updatedAt,
    this.createdByUser,
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
    String? groupDescription,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? createdByUser,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      groupImage: groupImage ?? this.groupImage,
      participants: participants ?? this.participants,
      groupDescription: groupDescription ?? this.groupDescription,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUser: createdByUser ?? this.createdByUser,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    name,
    groupImage,
    participants,
    groupDescription,
    createdByUserId,
    createdAt,
    updatedAt,
    createdByUser,
  ];
}
