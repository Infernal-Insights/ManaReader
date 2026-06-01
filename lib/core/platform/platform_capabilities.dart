import 'dart:io';

/// Feature flags per platform.
class PlatformCapabilities {
  final bool canWatchFolders;
  final bool canScanFilesystem;
  final bool canPersistFolderAccess;

  const PlatformCapabilities({
    required this.canWatchFolders,
    required this.canScanFilesystem,
    required this.canPersistFolderAccess,
  });

  /// Resolve capabilities for the current runtime platform.
  static PlatformCapabilities current() {
    if (Platform.isAndroid) {
      return const PlatformCapabilities(
        canWatchFolders: false,
        canScanFilesystem: false,
        canPersistFolderAccess: true, // via SAF persisted URIs
      );
    } else if (Platform.isIOS) {
      return const PlatformCapabilities(
        canWatchFolders: false,
        canScanFilesystem: false,
        canPersistFolderAccess: true, // via security-scoped bookmarks
      );
    } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return const PlatformCapabilities(
        canWatchFolders: true,
        canScanFilesystem: true,
        canPersistFolderAccess: true,
      );
    }
    return const PlatformCapabilities(
      canWatchFolders: false,
      canScanFilesystem: false,
      canPersistFolderAccess: false,
    );
  }
}
