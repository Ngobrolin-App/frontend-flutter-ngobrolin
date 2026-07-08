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

  // Media
  final String? mediaUrl;
  final String? mediaFileName;
  final String? mediaFileType;
  final int? mediaSize;

  // Forward
  final String? forwardedFromMessageId;
  final int? forwardedCount;

  // System
  final String? systemEventType;
  final Map<String, dynamic>? systemMetadata;

  // Relation
  final UserModel? sender;
  final MessageModel? repliedMessage;

  // UI helper
  final bool? isSendByMe;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.type = 'text',
    this.isRead = false,
    required this.createdAt,
    this.mediaUrl,
    this.mediaFileName,
    this.mediaFileType,
    this.mediaSize,
    this.forwardedFromMessageId,
    this.forwardedCount,
    this.systemEventType,
    this.systemMetadata,
    this.sender,
    this.repliedMessage,
    this.isSendByMe,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? mediaUrl,
    String? mediaFileName,
    String? mediaFileType,
    int? mediaSize,
    String? forwardedFromMessageId,
    int? forwardedCount,
    String? systemEventType,
    Map<String, dynamic>? systemMetadata,
    UserModel? sender,
    MessageModel? repliedMessage,
    bool? isSendByMe,
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
      mediaFileName: mediaFileName ?? this.mediaFileName,
      mediaFileType: mediaFileType ?? this.mediaFileType,
      mediaSize: mediaSize ?? this.mediaSize,
      forwardedFromMessageId:
          forwardedFromMessageId ?? this.forwardedFromMessageId,
      forwardedCount: forwardedCount ?? this.forwardedCount,
      systemEventType: systemEventType ?? this.systemEventType,
      systemMetadata: systemMetadata ?? this.systemMetadata,
      sender: sender ?? this.sender,
      repliedMessage: repliedMessage ?? this.repliedMessage,
      isSendByMe: isSendByMe ?? this.isSendByMe,
    );
  }

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
    mediaFileName,
    mediaFileType,
    mediaSize,
    forwardedFromMessageId,
    forwardedCount,
    systemEventType,
    systemMetadata,
    sender,
    repliedMessage,
    isSendByMe,
  ];
}
