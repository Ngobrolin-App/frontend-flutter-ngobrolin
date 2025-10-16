import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat.g.dart';

@JsonSerializable()
class Chat extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String username;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  const Chat({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
  });

  /// Creates a Chat from JSON data
  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);

  /// Converts Chat to JSON
  Map<String, dynamic> toJson() => _$ChatToJson(this);

  /// Creates a copy of Chat with specified fields replaced
  Chat copyWith({
    String? id,
    String? userId,
    String? name,
    String? username,
    String? avatarUrl,
    String? lastMessage,
    DateTime? timestamp,
    int? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Creates a Chat with updated unread count
  Chat markAsRead() {
    return copyWith(unreadCount: 0);
  }

  /// Creates a Chat with updated last message
  Chat updateLastMessage(String message, DateTime time) {
    return copyWith(
      lastMessage: message,
      timestamp: time,
      unreadCount: unreadCount + 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        username,
        avatarUrl,
        lastMessage,
        timestamp,
        unreadCount,
      ];
}