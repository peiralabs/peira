/// A media server's status snapshot (Jellyfin or Plex): identity, active
/// playback sessions, per-library counts, and recently added items. Both
/// clients parse into this one shape so the Media tab renders them with the
/// same panel.
class MediaServerStatus {
  const MediaServerStatus({
    required this.serverName,
    required this.version,
    this.sessions = const [],
    this.libraries = const [],
    this.recent = const [],
  });

  final String serverName;
  final String version;
  final List<MediaSession> sessions;
  final List<MediaLibrary> libraries;
  final List<MediaRecentItem> recent;
}

/// One active playback session (now playing).
class MediaSession {
  const MediaSession({
    required this.user,
    required this.title,
    this.subtitle = '',
    this.paused = false,
    this.progress = 0,
  });

  final String user;
  final String title;

  /// Series name for an episode, year for a movie — '' when unknown.
  final String subtitle;
  final bool paused;

  /// Playback position 0–1 (0 when the server didn't report a duration).
  final double progress;
}

/// One library (or item class) with its item count.
class MediaLibrary {
  const MediaLibrary({required this.name, required this.count});

  final String name;
  final int count;
}

/// One recently-added library item.
class MediaRecentItem {
  const MediaRecentItem({required this.title, this.subtitle = ''});

  final String title;
  final String subtitle;
}
