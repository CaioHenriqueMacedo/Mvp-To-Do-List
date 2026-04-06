import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;
  final int totalTasks;
  final int completedTasks;

  Category({
    required this.name,
    required this.icon,
    required this.color,
    this.totalTasks = 0,
    this.completedTasks = 0,
  });
}

class SubTask {
  String title;
  bool isDone;

  SubTask({required this.title, this.isDone = false});

  Map<String, dynamic> toJson() => {'title': title, 'isDone': isDone};
  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(title: json['title'], isDone: json['isDone']);
}

class Task {
  String title;
  String? subtitle;
  String category;
  bool isDone;
  DateTime createdAt;
  List<SubTask> subtasks;

  Task({
    required this.title,
    this.subtitle,
    this.category = 'Geral',
    this.isDone = false,
    DateTime? createdAt,
    List<SubTask>? subtasks,
  }) : createdAt = createdAt ?? DateTime.now(),
       subtasks = subtasks ?? [];

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'category': category,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    title: json['title'],
    subtitle: json['subtitle'],
    category: json['category'],
    isDone: json['isDone'],
    createdAt: DateTime.parse(json['createdAt']),
    subtasks: (json['subtasks'] as List).map((s) => SubTask.fromJson(s)).toList(),
  );
}