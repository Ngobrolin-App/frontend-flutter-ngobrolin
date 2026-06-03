import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation_participant_model.g.dart';

@JsonSerializable()
class ConversationParticipantModel extends Equatable {
  final String id;
  final String conversationId;
  final String name;
  final String username;
  final String? avatarUrl;
  final String? lastReadMessageId;
  final DateTime? joinedAt;

  const ConversationParticipantModel({
    required this.id,
    required this.conversationId,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.lastReadMessageId,
    this.joinedAt,
  });

  /// Creates a Chat from JSON data
  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationParticipantModelFromJson(json);

  /// Converts Chat to JSON
  Map<String, dynamic> toJson() => _$ConversationParticipantModelToJson(this);

  /// Creates a copy of Chat with specified fields replaced
  ConversationParticipantModel copyWith({
    String? id,
    String? conversationId,
    String? name,
    String? username,
    String? avatarUrl,
    String? lastReadMessageId,
    DateTime? joinedAt,
  }) {
    return ConversationParticipantModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    name,
    username,
    avatarUrl,
    lastReadMessageId,
    joinedAt,
  ];
}
