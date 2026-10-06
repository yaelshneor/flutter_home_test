import 'package:flutter/material.dart';

import '../state/characters_state.dart';
import 'character_row.dart';
import 'pagination_status.dart';

class CharactersList extends StatelessWidget {
  const CharactersList({
    super.key,
    required this.collection,
    required this.favoriteUrl,
    required this.scrollController,
    required this.onFavoriteTap,
    required this.onRetryPagination,
  });

  final CharacterCollection collection;
  final String? favoriteUrl;
  final ScrollController scrollController;
  final ValueChanged<String> onFavoriteTap;
  final VoidCallback onRetryPagination;

  @override
  Widget build(BuildContext context) {
    if (collection.characters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No characters found.'),
        ),
      );
    }

    final hasFooter =
        collection.isLoadingMore || collection.paginationFailure != null;

    return ListView.builder(
      key: const PageStorageKey<String>('characters-list'),
      controller: scrollController,
      itemCount: collection.characters.length + (hasFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == collection.characters.length) {
          return PaginationStatus(
            isLoading: collection.isLoadingMore,
            failure: collection.paginationFailure,
            onRetry: onRetryPagination,
          );
        }

        final character = collection.characters[index];

        return CharacterRow(
          key: ValueKey(character.url),
          character: character,
          isFavorite: favoriteUrl == character.url,
          onTap: () => onFavoriteTap(character.url),
        );
      },
    );
  }
}
