import 'package:image_picker/image_picker.dart';

enum MediaSource { camera, gallery, file }

extension MediaSourceX on MediaSource {
  String get getTranslateKey {
    switch (this) {
      case MediaSource.camera:
        return 'take_photo';
      case MediaSource.gallery:
        return 'choose_image';
      case MediaSource.file:
        return 'choose_file';
    }
  }

  ImageSource? get getImageSource {
    switch (this) {
      case MediaSource.camera:
        return ImageSource.camera;
      case MediaSource.gallery:
        return ImageSource.gallery;
      case MediaSource.file:
        return null;
    }
  }

  String get getMediaType {
    switch (this) {
      case MediaSource.camera:
        return 'image';
      case MediaSource.gallery:
        return 'image';
      case MediaSource.file:
        return 'file';
    }
  }
}

// ==================

enum ReplyMessageLayout { bubble, composer }

enum ConversationType { private, group }

extension ConversationTypeX on ConversationType {
  bool get isShowParticipantsIncludeMe {
    switch (this) {
      case ConversationType.private:
        return false;
      case ConversationType.group:
        return true;
    }
  }
}

enum UserStatus { online, offline }

enum MessageType { text, image, file, audio, video, system }

// ==================

enum ProfileTapOption { viewProfileImage, changeProfileImage }

extension ProfileTapOptionX on ProfileTapOption {
  String get getTranslateKey {
    switch (this) {
      case ProfileTapOption.viewProfileImage:
        return 'view_profile_image';
      case ProfileTapOption.changeProfileImage:
        return 'change_profile_image';
    }
  }
}

// ==================

enum UserSelectionAction { createNewGroup, forwardMessage, addNewMembers }

extension UserSelectionActionX on UserSelectionAction {
  String get getSelectingTranslanteKey {
    switch (this) {
      case UserSelectionAction.createNewGroup:
        return 'select_new_group_members';
      case UserSelectionAction.forwardMessage:
        return 'select_users_to_forward_message';
      case UserSelectionAction.addNewMembers:
        return 'select_add_new_members';
    }
  }
}
