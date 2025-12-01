import 'dart:async';
import 'package:flutter/foundation.dart';

/// Initialization phase
enum InitPhase {
  firebase('Firebase Initialization'),
  services('Service Setup'),
  controllers('Controller Loading'),
  security('Security Checks'),
  background('Background Tasks'),
  complete('Initialization Complete');

  const InitPhase(this.description);
  final String description;
}

/// Detailed initialization step
class InitStepDetail {
  final String id;
  final String name;
  final String description;
  final double weight;
  final InitPhase phase;
  final bool isCritical;

  const InitStepDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.weight,
    required this.phase,
    this.isCritical = false,
  });
}

/// Initialization progress event
class InitProgressEvent {
  final InitStepDetail step;
  final double progress;
  final DateTime timestamp;
  final String? error;

  InitProgressEvent({
    required this.step,
    required this.progress,
    required this.timestamp,
    this.error,
  });

  bool get hasError => error != null;
  bool get isComplete => progress >= 1.0;
}

/// Initialization progress tracker
class InitProgressTracker {
  static final InitProgressTracker _instance = InitProgressTracker._internal();
  factory InitProgressTracker() => _instance;
  InitProgressTracker._internal();

  final List<InitStepDetail> _steps = [
    // Firebase Phase (20%)
    InitStepDetail(
      id: 'firebase_init',
      name: 'Firebase Initialization',
      description: 'Initializing Firebase services',
      weight: 0.20,
      phase: InitPhase.firebase,
      isCritical: true,
    ),

    // Services Phase (30%)
    InitStepDetail(
      id: 'service_locator',
      name: 'Service Locator',
      description: 'Setting up dependency injection',
      weight: 0.10,
      phase: InitPhase.services,
      isCritical: true,
    ),
    InitStepDetail(
      id: 'notifications',
      name: 'Notifications',
      description: 'Initializing notification system',
      weight: 0.05,
      phase: InitPhase.services,
      isCritical: true,
    ),
    InitStepDetail(
      id: 'audio_services',
      name: 'Audio Services',
      description: 'Setting up audio playback',
      weight: 0.10,
      phase: InitPhase.services,
      isCritical: true,
    ),
    InitStepDetail(
      id: 'data_services',
      name: 'Data Services',
      description: 'Initializing data management',
      weight: 0.05,
      phase: InitPhase.services,
      isCritical: true,
    ),

    // Controllers Phase (30%)
    InitStepDetail(
      id: 'critical_controllers',
      name: 'Critical Controllers',
      description: 'Loading essential UI controllers',
      weight: 0.15,
      phase: InitPhase.controllers,
      isCritical: true,
    ),
    InitStepDetail(
      id: 'theme_setup',
      name: 'Theme Setup',
      description: 'Loading theme and colors',
      weight: 0.05,
      phase: InitPhase.controllers,
      isCritical: true,
    ),
    InitStepDetail(
      id: 'font_setup',
      name: 'Font Setup',
      description: 'Initializing custom fonts',
      weight: 0.05,
      phase: InitPhase.controllers,
      isCritical: true,
    ),
    InitStepDetail(
      id: 'non_critical_controllers',
      name: 'Additional Controllers',
      description: 'Loading remaining controllers',
      weight: 0.05,
      phase: InitPhase.controllers,
      isCritical: false,
    ),

    // Security Phase (10%)
    InitStepDetail(
      id: 'security_checks',
      name: 'Security Checks',
      description: 'Running security validations',
      weight: 0.05,
      phase: InitPhase.security,
      isCritical: true,
    ),
    InitStepDetail(
      id: 'deep_links',
      name: 'Deep Links',
      description: 'Setting up deep link handling',
      weight: 0.05,
      phase: InitPhase.security,
      isCritical: false,
    ),

    // Background Phase (10%)
    InitStepDetail(
      id: 'background_tasks',
      name: 'Background Tasks',
      description: 'Scheduling background operations',
      weight: 0.05,
      phase: InitPhase.background,
      isCritical: false,
    ),
    InitStepDetail(
      id: 'lazy_loading',
      name: 'Lazy Loading',
      description: 'Configuring lazy service loading',
      weight: 0.05,
      phase: InitPhase.background,
      isCritical: false,
    ),
  ];

  final StreamController<InitProgressEvent> _progressController = 
      StreamController<InitProgressEvent>.broadcast();
  
  final Map<String, DateTime> _stepStartTimes = {};
  final Map<String, DateTime> _stepEndTimes = {};
  final Map<String, String> _stepErrors = {};
  
  double _currentProgress = 0.0;
  InitStepDetail? _currentStep;
  DateTime? _startTime;

  /// Stream of progress events
  Stream<InitProgressEvent> get progressStream => _progressController.stream;

  /// Current progress (0.0 to 1.0)
  double get currentProgress => _currentProgress;

  /// Current step being executed
  InitStepDetail? get currentStep => _currentStep;

