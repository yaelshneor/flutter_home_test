import '../models/character.dart';

class CharacterSorter {
  const CharacterSorter();

  List<Character> sortByHeight(List<Character> characters) {
    final sorted = List<Character>.of(characters);

    sorted.sort((a, b) {
      final aHeight = a.heightCm;
      final bHeight = b.heightCm;

      if (aHeight == null && bHeight == null) {
        return 0;
      }

      if (aHeight == null) {
        return 1;
      }

      if (bHeight == null) {
        return -1;
      }

      return aHeight.compareTo(bHeight);
    });

    return sorted;
  }
}
