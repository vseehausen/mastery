import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A queued review write that failed to persist and needs retry.
class QueuedReviewWrite {
  const QueuedReviewWrite({
    required this.cardId,
    required this.vocabularyId,
    required this.userId,
    required this.sessionId,
    required this.rating,
    required this.responseTimeMs,
    required this.interactionMode,
    required this.stateBefore,
    required this.stateAfter,
    required this.stabilityBefore,
    required this.stabilityAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
    required this.retrievabilityAtReview,
    required this.cueType,
    required this.due,
    required this.state,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    required this.isLeech,
    required this.progressStage,
    required this.timestamp,
  });

  factory QueuedReviewWrite.fromJson(Map<String, dynamic> json) {
    return QueuedReviewWrite(
      cardId: json['cardId'] as String,
      vocabularyId: json['vocabularyId'] as String,
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      rating: json['rating'] as int,
      responseTimeMs: json['responseTimeMs'] as int,
      interactionMode: json['interactionMode'] as int,
      stateBefore: json['stateBefore'] as int,
      stateAfter: json['stateAfter'] as int,
      stabilityBefore: (json['stabilityBefore'] as num).toDouble(),
      stabilityAfter: (json['stabilityAfter'] as num).toDouble(),
      difficultyBefore: (json['difficultyBefore'] as num).toDouble(),
      difficultyAfter: (json['difficultyAfter'] as num).toDouble(),
      retrievabilityAtReview: (json['retrievabilityAtReview'] as num).toDouble(),
      cueType: json['cueType'] as String?,
      due: DateTime.parse(json['due'] as String),
      state: json['state'] as int,
      stability: (json['stability'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      reps: json['reps'] as int,
      lapses: json['lapses'] as int,
      isLeech: json['isLeech'] as bool,
      progressStage: json['progressStage'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  final String cardId;
  final String vocabularyId;
  final String userId;
  final String sessionId;
  final int rating;
  final int responseTimeMs;
  final int interactionMode;
  final int stateBefore;
  final int stateAfter;
  final double stabilityBefore;
  final double stabilityAfter;
  final double difficultyBefore;
  final double difficultyAfter;
  final double retrievabilityAtReview;
  final String? cueType;
  final DateTime due;
  final int state;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final bool isLeech;
  final String progressStage;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'vocabularyId': vocabularyId,
        'userId': userId,
        'sessionId': sessionId,
        'rating': rating,
        'responseTimeMs': responseTimeMs,
        'interactionMode': interactionMode,
        'stateBefore': stateBefore,
        'stateAfter': stateAfter,
        'stabilityBefore': stabilityBefore,
        'stabilityAfter': stabilityAfter,
        'difficultyBefore': difficultyBefore,
        'difficultyAfter': difficultyAfter,
        'retrievabilityAtReview': retrievabilityAtReview,
        'cueType': cueType,
        'due': due.toIso8601String(),
        'state': state,
        'stability': stability,
        'difficulty': difficulty,
        'reps': reps,
        'lapses': lapses,
        'isLeech': isLeech,
        'progressStage': progressStage,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Service for managing queued review writes that failed to persist.
///
/// Provides three-layer resilience:
/// 1. Immediate retry with exponential backoff (3 attempts)
/// 2. Local persistence if all retries fail
/// 3. Automatic drain on app startup or next successful write
class ReviewWriteQueue {
  ReviewWriteQueue(this._prefs);

  static const _queueKey = 'review_write_queue';
  final SharedPreferences _prefs;

  /// Get the current queue size
  Future<int> getQueueSize() async {
    final json = _prefs.getString(_queueKey);
    if (json == null) return 0;
    final list = jsonDecode(json) as List;
    return list.length;
  }

  /// Enqueue a failed write for later retry
  Future<void> enqueue(QueuedReviewWrite write) async {
    final json = _prefs.getString(_queueKey);
    final List<dynamic> list = json != null ? jsonDecode(json) as List : [];
    list.add(write.toJson());
    await _prefs.setString(_queueKey, jsonEncode(list));
    debugPrint('[ReviewWriteQueue] Enqueued write for card ${write.cardId}. Queue size: ${list.length}');
  }

  /// Drain the queue by retrying all pending writes
  Future<void> drain(Future<void> Function(QueuedReviewWrite) writeFunc) async {
    final json = _prefs.getString(_queueKey);
    if (json == null) return;

    final list = jsonDecode(json) as List;
    if (list.isEmpty) return;

    debugPrint('[ReviewWriteQueue] Draining queue with ${list.length} writes');

    final writes = list.map((e) => QueuedReviewWrite.fromJson(e as Map<String, dynamic>)).toList();
    final failed = <QueuedReviewWrite>[];

    for (final write in writes) {
      try {
        await writeFunc(write);
      } catch (error) {
        debugPrint('[ReviewWriteQueue] Failed to drain write for card ${write.cardId}: $error');
        failed.add(write);
      }
    }

    // Update queue with only the failed writes
    if (failed.isEmpty) {
      await _prefs.remove(_queueKey);
      debugPrint('[ReviewWriteQueue] Queue drained successfully');
    } else {
      final failedJson = jsonEncode(failed.map((w) => w.toJson()).toList());
      await _prefs.setString(_queueKey, failedJson);
      debugPrint('[ReviewWriteQueue] ${failed.length} writes still in queue after drain');
    }
  }

  /// Clear the queue (for testing or manual recovery)
  Future<void> clear() async {
    await _prefs.remove(_queueKey);
  }
}

/// Retry a future with exponential backoff.
/// Returns the result on success, throws on failure after all retries.
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  while (true) {
    try {
      return await operation();
    } catch (error) {
      attempt++;
      if (attempt >= maxAttempts) {
        rethrow;
      }
      final delay = initialDelay * (1 << (attempt - 1)); // 1s, 2s, 4s
      debugPrint('[retryWithBackoff] Attempt $attempt failed, retrying in ${delay.inSeconds}s: $error');
      await Future<void>.delayed(delay);
    }
  }
}