  /// Total initialization time
  Duration? get totalTime => _startTime != null 
      ? DateTime.now().difference(_startTime!) 
      : null;

  /// Get all initialization steps
  List<InitStepDetail> get allSteps => List.unmodifiable(_steps);

  /// Get steps by phase
  List<InitStepDetail> getStepsByPhase(InitPhase phase) {
    return _steps.where((step) => step.phase == phase).toList();
  }

  /// Start initialization tracking
  void startTracking() {
    _startTime = DateTime.now();
    _currentProgress = 0.0;
    _currentStep = null;
    _stepStartTimes.clear();
    _stepEndTimes.clear();
    _stepErrors.clear();

    _emitProgress(
      InitStepDetail(
        id: 'start',
        name: 'Initialization Started',
        description: 'Starting app initialization',
        weight: 0.0,
        phase: InitPhase.firebase,
      ),
      0.0,
    );

    if (kDebugMode) {
      debugPrint('🚀 Initialization tracking started');
    }
  }

  /// Start a specific step
  void startStep(String stepId) {
    final step = _steps.firstWhere((s) => s.id == stepId);
    _currentStep = step;
    _stepStartTimes[stepId] = DateTime.now();

    _emitProgress(step, _currentProgress);

    if (kDebugMode) {
      print('▶️ Started: ${step.name} - ${step.description}');
    }
  }

  /// Update progress for current step
  void updateProgress(String stepId, double stepProgress) {
    final step = _steps.firstWhere((s) => s.id == stepId);
    final stepIndex = _steps.indexOf(step);
    
    // Calculate overall progress
    double accumulatedProgress = 0.0;
    for (int i = 0; i < stepIndex; i++) {
      accumulatedProgress += _steps[i].weight;
    }
    accumulatedProgress += step.weight * stepProgress;
    
    _currentProgress = accumulatedProgress;
    _currentStep = step;

    _emitProgress(step, _currentProgress);

    if (kDebugMode && stepProgress >= 1.0) {
      final duration = _stepStartTimes[stepId] != null
          ? DateTime.now().difference(_stepStartTimes[stepId]!)
          : null;
      if (kDebugMode) {
        print('✅ Completed: ${step.name}${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}');
      }
    }
  }

  /// Complete a step
  void completeStep(String stepId) {
    updateProgress(stepId, 1.0);
    _stepEndTimes[stepId] = DateTime.now();
  }

  /// Mark step as failed
  void failStep(String stepId, String error) {
    final step = _steps.firstWhere((s) => s.id == stepId);
    _stepErrors[stepId] = error;
    _stepEndTimes[stepId] = DateTime.now();

    _emitProgress(step, _currentProgress, error: error);

    if (kDebugMode) {
      print('❌ Failed: ${step.name} - $error');
    }
  }

  /// Complete initialization
  void complete() {
    _currentProgress = 1.0;
    _currentStep = null;

    _emitProgress(
      InitStepDetail(
        id: 'complete',
        name: 'Initialization Complete',
        description: 'App initialization finished successfully',
        weight: 0.0,
        phase: InitPhase.complete,
      ),
      1.0,
    );

    if (kDebugMode) {
      final total = totalTime;
      print('🎉 Initialization complete${total != null ? ' in ${total.inMilliseconds}ms' : ''}');
    }
  }

  /// Emit progress event
  void _emitProgress(InitStepDetail step, double progress, {String? error}) {
    final event = InitProgressEvent(
      step: step,
      progress: progress,
      timestamp: DateTime.now(),
      error: error,
    );

    _progressController.add(event);
  }

  /// Get step execution time
  Duration? getStepDuration(String stepId) {
    final start = _stepStartTimes[stepId];
    final end = _stepEndTimes[stepId];
    
    if (start != null && end != null) {
      return end.difference(start);
    }
    return null;
  }

  /// Get initialization summary
  Map<String, dynamic> getSummary() {
    return {
      'totalTime': totalTime?.inMilliseconds,
      'currentProgress': _currentProgress,
      'currentStep': _currentStep?.name,
      'completedSteps': _stepEndTimes.length,
      'failedSteps': _stepErrors.length,
      'stepDetails': _steps.map((step) => {
        'id': step.id,
        'name': step.name,
        'phase': step.phase.name,
        'isCritical': step.isCritical,
        'duration': getStepDuration(step.id)?.inMilliseconds,
        'error': _stepErrors[step.id],
        'status': _stepEndTimes.containsKey(step.id) 
            ? (_stepErrors.containsKey(step.id) ? 'failed' : 'completed')
            : (_stepStartTimes.containsKey(step.id) ? 'in_progress' : 'pending'),
      }).toList(),
    };
  }

  /// Dispose the tracker
  void dispose() {
    _progressController.close();
  }
}

/// Global progress tracker instance
final initProgressTracker = InitProgressTracker();