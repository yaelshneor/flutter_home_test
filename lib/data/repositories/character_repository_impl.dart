import 'package:dio/dio.dart';

import '../../domain/models/characters_page.dart';
import '../../domain/repositories/character_repository.dart';
import '../datasources/swapi_api_client.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  CharacterRepositoryImpl({required this.apiClient});

  final SwapiApiClient apiClient;

  @override
  Future<CharactersPage> fetchPage(
    String url, {
    CancelToken? cancelToken,
  }) async {
    final dto = await apiClient.fetchPage(url, cancelToken: cancelToken);

    return dto.toDomain();
  }
}
