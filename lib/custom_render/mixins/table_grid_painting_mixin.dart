import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/mixins/base.dart';

mixin TableGridPaintingMixin on TableViewportMetrics {
  void paintGrid({
    required Canvas canvas,
    required ChildVicinity start,
    required ChildVicinity end,
    required Offset offset,
  }) {
    if (verticalBorderWidth <= 0 && horizontalBorderWidth <= 0) {
      return;
    }

    final columnTranslation = resolveColumnTranslation(start, end);
    final rowTranslation = resolveRowTranslation(start, end);

    if (columnTranslation == null || rowTranslation == null) {
      return;
    }

    final startX =
        getColumnSpan(start.xIndex)!.leadingOffset + columnTranslation;
    final endX = getColumnSpan(end.xIndex)!.trailingOffset +
        columnTranslation +
        verticalBorderWidth;
    final startY = getRowSpan(start.yIndex)!.leadingOffset + rowTranslation;
    final endY = getRowSpan(end.yIndex)!.trailingOffset +
        rowTranslation +
        horizontalBorderWidth;
    final clipBounds = canvas.getLocalClipBounds();
    final clippedEndX = math.min(endX, clipBounds.right - offset.dx);
    final clippedEndY = math.min(endY, clipBounds.bottom - offset.dy);

    if (verticalBorderWidth > 0) {
      final verticalPaint = Paint()
        ..color = verticalBorderSide.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = verticalBorderWidth;

      /// line count = column count + 2 (including the leading and trailing border lines)
      final verticalSegmentCount = end.xIndex - start.xIndex + 2;
      final verticalPoints = Float32List(verticalSegmentCount * 4);
      int pointIndex = 0;
      final yStart = offset.dy + startY;
      final yEnd = offset.dy + clippedEndY + horizontalBorderWidth / 2;

      for (int column = start.xIndex; column <= end.xIndex; column++) {
        final x = getColumnSpan(column)!.leadingOffset +
            columnTranslation +
            verticalBorderWidth / 2;

        final xOffset = offset.dx + x;

        verticalPoints[pointIndex++] = xOffset;
        verticalPoints[pointIndex++] = yStart;
        verticalPoints[pointIndex++] = xOffset;
        verticalPoints[pointIndex++] = yEnd;
      }

      final trailingX = math.max(
        startX + verticalBorderWidth / 2,
        clippedEndX,
      );

      verticalPoints[pointIndex++] = offset.dx + trailingX;
      verticalPoints[pointIndex++] = yStart;
      verticalPoints[pointIndex++] = offset.dx + trailingX;
      verticalPoints[pointIndex++] = yEnd;

      canvas.drawRawPoints(
        PointMode.lines,
        verticalPoints,
        verticalPaint,
      );
    }

    if (horizontalBorderWidth > 0) {
      final horizontalPaint = Paint()
        ..color = horizontalBorderSide.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = horizontalBorderWidth;

      /// line count = row count + 2 (including the leading and trailing border lines)
      final horizontalSegmentCount = end.yIndex - start.yIndex + 2;
      final horizontalPoints = Float32List(horizontalSegmentCount * 4);
      int pointIndex = 0;
      final xStart = offset.dx + startX;
      final xEnd = offset.dx + clippedEndX + verticalBorderWidth / 2;

      for (int row = start.yIndex; row <= end.yIndex; row++) {
        final y = getRowSpan(row)!.leadingOffset +
            rowTranslation +
            horizontalBorderWidth / 2;
        final yOffset = offset.dy + y;

        horizontalPoints[pointIndex++] = xStart;
        horizontalPoints[pointIndex++] = yOffset;
        horizontalPoints[pointIndex++] = xEnd;
        horizontalPoints[pointIndex++] = yOffset;
      }

      final trailingY = math.max(
        startY + horizontalBorderWidth / 2,
        clippedEndY,
      );

      horizontalPoints[pointIndex++] = xStart;
      horizontalPoints[pointIndex++] = offset.dy + trailingY;
      horizontalPoints[pointIndex++] = xEnd;
      horizontalPoints[pointIndex++] = offset.dy + trailingY;

      canvas.drawRawPoints(
        PointMode.lines,
        horizontalPoints,
        horizontalPaint,
      );
    }
  }

  double? resolveColumnTranslation(ChildVicinity start, ChildVicinity end);

  double? resolveRowTranslation(ChildVicinity start, ChildVicinity end);
}
