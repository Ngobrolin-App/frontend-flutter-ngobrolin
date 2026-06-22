import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ngobrolin_app/core/models/message_model.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';

part 'chat_list_item_model.g.dart';

@JsonSerializable()
class ChatListItemModel extends Equatable {
  final String id;
  final String type;
  final String? name;
  final String? groupImage;
  final DateTime? createdAt;
  final UserModel? privatePartnerUser;
  final MessageModel? lastMessage;
  final List<UserModel>? participants;
  final DateTime? joinedAt;
  final int? unreadCount;

  const ChatListItemModel({
    required this.id,
    required this.type,
    this.name,
    this.groupImage,
    this.createdAt,
    this.privatePartnerUser,
    this.lastMessage,
    this.participants,
    this.joinedAt,
    this.unreadCount,
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
    String? name,
    String? groupImage,
    DateTime? createdAt,
    UserModel? privatePartnerUser,
    MessageModel? lastMessage,
    List<UserModel>? participants,
    DateTime? joinedAt,
    int? unreadCount,
  }) {
    return ChatListItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      groupImage: groupImage ?? this.groupImage,
      createdAt: createdAt ?? this.createdAt,
      privatePartnerUser: privatePartnerUser ?? this.privatePartnerUser,
      lastMessage: lastMessage ?? this.lastMessage,
      participants: participants ?? this.participants,
      joinedAt: joinedAt ?? this.joinedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    name,
    groupImage,
    createdAt,
    privatePartnerUser,
    lastMessage,
    participants,
    joinedAt,
    unreadCount,
  ];
}
