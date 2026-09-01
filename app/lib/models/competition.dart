import 'package:uuid/uuid.dart';

class Competition {
  final String id;
  final String name;
  final String type; // 'xp_sprint', 'weekly_volume', 'habit_chain', 'custom'
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'upcoming', 'completed'
  final int entryFee;
  final int prizePool;
  final List<String> memberIds;
  final bool isPublic;

  Competition({
    String? id,
    required this.name,
    required this.type,
    this.description,
    required this.startDate,
    required this.endDate,
    this.status = 'upcoming',
    this.entryFee = 0,
    this.prizePool = 0,
    this.memberIds = const [],
    this.isPublic = false,
  }) : id = id ?? const Uuid().v4();

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': status,
        'entry_fee': entryFee,
        'prize_pool': prizePool,
        'member_ids': memberIds.join(','),
        'is_public': isPublic ? 1 : 0,
      };

  factory Competition.fromMap(Map<String, dynamic> map) => Competition(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        description: map['description'] as String?,
        startDate: DateTime.parse(map['start_date'] as String),
        endDate: DateTime.parse(map['end_date'] as String),
        status: map['status'] as String? ?? 'upcoming',
        entryFee: (map['entry_fee'] as int?) ?? 0,
        prizePool: (map['prize_pool'] as int?) ?? 0,
        memberIds: (map['member_ids'] as String? ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        isPublic: (map['is_public'] as int?) == 1,
      );
}

class CompetitionStanding {
  final String competitionId;
  final String userId;
  final String displayName;
  final int rank;
  final int score;
  final int xpContributed;

  CompetitionStanding({
    required this.competitionId,
    required this.userId,
    required this.displayName,
    required this.rank,
    required this.score,
    required this.xpContributed,
  });

  Map<String, dynamic> toMap() => {
        'competition_id': competitionId,
        'user_id': userId,
        'display_name': displayName,
        'rank': rank,
        'score': score,
        'xp_contributed': xpContributed,
      };

  factory CompetitionStanding.fromMap(Map<String, dynamic> map) =>
      CompetitionStanding(
        competitionId: map['competition_id'] as String,
        userId: map['user_id'] as String,
        displayName: map['display_name'] as String,
        rank: (map['rank'] as int),
        score: (map['score'] as int),
        xpContributed: (map['xp_contributed'] as int?) ?? 0,
      );
}
