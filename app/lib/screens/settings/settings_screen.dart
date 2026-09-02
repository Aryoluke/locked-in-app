import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  String? _serverUrl = AppConstants.defaultBaseUrl;
  final _serverController = TextEditingController();
  bool _darkMode = true;

  // Privacy toggles
  bool _shareWorkouts = true;
  bool _shareHabits = true;
  bool _shareStudy = true;
  bool _shareBody = false;
  bool _shareSocial = true;

  // Daily check-in reminder
  bool _dailyReminder = false;
  String _reminderTime = '19:00';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.displayName ?? '';
    _loadReminderPrefs();
  }

  Future<void> _loadReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dailyReminder = prefs.getBool('daily_reminder_enabled') ?? false;
      _reminderTime = prefs.getString('daily_reminder_time') ?? '19:00';
    });
  }

  Future<void> _setDailyReminder(bool enabled) async {
    setState(() => _dailyReminder = enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', enabled);
    await NotificationService.instance.refreshScheduledReminder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled
              ? 'Daily check-in set for $_reminderTime'
              : 'Daily check-in reminders off'),
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 19,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: AppColors.surface,
            dialBackgroundColor: AppColors.surfaceElevated,
            hourMinuteTextColor: AppColors.textPrimary,
            dayPeriodTextColor: AppColors.textPrimary,
            dayPeriodColor: AppColors.surfaceElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final time = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _reminderTime = time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_reminder_time', time);
    if (_dailyReminder) {
      await NotificationService.instance.refreshScheduledReminder();
    }
  }

  Future<void> _saveProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_nameController.text.trim().isNotEmpty) {
      await auth.updateProfile({
        'display_name': _nameController.text.trim(),
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  Future<void> _saveServerUrl() async {
    final url = _serverController.text.trim();
    if (url.isNotEmpty) {
      // Clear existing tokens and sync state — the new server won't recognise
      // tokens issued by a different server.  The user will need to log in again.
      final api = ApiService.instance;
      final oldUrl = api.baseUrl;
      if (url != oldUrl) {
        api.clearTokens();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.tokenKey);
        await prefs.remove(AppConstants.refreshTokenKey);
        await prefs.remove(AppConstants.lastSyncKey);
      }
      await api.setBaseUrl(url);
      setState(() => _serverUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(url != oldUrl
              ? 'Server URL updated — please log in again'
              : 'Server URL unchanged')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    // Placeholder: would use share/export utilities
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Export requires a file share utility to be attached')),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account?'),
        content: const Text(
          'This permanently deletes your account and all data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _forceSync() async {
    await Provider.of<SyncProvider>(context, listen: false).syncNow();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync triggered')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final sync = context.watch<SyncProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Profile =====
          _SectionHeader('PROFILE'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveProfile,
            child: const Text('SAVE PROFILE'),
          ),
          const SizedBox(height: 24),

          // ===== Appearance =====
          _SectionHeader('APPEARANCE'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark Mode'),
            subtitle: const Text('LOCKED IN is built for dark, but your choice'),
            value: themeProvider.isDark,
            activeColor: AppColors.primary,
            onChanged: (_) => themeProvider.toggle(),
          ),
          const SizedBox(height: 24),

          // ===== Reminders =====
          _SectionHeader('REMINDERS'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Daily check-in reminder'),
                  subtitle: const Text('A nudge to log your day and keep '
                      'the chain alive'),
                  value: _dailyReminder,
                  activeColor: AppColors.primary,
                  onChanged: _setDailyReminder,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  enabled: _dailyReminder,
                  leading: const Icon(Icons.schedule),
                  title: const Text('Reminder time'),
                  subtitle: Text(
                    _reminderTime,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textMuted),
                  onTap: _pickReminderTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== Privacy =====
          _SectionHeader('PRIVACY'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                _privacyToggle('Share workouts', _shareWorkouts,
                    (v) => setState(() => _shareWorkouts = v)),
                _privacyToggle('Share habits', _shareHabits,
                    (v) => setState(() => _shareHabits = v)),
                _privacyToggle('Share study', _shareStudy,
                    (v) => setState(() => _shareStudy = v)),
                _privacyToggle('Share body metrics', _shareBody,
                    (v) => setState(() => _shareBody = v)),
                _privacyToggle('Share social activity', _shareSocial,
                    (v) => setState(() => _shareSocial = v)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== Server / Sync =====
          _SectionHeader('SERVER & SYNC'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current server',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _serverUrl ?? '',
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serverController,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://localhost:8000',
                    prefixIcon:
                        Icon(Icons.dns, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _saveServerUrl,
                    child: const Text('UPDATE'),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.cloud_sync,
                        color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Offline sync'),
                          Text(
                            sync.isSyncing
                                ? 'Syncing...'
                                : sync.syncingPendingCount > 0
                                    ? '${sync.syncingPendingCount} item(s) pending'
                                    : 'All synced',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _forceSync,
                      child: const Text('SYNC NOW'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== Data =====
          _SectionHeader('DATA'),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download, color: AppColors.primary),
            title: const Text('Export my data'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: _exportData,
          ),
          const SizedBox(height: 24),

          // ===== Account =====
          _SectionHeader('ACCOUNT'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('LOG OUT'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _deleteAccount,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            icon: const Icon(Icons.delete_forever),
            label: const Text('DELETE ACCOUNT'),
          ),
          const SizedBox(height: 24),

          // ===== About =====
          _SectionHeader('ABOUT'),
          const SizedBox(height: 8),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'LOCKED IN v1.0.0\nFitness · Mind · Life · Squad',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
