import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean, Column, DateTime, Enum, Float, ForeignKey, Integer, String, Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from database import Base


def gen_uuid():
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=gen_uuid)
    email = Column(String, unique=True, nullable=False, index=True)
    username = Column(String, unique=True, nullable=False, index=True)
    display_name = Column(String, nullable=True)
    password_hash = Column(String, nullable=False)
    invite_code_used = Column(String, nullable=True)
    is_admin = Column(Boolean, default=False)
    body_type = Column(String, nullable=True)  # sleeper/bulk/hybrid
    height_cm = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)
    age = Column(Integer, nullable=True)
    dob = Column(String, nullable=True)
    activity_level = Column(String, nullable=True)
    goals = Column(Text, nullable=True)  # JSON
    dietary_preference = Column(String, nullable=True)
    allergies = Column(Text, nullable=True)  # JSON
    equipment = Column(Text, nullable=True)  # JSON
    training_history = Column(Text, nullable=True)
    sleep_baseline = Column(Float, nullable=True)
    lifestyle = Column(Text, nullable=True)  # JSON
    skin_type = Column(String, nullable=True)
    skin_concerns = Column(Text, nullable=True)  # JSON
    current_routine = Column(Text, nullable=True)  # JSON
    privacy_settings = Column(Text, nullable=True)  # JSON
    lock_in_level = Column(String, default="standard")  # mini/standard/full
    avatar_url = Column(String, nullable=True)
    status = Column(String, default="pending")  # pending/approved/banned
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_synced_at = Column(DateTime, nullable=True)


class WorkoutSession(Base):
    __tablename__ = "workout_sessions"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(String, nullable=False)  # YYYY-MM-DD
    duration_minutes = Column(Integer, nullable=True)
    workout_type = Column(String, nullable=True)  # gym/calisthenics/cardio/sport/routine
    name = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    total_volume_kg = Column(Float, nullable=True)
    estimated_calories = Column(Integer, nullable=True)
    xp_earned = Column(Float, default=0)
    is_template = Column(Boolean, default=False)
    template_name = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    sets = relationship("WorkoutSet", back_populates="session", cascade="all, delete-orphan")


class WorkoutSet(Base):
    __tablename__ = "workout_sets"

    id = Column(String, primary_key=True, default=gen_uuid)
    session_id = Column(String, ForeignKey("workout_sessions.id"), nullable=False, index=True)
    exercise_name = Column(String, nullable=False)
    exercise_variation = Column(String, nullable=True)
    set_number = Column(Integer, nullable=False)
    reps = Column(Integer, nullable=True)
    weight_kg = Column(Float, nullable=True)
    rest_seconds = Column(Integer, nullable=True)
    is_warmup = Column(Boolean, default=False)
    is_dropset = Column(Boolean, default=False)
    is_superset = Column(Boolean, default=False)
    superset_group = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    rpe = Column(Float, nullable=True)
    completed = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("WorkoutSession", back_populates="sets")


class Habit(Base):
    __tablename__ = "habits"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    category = Column(String, nullable=True)  # body/mind/life/skin/nutrition
    icon = Column(String, nullable=True)
    color = Column(String, nullable=True)
    target_frequency = Column(Integer, default=1)
    target_days = Column(Text, nullable=True)  # JSON
    is_active = Column(Boolean, default=True)
    order_index = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    logs = relationship("HabitLog", back_populates="habit", cascade="all, delete-orphan")


class HabitLog(Base):
    __tablename__ = "habit_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    habit_id = Column(String, ForeignKey("habits.id"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(String, nullable=False)
    completed = Column(Boolean, default=True)
    value = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    habit = relationship("Habit", back_populates="logs")


class DailyLog(Base):
    __tablename__ = "daily_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(String, nullable=False)
    mood = Column(Integer, nullable=True)
    energy = Column(Integer, nullable=True)
    motivation = Column(Integer, nullable=True)
    sleep_hours = Column(Float, nullable=True)
    sleep_quality = Column(Integer, nullable=True)
    water_ml = Column(Integer, nullable=True)
    calories = Column(Integer, nullable=True)
    protein_g = Column(Float, nullable=True)
    carbs_g = Column(Float, nullable=True)
    fats_g = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)
    body_fat_pct = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    xp_earned = Column(Float, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("user_id", "date", name="uq_daily_log_user_date"),
    )


class Streak(Base):
    __tablename__ = "streaks"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    streak_type = Column(String, nullable=False)  # daily_workout/daily_habits/daily_study/daily_all
    current_count = Column(Integer, default=0)
    longest_count = Column(Integer, default=0)
    last_active_date = Column(String, nullable=True)
    freeze_count = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("user_id", "streak_type", name="uq_streak_user_type"),
    )


