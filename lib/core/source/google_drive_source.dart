import 'dart:io';
import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

import 'content_source.dart';

const _kSupportedMimes = {
  'application/zip',
  'application/x-cbz',
  'application/pdf',
};

const _kSupportedExts = {'.cbz', '.zip', '.pdf'};

/// Google Drive implementation of [ContentSource].
/// Lists comic files in a configured Drive folder and downloads them on demand.
class GoogleDriveSource implements ContentSource {
  @override
  final String id;

  @override
  final String displayName;

  /// Drive folder ID to mirror. Defaults to root if null.
  final String? folderId;

  final GoogleSignIn _signIn;
  drive.DriveApi? _driveApi;
  http.Client? _httpClient;

  GoogleDriveSource({
    required this.id,
    this.displayName = 'Google Drive',
    this.folderId,
  }) : _signIn = GoogleSignIn(scopes: [drive.DriveApi.driveReadonlyScope]);

  @override
  bool get supportsWatching => false;

  Future<drive.DriveApi> _getApi() async {
    if (_driveApi != null) return _driveApi!;
    final account = _signIn.currentUser ?? await _signIn.signInSilently();
    if (account == null) throw Exception('Not signed in to Google');
    _httpClient = await _signIn.authenticatedClient();
    _driveApi = drive.DriveApi(_httpClient!);
    return _driveApi!;
  }

  @override
  Future<List<SourceItem>> listItems() async {
    final api = await _getApi();
    final items = <SourceItem>[];

    String? pageToken;
    do {
      final parentQuery = folderId != null
          ? "'${folderId!}' in parents"
          : "'root' in parents";
      final response = await api.files.list(
        q: "$parentQuery and trashed = false",
        fields: 'nextPageToken, files(id, name, size, modifiedTime, mimeType)',
        pageSize: 200,
        pageToken: pageToken,
        spaces: 'drive',
      );

      for (final file in response.files ?? []) {
        final name = file.name ?? '';
        final ext = p.extension(name).toLowerCase();
        final mime = file.mimeType ?? '';
        if (_kSupportedExts.contains(ext) || _kSupportedMimes.contains(mime)) {
          items.add(SourceItem(
            id: file.id!,
            title: p.basenameWithoutExtension(name),
            remoteId: file.id,
            fileSizeBytes: int.tryParse(file.size ?? ''),
            modifiedAt: file.modifiedTime,
          ));
        }
      }
      pageToken = response.nextPageToken;
    } while (pageToken != null);

    return items;
  }

  @override
  Future<File> fetchFile(String itemId) async {
    final api = await _getApi();
    final cacheDir = await getApplicationCacheDirectory();
    final destDir = Directory(p.join(cacheDir.path, 'drive_cache', id));
    await destDir.create(recursive: true);

    // Fetch file metadata to get original name
    final meta = await api.files.get(
      itemId,
      $fields: 'name,md5Checksum,size',
    ) as drive.File;

    final fileName = meta.name ?? itemId;
    final destPath = p.join(destDir.path, '$itemId${p.extension(fileName)}');
    final destFile = File(destPath);

    // Check if we already have a valid cached copy
    if (await destFile.exists()) {
      if (meta.md5Checksum != null) {
        final existing = await destFile.readAsBytes();
        final hash = md5.convert(existing).toString();
        if (hash == meta.md5Checksum) return destFile;
      } else {
        return destFile;
      }
    }

    // Download file
    final media = await api.files.get(
      itemId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final sink = destFile.openWrite();
    await media.stream.pipe(sink);
    await sink.close();

    return destFile;
  }

  Future<GoogleSignInAccount?> signIn() => _signIn.signIn();
  Future<void> signOut() async {
    await _signIn.signOut();
    _driveApi = null;
    _httpClient?.close();
    _httpClient = null;
  }

  bool get isSignedIn => _signIn.currentUser != null;

  @override
  Future<void> dispose() async {
    _httpClient?.close();
  }
}
