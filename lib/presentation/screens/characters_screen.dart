import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../controllers/characters_controller.dart';
import '../state/characters_state.dart';
import '../widgets/characters_list.dart';

class CharactersScreen extends ConsumerStatefulWidget {
  const CharactersScreen({super.key});

  @override
  ConsumerState<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends ConsumerState<CharactersScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()..addListener(_onScroll);

    _searchController = TextEditingController();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    const threshold = 400.0;

    if (_scrollController.position.extentAfter < threshold) {
      ref.read(charactersControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(charactersControllerProvider);

    if (_searchController.text != state.searchTerm &&
        state.searchTerm.isEmpty) {
      _searchController.clear();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Star Wars Characters')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _SearchField(
                  controller: _searchController,
                  onChanged: ref
                      .read(charactersControllerProvider.notifier)
                      .onSearchChanged,
                  onClear: () {
                    _searchController.clear();

                    ref
                        .read(charactersControllerProvider.notifier)
                        .clearSearch();
                  },
                ),
                Expanded(
                  child: switch (state) {
                    CharactersInitialLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    CharactersInitialError(:final failure) => _InitialError(
                      failure: failure,
                      onRetry: () {
                        ref
                            .read(charactersControllerProvider.notifier)
                            .retryInitial();
                      },
                    ),
                    CharactersSearchLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    CharactersSearchError(:final failure) => _SearchError(
                      failure: failure,
                      onRetry: () {
                        ref
                            .read(charactersControllerProvider.notifier)
                            .onSearchChanged(_searchController.text);
                      },
                    ),
                    CharactersLoaded(
                      :final visibleCollection,
                      :final favoriteUrl,
                    ) =>
                      CharactersList(
                        collection: visibleCollection,
                        favoriteUrl: favoriteUrl,
                        scrollController: _scrollController,
                        onFavoriteTap: (url) {
                          ref
                              .read(charactersControllerProvider.notifier)
                              .toggleFavorite(url);
                        },
                        onRetryPagination: () {
                          ref
                              .read(charactersControllerProvider.notifier)
                              .retryNextPage();
                        },
                      ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.clear),
              );
            },
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _InitialError extends StatelessWidget {
  const _InitialError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(failure.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry search'),
            ),
          ],
        ),
      ),
    );
  }
}
