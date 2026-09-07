import 'package:hive_ce/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/error/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(
    ref.watch(taskDioProvider),
    Hive.box<dynamic>('task_cache'),
    Hive.box<dynamic>('task_pending_mutations'),
  ),
);
final connectivityProvider = StreamProvider<bool>(
  (ref) => Connectivity().onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  ),
);

class TasksState {
  const TasksState({
    this.tasks = const [],
    this.total = 0,
    this.loadingMore = false,
    this.offline = false,
  });
  final List<Task> tasks;
  final int total;
  final bool loadingMore;
  final bool offline;
  bool get hasMore => tasks.length < total;
  TasksState copyWith({
    List<Task>? tasks,
    int? total,
    bool? loadingMore,
    bool? offline,
  }) => TasksState(
    tasks: tasks ?? this.tasks,
    total: total ?? this.total,
    loadingMore: loadingMore ?? this.loadingMore,
    offline: offline ?? this.offline,
  );
}

final tasksProvider = AsyncNotifierProvider<TasksController, TasksState>(
  TasksController.new,
);

class TasksController extends AsyncNotifier<TasksState> {
  String get _userId => ref
      .read(authStateProvider)
      .when(
        data: (user) => user?.uid,
        loading: () => null,
        error: (_, __) => null,
      )!;
  TaskRepository get _repository => ref.read(taskRepositoryProvider);
  TasksState? get _current => state.when(
    data: (value) => value,
    loading: () => null,
    error: (_, __) => null,
  );

  @override
  Future<TasksState> build() {
    ref.listen(connectivityProvider, (_, next) {
      next.when(
        data: (isOnline) {
          if (isOnline) syncPending();
        },
        loading: () {},
        error: (_, __) {},
      );
    });
    final cached = _repository.cached(_userId);
    if (cached.isNotEmpty) {
      state = AsyncData(
        TasksState(tasks: cached, total: cached.length, offline: true),
      );
    }
    return _load();
  }

  Future<TasksState> _load() async {
    try {
      final page = await _repository.fetch(_userId, skip: 0);
      return TasksState(tasks: page.tasks, total: page.total);
    } catch (_) {
      final cached = _repository.cached(_userId);
      if (cached.isNotEmpty) {
        return TasksState(tasks: cached, total: cached.length, offline: true);
      }
      rethrow;
    }
  }

  Future<void> refresh() async => state = await AsyncValue.guard(_load);

  Future<void> syncPending() async {
    final pending = _repository.pendingMutations(_userId);
    for (final mutation in pending) {
      try {
        final type = mutation['type'] as String;
        final payload = Map<String, dynamic>.from(mutation['payload'] as Map);
        if (type == 'create') {
          final created = await _repository.create(_userId, payload);
          final temporaryId = mutation['task_id'] as int;
          final latest = _current;
          if (latest != null) {
            state = AsyncData(latest.copyWith(
              tasks: [
                for (final task in latest.tasks)
                  task.id == temporaryId ? created : task,
              ],
            ));
          }
        } else if (type == 'update') {
          await _repository.update(_userId, Task.fromJson(payload));
        } else if (type == 'delete') {
          await _repository.delete(_userId, mutation['task_id'] as int);
        }
        await _repository.removeMutation(_userId, mutation);
      } on NetworkException {
        return;
      } catch (_) {
        await _repository.removeMutation(_userId, mutation);
      }
    }
    final latest = _current;
    if (latest != null) await _repository.cache(_userId, latest.tasks);
    await refresh();
  }

