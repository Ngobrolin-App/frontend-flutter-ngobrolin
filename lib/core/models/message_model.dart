import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? mediaUrl;
  final String? mediaFileType;
  final int? mediaSize;
  final String? mediaFileName;
  final UserModel? sender;
  final bool? isSendByMe;
  final MessageModel? repliedMessage;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.type = 'text',
    this.isRead = false,
    required this.createdAt,
    this.mediaUrl,
    this.mediaFileType,
    this.mediaSize,
    this.mediaFileName,
    this.sender,
    this.isSendByMe,
    this.repliedMessage,
  });

  /// Creates a MessageModel from JSON data
  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

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
    String? mediaUrl,
    String? mediaFileType,
    int? mediaSize,
    String? mediaFileName,
    UserModel? sender,
    bool? isSendByMe,
    MessageModel? repliedMessage,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaFileType: mediaFileType ?? this.mediaFileType,
      mediaSize: mediaSize ?? this.mediaSize,
      mediaFileName: mediaFileName ?? this.mediaFileName,
      sender: sender ?? this.sender,
      isSendByMe: isSendByMe ?? this.isSendByMe,
      repliedMessage: repliedMessage ?? this.repliedMessage,
    );
  }

  /// Checks if the MessageModel is sent by the current user
  bool isSentByMe(String currentUserId) => senderId == currentUserId;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    type,
    isRead,
    createdAt,
    mediaUrl,
    mediaFileType,
    mediaSize,
    mediaFileName,
    sender,
    repliedMessage,
  ];
}
