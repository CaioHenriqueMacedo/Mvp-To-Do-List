import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../model/task.dart';
import '../view/home_view.dart';

class TaskPresenter {
  final HomeView view;
  List<Task> tasks = [];
  bool isLoading = true;
  
  static const String _storageKey = 'tasks_mvp_todo';
  static const String _categoriesKey = 'categories_mvp_todo';

  // Categorias padrão
  List<Category> categories = [
    Category(name: 'Comida', icon: Icons.shopping_basket_rounded, color: Color(0xFFBBDEFB)),
    Category(name: 'Trabalho', icon: Icons.work_rounded, color: Color(0xFFE1BEE7)),
    Category(name: 'Educação', icon: Icons.school_rounded, color: Color(0xFFFFF9C4)),
    Category(name: 'Casa', icon: Icons.home_rounded, color: Color(0xFFC8E6C9)),
  ];

  TaskPresenter(this.view) {
    _init();
  }

  Future<void> _init() async {
    await _loadCategories();
    await _loadTasks();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? catJson = prefs.getString(_categoriesKey);
      if (catJson != null) {
        final List<dynamic> decoded = jsonDecode(catJson);
        categories = decoded.map((item) => Category(
          name: item['name'],
          icon: IconData(item['icon'], fontFamily: 'MaterialIcons'),
          color: Color(item['color']),
        )).toList();
      }
    } catch (e) {
      debugPrint("Erro ao carregar categorias: $e");
    }
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String catJson = jsonEncode(categories.map((c) => {
        'name': c.name,
        'icon': c.icon.codePoint,
        'color': c.color.value,
      }).toList());
      await prefs.setString(_categoriesKey, catJson);
    } catch (e) {
      debugPrint("Erro ao salvar categorias: $e");
    }
  }

  Future<void> _loadTasks() async {
    isLoading = true;
    view.updateList();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJson = prefs.getString(_storageKey);
      
      if (tasksJson != null) {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        tasks = decoded.map((item) => Task.fromJson(item)).toList();
      } else {
        _initSampleTasks();
      }
    } catch (e) {
      debugPrint("Erro ao carregar tarefas: $e");
    } finally {
      isLoading = false;
      view.updateList();
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, tasksJson);
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
    }
  }

  void _initSampleTasks() {
    tasks = [
      Task(
        title: "Comprar leite e ovos",
        subtitle: "9h - Supermercado",
        category: "Comida",
        subtasks: [SubTask(title: "Leite desnatado", isDone: true), SubTask(title: "Cartela de 12 ovos")],
      ),
      Task(
        title: "Reunião de Planejamento",
        subtitle: "10h - Chamada Online",
        category: "Trabalho",
        isDone: true,
      ),
    ];
    _saveTasks();
  }

  void addTask(String title, {String? subtitle, String category = 'Geral', List<String>? subtaskTitles}) {
    if (title.isEmpty) return;
    final List<SubTask> subtasks = subtaskTitles?.map((t) => SubTask(title: t)).toList() ?? [];
    tasks.insert(0, Task(title: title, subtitle: subtitle, category: category, subtasks: subtasks));
    view.updateList();
    _saveTasks();
  }

  void updateTask(int index, String title, {String? subtitle, String category = 'Geral', List<String>? subtaskTitles}) {
    if (title.isEmpty) return;
    final List<SubTask> subtasks = subtaskTitles?.map((t) => SubTask(title: t)).toList() ?? [];
    tasks[index].title = title;
    tasks[index].subtitle = subtitle;
    tasks[index].category = category;
    tasks[index].subtasks = subtasks;
    view.updateList();
    _saveTasks();
  }

  void toggleTask(int index) {
    tasks[index].isDone = !tasks[index].isDone;
    view.updateList();
    _saveTasks();
  }

  void toggleSubTask(int taskIdx, int subTaskIdx) {
    tasks[taskIdx].subtasks[subTaskIdx].isDone = !tasks[taskIdx].subtasks[subTaskIdx].isDone;
    view.updateList();
    _saveTasks();
  }

  void removeTask(int index) {
    tasks.removeAt(index);
    view.updateList();
    _saveTasks();
  }

  void addCategory(String name, IconData icon, Color color) {
    categories.add(Category(name: name, icon: icon, color: color));
    _saveCategories();
    view.updateList();
  }

  void removeCategory(int index) {
    categories.removeAt(index);
    _saveCategories();
    view.updateList();
  }

  // Estatísticas dinâmicas
  int get todayTasksCount => tasks.where((t) => !t.isDone).length;
  int get scheduledTasksCount => tasks.where((t) => t.subtitle != null).length;
  int get allTasksCount => tasks.length;
  int get overdueTasksCount => tasks.where((t) => !t.isDone && t.createdAt.day < DateTime.now().day).length;

  List<Category> getLiveCategories() {
    return categories.map((cat) {
      final total = tasks.where((t) => t.category == cat.name).length;
      final completed = tasks.where((t) => t.category == cat.name && t.isDone).length;
      return Category(
        name: cat.name,
        icon: cat.icon,
        color: cat.color,
        totalTasks: total,
        completedTasks: completed,
      );
    }).toList();
  }
}