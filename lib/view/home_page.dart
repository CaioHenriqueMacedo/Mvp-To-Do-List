import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presenter/task_presenter.dart';
import '../model/task.dart';
import 'home_view.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> implements HomeView {
  late TaskPresenter presenter;
  int _currentIndex = 0;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    presenter = TaskPresenter(this);
  }

  @override
  void updateList() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (presenter.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildMainDashboard(),
            _buildCategoryScreen(),
          ],
        ),
      ),
      floatingActionButton: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: FloatingActionButton(
          onPressed: () {
            if (_currentIndex == 0) {
              _showTaskSheet();
            } else {
              _showNewCategoryDialog();
            }
          },
          backgroundColor: const Color(0xFFE1BEE7),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Icon(_currentIndex == 0 ? Icons.add : Icons.category_rounded, color: Colors.indigo, size: 28),
        ),
      ),
    );
  }

  Widget _buildMainDashboard() {
    final List<Task> filteredTasks = _selectedCategoryFilter == null
        ? presenter.tasks
        : presenter.tasks.where((t) => t.category == _selectedCategoryFilter).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingSection(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 32),
          _buildTaskHeader(),
          if (_selectedCategoryFilter != null) _buildFilterBadge(),
          const SizedBox(height: 12),
          _buildTaskList(filteredTasks),
        ],
      ),
    );
  }

  Widget _buildFilterBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Filtrando: $_selectedCategoryFilter", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(width: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategoryFilter = null),
                child: const Icon(Icons.close, size: 16, color: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    final activeCount = presenter.tasks.where((t) => !t.isDone).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "To Do List",
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          "Você tem $activeCount tarefas pendentes hoje",
          style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600], letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard("Hoje", presenter.todayTasksCount, const Color(0xFFBBDEFB), Icons.calendar_today_rounded),
        _buildStatCard("Agendado", presenter.scheduledTasksCount, const Color(0xFFE1BEE7), Icons.alarm_rounded),
        _buildStatCard("Tudo", presenter.allTasksCount, const Color(0xFFFFF9C4), Icons.all_inbox_rounded),
        _buildStatCard("Atrasado", presenter.overdueTasksCount, const Color(0xFFFFCDD2), Icons.error_outline_rounded),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black45, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(count.toString(), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Text("Tarefas Recentes", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildTaskList(List<Task> displayTasks) {
    if (displayTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(_selectedCategoryFilter == null ? "Sem tarefas por agora. Relaxe! ☀️" : "Nenhuma tarefa em $_selectedCategoryFilter", style: GoogleFonts.outfit(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final task = displayTasks[index];
        final realIndex = presenter.tasks.indexOf(task);
        return _buildTaskItem(realIndex, task);
      },
    );
  }

  Widget _buildTaskItem(int index, Task task) {
    return Dismissible(
      key: Key('task_${task.createdAt.millisecondsSinceEpoch}_${task.title}'),
      onDismissed: (_) => presenter.removeTask(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: task.isDone ? 0.7 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => presenter.toggleTask(index),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: task.isDone ? const Color(0xFFC8E6C9) : Colors.transparent,
                          border: Border.all(color: task.isDone ? Colors.green : Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.green) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, decoration: task.isDone ? TextDecoration.lineThrough : null, color: task.isDone ? Colors.grey : Colors.black87)),
                        if (task.subtitle != null && task.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(task.subtitle!, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ],
                    ),
                  ),
                  _buildCategoryBadge(task.category),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      icon: Icon(Icons.edit_outlined, color: Colors.indigo[300], size: 18),
                      onPressed: () => _showTaskSheet(task: task, index: index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTaskOptionsMenu(index, task),
                ],
              ),
              if (task.subtasks.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.only(left: 36, top: 4), child: Divider(height: 1)),
                ...task.subtasks.asMap().entries.map((entry) => _buildSubtaskItem(index, entry.key, entry.value)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskOptionsMenu(int index, Task task) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert_rounded, color: Colors.grey[300], size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (value) {
          if (value == 'delete') _showDeleteConfirmation(index);
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text("Excluir", style: GoogleFonts.outfit(fontSize: 14, color: Colors.redAccent))])),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Excluir tarefa?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text("Deseja remover permanentemente esta tarefa?", style: GoogleFonts.outfit(color: Colors.grey[600])),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar", style: GoogleFonts.outfit(color: Colors.grey))),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: TextButton(onPressed: () { presenter.removeTask(index); Navigator.pop(context); }, child: Text("Excluir", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(int taskIdx, int subTaskIdx, SubTask sub) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 6),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => presenter.toggleSubTask(taskIdx, subTaskIdx),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: sub.isDone ? const Color(0xFFBBDEFB) : Colors.transparent,
                  border: Border.all(color: sub.isDone ? Colors.blueAccent : Colors.grey[300]!, width: 1.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: sub.isDone ? const Icon(Icons.check, size: 10, color: Colors.blueAccent) : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(sub.title, style: GoogleFonts.outfit(fontSize: 12, color: sub.isDone ? Colors.grey : Colors.black54, decoration: sub.isDone ? TextDecoration.lineThrough : null))),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(8)),
      child: Text(category, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepPurple[400])),
    );
  }

  Widget _buildCategoryScreen() {
    final liveCategories = presenter.getLiveCategories();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Categorias", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: IconButton(onPressed: _showNewCategoryDialog, icon: const Icon(Icons.add_circle_outline, color: Colors.indigo, size: 24)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: liveCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cat = liveCategories[index];
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryFilter = cat.name;
                        _currentIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cat.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: cat.color.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                            child: Icon(cat.icon, size: 20, color: Colors.black87),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                Text("${cat.totalTasks} tarefas • ${cat.completedTasks} concluídas", style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, -5))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_filled, "Início"),
          _buildNavItem(1, Icons.grid_view_rounded, "Categorias"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSelected ? Colors.indigo : Colors.grey[400], size: 22), const SizedBox(height: 4), Text(label, style: GoogleFonts.outfit(fontSize: 10, color: isSelected ? Colors.indigo : Colors.grey[400], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))]),
      ),
    );
  }

  void _showNewCategoryDialog() {
    final TextEditingController _catController = TextEditingController();
    Color _selectedColor = const Color(0xFFBBDEFB);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Nova Categoria", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _catController,
                decoration: InputDecoration(hintText: "Nome da categoria", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _colorOption(const Color(0xFFBBDEFB), _selectedColor, (c) => setDialogState(() => _selectedColor = c)),
                  _colorOption(const Color(0xFFE1BEE7), _selectedColor, (c) => setDialogState(() => _selectedColor = c)),
                  _colorOption(const Color(0xFFFFF9C4), _selectedColor, (c) => setDialogState(() => _selectedColor = c)),
                  _colorOption(const Color(0xFFC8E6C9), _selectedColor, (c) => setDialogState(() => _selectedColor = c)),
                  _colorOption(const Color(0xFFFFCDD2), _selectedColor, (c) => setDialogState(() => _selectedColor = c)),
                ],
              )
            ],
          ),
          actions: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar", style: GoogleFonts.outfit(color: Colors.grey))),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TextButton(onPressed: () { if (_catController.text.isNotEmpty) { presenter.addCategory(_catController.text, Icons.label_important_rounded, _selectedColor); Navigator.pop(context); } }, child: Text("Criar", style: GoogleFonts.outfit(color: Colors.indigo, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorOption(Color color, Color selected, Function(Color) onSelect) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSelect(color),
        child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selected == color ? Colors.black54 : Colors.transparent, width: 2))),
      ),
    );
  }

  void _showTaskSheet({Task? task, int? index}) {
    final TextEditingController _taskController = TextEditingController(text: task?.title ?? "");
    final TextEditingController _subtitleController = TextEditingController(text: task?.subtitle ?? "");
    final TextEditingController _subtaskInputController = TextEditingController();
    String _selectedCategory = task?.category ?? presenter.categories[0].name;
    List<String> _preparedSubtasks = task?.subtasks.map((s) => s.title).toList() ?? [];
    final bool isEditing = task != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isEditing ? "Editar Tarefa" : "Nova Tarefa", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
            const SizedBox(height: 16),
            _buildModalLabel("O que precisa fazer?"), _buildModalField(_taskController, "Ex: Comprar itens de festa", autofocus: !isEditing),
            const SizedBox(height: 12), _buildModalLabel("Detalhes (opcional)"), _buildModalField(_subtitleController, "Ex: Ir ao mercado às 18h"),
            const SizedBox(height: 20), _buildModalLabel("Categoria"), const SizedBox(height: 8),
            Wrap(spacing: 8, children: presenter.categories.map((cat) { final isSelected = _selectedCategory == cat.name; return MouseRegion(cursor: SystemMouseCursors.click, child: ChoiceChip(label: Text(cat.name), selected: isSelected, onSelected: (sel) { if (sel) setModalState(() => _selectedCategory = cat.name); }, selectedColor: cat.color, backgroundColor: Colors.grey[100], labelStyle: GoogleFonts.outfit(fontSize: 12, color: isSelected ? Colors.black87 : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))); }).toList()),
            const SizedBox(height: 24), _buildModalLabel("Detalhes / Subtarefas"), const SizedBox(height: 8),
            Row(children: [Expanded(child: _buildModalField(_subtaskInputController, "Ex: Leite condensado")), const SizedBox(width: 8), MouseRegion(cursor: SystemMouseCursors.click, child: Container(decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)), child: IconButton(icon: const Icon(Icons.add, color: Colors.indigo), onPressed: () { if (_subtaskInputController.text.isNotEmpty) { setModalState(() { _preparedSubtasks.add(_subtaskInputController.text); _subtaskInputController.clear(); }); } })))],),
            if (_preparedSubtasks.isNotEmpty) ...[const SizedBox(height: 12), ..._preparedSubtasks.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.check_circle_outline, size: 16, color: Colors.indigo[200]), const SizedBox(width: 8), Expanded(child: Text(entry.value, style: GoogleFonts.outfit(fontSize: 14))), MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: () => setModalState(() => _preparedSubtasks.removeAt(entry.key)), child: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent)))]))))],
            const SizedBox(height: 32),
            MouseRegion(cursor: SystemMouseCursors.click, child: SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE1BEE7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), onPressed: () { if (isEditing) { presenter.updateTask(index!, _taskController.text, subtitle: _subtitleController.text, category: _selectedCategory, subtaskTitles: _preparedSubtasks); } else { presenter.addTask(_taskController.text, subtitle: _subtitleController.text, category: _selectedCategory, subtaskTitles: _preparedSubtasks); } Navigator.pop(context); }, child: Text(isEditing ? "Salvar Alterações" : "Criar Tarefa", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16))))),
          ])),
        ),
      ),
    );
  }

  Widget _buildModalLabel(String text) { return Text(text, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)); }
  Widget _buildModalField(TextEditingController controller, String hint, {bool autofocus = false}) { return TextField(controller: controller, autofocus: autofocus, style: GoogleFonts.outfit(fontSize: 15), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]), filled: true, fillColor: Colors.grey[100], contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))); }
}