  Future<void> loadMore() async {
    final current = _current;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await _repository.fetch(_userId, skip: current.tasks.length);
      final merged = [...current.tasks, ...page.tasks];
      await _repository.cache(_userId, merged);
      state = AsyncData(current.copyWith(tasks: merged, total: page.total));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  Future<void> toggle(Task task) async {
    final current = _current;
    if (current == null) return;
    final optimistic = task.copyWith(isCompleted: !task.isCompleted);
    state = AsyncData(
      current.copyWith(
        tasks: [
          for (final item in current.tasks)
            if (item.id == task.id) optimistic else item,
        ],
      ),
    );
    try {
      final saved = await _repository.update(_userId, optimistic);
      final latest = _current;
      if (latest == null) return;
      final updated = [
        for (final item in latest.tasks)
          if (item.id == task.id) saved else item,
      ];
      await _repository.cache(_userId, updated);
      state = AsyncData(latest.copyWith(tasks: updated));
    } on NetworkException {
      await _repository.queueMutation(
        _userId,
        type: 'update',
        taskId: optimistic.id,
        payload: optimistic.toJson(),
      );
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> save({
    Task? existing,
    required String title,
    String? description,
    required TaskPriority priority,
    required TaskCategory category,
    DateTime? dueDate,
  }) async {
    final current = _current;
    if (current == null) return;
    try {
      if (existing == null) {
        final temporary = Task(
          id: -DateTime.now().microsecondsSinceEpoch,
          title: title,
          description: description,
          isCompleted: false,
          priority: priority,
          category: category,
          dueDate: dueDate,
          createdAt: DateTime.now(),
        );
        final optimistic = current.copyWith(
          tasks: [temporary, ...current.tasks],
          total: current.total + 1,
        );
        state = AsyncData(optimistic);

        final payload = <String, dynamic>{
          'title': title,
          'description': description,
          'is_completed': false,
          'priority':
              priority.name[0].toUpperCase() + priority.name.substring(1),
          'category':
              category.name[0].toUpperCase() + category.name.substring(1),
          'due_date': dueDate?.toIso8601String(),
        };
        try {
          final created = await _repository.create(_userId, payload);
          final latest = _current;
          if (latest == null) return;
          final updated = [
            for (final item in latest.tasks)
              item.id == temporary.id ? created : item,
          ];
          await _repository.cache(_userId, updated);
          state = AsyncData(latest.copyWith(tasks: updated));
        } on NetworkException {
          await _repository.queueMutation(
            _userId,
            type: 'create',
            taskId: temporary.id,
            payload: payload,
          );
          final latest = _current;
          if (latest != null) await _repository.cache(_userId, latest.tasks);
        }
      } else {
        final edited = Task(
          id: existing.id,
          title: title,
          description: description,
          isCompleted: existing.isCompleted,
          priority: priority,
          category: category,
          dueDate: dueDate,
          createdAt: existing.createdAt,
        );
        final optimistic = current.copyWith(
          tasks: [
            for (final item in current.tasks)
              if (item.id == existing.id) edited else item,
          ],
        );
        state = AsyncData(optimistic);
        try {
          final saved = await _repository.update(_userId, edited);
          final latest = _current;
          if (latest == null) return;
          final updated = [
            for (final item in latest.tasks)
              if (item.id == saved.id) saved else item,
          ];
          await _repository.cache(_userId, updated);
          state = AsyncData(latest.copyWith(tasks: updated));
        } on NetworkException {
          await _repository.queueMutation(
            _userId,
            type: 'update',
            taskId: edited.id,
            payload: edited.toJson(),
          );
          final latest = _current;
          if (latest != null) await _repository.cache(_userId, latest.tasks);
        }
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> delete(Task task) async {
    final current = _current;
    if (current == null) return;
    final optimistic = current.copyWith(
      tasks: current.tasks.where((item) => item.id != task.id).toList(),
      total: current.total > 0 ? current.total - 1 : 0,
    );
    state = AsyncData(optimistic);
    try {
      await _repository.delete(_userId, task.id);
      final latest = _current;
      if (latest != null) await _repository.cache(_userId, latest.tasks);
    } on NetworkException {
      await _repository.queueMutation(
        _userId,
        type: 'delete',
        taskId: task.id,
        payload: const {},
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
