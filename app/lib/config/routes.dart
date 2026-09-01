import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/train/workout_logging_screen.dart';
import '../screens/train/exercise_library_screen.dart';
import '../screens/train/templates_screen.dart';
import '../screens/train/pr_screen.dart';
import '../screens/mind/study_screen.dart';
import '../screens/mind/pomodoro_screen.dart';
import '../screens/life/habits_screen.dart';
import '../screens/life/skin_screen.dart';
import '../screens/squad/leaderboard_screen.dart';
import '../screens/squad/profile_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String workoutLog = '/workout-log';
  static const String exerciseLibrary = '/exercise-library';
  static const String templates = '/templates';
  static const String prs = '/prs';
  static const String study = '/study';
  static const String pomodoro = '/pomodoro';
  static const String habits = '/habits';
  static const String skin = '/skin';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (_) => const SplashScreen(),
      login: (_) => const LoginScreen(),
      signup: (_) => const SignupScreen(),
      onboarding: (_) => const OnboardingScreen(),
      home: (_) => const HomeScreen(),
      workoutLog: (_) => const WorkoutLoggingScreen(),
      exerciseLibrary: (_) => const ExerciseLibraryScreen(),
      templates: (_) => const TemplatesScreen(),
      prs: (_) => const PrScreen(),
      study: (_) => const StudyScreen(),
      pomodoro: (_) => const PomodoroScreen(),
      habits: (_) => const HabitsScreen(),
      skin: (_) => const SkinScreen(),
      leaderboard: (_) => const LeaderboardScreen(),
      profile: (_) => const ProfileScreen(),
      settings: (_) => const SettingsScreen(),
    };
  }
}
