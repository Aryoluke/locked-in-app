from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


# ─── Auth ────────────────────────────────────────────────────────────────────

class SignupRequest(BaseModel):
    email: str
    username: str
    password: str
    invite_code: str
    display_name: Optional[str] = None


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class RefreshRequest(BaseModel):
    refresh_token: str


# ─── User ────────────────────────────────────────────────────────────────────

class UserResponse(BaseModel):
    id: str
    email: str
    username: str
    display_name: Optional[str] = None
    is_admin: bool = False
    body_type: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    age: Optional[int] = None
    dob: Optional[str] = None
    activity_level: Optional[str] = None
    goals: Optional[str] = None
    dietary_preference: Optional[str] = None
    allergies: Optional[str] = None
    equipment: Optional[str] = None
    training_history: Optional[str] = None
    sleep_baseline: Optional[float] = None
    lifestyle: Optional[str] = None
    skin_type: Optional[str] = None
    skin_concerns: Optional[str] = None
    current_routine: Optional[str] = None
    privacy_settings: Optional[str] = None
    lock_in_level: str = "standard"
    avatar_url: Optional[str] = None
    status: str = "pending"
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    body_type: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    age: Optional[int] = None
    dob: Optional[str] = None
    activity_level: Optional[str] = None
    goals: Optional[str] = None
    dietary_preference: Optional[str] = None
    allergies: Optional[str] = None
    equipment: Optional[str] = None
    training_history: Optional[str] = None
    sleep_baseline: Optional[float] = None
    lifestyle: Optional[str] = None
    skin_type: Optional[str] = None
    skin_concerns: Optional[str] = None
    current_routine: Optional[str] = None
    privacy_settings: Optional[str] = None
    lock_in_level: Optional[str] = None
    avatar_url: Optional[str] = None


class UserStatsResponse(BaseModel):
    total_xp: float = 0
    level: int = 1
    creatine_currency: float = 0
    streaks: dict[str, int] = {}
    total_workouts: int = 0
    total_habits_completed: int = 0
    total_study_minutes: int = 0


# ─── Workout ─────────────────────────────────────────────────────────────────

class WorkoutSetCreate(BaseModel):
    exercise_name: str
    exercise_variation: Optional[str] = None
    set_number: int = 1
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    rest_seconds: Optional[int] = None
    is_warmup: bool = False
    is_dropset: bool = False
    is_superset: bool = False
    superset_group: Optional[str] = None
    notes: Optional[str] = None
    rpe: Optional[float] = None
    completed: bool = True


class WorkoutSetResponse(BaseModel):
    id: str
    session_id: str
    exercise_name: str
    exercise_variation: Optional[str] = None
    set_number: int
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    rest_seconds: Optional[int] = None
    is_warmup: bool = False
    is_dropset: bool = False
    is_superset: bool = False
    superset_group: Optional[str] = None
    notes: Optional[str] = None
    rpe: Optional[float] = None
    completed: bool = True
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class WorkoutSessionCreate(BaseModel):
    date: str
    duration_minutes: Optional[int] = None
    workout_type: Optional[str] = None
    name: Optional[str] = None
    notes: Optional[str] = None
    total_volume_kg: Optional[float] = None
    estimated_calories: Optional[int] = None
    sets: Optional[list[WorkoutSetCreate]] = None


class WorkoutSessionUpdate(BaseModel):
    date: Optional[str] = None
    duration_minutes: Optional[int] = None
    workout_type: Optional[str] = None
    name: Optional[str] = None
    notes: Optional[str] = None
    total_volume_kg: Optional[float] = None
    estimated_calories: Optional[int] = None


class WorkoutSessionResponse(BaseModel):
    id: str
    user_id: str
    date: str
    duration_minutes: Optional[int] = None
    workout_type: Optional[str] = None
    name: Optional[str] = None
    notes: Optional[str] = None
    total_volume_kg: Optional[float] = None
    estimated_calories: Optional[int] = None
    xp_earned: float = 0
    is_template: bool = False
    template_name: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    sets: list[WorkoutSetResponse] = []

    class Config:
        from_attributes = True


class TemplateSave(BaseModel):
    session_id: str
    template_name: str


class ExerciseInfo(BaseModel):
    name: str
    category: str
    muscles: list[str] = []
    equipment: list[str] = []


