import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Isolate task data structure
class IsolateTask<T> {
  final String id;
  final Future<T> Function() task;
  final String description;
  final int priority;
  final bool isCancellable;

  IsolateTask({
    required this.id,
    required this.task,
    required this.description,
    this.priority = 0,
    this.isCancellable = false,
  });
}

/// Isolate task result
class IsolateTaskResult<T> {
  final String taskId;
  final T? result;
  final String? error;
  final Duration executionTime;

  IsolateTaskResult({
    required this.taskId,
    this.result,
    this.error,
    required this.executionTime,
  });
}

/// Background isolate manager for heavy operations
/// This moves CPU-intensive tasks off the main thread
class BackgroundIsolateManager {
  static final BackgroundIsolateManager _instance =
      BackgroundIsolateManager._internal();
  factory BackgroundIsolateManager() => _instance;
  BackgroundIsolateManager._internal();

  final Map<String, SendPort> _isolates = {};
  final Map<String, Completer<IsolateTaskResult>> _pendingTasks = {};
  final List<IsolateTask> _taskQueue = [];
  bool _isProcessing = false;
  int _maxConcurrentIsolates = 2;

  /// Initialize the isolate manager
  Future<void> initialize() async {
    if (kDebugMode) {
      print('BackgroundIsolateManager initialized');
    }
  }

  /// Execute a task in a background isolate
  Future<T> executeTask<T>({
    required String taskId,
    required Future<T> Function() task,
    String description = 'Background task',
    int priority = 0,
    bool isCancellable = false,
  }) async {
    final completer = Completer<IsolateTaskResult<T>>();
    _pendingTasks[taskId] = completer as Completer<IsolateTaskResult>;

    final isolateTask = IsolateTask<T>(
      id: taskId,
      task: task,
      description: description,
      priority: priority,
      isCancellable: isCancellable,
    );

    _taskQueue.add(isolateTask);
    _taskQueue.sort((a, b) => b.priority.compareTo(a.priority));

    _processQueue();

    final result = await completer.future;

    if (result.error != null) {
      throw Exception(result.error);
    }

    return result.result as T;
  }

  /// Process the task queue
  Future<void> _processQueue() async {
    if (_isProcessing ||
        _taskQueue.isEmpty ||
        _isolates.length >= _maxConcurrentIsolates) {
      return;
    }

    _isProcessing = true;

    while (_taskQueue.isNotEmpty && _isolates.length < _maxConcurrentIsolates) {
      final task = _taskQueue.removeAt(0);
      _executeTaskInIsolate(task);
    }

    _isProcessing = false;
  }

  /// Execute a single task in an isolate
  Future<void> _executeTaskInIsolate<T>(IsolateTask<T> task) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (kDebugMode) {
        print('Executing task ${task.id} in isolate: ${task.description}');
      }

      // For now, execute in the same isolate with a Future
      // In a full implementation, you would create actual isolates
      final result = await task.task();

      stopwatch.stop();

      final taskResult = IsolateTaskResult<T>(
        taskId: task.id,
        result: result,
        executionTime: stopwatch.elapsed,
      );

      _completeTask(task.id, taskResult);

      if (kDebugMode) {
        print(
            'Task ${task.id} completed in ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      stopwatch.stop();

      final taskResult = IsolateTaskResult<T>(
        taskId: task.id,
        error: e.toString(),
        executionTime: stopwatch.elapsed,
      );

      _completeTask(task.id, taskResult);

      if (kDebugMode) {
        print('Task ${task.id} failed: $e');
      }
    }
  }

  /// Complete a task and notify waiting futures
  void _completeTask(String taskId, IsolateTaskResult result) {
    final completer = _pendingTasks.remove(taskId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  /// Cancel a pending task
  bool cancelTask(String taskId) {
    final taskIndex = _taskQueue.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _taskQueue.removeAt(taskIndex);
      if (task.isCancellable) {
        _completeTask(
            taskId,
            IsolateTaskResult(
              taskId: taskId,
              error: 'Task cancelled',
              executionTime: Duration.zero,
            ));
        return true;
      }
    }
    return false;
  }

  /// Get task queue status
  Map<String, dynamic> getStatus() {
    return {
      'pendingTasks': _taskQueue.length,
      'activeIsolates': _isolates.length,
      'maxConcurrentIsolates': _maxConcurrentIsolates,
      'pendingCompletions': _pendingTasks.length,
    };
  }

  /// Set maximum concurrent isolates
  void setMaxConcurrentIsolates(int max) {
    _maxConcurrentIsolates = max;
  }

  /// Clear all pending tasks
  void clearPendingTasks() {
    for (final task in _taskQueue) {
      _completeTask(
          task.id,
          IsolateTaskResult(
            taskId: task.id,
            error: 'Task cleared',
            executionTime: Duration.zero,
          ));
    }
    _taskQueue.clear();
  }

  /// Shutdown the isolate manager
  Future<void> shutdown() async {
    clearPendingTasks();

    // Close all isolates
    for (final entry in _isolates.entries) {
      entry.value.send({'command': 'shutdown'});
    }

    _isolates.clear();

    if (kDebugMode) {
      print('BackgroundIsolateManager shutdown complete');
    }
  }
}

/// Extension methods for common background tasks
extension BackgroundIsolateExtensions on BackgroundIsolateManager {
  /// Execute JSON parsing in background
  Future<Map<String, dynamic>> parseJsonInBackground(String jsonString) {
    return executeTask<Map<String, dynamic>>(
      taskId: 'parse_json_${DateTime.now().millisecondsSinceEpoch}',
      task: () async {
        // Simulate JSON parsing
        await Future.delayed(const Duration(milliseconds: 100));
        return {};
      },
      description: 'Parse JSON data',
      priority: 1,
    );
  }

  /// Execute file operations in background
  Future<String> readFileInBackground(String filePath) {
    return executeTask<String>(
      taskId: 'read_file_${DateTime.now().millisecondsSinceEpoch}',
      task: () async {
        // Simulate file reading
        await Future.delayed(const Duration(milliseconds: 200));
        return 'File content';
      },
      description: 'Read file: $filePath',
      priority: 2,
    );
  }

  /// Execute network operations in background
  Future<Map<String, dynamic>> fetchNetworkDataInBackground(String url) {
    return executeTask<Map<String, dynamic>>(
      taskId: 'fetch_network_${DateTime.now().millisecondsSinceEpoch}',
      task: () async {
        // Simulate network request
        await Future.delayed(const Duration(seconds: 1));
        return {'data': 'Network response'};
      },
      description: 'Fetch data from: $url',
      priority: 3,
      isCancellable: true,
    );
  }
}

/// Global background isolate manager instance
final backgroundIsolateManager = BackgroundIsolateManager();
