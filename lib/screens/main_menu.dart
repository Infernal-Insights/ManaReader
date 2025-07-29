import 'package:flutter/material.dart';

import 'history_screen.dart';
import 'library_screen.dart';

/// Simple start screen offering navigation to major sections.
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mana Reader')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              ),
              child: const Text('Library'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: const Text('History'),
            ),
          ],
        ),
      ),
    );
  }
}
