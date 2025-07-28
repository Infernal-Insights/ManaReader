import 'package:flutter/material.dart';

import 'screens/library_screen.dart';

void main() => runApp(const ManaReaderApp());

class ManaReaderApp extends StatelessWidget {
  const ManaReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mana Reader',
      theme: ThemeData.dark(),
      home: const LibraryScreen(),
    );
  }
}
