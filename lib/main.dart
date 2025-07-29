import 'package:flutter/material.dart';
import 'screens/main_menu.dart';

void main() => runApp(const ManaReaderApp());

class ManaReaderApp extends StatelessWidget {
  const ManaReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mana Reader',
      theme: ThemeData.dark(),
      home: const MainMenu(),
    );
  }
}
