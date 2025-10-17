import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class Message extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Creates a Message from JSON data
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  /// Converts Message to JSON
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  /// Creates a copy of Message with specified fields replaced
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Checks if the message is sent by the current user
  bool isSentByMe(String currentUserId) => senderId == currentUserId;

  @override
  List<Object?> get props => [id, senderId, receiverId, content, isRead, createdAt, readAt];
}
