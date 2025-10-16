import 'package:get_it/get_it.dart';

import '../repositories/auth_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api/api_service.dart';
import '../services/api/dio_client.dart';
import '../viewmodels/auth/auth_view_model.dart';
import '../viewmodels/chat/chat_list_view_model.dart';
import '../viewmodels/chat/chat_view_model.dart';
import '../viewmodels/profile/profile_view_model.dart';
import '../viewmodels/search/search_user_view_model.dart';
import '../viewmodels/settings/settings_view_model.dart';

/// Service locator instance
final GetIt serviceLocator = GetIt.instance;

/// Setup service locator
void setupServiceLocator() {
  // Register services
  serviceLocator.registerLazySingleton(() => DioClient());
  serviceLocator.registerLazySingleton(() => ApiService());

  // Register repositories
  serviceLocator.registerLazySingleton(() => AuthRepository(
        apiService: serviceLocator<ApiService>(),
      ));
  serviceLocator.registerLazySingleton(() => UserRepository(
        apiService: serviceLocator<ApiService>(),
      ));
  serviceLocator.registerLazySingleton(() => ChatRepository(
        apiService: serviceLocator<ApiService>(),
      ));
  serviceLocator.registerLazySingleton(() => SettingsRepository(
        apiService: serviceLocator<ApiService>(),
      ));

  // Register view models
  serviceLocator.registerFactory(() => AuthViewModel(
        authRepository: serviceLocator<AuthRepository>(),
      ));
  serviceLocator.registerFactory(() => ProfileViewModel(
        userRepository: serviceLocator<UserRepository>(),
      ));
  serviceLocator.registerFactory(() => ChatViewModel(
        chatRepository: serviceLocator<ChatRepository>(),
      ));
  serviceLocator.registerFactory(() => ChatListViewModel(
        chatRepository: serviceLocator<ChatRepository>(),
      ));
  serviceLocator.registerFactory(() => SearchUserViewModel(
        userRepository: serviceLocator<UserRepository>(),
      ));
  serviceLocator.registerFactory(() => SettingsViewModel(
        settingsRepository: serviceLocator<SettingsRepository>(),
      ));
}