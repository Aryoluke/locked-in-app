import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/daily_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/social_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/study_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/xp_provider.dart';
import 'services/local_db_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database (SQLite)
  await LocalDbService.instance.init();
  await LocalDbService.instance.seedExercises();

  // Initialize notifications + restore the user's scheduled daily reminder
  await NotificationService.instance.init();
  await NotificationService.instance.refreshScheduledReminder();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => DailyProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
        ChangeNotifierProvider(create: (_) => XpProvider()),
        ChangeNotifierProvider(create: (_) => StudyProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: const LockedInApp(),
    ),
  );
}
