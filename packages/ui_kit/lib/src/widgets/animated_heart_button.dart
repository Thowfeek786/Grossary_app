import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedHeartButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedHeartButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 24,
    this.activeColor = const Color(0xFFEF4444),
    this.inactiveColor = const Color(0xFF94A3B8),
  });

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with TickerProviderStateMixin {
  late AnimationController _selectController;
  late AnimationController _deselectController;

  late Animation<double> _selectScale;
  late Animation<double> _selectParticleRadius;
  late Animation<double> _selectParticleOpacity;

  late Animation<double> _deselectShake;
  late Animation<double> _deselectOffset;
  late Animation<double> _deselectOpacity;

  bool _isBrokenState = false;

  @override
  void initState() {
    super.initState();

    // 1. Selection Animation Controller (Sparkle Burst)
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _selectScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.55)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.55, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_selectController);

    _selectParticleRadius = Tween<double>(begin: 0.0, end: 1.8).animate(
      CurvedAnimation(parent: _selectController, curve: Curves.easeOutQuart),
    );

    _selectParticleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _selectController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // 2. Deselection Animation Controller (Broken Heart Shake & Shatter)
    _deselectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _deselectShake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.25), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.25, end: 0.25), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: -0.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _deselectController,
      curve: Curves.easeInOut,
    ));

    _deselectOffset = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(
        parent: _deselectController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInQuad),
      ),
    );

    _deselectOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _deselectController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _deselectController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isBrokenState = false;
        });
        _deselectController.reset();
      }
    });
  }

  @override
  void dispose() {
    _selectController.dispose();
    _deselectController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isFavorite) {
      // Unfavoriting -> Trigger Broken Heart Animation
      HapticFeedback.mediumImpact();
      setState(() {
        _isBrokenState = true;
      });
      _deselectController.forward(from: 0.0);
    } else {
      // Favoriting -> Trigger Best Selection Burst Animation
      HapticFeedback.selectionClick();
      _selectController.forward(from: 0.0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size * 2.0,
        height: widget.size * 2.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particle Burst Painter (On Select)
            if (_selectController.isAnimating)
              AnimatedBuilder(
                animation: _selectController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size * 2.0, widget.size * 2.0),
                    painter: _ParticleBurstPainter(
                      progress: _selectParticleRadius.value,
                      opacity: _selectParticleOpacity.value,
                      color: widget.activeColor,
                    ),
                  );
                },
              ),

            // Heart Icon (Selection Elastic Pop OR Broken Heart Shake)
            AnimatedBuilder(
              animation:
                  Listenable.merge([_selectController, _deselectController]),
              builder: (context, child) {
                if (_isBrokenState || _deselectController.isAnimating) {
                  // Broken Heart Shatter Rendering
                  return Transform.translate(
                    offset: Offset(0, _deselectOffset.value),
                    child: Transform.rotate(
                      angle: _deselectShake.value,
                      child: Opacity(
                        opacity: _deselectOpacity.value,
                        child: Icon(
                          Icons.heart_broken_rounded,
                          color: Color.lerp(
                            widget.activeColor,
                            const Color(0xFF64748B),
                            _deselectController.value,
                          ),
                          size: widget.size,
                        ),
                      ),
                    ),
                  );
                }

                // Normal / Selected Heart Elastic Scale Rendering
                return Transform.scale(
                  scale:
                      _selectController.isAnimating ? _selectScale.value : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isFavorite
                          ? widget.activeColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      boxShadow: widget.isFavorite
                          ? [
                              BoxShadow(
                                color: widget.activeColor.withValues(alpha: 0.25),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      widget.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: widget.isFavorite
                          ? widget.activeColor
                          : widget.inactiveColor,
                      size: widget.size,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticleBurstPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Color color;

  _ParticleBurstPainter({
    required this.progress,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.38 * progress;
    final particleRadius = 2.5 * (1.0 - progress * 0.4);

    final paint = Paint()
      ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    const count = 7;
    for (int i = 0; i < count; i++) {
      final angle = (2 * math.pi / count) * i;
      final x = center.dx + baseRadius * math.cos(angle);
      final y = center.dy + baseRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), particleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
