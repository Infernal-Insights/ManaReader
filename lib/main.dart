import 'package:flutter/material.dart';
import 'screens/main_menu.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'database/db_helper.dart';

void main() => runApp(const ManaReaderApp());

class ManaReaderApp extends StatefulWidget {
  const ManaReaderApp({super.key});

  @override
  State<ManaReaderApp> createState() => _ManaReaderAppState();
}

class _ManaReaderAppState extends State<ManaReaderApp> {
  @override
  void dispose() {
    DbHelper.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainMenu(),
    );
  }
}
