import 'character.dart';

class CharactersPage {
  const CharactersPage({required this.characters, required this.nextUrl});

  final List<Character> characters;
  final String? nextUrl;

  bool get hasNextPage => nextUrl != null;
}
