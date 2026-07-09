import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';

part 'conversation_participant_model.g.dart';

@JsonSerializable()
class ConversationParticipantModel extends Equatable {
  final String id;
  final String conversationId;
  final String userId;
  final String? lastReadMessageId;
  final DateTime? joinedAt;
  final UserModel? user;

  const ConversationParticipantModel({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.lastReadMessageId,
    this.joinedAt,
    this.user,
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
    String? userId,
    String? lastReadMessageId,
    DateTime? joinedAt,
    UserModel? user,
  }) {
    return ConversationParticipantModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      joinedAt: joinedAt ?? this.joinedAt,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    userId,
    lastReadMessageId,
    joinedAt,
    user,
  ];
}
