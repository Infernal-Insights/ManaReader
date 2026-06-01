import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../core/sync/cache_manager.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final cacheManager = CacheManager(db);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Sync'),
          _SyncPrefsSection(),
          const Divider(),
          const _SectionHeader('Cache'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Clear Cache'),
            subtitle: const Text('Remove all downloaded files'),
            onTap: () => _confirmClearCache(context, cacheManager),
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ManaReader'),
            subtitle: Text('v1.0.0'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(BuildContext context, CacheManager cacheManager) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will remove all downloaded comic files from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await cacheManager.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SyncPrefsSection extends StatefulWidget {
  @override
  State<_SyncPrefsSection> createState() => _SyncPrefsSectionState();
}

class _SyncPrefsSectionState extends State<_SyncPrefsSection> {
  bool _wifiOnly = true;
  bool _autoSync = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> _prefsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'sync_prefs.json'));
  }

  Future<void> _load() async {
    try {
      final file = await _prefsFile();
      if (await file.exists()) {
        final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        setState(() {
          _wifiOnly = map['wifi_only'] as bool? ?? true;
          _autoSync = map['auto_sync'] as bool? ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final file = await _prefsFile();
      await file.writeAsString(
          jsonEncode({'wifi_only': _wifiOnly, 'auto_sync': _autoSync}));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.wifi_outlined),
          title: const Text('Wi-Fi only'),
          subtitle: const Text('Only sync when connected to Wi-Fi'),
          value: _wifiOnly,
          onChanged: (v) {
            setState(() => _wifiOnly = v);
            _save();
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.sync_outlined),
          title: const Text('Auto sync'),
          subtitle: const Text('Sync when the app opens'),
          value: _autoSync,
          onChanged: (v) {
            setState(() => _autoSync = v);
            _save();
          },
        ),
      ],
    );
  }
}
