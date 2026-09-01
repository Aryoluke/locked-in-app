class AppConstants {
  AppConstants._();

  // API
  static const String defaultBaseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration syncInterval = Duration(seconds: 30);

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String signupEndpoint = '/auth/signup';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String profileEndpoint = '/user/profile';
  static const String workoutsEndpoint = '/workouts';
  static const String habitsEndpoint = '/habits';
  static const String dailyLogsEndpoint = '/daily-logs';
  static const String streaksEndpoint = '/streaks';
  static const String xpEndpoint = '/xp';
  static const String competitionsEndpoint = '/competitions';
  static const String bodyLogsEndpoint = '/body-logs';
  static const String studyLogsEndpoint = '/study-logs';
  static const String pomodoroEndpoint = '/pomodoros';
  static const String socialEndpoint = '/social';
  static const String syncEndpoint = '/sync';
  static const String exercisesEndpoint = '/exercises';
  static const String templatesEndpoint = '/templates';
  static const String prsEndpoint = '/prs';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String baseUrlKey = 'base_url';
  static const String lastSyncKey = 'last_sync';
  static const String themeKey = 'theme_mode';

  // XP System
  static const int xpWorkoutComplete = 50;
  static const int xpPerSet = 2;
  static const int xpHabitComplete = 10;
  static const int xpStudyHour = 25;
  static const int xpPomodoroComplete = 15;
  static const int xpWaterLogged = 5;
  static const int xpStreakBonusMultiplier = 2;
  static const int xpDailyLogin = 5;

  // Level thresholds
  static const List<int> levelThresholds = [
    0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5200,
    6500, 8000, 10000, 12500, 15500, 19000, 23000, 28000, 34000, 41000,
  ];

  // Pomodoro
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroBreakMinutes = 5;
  static const int pomodoroLongBreakMinutes = 15;
  static const int pomodoroCyclesBeforeLong = 4;

  // Water
  static const double waterGoalLiters = 3.0;
  static const double waterIncrement = 0.25;

  // Lock-in levels
  static const List<String> lockInLevels = [
    'Asleep',
    'Warming Up',
    'Focused',
    'In The Zone',
    'LOCKED IN',
    'UNSTOPPABLE',
    'TRANSCENDENT',
  ];
}

class ExerciseCategories {
  static const List<String> categories = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Legs',
    'Core',
    'Cardio',
    'Full Body',
    'Forearms',
    'Calves',
    'Neck',
  ];

  static const Map<String, List<String>> exercises = {
    'Chest': [
      'Barbell Bench Press',
      'Incline Dumbbell Press',
      'Cable Fly',
      'Dumbbell Fly',
      'Push Up',
      'Dips',
      'Decline Bench Press',
      'Machine Chest Press',
      'Pec Deck',
      'Incline Cable Fly',
    ],
    'Back': [
      'Deadlift',
      'Barbell Row',
      'Pull Up',
      'Lat Pulldown',
      'Cable Row',
      'T-Bar Row',
      'Dumbbell Row',
      'Seated Row',
      'Face Pull',
      'Good Morning',
    ],
    'Shoulders': [
      'Overhead Press',
      'Lateral Raise',
      'Front Raise',
      'Rear Delt Fly',
      'Arnold Press',
      'Upright Row',
      'Shrugs',
      'Cable Lateral Raise',
      'Machine Shoulder Press',
    ],
    'Biceps': [
      'Barbell Curl',
      'Dumbbell Curl',
      'Hammer Curl',
      'Preacher Curl',
      'Cable Curl',
      'Concentration Curl',
      'Incline Dumbbell Curl',
    ],
    'Triceps': [
      'Tricep Pushdown',
      'Skull Crushers',
      'Overhead Tricep Extension',
      'Close Grip Bench Press',
      'Dips',
      'Tricep Kickback',
    ],
    'Legs': [
      'Barbell Squat',
      'Leg Press',
      'Romanian Deadlift',
      'Leg Extension',
      'Leg Curl',
      'Bulgarian Split Squat',
      'Walking Lunges',
      'Hip Thrust',
      'Goblet Squat',
      'Leg Press Calf Raise',
    ],
    'Core': [
      'Plank',
      'Cable Crunch',
      'Hanging Leg Raise',
      'Ab Wheel Rollout',
      'Russian Twist',
      'Dead Bug',
      'Side Plank',
      'Bicycle Crunch',
    ],
    'Cardio': [
      'Running',
      'Cycling',
      'Rowing',
      'Jump Rope',
      'Stairmaster',
      'Elliptical',
      'Swimming',
      'Battle Ropes',
    ],
    'Full Body': [
      'Clean and Press',
      'Thrusters',
      'Burpees',
      'Turkish Get Up',
      'Man Maker',
    ],
  };
}
