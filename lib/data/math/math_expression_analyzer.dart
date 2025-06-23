import 'dart:async';
import 'dart:developer';

import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/math/math_expression.dart';

/// Service for analyzing strokes and detecting mathematical expressions
/// This implements Phase 1 of the "Magic Button" plan
class MathExpressionAnalyzer {
  // Timing constants for pause detection (in milliseconds)
  static const int microPauseThreshold = 200; // Character-level pauses
  static const int wordLevelPauseThreshold = 700; // Between characters/terms
  static const int expressionCompletionPauseThreshold =
      800; // Expression finished

  // Spatial grouping constants
  static const double proximityThreshold =
      80.0; // Distance for grouping strokes

  Timer? _pauseTimer;
  DateTime? _lastStrokeTime;
  List<Stroke> _recentStrokes = [];
  List<MathExpression> _detectedExpressions = [];

  // Callbacks for expression detection events
  Function(List<MathExpression>)? onExpressionsDetected;
  Function()? onExpressionsCleared;

  MathExpressionAnalyzer({
    this.onExpressionsDetected,
    this.onExpressionsCleared,
  });

  /// Gets the currently detected expressions
  List<MathExpression> get detectedExpressions =>
      List.unmodifiable(_detectedExpressions);

  /// Called when a new stroke is added to the canvas
  void onStrokeAdded(Stroke newStroke) {
    final now = DateTime.now();

    // Cancel any pending analysis
    _pauseTimer?.cancel();

    // Update stroke timing
    _lastStrokeTime = now;
    _recentStrokes.add(newStroke);

    // Start a timer to detect when the user has paused
    _pauseTimer = Timer(
      const Duration(milliseconds: expressionCompletionPauseThreshold),
      () => _analyzeForMathExpressions(),
    );

    log('Stroke added. Recent strokes: ${_recentStrokes.length}');
  }

  /// Called when strokes are removed (e.g., by eraser)
  void onStrokesRemoved(List<Stroke> removedStrokes) {
    // Remove the strokes from our tracking
    _recentStrokes.removeWhere((stroke) => removedStrokes.contains(stroke));

    // Remove any expressions that no longer have valid strokes
    _detectedExpressions.removeWhere((expr) =>
        expr.strokes.any((stroke) => removedStrokes.contains(stroke)));

    // Re-analyze if we still have strokes
    if (_recentStrokes.isNotEmpty) {
      _analyzeForMathExpressions();
    } else {
      _clearExpressions();
    }
  }

  /// Called when all strokes are cleared
  void onAllStrokesCleared() {
    _recentStrokes.clear();
    _clearExpressions();
    _pauseTimer?.cancel();
  }

  /// Called when the user starts lasso mode
  void onLassoModeStarted() {
    _clearExpressions();
  }

  /// Creates an expression from manually selected strokes (lasso mode)
  MathExpression? createExpressionFromLassoedStrokes(
      List<Stroke> selectedStrokes) {
    if (selectedStrokes.isEmpty) return null;

    final expression = MathExpression(
      id: MathExpression.generateId(),
      strokes: selectedStrokes,
      boundingBox: BoundingBox.fromStrokes(selectedStrokes),
      createdAt: DateTime.now(),
    );

    _detectedExpressions = [expression];
    onExpressionsDetected?.call(_detectedExpressions);

    return expression;
  }

  /// Main analysis method - implements the stroke clustering algorithm
  void _analyzeForMathExpressions() {
    if (_recentStrokes.isEmpty) {
      _clearExpressions();
      return;
    }

    log('Analyzing ${_recentStrokes.length} strokes for math expressions');

    // Group all strokes using spatial proximity
    final groups = _groupAllStrokes(_recentStrokes);

    if (groups.isEmpty) {
      _clearExpressions();
      return;
    }

    // Convert groups to math expressions
    final expressions = groups
        .where((group) => group.strokes.isNotEmpty)
        .map((group) => MathExpression(
              id: MathExpression.generateId(),
              strokes: group.strokes,
              boundingBox: group.boundingBox,
              createdAt: DateTime.now(),
            ))
        .toList();

    _detectedExpressions = expressions;
    log('Detected ${expressions.length} math expressions');

    onExpressionsDetected?.call(_detectedExpressions);
  }

  /// Groups strokes based on spatial proximity using an iterative merging algorithm
  List<StrokeGroup> _groupAllStrokes(List<Stroke> allStrokes) {
    if (allStrokes.isEmpty) return [];

    // Start with each stroke as its own group
    List<StrokeGroup> groups =
        allStrokes.map((stroke) => StrokeGroup.fromStrokes([stroke])).toList();

    // Keep merging groups until no more merges are possible
    bool mergedInThisPass = true;
    while (mergedInThisPass) {
      mergedInThisPass = false;

      for (int i = 0; i < groups.length; i++) {
        for (int j = i + 1; j < groups.length; j++) {
          if (_areGroupsNear(groups[i], groups[j], proximityThreshold)) {
            // Merge group j into group i
            final mergedStrokes = [...groups[i].strokes, ...groups[j].strokes];
            groups[i] = StrokeGroup.fromStrokes(mergedStrokes);
            groups.removeAt(j);
            mergedInThisPass = true;
            break;
          }
        }
        if (mergedInThisPass) break;
      }
    }

    return groups;
  }

  /// Checks if two stroke groups are spatially close to each other
  bool _areGroupsNear(
      StrokeGroup groupA, StrokeGroup groupB, double threshold) {
    return groupA.boundingBox.isNear(groupB.boundingBox, threshold);
  }

  /// Clears all detected expressions
  void _clearExpressions() {
    if (_detectedExpressions.isNotEmpty) {
      _detectedExpressions.clear();
      onExpressionsCleared?.call();
    }
  }

  void dispose() {
    _pauseTimer?.cancel();
    _recentStrokes.clear();
    _detectedExpressions.clear();
  }

  Map<String, dynamic> getAnalysisStats() {
    return {
      'recentStrokesCount': _recentStrokes.length,
      'detectedExpressionsCount': _detectedExpressions.length,
      'lastStrokeTime': _lastStrokeTime?.toIso8601String(),
      'timerActive': _pauseTimer?.isActive ?? false,
    };
  }

  void refreshAnalysis(List<List<Stroke>> allPageStrokes) {
    _pauseTimer?.cancel();
    _recentStrokes.clear();

    final allStrokes = <Stroke>[];
    for (final pageStrokes in allPageStrokes) {
      allStrokes.addAll(pageStrokes);
    }

    if (allStrokes.isEmpty) {
      _clearExpressions();
      return;
    }

    _recentStrokes = allStrokes;
    _analyzeForMathExpressions();
  }
}
