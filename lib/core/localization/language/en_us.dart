// English language strings
const Map<String, String> enUS = {
  // App name
  'app_name': 'Ngobrolin',

  // Onboarding
  'welcome_message': 'Welcome to Ngobrolin!',
  'welcome_description_1': 'Find new friends and connect anytime, anywhere.',
  'welcome_description_2':
      'Build connections, share stories, and stay close with anyone.',
  'start_now': 'Start Now',

  // Auth
  'sign_in': 'Sign In',
  'sign_up': 'Sign Up',
  'username': 'Username',
  'enter_username': 'Enter username',
  'username_or_email': 'Username or Email',
  'enter_username_or_email': 'Enter username or email',
  'please_enter_username_or_email': 'Please enter your username or email',
  'password': 'Password',
  'confirm_password': 'Confirm Password',
  'enter_password': 'Enter password',
  'name': 'Name',
  'enter_name': 'Enter Name',
  'dont_have_account': 'Don\'t have an account?',
  'register': 'Register',
  'already_have_account': 'Already have an account?',
  'login': 'Login',
  'forgot_password': 'Forgot Password?',
  'registration_successful': 'Registration Successful',
  'registration_failed': 'Registration Failed',
  'login_failed': 'Login Failed',
  'please_enter_name': 'Please enter your name',
  'please_enter_username': 'Please enter your username',
  'please_enter_password': 'Please enter your password',
  'username_cannot_contain_spaces': 'Username cannot contain spaces',
  'password_must_be_at_least_6_characters':
      'Password must be at least 6 characters',
  'please_confirm_your_password': 'Please confirm your password',
  'passwords_do_not_match': 'Passwords do not match',

  // Forgot Password
  'forgot_password_desc':
      'Enter your email address and we will send you a link to reset your password.',
  'enter_email': 'Enter your email',
  'email': 'Email',
  'please_enter_email': 'Please enter your email',
  'invalid_email': 'Please enter a valid email',
  'send_reset_link': 'Send Reset Link',
  'email_sent': 'Email Sent!',
  'reset_email_sent_desc':
      'We have sent a password reset link to your email. Please check your inbox and spam folder.',
  'back_to_login': 'Back to Login',
  'forgot_password_failed': 'Failed to send reset link',
  'reset_password': 'Reset Password',
  'reset_password_desc': 'Please enter your new password below.',
  'enter_new_password': 'Enter new password',
  'invalid_token': 'Invalid or missing reset token',
  'reset_password_failed': 'Failed to reset password',
  'password_reset_success': 'Password Reset Successful!',
  'password_reset_success_desc':
      'Your password has been reset successfully. You can now login with your new password.',

  // Main Navigation
  'chats': 'Chats',
  'users': 'Users',
  'profile': 'Profile',
  'settings': 'Settings',
  'route_not_found': 'Route not found',

  // Search
  'search_chat_friends': 'Search chat friends',
  'search_users': 'Search users',
  'no_users_found': 'No users found',

  // Profile
  'edit_profile': 'Edit Profile',
  'bio': 'Bio',
  'current_password': 'Current Password',
  'new_password': 'New Password',
  'confirm_new_password': 'Confirm New Password',
  'save_changes': 'Save Changes',
  'save': 'Save',
  'start_chat': 'Start Chat',
  'message': 'Message',
  'logout': 'Logout',
  'change_password': 'Change Password',
  'profile_updated': 'Profile updated successfully',
  'logout_success': 'Successfully logged out',
  'logout_failed': 'Failed to log out',

  // Settings
  'blocked_users': 'Blocked Users',
  'app_language': 'App Language',
  'private_account': 'Private Account',
  'private_account_description':
      'When your account is set to private, other users cannot start a chat with you.',
  'block_account': 'Block Account',
  'yes': 'Yes',
  'no': 'No',
  'are_you_sure_logout': 'Are you sure you want to logout?',
  'are_you_sure_block': 'Are you sure you want to block this user?',
  'no_blocked_users': 'No blocked users',
  'no_blocked_users_description': 'No users have been blocked yet.',
  'unblock': 'Unblock',
  'unblock_user': 'Unblock User',
  'unblock_user_confirmation': 'Are you sure you want to unblock this user?',
  'user_unblocked': 'User unblocked successfully',
  'about_ngobrolin': 'About Ngobrolin',
  'about_ngobrolin_description':
      'Ngobrolin is a messaging app that allows users to share stories, interact, and stay close with anyone.',
  '2025_ngobrolin': '@2025 Ngobrolin',

  // Chat
  'type_message': 'Type a message...',
  'no_messages': 'No messages yet',
  'no_chats': 'No chats yet',
  'start_new_chat': 'Start a new chat',
  'user_is_blocked_cannot_start_chat':
      'This user is blocked. You cannot start a chat.',
  'choose_image': 'Choose Image',
  'choose_file': 'Choose File',
  'file': 'File',
  'image': 'Image',
  'typing': 'Typing',
  'online': 'Online',
  'copied_to_clipboard': 'Copied to clipboard',
  'replying_to': 'Replying to',
  'take_photo': 'Take Photo',
  'preview_image': 'Preview Image',
  'add_caption': 'Add caption',
  "new_group": "New Group",
  "groups": "Groups",
  "group": "Group",
  'group_info': 'Group Info',
  'group_description': 'Group Description',
  'description': 'Description',
  "select_members": "Select Members",
  "new_community": "New Community",
  "community": "Community",
  "communities": "Communities",
  "leave_group": "Leave Group",
  "add_members": "Add Members",
  "leave_community": "Leave Community",
  "continue": "Continue",
  "select_new_group_members": "Select New Group Members",
  "preview_attachment": "Preview Attachment",
  "crop_image": "Crop Image",
  'group_name': 'Group Name',
  'please_enter_group_name': 'Please enter a group name',
  'members': 'Members',
  'create_new_group': 'Create New Group',
  'participantids_required': 'At least one participant is required',
  'create_group_success': 'Group created successfully',
  'create_group_failed': 'Failed to create group',
  'download_and_open': 'Download and Open',
  'download': 'Download',
  'forward': 'Forward',
  'forwarded': 'Forwarded',
  'copy': 'Copy',
  'reply': 'Reply',
  'message_unsent': 'Message unsent',
  'unsend_message': 'Unsend Message',
  'createdbyuserid_required': 'Creator user ID is required',
  'are_you_sure_leave_group': 'Are you sure you want to leave this group?',
  'leave_group_success': 'Successfully left the group',
  'leave_group_failed': 'Failed to leave the group',
  'add_group_description': 'Add group description',
  'group_description_visibility':
      'The group description is visible to group members, people invited to this group, and people who request to join this group.',
  'conversation_update_success': 'Conversation updated successfully',
  'conversation_update_failed': 'Failed to update conversation',
  'conversation_name_update_success': 'Conversation name updated successfully',
  'conversation_name_update_failed': 'Failed to update conversation name',
  'conversation_group_image_update_success': 'Group image updated successfully',
  'conversation_group_image_update_failed': 'Failed to update group image',
  'conversation_group_description_update_success':
      'Group description updated successfully',
  'conversation_group_description_update_failed':
      'Failed to update group description',
  'join_group': 'Join Group',
  'request_to_join_group': 'Request to Join Group',
  'none_selected': 'Nothing selected',
  'select_users': 'Select Users',
  'select_add_new_members': 'Select Members to Add',
  'select_users_to_forward_message': 'Select users to forward the message',
  'already_member': 'Already a member',
  'member': 'Member',
  'add_member_success': 'Member added successfully',
  'add_member_failed': 'Failed to add member',
  'participants_added_success': 'Participants added successfully',

  // General Enums
  'view_profile_image': 'View Profile Image',
  'change_profile_image': 'Change Profile Image',

  // Errors
  'error_occurred': 'An error occurred',
  'try_again': 'Try again',
  'no_internet': 'No internet connection',
  'check_connection': 'Please check your connection and try again',
  'failed_to_send_message': 'Failed to send message',
  "failed_to_load_image": "Failed to load image",
  "image_unavailable": "Image unavailable",
  "failed_to_pick_image": "Failed to pick image",
  'no_file_uploaded': 'No file uploaded',
  'permission_denied': 'Permission denied',

  // Misc
  'cancel': 'Cancel',
  'ok': 'OK',
  'done': 'Done',
  'next': 'Next',
  'back': 'Back',
  'search': 'Search',
  'loading': 'Loading...',
  'today': 'Today',
  'yesterday': 'Yesterday',
  'read_more': 'Read more',
  'load_more': 'Load more',
  'none': 'None',

  // Custom messages for block/unblock with name
  'has_been_unblocked': 'has been unblocked',
  'failed_to_unblock': 'Failed to unblock',
  'has_been_blocked': 'has been blocked',
  'failed_to_block': 'Failed to block',

  // Language
  'language': 'Bahasa',
  'english': 'English',
  'indonesia': 'Indonesia',

  // Api Response Messages
  'user_with_username_or_email_not_found':
      'User with username or email not found',
  'password_incorrect': 'Password is incorrect',
  'current_password_incorrect': 'Current password is incorrect',
  'login_success': 'Login successful',
  'registration_success': 'Registration successful',
  'validation_failed': 'Validation failed',
  'email_already_exists': 'Email already exists',
  'user_not_found': 'User not found',
  'data_retrieved': 'Data retrieved successfully',
  'email_not_registered': 'Email not registered',
  'token_invalid_or_expired': 'Token is invalid or has expired',
  'user_is_blocked': 'User is blocked',
  'user_blocked_successfully': 'User blocked successfully',
  'cannot_block_yourself': 'Cannot block yourself',
  'user_already_blocked': 'User is already blocked',
  'user_unblocked_successfully': 'User unblocked successfully',
  'user_is_not_blocked': 'User is not blocked',
  'partnerid_required': 'PartnerId required',
  'conversationid_required': 'ConversationId required',
  'authentication_failed': 'Authentication Failed',
  'reset_password_email_sent_failed': 'Failed to send the password reset email',
  'reset_password_email_sent_success':
      'An email to reset your password has been sent',
  'create_conversation_failed': 'Failed to create conversation',
  'create_conversation_private_user_failed':
      'Failed to create conversation with private user',
  'create_conversation_blocked_user_failed':
      'Failed to create conversation with blocked user',
  'create_conversation_success': 'Successfully started a conversation',
  'access_denied': 'Access Denied',
  'conversation_not_found': 'Conversation Not Found',
  'can_only_update_group_conversations': 'Can only update group conversations',
  'you_are_not_a_participant': 'You are not a participant in this conversation',
  'left_conversation_success': 'Successfully left the conversation',
  'message_sent_success': 'Message sent successfully',
  'message_sent_failed': 'Failed to send message',
  'message_not_found': 'Message not found',
  'can_only_edit_your_own_messages': 'Can only edit your own messages',
  'can_only_delete_your_own_messages': 'Can only delete your own messages',
  'message_update_success': 'Message updated successfully',
  'message_update_failed': 'Failed to update message',
  'message_delete_success': 'Message deleted successfully',
  'message_delete_failed': 'Failed to delete message',
  'messages_marked_as_read': 'Messages marked as read',

  // RESPONSESTATUS STATUSCODE
  // --- 2xx Success ---
  'success': 'Success',
  'resource_created_successfully': 'Resource created successfully',
  'request_accepted_and_processing':
      'Request accepted and is currently processing',
  'request_successful_with_no_content':
      'Request successful with no content returned',
  // --- 3xx Redirection ---
  'resource_moved_permanently': 'Resource moved permanently',
  'resource_found_elsewhere': 'Resource found elsewhere',
  'resource_not_modified': 'Resource not modified',
  // --- 4xx Client Errors ---
  'bad_request_or_invalid_syntax': 'Bad request or invalid syntax',
  'unauthorized_access_authentication_required':
      'Unauthorized access, authentication required',
  'forbidden_access_permission_denied': 'Forbidden access, permission denied',
  'resource_not_found': 'Resource not found',
  'http_method_not_allowed': 'HTTP method not allowed',
  'resource_conflict_state': 'Resource conflict state',
  'validation_error': 'Unprocessable entity, validation error',
  'rate_limit_exceeded': 'Too many requests, rate limit exceeded',
  // --- 5xx Server Errors ---
  'internal_server_error': 'Internal server error',
  'server_does_not_support_functionality':
      'Server does not support requested functionality',
  'invalid_response_from_upstream_server':
      'Bad gateway, invalid response from upstream server',
  'server_temporarily_overloaded_or_down':
      'Service unavailable, server temporarily overloaded or down',
  'upstream_server_timeout': 'Gateway timeout, upstream server timed out',

  // PERMISSION
  'permission_request': 'Permission Request',

  'notification_permission_request': 'Notification Permission Request',
  'notification_permission_request_desc':
      'To make sure you don\'t miss any important chats from your friends, allow Ngobrolin to send notifications to your phone.',

  'camera_permission_request': 'Camera permission request',
  'camera_permission_request_desc':
      'Allow Ngobrolin to access your camera so you can take photos and share them in chats.',

  'media_permission_request': 'Files, Photos & Videos permission request',
  'media_permission_request_desc':
      'Allow Ngobrolin to access your files, photos, and videos so you can share them in chats.',

  'later': 'Later',
  'enable': 'Enable',

  // WITH ARGS
  'system_msg_group_created': '{actorName} created the group "{groupName}"',
  'system_msg_user_added': '{actorName} added {targetName}',
  'system_msg_image_changed': '{actorName} changed the group photo',
  'system_msg_name_changed':
      '{actorName} changed the group name to "{groupName}"',
  'system_msg_user_removed': '{actorName} removed {targetName}',
  'system_msg_user_left': '{actorName} left the group',
  'user_typing': '{actorName} is typing',
  'number_of_members': '{number} members',
  'system_msg_description_changed':
      '{actorName} changed the group description to "{groupDescription}"',
};
