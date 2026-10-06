import 'package:flutter/material.dart';

import '../../domain/models/character.dart';

class CharacterRow extends StatelessWidget {
  const CharacterRow({
    super.key,
    required this.character,
    required this.isFavorite,
    required this.onTap,
  });

  final Character character;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: character.rowHeight,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Material(
                color: isFavorite
                    ? colorScheme.secondaryContainer
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isFavorite
                      ? BorderSide(color: colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: isFavorite
                              ? Icon(
                                  Icons.star_rounded,
                                  color: colorScheme.primary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            character.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: isFavorite
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          constraints: const BoxConstraints(minWidth: 64),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            character.heightLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Visual separator between character rows.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
