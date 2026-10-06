import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/models/character.dart';
import 'package:task_manager/domain/models/characters_page.dart';
import 'package:task_manager/domain/repositories/character_repository.dart';
import 'package:task_manager/domain/repositories/favorite_repository.dart';
import 'package:task_manager/presentation/controllers/characters_controller.dart';
import 'package:task_manager/presentation/providers/app_providers.dart';
import 'package:task_manager/presentation/state/characters_state.dart';

class FakeCharacterRepository implements CharacterRepository {
  FakeCharacterRepository(this.pages);

  final Map<String, CharactersPage> pages;
  final List<String> requestedUrls = [];

  @override
  Future<CharactersPage> fetchPage(
    String url, {
    CancelToken? cancelToken,
  }) async {
    requestedUrls.add(url);

    final page = pages[url];

    if (page == null) {
      throw StateError('No fake page for $url');
    }

    return page;
  }
}

class FakeFavoriteRepository implements FavoriteRepository {
  String? favoriteUrl;

  @override
  Future<String?> getFavoriteUrl() async {
    return favoriteUrl;
  }

  @override
  Future<void> saveFavoriteUrl(String url) async {
    favoriteUrl = url;
  }

  @override
  Future<void> clearFavorite() async {
    favoriteUrl = null;
  }
}

class DelayedFakeCharacterRepository extends FakeCharacterRepository {
  DelayedFakeCharacterRepository(super.pages);

  final Completer<void> page2Completer = Completer<void>();

  @override
  Future<CharactersPage> fetchPage(
    String url, {
    CancelToken? cancelToken,
  }) async {
    requestedUrls.add(url);

    final page = pages[url];

    if (page == null) {
      throw StateError('No fake page for $url');
    }

    if (url.contains('page=2')) {
      await page2Completer.future;
    }

    return page;
  }
}

void main() {
  const page1Url = 'https://swapi.dev/api/people/';
  const page2Url = 'https://swapi.dev/api/people/?page=2';

  late FakeCharacterRepository repository;
  late FakeFavoriteRepository favoriteRepository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeCharacterRepository({
      page1Url: const CharactersPage(
        characters: [Character(name: 'Luke', rawHeight: '172', url: 'luke')],
        nextUrl: page2Url,
      ),
      page2Url: const CharactersPage(
        characters: [Character(name: 'Yoda', rawHeight: '66', url: 'yoda')],
        nextUrl: null,
      ),
    });

    favoriteRepository = FakeFavoriteRepository();

    container = ProviderContainer(
      overrides: [
        characterRepositoryProvider.overrideWithValue(repository),
        favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<CharactersLoaded> waitForLoaded() async {
    container.read(charactersControllerProvider);

    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(charactersControllerProvider);

      if (state is CharactersLoaded) {
        return state;
      }
    }

    fail('Controller did not reach loaded state.');
  }

  test('loads the first page on initialization', () async {
    final state = await waitForLoaded();

    expect(state.visibleCollection.characters.length, 1);
    expect(state.visibleCollection.characters.first.name, 'Luke');

    expect(repository.requestedUrls, [page1Url]);
  });

  test('appends the next page', () async {
    await waitForLoaded();

    await container.read(charactersControllerProvider.notifier).loadNextPage();

    final state = container.read(charactersControllerProvider);

    expect(state, isA<CharactersLoaded>());

    final loaded = state as CharactersLoaded;

    expect(loaded.visibleCollection.characters.length, 2);
  });

  test('stops requesting when next is null', () async {
    await waitForLoaded();

    final controller = container.read(charactersControllerProvider.notifier);

    await controller.loadNextPage();
    await controller.loadNextPage();

    expect(repository.requestedUrls.where((url) => url == page2Url).length, 1);
  });

  test('does not request the same page twice concurrently', () async {
    final delayedRepository = DelayedFakeCharacterRepository({
      page1Url: const CharactersPage(
        characters: [Character(name: 'Luke', rawHeight: '172', url: 'luke')],
        nextUrl: page2Url,
      ),
      page2Url: const CharactersPage(
        characters: [Character(name: 'Yoda', rawHeight: '66', url: 'yoda')],
        nextUrl: null,
      ),
    });

    final delayedFavoriteRepository = FakeFavoriteRepository();

    final delayedContainer = ProviderContainer(
      overrides: [
        characterRepositoryProvider.overrideWithValue(delayedRepository),
        favoriteRepositoryProvider.overrideWithValue(delayedFavoriteRepository),
      ],
    );

    addTearDown(delayedContainer.dispose);

    delayedContainer.read(charactersControllerProvider);

    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      if (delayedContainer.read(charactersControllerProvider)
          is CharactersLoaded) {
        break;
      }
    }

    expect(
      delayedContainer.read(charactersControllerProvider),
      isA<CharactersLoaded>(),
    );

    final controller = delayedContainer.read(
      charactersControllerProvider.notifier,
    );

    final firstRequest = controller.loadNextPage();

    await Future<void>.delayed(Duration.zero);

    final secondRequest = controller.loadNextPage();

    expect(
      delayedRepository.requestedUrls.where((url) => url == page2Url).length,
      1,
    );

    delayedRepository.page2Completer.complete();

    await Future.wait([firstRequest, secondRequest]);

    expect(
      delayedRepository.requestedUrls.where((url) => url == page2Url).length,
      1,
    );
  });

  test('sorts only after the final page is loaded', () async {
    final firstState = await waitForLoaded();

    expect(firstState.visibleCollection.characters.first.name, 'Luke');

    await container.read(charactersControllerProvider.notifier).loadNextPage();

    final state =
        container.read(charactersControllerProvider) as CharactersLoaded;

    expect(
      state.visibleCollection.characters
          .map((character) => character.name)
          .toList(),
      ['Yoda', 'Luke'],
    );
  });
}
