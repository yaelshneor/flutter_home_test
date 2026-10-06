import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../data/datasources/swapi_api_client.dart';
import '../../domain/models/characters_page.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../domain/services/character_sorter.dart';
import '../providers/app_providers.dart';
import '../state/characters_state.dart';

final charactersControllerProvider =
    NotifierProvider<CharactersController, CharactersState>(
      CharactersController.new,
    );

class CharactersController extends Notifier<CharactersState> {
  late CharacterRepository _characterRepository;
  late FavoriteRepository _favoriteRepository;
  late CharacterSorter _sorter;

  Timer? _searchDebounce;
  CancelToken? _searchCancelToken;
  int _searchGeneration = 0;

  @override
  CharactersState build() {
    _characterRepository = ref.watch(characterRepositoryProvider);
    _favoriteRepository = ref.watch(favoriteRepositoryProvider);
    _sorter = ref.watch(characterSorterProvider);

    ref.onDispose(() {
      _searchDebounce?.cancel();
      _searchCancelToken?.cancel();
    });

    Future.microtask(initialize);

    return const CharactersInitialLoading(favoriteUrl: null);
  }

  Future<void> initialize() async {
    String? favoriteUrl;

    try {
      favoriteUrl = await _favoriteRepository.getFavoriteUrl();
    } on AppFailure {
      favoriteUrl = null;
    }

    state = CharactersInitialLoading(favoriteUrl: favoriteUrl);

    await _loadInitialPage(favoriteUrl);
  }

  Future<void> _loadInitialPage(String? favoriteUrl) async {
    const url = SwapiApiClient.initialPeopleUrl;

    try {
      final page = await _characterRepository.fetchPage(url);

      final collection = _collectionFromFirstPage(page, requestedUrl: url);

      state = CharactersLoaded(
        mainCollection: collection,
        visibleCollection: collection,
        isSearching: false,
        favoriteUrl: favoriteUrl,
        searchTerm: '',
      );
    } on AppFailure catch (failure) {
      state = CharactersInitialError(
        failure: failure,
        favoriteUrl: favoriteUrl,
      );
    }
  }

  Future<void> retryInitial() async {
    final favoriteUrl = state.favoriteUrl;

    state = CharactersInitialLoading(favoriteUrl: favoriteUrl);

    await _loadInitialPage(favoriteUrl);
  }

  Future<void> loadNextPage() async {
    final currentState = state;

    if (currentState is! CharactersLoaded) {
      return;
    }

    final collection = currentState.visibleCollection;
    final nextUrl = collection.nextUrl;

    if (nextUrl == null ||
        collection.isLoadingMore ||
        collection.requestedUrls.contains(nextUrl)) {
      return;
    }

    final requestedUrls = {...collection.requestedUrls, nextUrl};

    final loadingCollection = collection.copyWith(
      isLoadingMore: true,
      clearPaginationFailure: true,
      requestedUrls: requestedUrls,
    );

    state = currentState.copyWith(
      visibleCollection: loadingCollection,
      mainCollection: currentState.isSearching
          ? currentState.mainCollection
          : loadingCollection,
    );

    try {
      final page = await _characterRepository.fetchPage(nextUrl);

      final updated = _appendPage(loadingCollection, page);

      final latestState = state;

      if (latestState is! CharactersLoaded) {
        return;
      }

      if (currentState.isSearching != latestState.isSearching ||
          currentState.searchTerm != latestState.searchTerm) {
        return;
      }

      state = latestState.copyWith(
        visibleCollection: updated,
        mainCollection: latestState.isSearching ? null : updated,
      );
    } on CancelledFailure {
      return;
    } on AppFailure catch (failure) {
      final latestState = state;

      if (latestState is! CharactersLoaded) {
        return;
      }

      if (currentState.isSearching != latestState.isSearching ||
          currentState.searchTerm != latestState.searchTerm) {
        return;
      }

      final failedCollection = loadingCollection.copyWith(
        isLoadingMore: false,
        paginationFailure: failure,
        requestedUrls: {...loadingCollection.requestedUrls}..remove(nextUrl),
      );

      state = latestState.copyWith(
        visibleCollection: failedCollection,
        mainCollection: latestState.isSearching ? null : failedCollection,
      );
    }
  }

  Future<void> retryNextPage() {
    return loadNextPage();
  }

