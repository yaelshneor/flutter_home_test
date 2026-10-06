import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/models/character.dart';
import 'package:task_manager/domain/services/character_sorter.dart';

void main() {
  const sorter = CharacterSorter();

  test('sorts known heights ascending and places unknown heights last', () {
    const characters = [
      Character(name: 'Luke', rawHeight: '172', url: 'luke'),
      Character(name: 'Unknown', rawHeight: 'unknown', url: 'unknown'),
      Character(name: 'Yoda', rawHeight: '66', url: 'yoda'),
      Character(name: 'Chewbacca', rawHeight: '228', url: 'chewbacca'),
    ];

    final result = sorter.sortByHeight(characters);

    expect(result.map((character) => character.name).toList(), [
      'Yoda',
      'Luke',
      'Chewbacca',
      'Unknown',
    ]);
  });

  test('does not mutate the original list', () {
    const characters = [
      Character(name: 'Luke', rawHeight: '172', url: 'luke'),
      Character(name: 'Yoda', rawHeight: '66', url: 'yoda'),
    ];

    sorter.sortByHeight(characters);

    expect(characters.first.name, 'Luke');
  });
}
