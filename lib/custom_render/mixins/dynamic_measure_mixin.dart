import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/mixins/base.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

mixin TableDynamicExtentMeasurerMixin
    on RenderTwoDimensionalViewport, TableViewportMetrics {
  (RenderBox?, bool) obtainCellForMeasurement(ChildVicinity vicinity);

  final _dynamicRows = <int, Extent>{};

  /// Measures the dynamic rows by laying out all cells in those rows to determine the max cell height,
  /// it is quite expensively, as it will force to schedule a new layout pass after the measurement is done,
  /// but it is necessary to support dynamic row height.
  ///
  bool measureDynamicRows() {
    if (_dynamicRows.isEmpty) return false;

    bool hasRowMeasured = false;

    for (final entry in _dynamicRows.entries) {
      final row = entry.key;
      final rowExtent = entry.value;

      if (row < 0 || row >= delegate.rowCount) {
        continue;
      }

      if (rowExtent.isMeasured) continue;

      double maxCellHeight = 0;

      /// we need to layout all cells in this row to determine the max cell height,
      /// which will be used as the row extent for dynamic row.
      for (int column = 0; column < delegate.columnCount; column++) {
        final columnSpan = getColumnSpan(column);

        if (columnSpan == null) continue;

        final vicinity = ChildVicinity(xIndex: column, yIndex: row);

        final (cell, cached) = obtainCellForMeasurement(vicinity);

        if (cell == null) continue;

        hasRowMeasured = true;

        final cellWidth = math.max(0.0, columnSpan.extent);
        final (minHeight, maxHeight) = rowExtent.range;

        cell.layout(
          BoxConstraints(
            minWidth: cellWidth,
            maxWidth: cellWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
          ),
          parentUsesSize: true,
        );

        if (!cached) {
          final data = parentDataOf(cell);

          final columnLeading = getColumnSpan(column)?.leadingOffset ?? 0;
          final rowLeading = getRowSpan(row - 1)?.trailingOffset ?? 0;

          data.layoutOffset = Offset(
            columnLeading + verticalBorderWidth,
            rowLeading + horizontalBorderWidth,
          );
        }

        maxCellHeight = math.max(maxCellHeight, cell.size.height);
      }

      rowExtent.acceptMeasurement(maxCellHeight);
    }

    assert(
      _dynamicRows.values.every((extent) => extent.isMeasured),
      "All dynamic rows should be measured after calling measureDynamicRows.",
    );

    _dynamicRows.clear();

    return hasRowMeasured;
  }

  bool measureHeaderRowIfNeeded() {
    final headerRowExtent = delegate.getRowExtent(0);

    bool needMeasureColumn = false;

    for (int column = 0; column < delegate.columnCount; column++) {
      final colExtent = delegate.getColumnExtent(column);

      if (!colExtent.isMeasured) {
        needMeasureColumn = true;
        break;
      }
    }

    if (!needMeasureColumn && headerRowExtent.isMeasured) {
      return false;
    }

    bool headerRowMeasured = false;

    final (minHeaderCellHeight, maxHeaderCellHeight) = headerRowExtent.range;

    double columnLeading = 0;
    double maxHeaderRowHeight = 0;

    /// as long as there is at least one column or the header row itself is not measured,
    /// we need to build the entire header row to measure possible dynamic extents.
    for (int column = 0; column < delegate.columnCount; column++) {
      final colExtent = delegate.getColumnExtent(column);

      final vicinity = ChildVicinity(xIndex: column, yIndex: 0);

      final (cell, _) = obtainCellForMeasurement(vicinity);

      if (cell == null) continue;

      headerRowMeasured = true;

      final (minCellWidth, maxCellWidth) = colExtent.range;

      cell.layout(
        BoxConstraints(
          minHeight: minHeaderCellHeight,
          maxHeight: maxHeaderCellHeight,
          minWidth: minCellWidth,
          maxWidth: maxCellWidth,
        ),
        parentUsesSize: true,
      );

      /// Some header cells may not be visible due to horizontal scrolling when layout the header row,
      /// but we forcely build and layout them.
      ///
      /// so we need also to set their layout offset to the correct position to
      /// make sure they are in the right place when they become visible.
      final data = parentDataOf(cell);

      data.layoutOffset = Offset(
        columnLeading + verticalBorderWidth,
        horizontalBorderWidth,
      );

      columnLeading = data.layoutOffset!.dx + cell.size.width;

      maxHeaderRowHeight = math.max(maxHeaderRowHeight, cell.size.height);
      colExtent.acceptMeasurement(cell.size.width);
    }

    if (!headerRowExtent.isMeasured) {
      headerRowMeasured = true;
      headerRowExtent.acceptMeasurement(maxHeaderRowHeight);
    }

    return headerRowMeasured;
  }

  void markRowNeedsMeasurement(int row, Extent extent) {
    if (row < 0 || row >= delegate.rowCount) {
      return;
    }

    assert(!extent.isMeasured,
        'Cannot mark row $row for measurement with a measured extent.');

    _dynamicRows[row] = extent;
  }
}
