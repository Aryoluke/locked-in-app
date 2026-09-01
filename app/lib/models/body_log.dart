import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BodyLog {
  final String id;
  final DateTime date;
  final double weight;
  final double? bodyFatPercentage;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? biceps;
  final double? thigh;
  final String? photoPath;
  final String? notes;

  BodyLog({
    String? id,
    DateTime? date,
    required this.weight,
    this.bodyFatPercentage,
    this.chest,
    this.waist,
    this.hips,
    this.biceps,
    this.thigh,
    this.photoPath,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'body_fat_percentage': bodyFatPercentage,
        'chest': chest,
        'waist': waist,
        'hips': hips,
        'biceps': biceps,
        'thigh': thigh,
        'photo_path': photoPath,
        'notes': notes,
      };

  factory BodyLog.fromMap(Map<String, dynamic> map) => BodyLog(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        weight: (map['weight'] as num).toDouble(),
        bodyFatPercentage: (map['body_fat_percentage'] as num?)?.toDouble(),
        chest: (map['chest'] as num?)?.toDouble(),
        waist: (map['waist'] as num?)?.toDouble(),
        hips: (map['hips'] as num?)?.toDouble(),
        biceps: (map['biceps'] as num?)?.toDouble(),
        thigh: (map['thigh'] as num?)?.toDouble(),
        photoPath: map['photo_path'] as String?,
        notes: map['notes'] as String?,
      );
}

class BodyMetric {
  final String label;
  final double value;
  final String unit;
  final double? previousValue;
  final IconData icon;

  BodyMetric({
    required this.label,
    required this.value,
    required this.unit,
    this.previousValue,
    required this.icon,
  });

  double? get change {
    if (previousValue == null || previousValue == 0) return null;
    return value - previousValue!;
  }
}
