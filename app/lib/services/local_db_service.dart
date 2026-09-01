import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../config/constants.dart';
import '../models/body_log.dart';
import '../models/competition.dart';
import '../models/daily_log.dart';
import '../models/habit.dart';
import '../models/pomodoro.dart';
import '../models/social.dart';
import '../models/streak.dart';
import '../models/study_log.dart';
import '../models/sync.dart';
import '../models/user.dart';
import '../models/workout.dart';
import '../models/xp.dart';

class LocalDbService {
  LocalDbService._internal();
  static final LocalDbService instance = LocalDbService._internal();

  Database? _db;
  bool _initialized = false;

  Future<Database> get database async {
    if (_db != null) return _db!;
    if (!_initialized) {
      await init();
    }
    return _db!;
  }

  Future<void> init() async {
    if (_initialized) return;
    // On web, sqflite's native SQLite is unavailable; use the WASM-backed
    // FFI factory instead (sqlite compiled to WebAssembly). The no-worker
    // variant loads sqlite3.wasm directly in-page (avoids needing the
    // shared-worker JS that the default factory requires).
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
    }
    final dir = await getDatabasesPath();
    final path = join(dir, 'locked_in.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _initialized = true;
  }

  /// Pre-release: a schema rebuild on any version bump is acceptable (no
  /// user data is worth migrating yet). The only history so far is v1, which
  /// could be a partial schema from before the competition_standings DDL was
  /// fixed - so drop everything and recreate.
  static const _tableNames = [
    'users',
    'workouts',
    'workout_sets',
    'exercises',
    'templates',
    'habits',
    'habit_completions',
    'daily_logs',
    'streaks',
    'xp_transactions',
    'body_logs',
    'study_logs',
    'subjects',
    'pomodoro_sessions',
    'mood_checkins',
    'competitions',
    'competition_standings',
    'friends',
    'activity_events',
    'leaderboard',
    'sync_status',
    'pending_changes',
    'sync_meta',
  ];

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (final table in _tableNames) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    // --- Core entity tables (mirror server) ---
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        display_name TEXT,
        avatar_url TEXT,
        date_of_birth TEXT,
        height_cm REAL,
        weight_kg REAL,
        body_type TEXT,
        fitness_goal TEXT,
        dietary_preference TEXT,
        activity_level TEXT,
        sleep_schedule TEXT,
        available_equipment TEXT,
        goals TEXT,
        onboarding_complete INTEGER DEFAULT 0,
        total_xp INTEGER DEFAULT 0,
        current_level INTEGER DEFAULT 1,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        privacy_settings TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        name TEXT,
        template_id TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        superset_mode INTEGER DEFAULT 0,
        total_volume REAL DEFAULT 0,
        estimated_calories INTEGER DEFAULT 0,
        xp_earned INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sets (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER DEFAULT 0,
        weight REAL DEFAULT 0,
        completed INTEGER DEFAULT 0,
        notes TEXT,
        timestamp TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        body_part TEXT,
        variation TEXT,
        is_custom INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        exercise_names TEXT,
        exercise_defaults TEXT,
        notes TEXT,
        estimated_duration_min INTEGER DEFAULT 45,
        synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        category TEXT,
        frequency TEXT,
        target_count INTEGER DEFAULT 1,
        created_at TEXT,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        total_completions INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_completions (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        count INTEGER DEFAULT 1,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        water_liters REAL DEFAULT 0,
        steps INTEGER DEFAULT 0,
        sleep_hours INTEGER DEFAULT 0,
        sleep_quality INTEGER DEFAULT 3,
        energy_level INTEGER DEFAULT 3,
        mood INTEGER DEFAULT 3,
        motivation INTEGER DEFAULT 3,
        body_weight REAL,
        muscle_soreness INTEGER DEFAULT 1,
        notes TEXT,
        synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE streaks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        streak_type TEXT NOT NULL,
        current_count INTEGER DEFAULT 0,
        longest_count INTEGER DEFAULT 0,
        last_completed_at TEXT,
        start_date TEXT,
        synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE xp_transactions (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL,
        source TEXT NOT NULL,
        description TEXT,
        timestamp TEXT,
        is_streak_bonus INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE body_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        body_fat_percentage REAL,
        chest REAL,
        waist REAL,
        hips REAL,
        biceps REAL,
        thigh REAL,
        photo_path TEXT,
        notes TEXT,
        synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE study_logs (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        topic TEXT,
        minutes INTEGER NOT NULL,
        pomodoros INTEGER DEFAULT 0,
        date TEXT,
        notes TEXT,
        focus_score INTEGER DEFAULT 5,
        synced INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT,
        total_minutes INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        tag TEXT,
        planned_minutes INTEGER NOT NULL,
        actual_seconds INTEGER DEFAULT 0,
        start_time TEXT,
        end_time TEXT,
        completed INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE mood_checkins (
        id TEXT PRIMARY KEY,
        energy INTEGER NOT NULL,
        mood INTEGER NOT NULL,
        motivation INTEGER NOT NULL,
        timestamp TEXT,
        note TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE competitions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT,
        description TEXT,
        start_date TEXT,
        end_date TEXT,
        status TEXT,
        entry_fee INTEGER DEFAULT 0,
        prize_pool INTEGER DEFAULT 0,
        member_ids TEXT,
        is_public INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE competition_standings (
        competition_id TEXT,
        user_id TEXT,
        display_name TEXT,
        rank INTEGER,
        score INTEGER,
        xp_contributed INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 1,
        PRIMARY KEY (competition_id, user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE friends (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar_url TEXT,
        xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        current_streak INTEGER DEFAULT 0,
        is_online INTEGER DEFAULT 0,
        last_active TEXT,
        synced INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT,
        type TEXT,
        message TEXT,
        xp_earned INTEGER DEFAULT 0,
        timestamp TEXT,
        workout_name TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE leaderboard (
        user_id TEXT PRIMARY KEY,
        rank INTEGER,
        name TEXT,
        xp INTEGER,
        level INTEGER,
        streak INTEGER,
        is_user INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    // --- Sync infrastructure ---
    await db.execute('''
      CREATE TABLE sync_status (
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        status TEXT NOT NULL,
        updated_at TEXT,
        PRIMARY KEY (entity_type, entity_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idempotency_key TEXT NOT NULL UNIQUE,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT,
        queued_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute(
        "INSERT INTO sync_meta (key, value) VALUES ('last_sync', '')");

    // Indexes
    await db.execute('CREATE INDEX idx_workout_sets_workout ON workout_sets(workout_id)');
    await db.execute('CREATE INDEX idx_habit_completions_date ON habit_completions(date)');
    await db.execute('CREATE INDEX idx_daily_logs_date ON daily_logs(date)');
    await db.execute('CREATE INDEX idx_study_logs_date ON study_logs(date)');
  }

  // ===== Generic CRUD =====
  Future<void> upsert(String table, Map<String, dynamic> data,
      {String? conflictTarget}) async {
    final db = await database;
    final conflict = conflictTarget ?? 'id';
    await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAll(String table,
      {String? where,
      List<dynamic>? whereArgs,
      String? orderBy,
      int? limit}) async {
    final db = await database;
    return db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  Future<Map<String, dynamic>?> queryById(
      String table, String id) async {
    final db = await database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> deleteById(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as c FROM $table ${where != null ? 'WHERE $where' : ''}',
        whereArgs);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===== Domain-specific helpers =====

  // Workouts
  Future<void> saveWorkout(Workout workout, List<WorkoutSet> sets) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('workouts', workout.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('workout_sets', where: 'workout_id = ?', whereArgs: [workout.id]);
      for (final s in sets) {
        await txn.insert('workout_sets', s.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> loadWorkouts({int limit = 50}) async {
    final db = await database;
    return db.query('workouts',
        orderBy: 'start_time DESC', limit: limit);
  }

  Future<Map<String, dynamic>?> loadActiveWorkout() async {
    final db = await database;
    final rows = await db.query('workouts',
        where: 'end_time IS NULL', orderBy: 'start_time DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> loadSetsForWorkout(String workoutId) async {
    final db = await database;
    return db.query('workout_sets',
        where: 'workout_id = ?', whereArgs: [workoutId], orderBy: 'set_number ASC');
  }

  // Unsynced
  Future<List<SyncRecord>> getPendingSyncRecords() async {
    final db = await database;
    final rows = await db.query('sync_status',
        where: "status IN ('pending','failed')", orderBy: 'updated_at ASC');
    return rows
        .map((r) => SyncRecord(
              entityType: r['entity_type'] as String,
              entityId: r['entity_id'] as String,
              operation: 'update',
              createdAt: DateTime.parse(r['updated_at'] as String),
              status: SyncStatus.values.firstWhere(
                  (s) => s.name == r['status']),
            ))
        .toList();
  }

  Future<void> markSynced(String entityType, String entityId) async {
    final db = await database;
    await db.delete('sync_status',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [entityType, entityId]);
    await db.delete('pending_changes',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [entityType, entityId]);
  }

  Future<int> pendingCount() async {
    return count('sync_status', where: "status = 'pending'");
  }

  // ===== Sync meta =====
  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query('sync_meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert('sync_meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ===== Seed data =====
  Future<void> seedExercises() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM exercises'))!;
    if (count > 0) return;

    final batch = db.batch();
    var id = 0;
    ExerciseCategories.exercises.forEach((category, names) {
      for (final name in names) {
        id++;
        batch.insert('exercises', {
          'id': 'ex_$id',
          'name': name,
          'body_part': category,
          'is_custom': 0,
        });
      }
    });
    await batch.commit(noResult: true);
  }
}
