import 'dart:math';

import 'package:flutter/material.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/tools/_tool.dart';

/// Lasso selection tool for manually selecting strokes for math expressions
class LassoTool extends Tool {
  LassoTool._();

  static final LassoTool _current = LassoTool._();
  static LassoTool get current => _current;

  @override
  ToolId get toolId => ToolId.select; // Reuse select tool ID

  List<Offset> _lassoPoints = [];
  bool _isActive = false;
  Path? _lassoPath;

  /// Gets the current lasso path for rendering
  Path? get lassoPath => _lassoPath;

  /// Whether the lasso tool is currently active
  bool get isActive => _isActive;

  /// Gets the current lasso points
  List<Offset> get lassoPoints => List.unmodifiable(_lassoPoints);

  /// Starts lasso selection
  void startLasso() {
    _isActive = true;
    _lassoPoints.clear();
    _lassoPath = null;
  }

  /// Stops lasso selection and returns selected strokes
  List<Stroke> stopLasso(List<Stroke> allStrokes) {
    _isActive = false;
    final selectedStrokes = _getStrokesInLasso(allStrokes);
    _lassoPoints.clear();
    _lassoPath = null;
    return selectedStrokes;
  }

  /// Cancels lasso selection without returning strokes
  void cancelLasso() {
    _isActive = false;
    _lassoPoints.clear();
    _lassoPath = null;
  }

  /// Called when user starts drawing the lasso
  void onLassoStart(Offset position) {
    if (!_isActive) return;

    _lassoPoints.clear();
    _lassoPoints.add(position);
    _updateLassoPath();
  }

  /// Called when user continues drawing the lasso
  void onLassoUpdate(Offset position) {
    if (!_isActive) return;

    _lassoPoints.add(position);
    _updateLassoPath();
  }

  /// Called when user finishes drawing the lasso
  List<Stroke> onLassoEnd(List<Stroke> allStrokes) {
    if (!_isActive) return [];

    return stopLasso(allStrokes);
  }

  /// Updates the lasso path for rendering
  void _updateLassoPath() {
    if (_lassoPoints.isEmpty) {
      _lassoPath = null;
      return;
    }

    _lassoPath = Path();
    _lassoPath!.moveTo(_lassoPoints.first.dx, _lassoPoints.first.dy);

    for (int i = 1; i < _lassoPoints.length; i++) {
      _lassoPath!.lineTo(_lassoPoints[i].dx, _lassoPoints[i].dy);
    }
  }

  /// Creates a dashed path for rendering the lasso
  Path createDashedLassoPath() {
    if (_lassoPoints.isEmpty) return Path();

    return _createDashedPath(_lassoPoints);
  }

  /// Creates a dashed path from a list of points
  Path _createDashedPath(List<Offset> points) {
    if (points.isEmpty) return Path();

    const dashLength = 10.0;
    const gapLength = 5.0;

    final path = Path();
    double totalLength = 0;
    bool isDash = true;

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final dx = points[i].dx - points[i - 1].dx;
      final dy = points[i].dy - points[i - 1].dy;
      final segmentLength = sqrt(dx * dx + dy * dy);

      totalLength += segmentLength;

      if (totalLength > (isDash ? dashLength : gapLength)) {
        totalLength = 0;
        isDash = !isDash;

        if (isDash) {
          path.moveTo(points[i].dx, points[i].dy);
        } else {
          path.lineTo(points[i].dx, points[i].dy);
        }
      } else if (isDash) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    return path;
  }

  /// Determines which strokes are inside the lasso selection
  List<Stroke> _getStrokesInLasso(List<Stroke> allStrokes) {
    if (_lassoPoints.length < 3) return [];

    final selectedStrokes = <Stroke>[];

    for (final stroke in allStrokes) {
      if (_isStrokeInLasso(stroke)) {
        selectedStrokes.add(stroke);
      }
    }

    return selectedStrokes;
  }

  /// Checks if a stroke is inside the lasso polygon
  bool _isStrokeInLasso(Stroke stroke) {
    if (_lassoPoints.length < 3) return false;

    // Check if any point of the stroke's polygon is inside the lasso
    final strokePolygon = stroke.highQualityPolygon;

    for (final point in strokePolygon) {
      if (_isPointInPolygon(point, _lassoPoints)) {
        return true;
      }
    }

    return false;
  }

  /// Point-in-polygon test using ray casting algorithm
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;

      if (((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }
}
