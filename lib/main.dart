import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ManaReaderApp()));
}

class ManaReaderApp extends ConsumerWidget {
  const ManaReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter();
    return MaterialApp.router(
      title: 'ManaReader',
      theme: ManaTheme.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
