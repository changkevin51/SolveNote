import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:saber/data/math/math_expression.dart';
import 'package:saber/data/editor/page.dart';
import 'dart:math';

/// Overlay widget that displays visual bounding boxes around detected math expressions
class MathExpressionOverlay extends StatelessWidget {
  const MathExpressionOverlay({
    super.key,
    required this.expressions,
    required this.onSolveExpression,
    required this.canvasSize,
    required this.transformationController,
    required this.pages,
  });

  final List<MathExpression> expressions;
  final Function(MathExpression) onSolveExpression;
  final Size canvasSize;
  final TransformationController transformationController;
  final List<EditorPage> pages;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: expressions.map((expression) {
        return MathExpressionBoundingBox(
          expression: expression,
          onSolve: () => onSolveExpression(expression),
          transformationController: transformationController,
          pages: pages,
        );
      }).toList(),
    );
  }
}

/// Individual bounding box widget for a math expression
class MathExpressionBoundingBox extends StatefulWidget {
  const MathExpressionBoundingBox({
    super.key,
    required this.expression,
    required this.onSolve,
    required this.transformationController,
    required this.pages,
  });

  final MathExpression expression;
  final VoidCallback onSolve;
  final TransformationController transformationController;
  final List<EditorPage> pages;

  @override
  State<MathExpressionBoundingBox> createState() =>
      _MathExpressionBoundingBoxState();
}

class _MathExpressionBoundingBoxState extends State<MathExpressionBoundingBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.transformationController,
      builder: (context, child) {
        final boundingBox = widget.expression.boundingBox;
        final rect =
            boundingBox.toRect(); // Find which page this expression is on
        int pageIndex = 0;
        if (widget.expression.strokes.isNotEmpty) {
          pageIndex = widget.expression.strokes.first.pageIndex;
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final currentPage = widget.pages[pageIndex];
        final pageSize = currentPage.size;
        final pageWidthFitted = min(pageSize.width, screenWidth);

        final double pageOffsetX = (screenWidth > pageWidthFitted)
            ? (screenWidth - pageWidthFitted) / 2
            : 0;
        double pageOffsetY = 30; // Initial top gap for first page
        for (int i = 0; i < pageIndex && i < widget.pages.length; i++) {
          final pageSize = widget.pages[i].size;
          final pageWidthFitted = min(pageSize.width, screenWidth);

          pageOffsetY += pageSize.height * (pageWidthFitted / pageSize.width);
          pageOffsetY += 16; // Gap after each page
        }

        final transformation = widget.transformationController.value;
        final scale = transformation.getMaxScaleOnAxis();
        final translation = transformation.getTranslation();

        final transformedRect = Rect.fromLTRB(
          (rect.left + pageOffsetX) * scale + translation.x,
          (rect.top + pageOffsetY) * scale + translation.y,
          (rect.right + pageOffsetX) * scale + translation.x,
          (rect.bottom + pageOffsetY) * scale + translation.y,
        );

        const padding = 8.0;
        final expandedRect = Rect.fromLTRB(
          transformedRect.left - padding,
          transformedRect.top - padding,
          transformedRect.right + padding,
          transformedRect.bottom + padding,
        );

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              left: expandedRect.left,
              top: expandedRect.top,
              width: expandedRect.width,
              height: expandedRect.height,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Stack(
                    children: [
                      // Bounding box background
                      Container(
                        width: expandedRect.width,
                        height: expandedRect.height,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      // Solve button positioned near the top-right corner of the box
                      Positioned(
                        right: 4,
                        top: 4,
                        child: _SolveButton(
                          onPressed: () {
                            // Use qualified import to avoid ambiguity with dart:math
                            developer.log(
                                'Solve button pressed for expression ${widget.expression.id}');
                            widget.onSolve();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Custom solve button widget
class _SolveButton extends StatefulWidget {
  const _SolveButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<_SolveButton> createState() => _SolveButtonState();
}

class _SolveButtonState extends State<_SolveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _buttonAnimationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _buttonAnimationController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _buttonAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _buttonAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _buttonScaleAnimation.value,
            child: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.blue.shade700,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Solve',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
