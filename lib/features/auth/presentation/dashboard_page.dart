import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_editor.dart';
import '../../tasks/presentation/task_providers.dart';
import 'auth_providers.dart';
import 'profile_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  String _search = '';
  bool? _completed;
  TaskSort _sort = TaskSort.createdDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 240) {
        ref.read(tasksProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final profile = ref.watch(userProfileProvider).when(
          data: (value) => value,
          loading: () => null,
          error: (_, __) => null,
        );
    final currentProfile = profile;
    final name = currentProfile?.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(name?.isEmpty ?? true ? 'My Tasks' : "$name's Tasks"),
        actions: [
          IconButton(
            tooltip: 'Profile and theme',
            onPressed: currentProfile == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(profile: currentProfile))),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _TaskLoadError(error: error),
        data: (state) => _TaskList(
          state: state,
          controller: _scrollController,
          search: _search,
          completed: _completed,
          sort: _sort,
          onSearch: _debounceSearch,
          onCompleted: (value) => setState(() => _completed = value),
          onSort: (value) => setState(() => _sort = value),
          onRefresh: () => ref.read(tasksProvider.notifier).refresh(),
          onToggle: (task) => ref.read(tasksProvider.notifier).toggle(task),
          onEdit: _openEditor,
          onDelete: _delete,
        ),
      ),
    );
  }

  void _openEditor([Task? task]) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskEditor(task: task)));
  }

  Future<bool> _delete(Task task) async {
    try {
      await ref.read(tasksProvider.notifier).delete(task);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete task.')));
      }
      return false;
    }
  }

  void _debounceSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _search = value);
    });
  }
}

class _TaskLoadError extends StatelessWidget {
  const _TaskLoadError({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      NetworkException() => 'You appear to be offline. Connect to the internet and pull down to retry.',
      CacheException() => 'Saved tasks could not be read. Please try again.',
      ServerException() => 'The task service is unavailable. Please try again shortly.',
      _ => 'Tasks could not be loaded. Please try again.',
    };
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)));
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.state, required this.controller, required this.search, required this.completed, required this.sort, required this.onSearch, required this.onCompleted, required this.onSort, required this.onRefresh, required this.onToggle, required this.onEdit, required this.onDelete});
  final TasksState state;
  final ScrollController controller;
  final String search;
  final bool? completed;
  final TaskSort sort;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool?> onCompleted;
  final ValueChanged<TaskSort> onSort;
  final Future<void> Function() onRefresh;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onEdit;
  final Future<bool> Function(Task) onDelete;

  @override
  Widget build(BuildContext context) {
    final visible = state.tasks.where((task) =>
      (completed == null || task.isCompleted == completed) && task.title.toLowerCase().contains(search.toLowerCase())).toList()
      ..sort((a, b) => switch (sort) { TaskSort.dueDate => (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999)), TaskSort.priority => b.priority.index.compareTo(a.priority.index), TaskSort.createdDate => b.createdAt.compareTo(a.createdAt) });
    return Column(children: [
      if (state.offline) const MaterialBanner(content: Text('Offline - showing saved tasks.'), actions: [SizedBox.shrink()]),
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: TextField(onChanged: onSearch, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search tasks'))),
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
        for (final value in <bool?>[null, false, true]) Padding(padding: const EdgeInsets.all(4), child: ChoiceChip(label: Text(value == null ? 'All' : value ? 'Completed' : 'Pending'), selected: completed == value, onSelected: (_) => onCompleted(value))),
        PopupMenuButton<TaskSort>(onSelected: onSort, itemBuilder: (_) => const [PopupMenuItem(value: TaskSort.dueDate, child: Text('Due date')), PopupMenuItem(value: TaskSort.priority, child: Text('Priority')), PopupMenuItem(value: TaskSort.createdDate, child: Text('Created date'))], child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.sort))),
      ])),
      Expanded(child: RefreshIndicator(onRefresh: onRefresh, child: visible.isEmpty ? ListView(children: const [SizedBox(height: 160), Center(child: Text('No tasks found.'))]) : ListView.builder(controller: controller, itemCount: visible.length + (state.loadingMore ? 1 : 0), itemBuilder: (_, index) { if (index == visible.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())); final task = visible[index]; return Dismissible(key: ValueKey(task.id), direction: DismissDirection.endToStart, confirmDismiss: (_) => onDelete(task), background: const ColoredBox(color: Colors.red, child: Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.all(20), child: Icon(Icons.delete, color: Colors.white)))), child: ListTile(onTap: () => onEdit(task), leading: Checkbox(value: task.isCompleted, onChanged: (_) => onToggle(task)), title: Text(task.title), subtitle: Text('${task.category.name} • ${task.priority.name}'), trailing: Icon(task.isCompleted ? Icons.task_alt : Icons.radio_button_unchecked))); }))),
    ]);
  }
}
