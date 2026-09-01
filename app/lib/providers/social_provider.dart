import 'package:flutter/foundation.dart';

import '../models/competition.dart';
import '../models/social.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

class SocialProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;
  final SyncService _sync = SyncService.instance;

  List<Friend> _friends = [];
  List<ActivityEvent> _activity = [];
  List<LeaderboardEntry> _leaderboard = [];
  List<Competition> _competitions = [];
  List<CompetitionStanding> _standings = [];

  List<Friend> get friends => List.unmodifiable(_friends);
  List<ActivityEvent> get activity => List.unmodifiable(_activity);
  List<LeaderboardEntry> get leaderboard => List.unmodifiable(_leaderboard);
  List<Competition> get competitions => List.unmodifiable(_competitions);

  Future<void> init() async {
    await loadFriends();
    await loadActivity();
    await loadLeaderboard();
    await loadCompetitions();
  }

  Future<void> loadFriends() async {
    try {
      final rows = await _db.queryAll('friends', orderBy: 'last_active DESC');
      _friends = rows.map((r) => Friend.fromMap(r)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadActivity({int limit = 50}) async {
    try {
      final rows = await _db.queryAll('activity_events',
          orderBy: 'timestamp DESC', limit: limit);
      _activity = rows.map((r) => ActivityEvent.fromMap(r)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadLeaderboard() async {
    try {
      final rows = await _db.queryAll('leaderboard', orderBy: 'rank ASC');
      _leaderboard = rows
          .map((r) => LeaderboardEntry.fromMap(
                r,
                isUser: (r['is_user'] as int?) == 1,
              ))
          .toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadCompetitions() async {
    try {
      final rows = await _db.queryAll('competitions', orderBy: 'end_date ASC');
      _competitions = rows.map((r) => Competition.fromMap(r)).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> addFriend(String name) async {
    final friend = Friend(name: name, lastActive: DateTime.now());
    await _db.upsert('friends', friend.toMap());
    await _sync.writeLocal('friends', 'friend', friend.id, friend.toMap());
    _friends.add(friend);
    notifyListeners();
  }

  Future<void> logActivity(ActivityEvent event) async {
    await _db.upsert('activity_events', event.toMap());
    await _sync.writeLocal(
        'activity_events', 'activity', event.id, event.toMap());
    _activity.insert(0, event);
    notifyListeners();
  }

  Future<void> joinCompetition(Competition competition) async {
    if (!_competitions.any((c) => c.id == competition.id)) {
      await _db.upsert('competitions', competition.toMap());
      await _sync.writeLocal(
          'competitions', 'competition', competition.id, competition.toMap());
      _competitions.add(competition);
    }
    notifyListeners();
  }

  Future<void> leaveCompetition(String id) async {
    _competitions.removeWhere((c) => c.id == id);
    await _db.deleteById('competitions', id);
    await _sync.deleteLocal('competitions', 'competition', id);
    notifyListeners();
  }

  void updateMyLeaderboardEntry({required int xp, required int level, required int streak}) {
    final idx = _leaderboard.indexWhere((e) => e.isUser);
    if (idx >= 0) {
      _leaderboard[idx] = LeaderboardEntry(
        rank: _leaderboard[idx].rank,
        userId: _leaderboard[idx].userId,
        name: _leaderboard[idx].name,
        xp: xp,
        level: level,
        streak: streak,
        isUser: true,
      );
      _leaderboard.sort((a, b) => b.xp.compareTo(a.xp));
      for (var i = 0; i < _leaderboard.length; i++) {
        if (_leaderboard[i].rank != i + 1) {
          _leaderboard[i] = LeaderboardEntry(
            rank: i + 1,
            userId: _leaderboard[i].userId,
            name: _leaderboard[i].name,
            xp: _leaderboard[i].xp,
            level: _leaderboard[i].level,
            streak: _leaderboard[i].streak,
            isUser: _leaderboard[i].isUser,
          );
        }
      }
      notifyListeners();
    }
  }
}
