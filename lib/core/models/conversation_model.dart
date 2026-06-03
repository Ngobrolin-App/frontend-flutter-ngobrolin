import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation_model.g.dart';

@JsonSerializable()
class ConversationModel extends Equatable {
  final String id;
  final String type;
  final String? name;
  final String? groupImage;

  const ConversationModel({required this.id, required this.type, this.name, this.groupImage});

  /// Creates a ConversationModel from JSON data
  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  /// Converts ConversationModel to JSON
  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);

  /// Creates a copy of ConversationModel with specified fields replaced
  ConversationModel copyWith({String? id, String? type, String? name, String? groupImage}) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      groupImage: groupImage ?? this.groupImage,
    );
  }

  @override
  List<Object?> get props => [id, type, name, groupImage];
}
