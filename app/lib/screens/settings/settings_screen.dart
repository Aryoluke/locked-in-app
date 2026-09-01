import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.displayName ?? '';
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
      await ApiService.instance.setBaseUrl(url);
      setState(() => _serverUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server URL updated')),
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
