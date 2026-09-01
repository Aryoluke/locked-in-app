import 'package:flutter/material.dart';

import '../config/theme.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = 'LOCKING IN...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              backgroundColor: AppColors.surfaceElevated,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