class XpBalance(Base):
    __tablename__ = "xp_balances"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), unique=True, nullable=False)
    total_xp = Column(Float, default=0)
    level = Column(Integer, default=1)
    creatine_currency = Column(Float, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class XpTransaction(Base):
    __tablename__ = "xp_transactions"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    source = Column(String, nullable=False)  # workout/habit/study/streak/combo/duel/competition/quest/arc
    source_id = Column(String, nullable=True)
    description = Column(String, nullable=True)
    multiplier = Column(Float, default=1.0)
    created_at = Column(DateTime, default=datetime.utcnow)


class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id_1 = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    user_id_2 = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    status = Column(String, default="pending")  # pending/accepted/blocked
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("user_id_1", "user_id_2", name="uq_friendship_pair"),
    )


class Competition(Base):
    __tablename__ = "competitions"

    id = Column(String, primary_key=True, default=gen_uuid)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    competition_type = Column(String, nullable=True)  # weekly/monthly/battle/sport
    stat_tracked = Column(String, nullable=True)
    start_date = Column(String, nullable=True)
    end_date = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    entries = relationship("CompetitionEntry", back_populates="competition", cascade="all, delete-orphan")


class CompetitionEntry(Base):
    __tablename__ = "competition_entries"

    id = Column(String, primary_key=True, default=gen_uuid)
    competition_id = Column(String, ForeignKey("competitions.id"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    score = Column(Float, default=0)
    rank = Column(Integer, nullable=True)
    joined_at = Column(DateTime, default=datetime.utcnow)

    competition = relationship("Competition", back_populates="entries")

    __table_args__ = (
        UniqueConstraint("competition_id", "user_id", name="uq_competition_entry"),
    )


class Reaction(Base):
    __tablename__ = "reactions"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    target_type = Column(String, nullable=False)  # workout/habit/study
    target_id = Column(String, nullable=False)
    reaction_type = Column(String, nullable=False)  # fire/laugh/cheer/pr
    created_at = Column(DateTime, default=datetime.utcnow)


class InviteCode(Base):
    __tablename__ = "invite_codes"

    id = Column(String, primary_key=True, default=gen_uuid)
    code = Column(String, unique=True, nullable=False, index=True)
    created_by = Column(String, ForeignKey("users.id"), nullable=False)
    used_by = Column(String, ForeignKey("users.id"), nullable=True)
    max_uses = Column(Integer, default=1)
    current_uses = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)


class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    badge_name = Column(String, nullable=False)
    badge_tier = Column(String, nullable=True)  # bronze/silver/gold
    category = Column(String, nullable=True)
    earned_at = Column(DateTime, default=datetime.utcnow)


class PomodoroSession(Base):
    __tablename__ = "pomodoro_sessions"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    subject = Column(String, nullable=True)
    duration_minutes = Column(Integer, nullable=True)
    completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class StudyLog(Base):
    __tablename__ = "study_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    subject = Column(String, nullable=True)
    topic = Column(String, nullable=True)
    duration_minutes = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    date = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class BodyLog(Base):
    __tablename__ = "body_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(String, nullable=False)
    weight_kg = Column(Float, nullable=True)
    body_fat_pct = Column(Float, nullable=True)
    muscle_mass_kg = Column(Float, nullable=True)
    arm_cm = Column(Float, nullable=True)
    chest_cm = Column(Float, nullable=True)
    waist_cm = Column(Float, nullable=True)
    photo_path = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class SleepLog(Base):
    __tablename__ = "sleep_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(String, nullable=False)
    bedtime = Column(String, nullable=True)
    wake_time = Column(String, nullable=True)
    duration_hours = Column(Float, nullable=True)
    quality = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class SupplementLog(Base):
    __tablename__ = "supplement_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    supplement_name = Column(String, nullable=False)
    dosage = Column(String, nullable=True)
    taken_at = Column(String, nullable=True)
    date = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class CompetitionWar(Base):
    __tablename__ = "competition_wars"

    id = Column(String, primary_key=True, default=gen_uuid)
    squad1_ids = Column(Text, nullable=True)  # JSON
    squad2_ids = Column(Text, nullable=True)  # JSON
    start_date = Column(String, nullable=True)
    end_date = Column(String, nullable=True)
    winner_squad = Column(Integer, nullable=True)
    total_damage_squad1 = Column(Float, default=0)
    total_damage_squad2 = Column(Float, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
