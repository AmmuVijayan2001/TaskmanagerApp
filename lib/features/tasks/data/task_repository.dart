import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/task.dart';

class TaskPage {
  const TaskPage(this.tasks, this.total);
  final List<Task> tasks;
  final int total;
}

class TaskRepository {
  TaskRepository(this._dio, this._cache, this._pendingMutations);
  final Dio _dio;
  final Box<dynamic> _cache;
  final Box<dynamic> _pendingMutations;

  Future<TaskPage> fetch(
    String userId, {
    required int skip,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/tasks/',
        queryParameters: {'user_id': userId, 'skip': skip, 'limit': limit},
      );
      final body = response.data as Map<String, dynamic>;
      final tasks = ((body['data'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();
      if (skip == 0)
        await _cache.put(userId, tasks.map((task) => task.toJson()).toList());
      return TaskPage(tasks, body['total'] as int? ?? tasks.length);
    } on DioException catch (error) {
      throw error.error is AppException
          ? error.error! as AppException
          : NetworkException('Could not load tasks.', cause: error);
    }
  }

  List<Task> cached(String userId) {
    final raw = _cache.get(userId) as List? ?? const [];
    return raw
        .cast<Map>()
        .map((item) => Task.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> cache(String userId, List<Task> tasks) =>
      _cache.put(userId, tasks.map((task) => task.toJson()).toList());

  List<Map<String, dynamic>> pendingMutations(String userId) {
    final raw = _pendingMutations.get(userId) as List? ?? const [];
    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> queueMutation(
    String userId, {
    required String type,
    int? taskId,
    required Map<String, dynamic> payload,
  }) async {
    final pending = pendingMutations(userId)
      ..add({'type': type, 'task_id': taskId, 'payload': payload});
    await _pendingMutations.put(userId, pending);
  }

  Future<void> removeMutation(
    String userId,
    Map<String, dynamic> mutation,
  ) async {
    final pending = pendingMutations(userId)..remove(mutation);
    if (pending.isEmpty) {
      await _pendingMutations.delete(userId);
    } else {
      await _pendingMutations.put(userId, pending);
    }
  }

  Future<Task> update(String userId, Task task) async {
    try {
      final response = await _dio.put(
        '/tasks/${task.id}',
        queryParameters: {'user_id': userId},
        data: task.toRequestJson(),
      );
      return Task.fromJson(
        Map<String, dynamic>.from((response.data as Map)['data'] as Map),
      );
    } on DioException catch (error) {
      throw error.error is AppException
          ? error.error! as AppException
          : ServerException('Could not update task.', cause: error);
    }
  }

  Future<Task> create(String userId, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '/tasks/',
        queryParameters: {'user_id': userId},
        data: payload,
      );
      return Task.fromJson(
        Map<String, dynamic>.from((response.data as Map)['data'] as Map),
      );
    } on DioException catch (error) {
      throw error.error is AppException
          ? error.error! as AppException
          : ServerException('Could not create task.', cause: error);
    }
  }

  Future<void> delete(String userId, int taskId) async {
    try {
      await _dio.delete('/tasks/$taskId', queryParameters: {'user_id': userId});
    } on DioException catch (error) {
      throw error.error is AppException
          ? error.error! as AppException
          : ServerException('Could not delete task.', cause: error);
    }
  }
}

final taskDioProvider = Provider<Dio>((ref) => ApiClient.create());
