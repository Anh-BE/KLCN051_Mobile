import 'dart:math' as math;
import 'package:flutter/material.dart';

class HuitLoading extends StatefulWidget {
  final double size;
  final String? message;
  final bool showMessage;

  const HuitLoading({
    super.key,
    this.size = 80,
    this.message,
    this.showMessage = true,
  });

  @override
  State<HuitLoading> createState() => _HuitLoadingState();
}

class _HuitLoadingState extends State<HuitLoading> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final String _logoUrl = 'https://res.cloudinary.com/wpyhssfm/image/upload/logohuit';

  @override
  void initState() {
    super.initState();

    // Vòng quay tròn mượt mà quanh logo
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Hiệu ứng nhịp thở (Pulse / Breathing) nhẹ nhàng cho logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double spinnerSize = widget.size;
    final double logoSize = widget.size * 0.62;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: spinnerSize,
          height: spinnerSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Vòng quay gradient xoay tròn xung quanh
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: Size(spinnerSize, spinnerSize),
                      painter: _HuitSpinnerPainter(),
                    ),
                  );
                },
              ),

              // 2. Logo HUIT ở giữa với hiệu ứng nhịp thở
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0072E8).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.network(
                      _logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          'HUIT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0072E8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (widget.showMessage) ...[
          const SizedBox(height: 14),
          Text(
            widget.message ?? 'Đang tải dữ liệu...',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0072E8),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

// Vẽ vòng tròn xoay mờ chuyển màu HUIT (Xanh dương đậm sang Xanh ngọc)
class _HuitSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const Gradient gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: [
        Colors.transparent,
        Color(0x220072E8),
        Color(0xFF0084FF),
        Color(0xFF00C6FF),
      ],
      stops: [0.0, 0.3, 0.75, 1.0],
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final double radius = (size.width - 4) / 2;
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
