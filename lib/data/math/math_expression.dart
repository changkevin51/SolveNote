import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:saber/components/canvas/_stroke.dart';

enum MathExpressionSolveState { idle, solving, solved, error }

/// Represents a detected mathematical expression
class MathExpression {
  final String id;
  final List<Stroke> strokes;
  final BoundingBox boundingBox;
  final DateTime createdAt;
  bool isSelected;

  MathExpressionSolveState solveState = MathExpressionSolveState.idle;
  String? solution;
  String? steps;
  String? errorMessage;

  /// Whether the solution popup is currently visible.
  bool isPopupVisible = false;

  MathExpression({
    required this.id,
    required this.strokes,
    required this.boundingBox,
    required this.createdAt,
    this.isSelected = false,
  });

  /// Generates a unique ID for the expression
  static String generateId() {
    final random = Random().nextInt(100000).toString().padLeft(6, '0');
    return '${DateTime.now().millisecondsSinceEpoch}_$random';
  }

  /// Creates a copy of this expression with updated values
  MathExpression copyWith({
    String? id,
    List<Stroke>? strokes,
    BoundingBox? boundingBox,
    DateTime? createdAt,
    bool? isSelected,
    MathExpressionSolveState? solveState,
    String? solution,
    String? steps,
    String? errorMessage,
  }) {
    final newExpr = MathExpression(
      id: id ?? this.id,
      strokes: strokes ?? this.strokes,
      boundingBox: boundingBox ?? this.boundingBox,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
    );
    newExpr.solveState = solveState ?? this.solveState;
    newExpr.solution = solution ?? this.solution;
    newExpr.steps = steps ?? this.steps;
    newExpr.errorMessage = errorMessage ?? this.errorMessage;
    return newExpr;
  }

  /// Checks if this expression is empty (no strokes)
  bool get isEmpty => strokes.isEmpty;

  /// Gets the width of the expression
  double get width => boundingBox.maxX - boundingBox.minX;

  /// Gets the height of the expression
  double get height => boundingBox.maxY - boundingBox.minY;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'strokes': strokes.map((s) => s.toMap()).toList(),
      'boundingBox': boundingBox.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Represents a bounding box for a math expression
class BoundingBox {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  const BoundingBox({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  Map<String, dynamic> toMap() {
    return {
      'minX': minX,
      'minY': minY,
      'maxX': maxX,
      'maxY': maxY,
    };
  }

  /// Creates a bounding box from a list of strokes
  factory BoundingBox.fromStrokes(List<Stroke> strokes) {
    if (strokes.isEmpty) {
      return const BoundingBox(minX: 0, maxX: 0, minY: 0, maxY: 0);
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      // Use the high quality polygon to get accurate bounds
      final polygon = stroke.highQualityPolygon;
      for (final point in polygon) {
        if (point.dx < minX) minX = point.dx;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dy > maxY) maxY = point.dy;
      }
    }

    return BoundingBox(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  /// Creates a bounding box from a single point
  factory BoundingBox.fromPoint(Offset point) {
    return BoundingBox(
      minX: point.dx,
      maxX: point.dx,
      minY: point.dy,
      maxY: point.dy,
    );
  }

  /// Checks if two bounding boxes are near each other within a threshold
  bool isNear(BoundingBox other, double threshold) {
    return minX < other.maxX + threshold &&
        maxX > other.minX - threshold &&
        minY < other.maxY + threshold &&
        maxY > other.minY - threshold;
  }

  /// Expands the bounding box by a padding amount
  BoundingBox expand(double padding) {
    return BoundingBox(
      minX: minX - padding,
      maxX: maxX + padding,
      minY: minY - padding,
      maxY: maxY + padding,
    );
  }

  /// Gets the center point of the bounding box
  Offset get center => Offset((minX + maxX) / 2, (minY + maxY) / 2);

  /// Gets the top-left corner of the bounding box
  Offset get topLeft => Offset(minX, minY);

  /// Gets the bottom-right corner of the bounding box
  Offset get bottomRight => Offset(maxX, maxY);

  /// Converts to a Flutter Rect
  Rect toRect() => Rect.fromLTRB(minX, minY, maxX, maxY);
}
