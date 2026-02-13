import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/session_card.dart';

/// Lightweight audio service for word pronunciation playback.
/// Prefetches audio files for the session and plays from cache.
class AudioService {
  AudioPlayer? _player;
  final Map<String, String> _cache = {};

  /// Download audio files for all cards in the session to local cache.
  Future<void> prefetchForSession(
    List<SessionCard> cards,
    String accent,
  ) async {
    final urls = cards
        .map((c) => c.audioUrlFor(accent))
        .where((u) => u != null)
        .cast<String>()
        .toSet();

    final toDownload = urls.where((u) => !_cache.containsKey(u)).toList();
    if (toDownload.isEmpty) return;

    final dir = await _cacheDir();
    await Future.wait(
      toDownload.map((url) => _downloadToCache(url, dir)),
      eagerError: false,
    );
  }

  /// Play audio from cache or URL. Cancels any in-progress playback first.
  Future<void> play(String? audioUrl) async {
    if (audioUrl == null) return;

    try {
      await stop();
      _player ??= AudioPlayer();

      final cached = _cache[audioUrl];
      if (cached != null && File(cached).existsSync()) {
        await _player!.setFilePath(cached);
      } else {
        await _player!.setUrl(audioUrl);
      }
      await _player!.play();
    } catch (_) {
      // Non-blocking — audio failure should never break the session
    }
  }

  /// Stop any in-progress playback.
  Future<void> stop() async {
    try {
      if (_player?.playing == true) {
        await _player!.stop();
      }
    } catch (_) {}
  }

  /// Release player resources.
  void dispose() {
    _player?.dispose();
    _player = null;
  }

  Future<Directory> _cacheDir() async {
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/word_audio');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _downloadToCache(String url, Directory dir) async {
    try {
      final filename = url.hashCode.toRadixString(16);
      final file = File('${dir.path}/$filename.mp3');
      if (file.existsSync()) {
        _cache[url] = file.path;
        return;
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _cache[url] = file.path;
      }
    } catch (_) {
      // Non-blocking
    }
  }
}
