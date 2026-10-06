import '../../core/errors/app_failure.dart';
import '../../domain/models/character.dart';

class CharacterCollection {
  const CharacterCollection({
    this.characters = const [],
    this.nextUrl,
    this.isLoadingMore = false,
    this.paginationFailure,
    this.requestedUrls = const {},
  });

  final List<Character> characters;
  final String? nextUrl;
  final bool isLoadingMore;
  final AppFailure? paginationFailure;
  final Set<String> requestedUrls;

  bool get hasNextPage => nextUrl != null;

  CharacterCollection copyWith({
    List<Character>? characters,
    String? nextUrl,
    bool clearNextUrl = false,
    bool? isLoadingMore,
    AppFailure? paginationFailure,
    bool clearPaginationFailure = false,
    Set<String>? requestedUrls,
  }) {
    return CharacterCollection(
      characters: characters ?? this.characters,
      nextUrl: clearNextUrl ? null : nextUrl ?? this.nextUrl,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationFailure: clearPaginationFailure
          ? null
          : paginationFailure ?? this.paginationFailure,
      requestedUrls: requestedUrls ?? this.requestedUrls,
    );
  }
}

sealed class CharactersState {
  const CharactersState({required this.favoriteUrl, required this.searchTerm});

  final String? favoriteUrl;
  final String searchTerm;
}

final class CharactersInitialLoading extends CharactersState {
  const CharactersInitialLoading({
    required super.favoriteUrl,
    super.searchTerm = '',
  });
}

final class CharactersInitialError extends CharactersState {
  const CharactersInitialError({
    required this.failure,
    required super.favoriteUrl,
    super.searchTerm = '',
  });

  final AppFailure failure;
}

final class CharactersLoaded extends CharactersState {
  const CharactersLoaded({
    required this.mainCollection,
    required this.visibleCollection,
    required this.isSearching,
    required super.favoriteUrl,
    required super.searchTerm,
  });

  final CharacterCollection mainCollection;
  final CharacterCollection visibleCollection;
  final bool isSearching;

  bool get isEmpty => visibleCollection.characters.isEmpty;

  CharactersLoaded copyWith({
    CharacterCollection? mainCollection,
    CharacterCollection? visibleCollection,
    bool? isSearching,
    String? favoriteUrl,
    bool clearFavorite = false,
    String? searchTerm,
  }) {
    return CharactersLoaded(
      mainCollection: mainCollection ?? this.mainCollection,
      visibleCollection: visibleCollection ?? this.visibleCollection,
      isSearching: isSearching ?? this.isSearching,
      favoriteUrl: clearFavorite ? null : favoriteUrl ?? this.favoriteUrl,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

final class CharactersSearchLoading extends CharactersState {
  const CharactersSearchLoading({
    required this.mainCollection,
    required super.favoriteUrl,
    required super.searchTerm,
  });

  final CharacterCollection mainCollection;
}

final class CharactersSearchError extends CharactersState {
  const CharactersSearchError({
    required this.failure,
    required this.mainCollection,
    required super.favoriteUrl,
    required super.searchTerm,
  });

  final AppFailure failure;
  final CharacterCollection mainCollection;
}
