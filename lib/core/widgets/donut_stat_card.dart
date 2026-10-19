import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Item dữ liệu cho 1 vòng tròn Donut
class DonutStatItem {
  final int value;
  final String label;
  final double progressPercent; // từ 0.0 đến 1.0 (hoặc > 1.0 nếu vượt)
  final Color color;
  final Color? trackColor;

  const DonutStatItem({
    required this.value,
    required this.label,
    required this.progressPercent,
    required this.color,
    this.trackColor,
  });
}

/// Widget Card hiển thị 3 vòng tròn Donut theo chuẩn thiết kế người dùng yêu cầu
class DonutStatCard extends StatelessWidget {
  final String? title;
  final String? filterPillText;
  final VoidCallback? onFilterTap;
  final List<DonutStatItem> items;
  final Widget? topSummaryWidget;

  const DonutStatCard({
    super.key,
    this.title,
    this.filterPillText,
    this.onFilterTap,
    required this.items,
    this.topSummaryWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Tiêu đề + Bộ lọc ngày tháng/đợt ở góc phải)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null && title!.isNotEmpty)
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (filterPillText != null && filterPillText!.isNotEmpty)
                InkWell(
                  onTap: onFilterTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Text(
                          filterPillText!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          if (topSummaryWidget != null) ...[
            const SizedBox(height: 12),
            topSummaryWidget!,
          ],

          const SizedBox(height: 16),

          // 2. Hàng ngang các vòng tròn Donut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildDonutRing(item),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutRing(DonutStatItem item) {
    final track = item.trackColor ?? item.color.withOpacity(0.18);
    final clampedPercent = item.progressPercent.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Vòng tròn Donut có số ở giữa
        SizedBox(
          width: 82,
          height: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(82, 82),
                painter: _DonutRingPainter(
                  percent: clampedPercent,
                  progressColor: item.color,
                  trackColor: track,
                  strokeWidth: 8.5,
                ),
              ),
              Text(
                '${item.value}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Nhãn text bên dưới
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

/// Painter vẽ vòng tròn Donut chuẩn xác
class _DonutRingPainter extends CustomPainter {
  final double percent;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _DonutRingPainter({
    required this.percent,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Vẽ vòng tròn nền
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Vẽ cung tiến độ đậm màu
    if (percent > 0.0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Bắt đầu từ góc 12 giờ (-pi / 2)
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * percent;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutRingPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
