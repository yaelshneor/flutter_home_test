import 'package:dio/dio.dart';

import '../../core/errors/app_failure.dart';
import '../dtos/characters_page_dto.dart';

class SwapiApiClient {
  SwapiApiClient(this._dio);

  final Dio _dio;

  static const String initialPeopleUrl = 'https://swapi.dev/api/people/';

  static const String _primaryHost = 'swapi.dev';
  static const String _fallbackHost = 'swapi.py4e.com';

  Future<CharactersPageDto> fetchPage(
    String url, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await _request(url, cancelToken: cancelToken);
    } on AppFailure catch (failure) {
      final uri = Uri.tryParse(url);

      if (uri?.host == _primaryHost &&
          failure is! CancelledFailure &&
          failure is! DataFailure) {
        final fallbackUri = uri!.replace(host: _fallbackHost);

        return _request(fallbackUri.toString(), cancelToken: cancelToken);
      }

      rethrow;
    }
  }

  Future<CharactersPageDto> _request(
    String url, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(url, cancelToken: cancelToken);

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw const DataFailure();
      }

      return CharactersPageDto.fromJson(data);
    } on DioException catch (error) {
      throw switch (error.type) {
        DioExceptionType.cancel => const CancelledFailure(),
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => const TimeoutFailure(),
        DioExceptionType.connectionError => const NetworkFailure(),
        DioExceptionType.badResponse => ServerFailure(
          'Server error (${error.response?.statusCode ?? 'unknown'}).',
        ),
        _ => const NetworkFailure(),
      };
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const DataFailure();
    }
  }
}
