import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/models/character.dart';

void main() {
  group('Character height parsing', () {
    test('parses a numeric height', () {
      const character = Character(
        name: 'Luke Skywalker',
        rawHeight: '172',
        url: 'luke',
      );

      expect(character.heightCm, 172);
      expect(character.rowHeight, 172);
      expect(character.heightLabel, '172');
    });

    test('unknown height uses 80 logical pixels', () {
      const character = Character(
        name: 'Unknown',
        rawHeight: 'unknown',
        url: 'unknown',
      );

      expect(character.heightCm, isNull);
      expect(character.rowHeight, 80);
      expect(character.heightLabel, 'unknown');
    });

    test('none height uses 80 logical pixels', () {
      const character = Character(
        name: 'Unknown',
        rawHeight: 'none',
        url: 'none',
      );

      expect(character.heightCm, isNull);
      expect(character.rowHeight, 80);
      expect(character.heightLabel, 'unknown');
    });

    test('invalid height does not crash', () {
      const character = Character(
        name: 'Invalid',
        rawHeight: 'not-a-number',
        url: 'invalid',
      );

      expect(character.heightCm, isNull);
      expect(character.rowHeight, 80);
    });
  });
}
