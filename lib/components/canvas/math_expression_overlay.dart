import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:saber/data/math/math_expression.dart';
import 'package:saber/data/editor/page.dart';
import 'dart:math' as math;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class _MathSyntax extends md.InlineSyntax {
  _MathSyntax() : super(r'(\$)(.*?)(\$)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[2]!));
    return true;
  }
}

class _MathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'math') {
      return Math.tex(
        element.textContent,
        textStyle: preferredStyle,
      );
    }
    return super.visitElementAfter(element, preferredStyle);
  }
}

/// Overlay widget that displays visual bounding boxes around detected math expressions
class MathExpressionOverlay extends StatelessWidget {
  const MathExpressionOverlay({
    super.key,
    required this.expressions,
    required this.onSolveExpression,
    required this.canvasSize,
    required this.transformationController,
    required this.pages,
    this.isMathRecognitionAvailable = true,
  });

  final List<MathExpression> expressions;
  final Function(MathExpression) onSolveExpression;
  final Size canvasSize;
  final TransformationController transformationController;
  final List<EditorPage> pages;
  final bool isMathRecognitionAvailable;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: expressions.map((expression) {
        return MathExpressionBoundingBox(
          expression: expression,
          onSolve: () => onSolveExpression(expression),
          onTap: () {
            expression.isPopupVisible = true;
            (context as Element).markNeedsBuild();
          },
          transformationController: transformationController,
          pages: pages,
          isMathRecognitionAvailable: isMathRecognitionAvailable,
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
    required this.onTap,
    required this.transformationController,
    required this.pages,
    this.isMathRecognitionAvailable = true,
  });

  final MathExpression expression;
  final VoidCallback onSolve;
  final VoidCallback onTap;
  final TransformationController transformationController;
  final List<EditorPage> pages;
  final bool isMathRecognitionAvailable;

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

        // Guard against invalid page index
        if (pageIndex < 0 || pageIndex >= widget.pages.length) {
          return const SizedBox.shrink();
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final currentPage = widget.pages[pageIndex];
        final pageSize = currentPage.size;
        final pageWidthFitted = math.min(pageSize.width, screenWidth);

        final double pageOffsetX = (screenWidth > pageWidthFitted)
            ? (screenWidth - pageWidthFitted) / 2
            : 0;
        double pageOffsetY = 30; // Initial top gap for first page
        for (int i = 0; i < pageIndex && i < widget.pages.length; i++) {
          final pageSize = widget.pages[i].size;
          final pageWidthFitted = math.min(pageSize.width, screenWidth);

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

        if (!widget.expression.isPopupVisible &&
            widget.expression.solveState == MathExpressionSolveState.solved) {
          return GestureDetector(
            onTap: widget.onTap,
            child: _buildSolvedMinimizedState(
                context, expandedRect, scale, widget.onTap),
          );
        }

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
                    clipBehavior: Clip.none,
                    children: [
                      // Bounding box background
                      Container(
                        width: expandedRect.width,
                        height: expandedRect.height,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      ..._buildContent(context, expandedRect),
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

  List<Widget> _buildContent(BuildContext context, Rect expandedRect) {
    switch (widget.expression.solveState) {
      case MathExpressionSolveState.idle:
        return [_buildIdleState()];
      case MathExpressionSolveState.solving:
        return [_buildSolvingState()];
      case MathExpressionSolveState.solved:
        if (widget.expression.isPopupVisible) {
          return _buildSolvedState(context, expandedRect);
        }
        return []; // Minimized view is handled outside
      case MathExpressionSolveState.error:
        return [_buildErrorState()];
    }
  }

  Widget _buildSolvedMinimizedState(BuildContext context, Rect expandedRect,
      double scale, VoidCallback onTap) {
    final theme = Theme.of(context);
    final solution = widget.expression.solution ?? '';
    final screenWidth = MediaQuery.of(context).size.width;

    final textStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurface,
      fontSize: 12 * scale,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Faint dashed bounding box
        Positioned(
          left: expandedRect.left,
          top: expandedRect.top,
          width: expandedRect.width,
          height: expandedRect.height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: Colors.grey.withOpacity(0.7),
                strokeWidth: 1.5,
                borderRadius: 8.0,
              ),
            ),
          ),
        ),
        // Answer text
        Positioned(
          left: math.max(16, math.min(expandedRect.left, screenWidth - 200)),
          top: expandedRect.bottom + 4 * scale,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth - 32,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Answer: ',
                    style: textStyle,
                  ),
                  Flexible(
                    child: Math.tex(
                      solution,
                      textStyle: textStyle,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleState() {
    return Positioned(
      right: 4,
      top: 4,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: _SolveButton(
          onPressed: widget.isMathRecognitionAvailable
              ? () {
                  developer.log(
                      'Solve button pressed for expression ${widget.expression.id}');
                  widget.onSolve();
                }
              : null,
          isEnabled: widget.isMathRecognitionAvailable,
        ),
      ),
    );
  }

  Widget _buildSolvingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  List<Widget> _buildSolvedState(BuildContext context, Rect expandedRect) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final spaceAbove = expandedRect.top;
    final spaceBelow = screenHeight - expandedRect.bottom;

    // Display above if there's not enough space below, but more space above.
    // Heuristic: 200px is a reasonable minimum height for the solution popup.
    final bool displayAbove = spaceBelow < 200 && spaceAbove > spaceBelow;

    final maxHeight = (displayAbove ? spaceAbove : spaceBelow) - 20;

    // Calculate popup width and position to avoid overflow
    const minPopupWidth = 200.0;
    const maxPopupWidth = 400.0;
    final preferredWidth =
        math.min(maxPopupWidth, math.max(minPopupWidth, expandedRect.width));

    // Calculate popup position to keep it within screen bounds
    double popupLeft = expandedRect.left;
    double popupWidth = preferredWidth;

    // Debug logging
    print('Popup positioning debug:');
    print('  expandedRect.left: ${expandedRect.left}');
    print('  expandedRect.right: ${expandedRect.right}');
    print('  screenWidth: $screenWidth');
    print('  preferredWidth: $preferredWidth');
    print('  initial popupLeft: $popupLeft');

    // Check if popup would overflow the right edge
    if (popupLeft + popupWidth > screenWidth - 16) {
      popupLeft = screenWidth - popupWidth - 16;
      print('  adjusted popupLeft for right overflow: $popupLeft');
    }

    // Check if popup would overflow the left edge
    if (popupLeft < 16) {
      popupLeft = 16;
      print('  adjusted popupLeft for left overflow: $popupLeft');
      // If the popup is too wide, reduce its width
      if (popupLeft + popupWidth > screenWidth - 16) {
        popupWidth = screenWidth - popupLeft - 16;
        print('  reduced popupWidth: $popupWidth');
      }
    }

    print('  final popupLeft: $popupLeft, popupWidth: $popupWidth');

    final solutionWidget = Positioned(
      top: displayAbove ? null : expandedRect.bottom + 5,
      bottom: displayAbove ? (screenHeight - expandedRect.top + 5) : null,
      left: popupLeft,
      width: popupWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight < 0 ? 0 : maxHeight,
          maxWidth:
              screenWidth - 32, // Ensure popup doesn't exceed screen width
        ),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          child: Card(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.expression.solution != null)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Answer:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Math.tex(
                                widget.expression.solution!,
                                textStyle: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.expression.steps != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Flexible(
                        child: MarkdownBody(
                          data: widget.expression.steps!,
                          builders: {
                            'math': _MathBuilder(),
                          },
                          inlineSyntaxes: [
                            _MathSyntax(),
                          ],
                          extensionSet: md.ExtensionSet.gitHubWeb,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return [solutionWidget];
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            widget.expression.errorMessage ?? 'An unknown error occurred.',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Custom solve button widget
class _SolveButton extends StatefulWidget {
  const _SolveButton({
    required this.onPressed,
    this.isEnabled = true,
  });

  final VoidCallback? onPressed;
  final bool isEnabled;

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
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _buttonAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? _onTapDown : null,
      onTapUp: widget.isEnabled ? _onTapUp : null,
      onTapCancel: widget.isEnabled ? _onTapCancel : null,
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
                  colors: widget.isEnabled
                      ? [
                          Colors.blue.shade600,
                          Colors.blue.shade700,
                        ]
                      : [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Solve',
                  style: TextStyle(
                    color:
                        widget.isEnabled ? Colors.white : Colors.grey.shade300,
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.borderRadius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final path = Path();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    path.addRRect(rrect);

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
