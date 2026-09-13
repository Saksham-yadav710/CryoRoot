import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/storage_analytics.dart';

class TimeSeriesChart extends StatelessWidget {
  final List<HistoricalDataPoint> dataPoints;
  final String title;
  final String unit;
  final Color lineColor;
  final double? safeMinThreshold;
  final double? safeMaxThreshold;
  final String? safeZoneLabel;

  const TimeSeriesChart({
    super.key,
    required this.dataPoints,
    required this.title,
    required this.unit,
    required this.lineColor,
    this.safeMinThreshold,
    this.safeMaxThreshold,
    this.safeZoneLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No historical telemetry recorded')),
      );
    }

    final values = dataPoints.map((e) => e.value).toList();
    final double rawMin = values.reduce(math.min);
    final double rawMax = values.reduce(math.max);

    // Padding for chart scale
    final double minY = (safeMinThreshold != null)
        ? math.min(rawMin, safeMinThreshold!) - 1.0
        : rawMin - 1.0;
    final double maxY = (safeMaxThreshold != null)
        ? math.max(rawMax, safeMaxThreshold!) + 1.0
        : rawMax + 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (safeZoneLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusGoodBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.statusGoodBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.statusGood,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        safeZoneLabel!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusGood,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _TimeSeriesPainter(
                dataPoints: dataPoints,
                lineColor: lineColor,
                minY: minY,
                maxY: maxY,
                safeMin: safeMinThreshold,
                safeMax: safeMaxThreshold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // X-Axis Timestamp Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dataPoints.first.label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textTertiary)),
              if (dataPoints.length > 4)
                Text(dataPoints[dataPoints.length ~/ 2].label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textTertiary)),
              Text(dataPoints.last.label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeSeriesPainter extends CustomPainter {
  final List<HistoricalDataPoint> dataPoints;
  final Color lineColor;
  final double minY;
  final double maxY;
  final double? safeMin;
  final double? safeMax;

  _TimeSeriesPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.minY,
    required this.maxY,
    this.safeMin,
    this.safeMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final double rangeY = (maxY - minY == 0) ? 1.0 : (maxY - minY);
    final double stepX = size.width / (dataPoints.length - 1);

    // 1. Draw Safe Threshold Band (if provided)
    if (safeMin != null && safeMax != null) {
      final double safeTopY =
          size.height - ((safeMax! - minY) / rangeY * size.height);
      final double safeBottomY =
          size.height - ((safeMin! - minY) / rangeY * size.height);

      final safeBandRect = Rect.fromLTRB(
        0,
        safeTopY.clamp(0.0, size.height),
        size.width,
        safeBottomY.clamp(0.0, size.height),
      );

      final safePaint = Paint()
        ..color = AppColors.statusGoodBg.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(safeBandRect, safePaint);

      // Dashed border lines
      final borderPaint = Paint()
        ..color = AppColors.statusGoodBorder
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(0, safeTopY), Offset(size.width, safeTopY), borderPaint);
      canvas.drawLine(
          Offset(0, safeBottomY), Offset(size.width, safeBottomY), borderPaint);
    }

    // 2. Draw Subtle Horizontal Gridlines
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75),
        Offset(size.width, size.height * 0.75), gridPaint);

    // 3. Build Smooth Curve Points
    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * stepX;
      final double y =
          size.height - ((dataPoints[i].value - minY) / rangeY * size.height);
      points.add(Offset(x, y.clamp(0.0, size.height)));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 4. Fill Area Gradient Below Path
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.28),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Curve Stroke
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 6. Draw Highlight Points
    for (int i = 0; i < points.length; i++) {
      if (i == 0 || i == points.length - 1 || i == points.length ~/ 2) {
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final ringPaint = Paint()
          ..color = lineColor
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(points[i], 4.5, dotPaint);
        canvas.drawCircle(points[i], 4.5, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimeSeriesPainter oldDelegate) => true;
}
