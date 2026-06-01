import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/db/database.dart';

class SeriesCard extends StatelessWidget {
  final SeriesData series;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SeriesCard({
    super.key,
    required this.series,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            Expanded(
              child: _CoverImage(coverPath: series.coverPath),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Text(
                series.title,
                style: theme.textTheme.labelLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (series.author != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Text(
                  series.author!,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String? coverPath;

  const _CoverImage({this.coverPath});

  @override
  Widget build(BuildContext context) {
    if (coverPath == null || coverPath!.isEmpty) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Icon(Icons.menu_book, size: 48, color: Colors.white24),
        ),
      );
    }

    final file = File(coverPath!);
    return file.existsSync()
        ? Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _Placeholder(),
          )
        : const _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: const Center(
        child: Icon(Icons.menu_book, size: 48, color: Colors.white24),
      ),
    );
  }
}
