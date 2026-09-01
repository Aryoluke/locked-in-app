import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/sync_provider.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final offline = sync.isOffline;
    final pending = sync.syncingPendingCount;

    if (!offline && pending == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: offline ? AppColors.error.withOpacity(0.15) : AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: offline ? AppColors.error : AppColors.warning,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            offline ? Icons.cloud_off : Icons.cloud_sync,
            size: 18,
            color: offline ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              offline
                  ? 'Offline — changes will sync when you\'re back'
                  : '$pending item(s) waiting to sync...',
              style: TextStyle(
                fontSize: 12,
                color: offline ? AppColors.error : AppColors.warning,
              ),
            ),
          ),
          if (sync.isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
