import '../../core/errors/app_failure.dart';
import '../../domain/models/characters_page.dart';
import 'character_dto.dart';

class CharactersPageDto {
  const CharactersPageDto({required this.results, required this.next});

  final List<CharacterDto> results;
  final String? next;

  factory CharactersPageDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final rawNext = json['next'];

    if (rawResults is! List) {
      throw const DataFailure();
    }

    if (rawNext != null && rawNext is! String) {
      throw const DataFailure();
    }

    final results = rawResults.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const DataFailure();
      }

      return CharacterDto.fromJson(item);
    }).toList();

    return CharactersPageDto(results: results, next: rawNext as String?);
  }

  CharactersPage toDomain() {
    return CharactersPage(
      characters: results.map((dto) => dto.toDomain()).toList(),
      nextUrl: next,
    );
  }
}
