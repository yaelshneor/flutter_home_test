import '../../core/errors/app_failure.dart';
import '../../domain/models/character.dart';

class CharacterDto {
  const CharacterDto({
    required this.name,
    required this.height,
    required this.url,
  });

  final String name;
  final String height;
  final String url;

  factory CharacterDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final height = json['height'];
    final url = json['url'];

    if (name is! String || height is! String || url is! String) {
      throw const DataFailure();
    }

    return CharacterDto(name: name, height: height, url: url);
  }

  Character toDomain() {
    return Character(name: name, rawHeight: height, url: url);
  }
}
