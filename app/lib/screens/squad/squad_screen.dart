import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/social_provider.dart';

class SquadScreen extends StatelessWidget {
  const SquadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('SQUAD'),
          actions: [
            IconButton(
              icon: const Icon(Icons.emoji_events,
                  color: AppColors.gold),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.leaderboard),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Squad'),
              Tab(text: 'Feed'),
              Tab(text: 'Compete'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SquadTab(),
            _FeedTab(),
            _CompeteTab(),
          ],
        ),
      ),
    );
  }
}

class _SquadTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'YOUR SQUAD',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (social.friends.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups,
                    color: AppColors.textMuted, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'No squad members yet.\nInvite your crew to get competitive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addFriend(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('ADD FRIEND'),
                ),
              ],
            ),
          )
        else
          ...social.friends.map((f) => _FriendTile(friend: f)),
      ],
    );
  }

  void _addFriend(BuildContext context) {
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Friend'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Squad member name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Provider.of<SocialProvider>(context, listen: false)
                    .addFriend(nameController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final dynamic friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    final online = friend.isOnline == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceElevated,
                child: Text(
                  (friend.name ?? '?').toString()[0].toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: online ? AppColors.success : AppColors.textMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name ?? 'Unknown',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lv ${friend.level ?? 1} · ${friend.xp ?? 0} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if ((friend.currentStreak ?? 0) > 0)
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: AppColors.warning, size: 16),
                Text(
                  '${friend.currentStreak}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();

    if (social.activity.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No activity yet.\nYour feed updates when you and your squad log in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: social.activity.length,
      itemBuilder: (context, index) {
        final event = social.activity[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor(event.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(event.type),
                    color: _typeColor(event.type), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      event.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (event.xpEarned > 0)
                Text(
                  '+${event.xpEarned}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _typeColor(dynamic type) {
    final name = type.name;
    if (name == 'workout') return AppColors.primary;
    if (name == 'study') return AppColors.mindColor;
    if (name == 'levelUp') return AppColors.gold;
    if (name == 'streak') return AppColors.warning;
    return AppColors.squadColor;
  }

  IconData _typeIcon(dynamic type) {
    final name = type.name;
    if (name == 'workout') return Icons.fitness_center;
    if (name == 'study') return Icons.school;
    if (name == 'levelUp') return Icons.emoji_events;
    if (name == 'streak') return Icons.local_fire_department;
    if (name == 'habit') return Icons.checklist;
    if (name == 'water') return Icons.water_drop;
    return Icons.notifications;
  }
}

class _CompeteTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();

    if (social.competitions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No competitions yet.\nSquads that compete together, stay together.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: social.competitions.length,
      itemBuilder: (context, index) {
        final c = social.competitions[index];
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: c.isActive ? AppColors.gold : AppColors.surfaceBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: AppColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.name,
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (c.isActive ? AppColors.gold : AppColors.textMuted)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.isActive ? 'LIVE' : c.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c.isActive
                            ? AppColors.gold
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.description ?? '${c.memberIds.length} members competing',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (c.prizePool > 0) ...[
                    const Icon(Icons.paid,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    const Text('Pool: '),
                    Text(
                      '\$${c.prizePool}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (c.isActive)
                    Text(
                      '${c.timeRemaining.inDays}d left',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
