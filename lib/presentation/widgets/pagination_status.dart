import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';

class PaginationStatus extends StatelessWidget {
  const PaginationStatus({
    super.key,
    required this.isLoading,
    required this.failure,
    required this.onRetry,
  });

  final bool isLoading;
  final AppFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Loading next page...'),
          ],
        ),
      );
    }

    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(failure!.message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
