import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/favorite_local_datasource.dart';
import '../../data/datasources/swapi_api_client.dart';
import '../../data/repositories/character_repository_impl.dart';
import '../../data/repositories/favorite_repository_impl.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../domain/services/character_sorter.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
    ),
  );
});

final preferencesProvider = Provider<SharedPreferencesAsync>((ref) {
  return SharedPreferencesAsync();
});

final apiClientProvider = Provider<SwapiApiClient>((ref) {
  return SwapiApiClient(ref.watch(dioProvider));
});

final favoriteLocalDataSourceProvider = Provider<FavoriteLocalDataSource>((
  ref,
) {
  return FavoriteLocalDataSource(ref.watch(preferencesProvider));
});

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl(
    localDataSource: ref.watch(favoriteLocalDataSourceProvider),
  );
});

final characterSorterProvider = Provider<CharacterSorter>((ref) {
  return const CharacterSorter();
});