  Future<void> toggleFavorite(String url) async {
    final currentFavorite = state.favoriteUrl;
    final newFavorite = currentFavorite == url ? null : url;

    _setFavoriteInState(newFavorite);

    try {
      if (newFavorite == null) {
        await _favoriteRepository.clearFavorite();
      } else {
        await _favoriteRepository.saveFavoriteUrl(newFavorite);
      }
    } on AppFailure {
      _setFavoriteInState(currentFavorite);
    }
  }

  void _setFavoriteInState(String? favoriteUrl) {
    state = switch (state) {
      CharactersInitialLoading s => CharactersInitialLoading(
        favoriteUrl: favoriteUrl,
        searchTerm: s.searchTerm,
      ),
      CharactersInitialError s => CharactersInitialError(
        failure: s.failure,
        favoriteUrl: favoriteUrl,
        searchTerm: s.searchTerm,
      ),
      CharactersSearchLoading s => CharactersSearchLoading(
        mainCollection: s.mainCollection,
        favoriteUrl: favoriteUrl,
        searchTerm: s.searchTerm,
      ),
      CharactersSearchError s => CharactersSearchError(
        failure: s.failure,
        mainCollection: s.mainCollection,
        favoriteUrl: favoriteUrl,
        searchTerm: s.searchTerm,
      ),
      CharactersLoaded s => s.copyWith(
        favoriteUrl: favoriteUrl,
        clearFavorite: favoriteUrl == null,
      ),
    };
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();

    final term = value.trim();
    final generation = ++_searchGeneration;

    if (term.isEmpty) {
      _searchCancelToken?.cancel('Search cleared');
      _restoreMainList();
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(term, generation),
    );
  }

  Future<void> _performSearch(String term, int generation) async {
    final mainCollection = _mainCollectionFromState();

    if (mainCollection == null) {
      return;
    }

    _searchCancelToken?.cancel('New search');

    final cancelToken = CancelToken();
    _searchCancelToken = cancelToken;

    state = CharactersSearchLoading(
      mainCollection: mainCollection,
      favoriteUrl: state.favoriteUrl,
      searchTerm: term,
    );

    final searchUri = Uri.parse(SwapiApiClient.initialPeopleUrl)
        .replace(queryParameters: {'search': term});

    try {
      final page = await _characterRepository.fetchPage(
        searchUri.toString(),
        cancelToken: cancelToken,
      );

      if (generation != _searchGeneration) {
        return;
      }

      final collection = _collectionFromFirstPage(
        page,
        requestedUrl: searchUri.toString(),
      );

      state = CharactersLoaded(
        mainCollection: mainCollection,
        visibleCollection: collection,
        isSearching: true,
        favoriteUrl: state.favoriteUrl,
        searchTerm: term,
      );
    } on CancelledFailure {
      return;
    } on AppFailure catch (failure) {
      if (generation != _searchGeneration) {
        return;
      }

      state = CharactersSearchError(
        failure: failure,
        mainCollection: mainCollection,
        favoriteUrl: state.favoriteUrl,
        searchTerm: term,
      );
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('Search cleared');
    _searchGeneration++;

    _restoreMainList();
  }

  void _restoreMainList() {
    final mainCollection = _mainCollectionFromState();

    if (mainCollection == null) {
      return;
    }

    state = CharactersLoaded(
      mainCollection: mainCollection,
      visibleCollection: mainCollection,
      isSearching: false,
      favoriteUrl: state.favoriteUrl,
      searchTerm: '',
    );
  }

  CharacterCollection? _mainCollectionFromState() {
    return switch (state) {
      CharactersLoaded s => s.mainCollection,
      CharactersSearchLoading s => s.mainCollection,
      CharactersSearchError s => s.mainCollection,
      _ => null,
    };
  }

  CharacterCollection _collectionFromFirstPage(
    CharactersPage page, {
    required String requestedUrl,
  }) {
    final characters = page.nextUrl == null
        ? _sorter.sortByHeight(page.characters)
        : List.of(page.characters);

    return CharacterCollection(
      characters: characters,
      nextUrl: page.nextUrl,
      requestedUrls: {requestedUrl},
    );
  }

  CharacterCollection _appendPage(
    CharacterCollection current,
    CharactersPage page,
  ) {
    var characters = [...current.characters, ...page.characters];

    if (page.nextUrl == null) {
      characters = _sorter.sortByHeight(characters);
    }

    return current.copyWith(
      characters: characters,
      nextUrl: page.nextUrl,
      clearNextUrl: page.nextUrl == null,
      isLoadingMore: false,
      clearPaginationFailure: true,
    );
  }
}
