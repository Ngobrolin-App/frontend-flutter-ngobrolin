import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_list_item_model.g.dart';

@JsonSerializable()
class ChatListItemModel extends Equatable {
  final String id;
  final String type;
  final String userId;
  final String name;
  final String username;
  final String? avatarUrl;
  final String lastMessage;
  final String? lastMessageId;
  final String lastMessageType;
  final DateTime timestamp;
  final int unreadCount;

  const ChatListItemModel({
    required this.id,
    required this.type,
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.lastMessage,
    this.lastMessageId,
    this.lastMessageType = 'text',
    required this.timestamp,
    this.unreadCount = 0,
  });

  /// Creates a ChatListItemModel from JSON data
  factory ChatListItemModel.fromJson(Map<String, dynamic> json) =>
      _$ChatListItemModelFromJson(json);

  /// Converts ChatListItemModel to JSON
  Map<String, dynamic> toJson() => _$ChatListItemModelToJson(this);

  /// Creates a copy of ChatListItemModel with specified fields replaced
  ChatListItemModel copyWith({
    String? id,
    String? type,
    String? userId,
    String? name,
    String? username,
    String? avatarUrl,
    String? lastMessage,
    String? lastMessageId,
    String? lastMessageType,
    DateTime? timestamp,
    int? unreadCount,
  }) {
    return ChatListItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    userId,
    name,
    username,
    avatarUrl,
    lastMessage,
    lastMessageId,
    lastMessageType,
    timestamp,
    unreadCount,
  ];
}
