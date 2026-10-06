import 'package:dio/dio.dart';

import '../models/characters_page.dart';

abstract interface class CharacterRepository {
  Future<CharactersPage> fetchPage(String url, {CancelToken? cancelToken});
}
