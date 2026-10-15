import 'package:flutter/material.dart';

class AchievementTask {
  final String id; // e.g., 'memories', 'virtual_hugs', 'chat_messages'
  final String name;
  final int targetValue;

  AchievementTask({
    required this.id,
    required this.name,
    required this.targetValue,
  });
}

class Milestone {
  final String id;
  final String title;
  final String subTitle; // e.g., '3-day streak'
  final String category; // e.g., 'STREAKS', 'CONNECTION'
  final String description;
  final IconData icon;
  final Color color;
  final List<AchievementTask> tasks;
  final String reward;

  Milestone({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.tasks,
    required this.reward,
  });

  // Backward compatibility for ActivityScreen roadmap
  int get daysRequired {
    try {
      return tasks.firstWhere((t) => t.id == 'streak').targetValue;
    } catch (_) {
      return 0;
    }
  }

  // Calculate overall progress (0.0 to 1.0)
  double getProgress(Map<String, int> stats) {
    if (tasks.isEmpty) return 1.0;
    
    double totalProgress = 0;
    for (var task in tasks) {
      final current = stats[task.id] ?? 0;
      totalProgress += (current / task.targetValue).clamp(0.0, 1.0);
    }
    return totalProgress / tasks.length;
  }

  bool isUnlocked(Map<String, int> stats) {
    for (var task in tasks) {
      final current = stats[task.id] ?? 0;
      if (current < task.targetValue) return false;
    }
    return true;
  }
}