class WorkoutStats(BaseModel):
    total_sessions: int = 0
    total_volume_kg: float = 0
    total_duration_minutes: int = 0
    average_duration_minutes: float = 0
    sessions_this_week: int = 0
    sessions_this_month: int = 0
    workout_frequency_per_week: float = 0


class PersonalRecord(BaseModel):
    exercise_name: str
    best_weight_kg: Optional[float] = None
    best_reps: Optional[int] = None
    best_volume: Optional[float] = None
    date: Optional[str] = None


# ─── Habit ───────────────────────────────────────────────────────────────────

class HabitCreate(BaseModel):
    name: str
    category: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    target_frequency: int = 1
    target_days: Optional[str] = None  # JSON
    order_index: int = 0


class HabitUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    target_frequency: Optional[int] = None
    target_days: Optional[str] = None
    is_active: Optional[bool] = None
    order_index: Optional[int] = None


class HabitResponse(BaseModel):
    id: str
    user_id: str
    name: str
    category: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    target_frequency: int = 1
    target_days: Optional[str] = None
    is_active: bool = True
    order_index: int = 0
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class HabitLogCreate(BaseModel):
    completed: bool = True
    value: Optional[float] = None
    notes: Optional[str] = None


class HabitLogResponse(BaseModel):
    id: str
    habit_id: str
    user_id: str
    date: str
    completed: bool = True
    value: Optional[float] = None
    notes: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class TodayHabit(BaseModel):
    habit: HabitResponse
    logged_today: bool = False
    log: Optional[HabitLogResponse] = None


class HabitStats(BaseModel):
    total_habits: int = 0
    active_habits: int = 0
    total_completions: int = 0
    today_completion_rate: float = 0
    best_streak: int = 0


# ─── Daily Log ───────────────────────────────────────────────────────────────

class DailyLogCreate(BaseModel):
    date: str
    mood: Optional[int] = Field(None, ge=1, le=5)
    energy: Optional[int] = Field(None, ge=1, le=5)
    motivation: Optional[int] = Field(None, ge=1, le=5)
    sleep_hours: Optional[float] = None
    sleep_quality: Optional[int] = Field(None, ge=1, le=5)
    water_ml: Optional[int] = None
    calories: Optional[int] = None
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fats_g: Optional[float] = None
    weight_kg: Optional[float] = None
    body_fat_pct: Optional[float] = None
    notes: Optional[str] = None


class DailyLogResponse(BaseModel):
    id: str
    user_id: str
    date: str
    mood: Optional[int] = None
    energy: Optional[int] = None
    motivation: Optional[int] = None
    sleep_hours: Optional[float] = None
    sleep_quality: Optional[int] = None
    water_ml: Optional[int] = None
    calories: Optional[int] = None
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fats_g: Optional[float] = None
    weight_kg: Optional[float] = None
    body_fat_pct: Optional[float] = None
    notes: Optional[str] = None
    xp_earned: float = 0
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── Body ────────────────────────────────────────────────────────────────────

class BodyLogCreate(BaseModel):
    date: str
    weight_kg: Optional[float] = None
    body_fat_pct: Optional[float] = None
    muscle_mass_kg: Optional[float] = None
    arm_cm: Optional[float] = None
    chest_cm: Optional[float] = None
    waist_cm: Optional[float] = None
    notes: Optional[str] = None


class BodyLogResponse(BaseModel):
    id: str
    user_id: str
    date: str
    weight_kg: Optional[float] = None
    body_fat_pct: Optional[float] = None
    muscle_mass_kg: Optional[float] = None
    arm_cm: Optional[float] = None
    chest_cm: Optional[float] = None
    waist_cm: Optional[float] = None
    photo_path: Optional[str] = None
    notes: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class BodyStats(BaseModel):
    latest_weight: Optional[float] = None
    weight_change_30d: Optional[float] = None
    latest_body_fat: Optional[float] = None
    body_fat_change_30d: Optional[float] = None
    total_logs: int = 0


# ─── Streaks & XP ───────────────────────────────────────────────────────────

class StreakResponse(BaseModel):
    id: str
    user_id: str
    streak_type: str
    current_count: int = 0
    longest_count: int = 0
    last_active_date: Optional[str] = None
    freeze_count: int = 0
    is_active: bool = True

    class Config:
        from_attributes = True


class XpBalanceResponse(BaseModel):
    total_xp: float = 0
    level: int = 1
    creatine_currency: float = 0
    xp_to_next_level: float = 0

    class Config:
        from_attributes = True


