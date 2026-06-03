import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.isRead = false,
    required this.createdAt,
  });

  /// Creates a MessageModel from JSON data
  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

  /// Converts MessageModel to JSON
  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  /// Creates a copy of MessageModel with specified fields replaced
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Checks if the MessageModel is sent by the current user
  bool isSentByMe(String currentUserId) => senderId == currentUserId;

  @override
  List<Object?> get props => [id, conversationId, senderId, content, type, isRead, createdAt];
}
