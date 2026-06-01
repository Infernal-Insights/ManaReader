import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/source/google_drive_source.dart';
import '../../core/sync/sync_engine.dart';

class AddDriveSourceScreen extends ConsumerStatefulWidget {
  const AddDriveSourceScreen({super.key});

  @override
  ConsumerState<AddDriveSourceScreen> createState() =>
      _AddDriveSourceScreenState();
}

class _AddDriveSourceScreenState
    extends ConsumerState<AddDriveSourceScreen> {
  bool _signingIn = false;
  bool _signedIn = false;
  bool _syncing = false;
  String? _userEmail;
  String? _error;
  GoogleDriveSource? _source;

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      final sourceId = 'gdrive_${const Uuid().v4()}';
      final source = GoogleDriveSource(id: sourceId);
      final account = await source.signIn();
      if (account == null) throw Exception('Sign-in cancelled');
      setState(() {
        _signedIn = true;
        _signingIn = false;
        _userEmail = account.email;
        _source = source;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _signingIn = false;
      });
    }
  }

  Future<void> _addSource() async {
    if (_source == null) return;
    setState(() => _syncing = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.sourceConfigDao.upsert(SourceConfigCompanion(
        sourceId: Value(_source!.id),
        type: const Value('google_drive'),
        configJson: Value(jsonEncode({'email': _userEmail})),
      ));
      final engine = SyncEngine(db);
      await engine.sync(_source!);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Drive source added')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Google Drive')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_outlined, size: 64, color: Color(0xFF9B59B6)),
            const SizedBox(height: 24),
            const Text(
              'Connect your Google Drive to sync your comic collection.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_signedIn) ...[
              ElevatedButton.icon(
                onPressed: _signingIn ? null : _signIn,
                icon: _signingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _userEmail ?? 'Signed in',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _syncing ? null : _addSource,
                child: _syncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Add Drive Source'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