class XpTransactionResponse(BaseModel):
    id: str
    user_id: str
    amount: float
    source: str
    source_id: Optional[str] = None
    description: Optional[str] = None
    multiplier: float = 1.0
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class XpEarnRequest(BaseModel):
    amount: float
    source: str
    source_id: Optional[str] = None
    description: Optional[str] = None


# ─── Social ──────────────────────────────────────────────────────────────────

class FriendRequest(BaseModel):
    user_id: str


class ReactionCreate(BaseModel):
    target_type: str
    target_id: str
    reaction_type: str


class ReactionResponse(BaseModel):
    id: str
    user_id: str
    target_type: str
    target_id: str
    reaction_type: str
    created_at: Optional[datetime] = None
    username: Optional[str] = None

    class Config:
        from_attributes = True


class LeaderboardEntry(BaseModel):
    rank: int
    user_id: str
    username: str
    display_name: Optional[str] = None
    total_xp: float = 0
    level: int = 1
    avatar_url: Optional[str] = None


class FeedItem(BaseModel):
    type: str  # workout/habit/study/body/log
    user_id: str
    username: str
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    data: dict[str, Any] = {}
    reactions: list[ReactionResponse] = []
    created_at: Optional[datetime] = None


class FriendshipResponse(BaseModel):
    id: str
    user_id_1: str
    user_id_2: str
    status: str
    created_at: Optional[datetime] = None
    friend_username: Optional[str] = None
    friend_display_name: Optional[str] = None
    friend_avatar_url: Optional[str] = None

    class Config:
        from_attributes = True


# ─── Competition ─────────────────────────────────────────────────────────────

class CompetitionResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    competition_type: Optional[str] = None
    stat_tracked: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_active: bool = True
    created_at: Optional[datetime] = None
    participant_count: int = 0

    class Config:
        from_attributes = True


class CompetitionEntryResponse(BaseModel):
    id: str
    competition_id: str
    user_id: str
    score: float = 0
    rank: Optional[int] = None
    joined_at: Optional[datetime] = None
    username: Optional[str] = None

    class Config:
        from_attributes = True


# ─── Study ───────────────────────────────────────────────────────────────────

class StudyLogCreate(BaseModel):
    subject: Optional[str] = None
    topic: Optional[str] = None
    duration_minutes: Optional[int] = None
    notes: Optional[str] = None
    date: Optional[str] = None


class StudyLogResponse(BaseModel):
    id: str
    user_id: str
    subject: Optional[str] = None
    topic: Optional[str] = None
    duration_minutes: Optional[int] = None
    notes: Optional[str] = None
    date: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class PomodoroCreate(BaseModel):
    subject: Optional[str] = None
    duration_minutes: int = 25


class PomodoroResponse(BaseModel):
    id: str
    user_id: str
    subject: Optional[str] = None
    duration_minutes: Optional[int] = None
    completed: bool = False
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class StudyStats(BaseModel):
    total_sessions: int = 0
    total_minutes: int = 0
    total_hours: float = 0
    sessions_this_week: int = 0
    sessions_this_month: int = 0
    subjects: dict[str, int] = {}


# ─── Sync ────────────────────────────────────────────────────────────────────

class SyncRecord(BaseModel):
    table_name: str
    records: list[dict[str, Any]] = []


class SyncPushRequest(BaseModel):
    changes: list[SyncRecord] = []
    client_timestamp: Optional[str] = None


class SyncPullRequest(BaseModel):
    since: Optional[str] = None


class SyncResponse(BaseModel):
    server_timestamp: str
    changes: list[SyncRecord] = []
    conflicts: list[dict[str, Any]] = []


# ─── Admin ───────────────────────────────────────────────────────────────────

class AdminInviteCodeCreate(BaseModel):
    code: Optional[str] = None
    max_uses: int = 1
    expires_at: Optional[str] = None


class InviteCodeResponse(BaseModel):
    id: str
    code: str
    created_by: str
    used_by: Optional[str] = None
    max_uses: int = 1
    current_uses: int = 0
    is_active: bool = True
    created_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class AdminSquadStats(BaseModel):
    total_users: int = 0
    approved_users: int = 0
    pending_users: int = 0
    total_workouts: int = 0
    total_habits_completed: int = 0
    total_study_minutes: int = 0
    avg_xp: float = 0
    avg_level: float = 0
