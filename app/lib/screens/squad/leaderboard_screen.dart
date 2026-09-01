import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/social_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final entries = social.leaderboard;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('LEADERBOARD'),
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events,
                      size: 60, color: AppColors.gold),
                  const SizedBox(height: 16),
                  const Text(
                    'No rankings yet.\nYour XP rank will show here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Seed a demo leaderboard with current user
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sync to pull squad rankings')),
                      );
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('SYNC RANKINGS'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _LeaderboardRow(entry: entry);
              },
            ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final dynamic entry;
  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank ?? 0;
    final isUser = entry.isUser == true;
    final isTop3 = rank <= 3;

    Color medalColor;
    switch (rank) {
      case 1:
        medalColor = AppColors.gold;
      case 2:
        medalColor = Colors.grey;
      case 3:
        medalColor = const Color(0xFFCD7F32);
      default:
        medalColor = AppColors.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUser ? AppColors.primary : AppColors.surfaceBorder,
          width: isUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: isTop3
                ? Icon(Icons.emoji_events, color: medalColor, size: 24)
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceElevated,
            child: Text(
              (entry.name ?? '?').toString()[0].toUpperCase(),
              style: TextStyle(
                color: isUser ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name ?? 'Member',
                  style: TextStyle(
                    color: isUser ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isUser ? 'You' : 'Lv ${entry.level ?? 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if ((entry.streak ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.warning, size: 14),
                  Text(
                    '${entry.streak}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            '${entry.xp ?? 0} XP',
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
