import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/mixins/base.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

mixin TableDynamicExtentMeasurerMixin
    on RenderTwoDimensionalViewport, TableViewportMetrics {
  (RenderBox?, bool) obtainCellForMeasurement(ChildVicinity vicinity);

  final _dynamicRows = <int>{};

  final _measuredRowExtents = _RowExtentMeasurement();
  final _measuredColumnExtents = _ColumnExtentMeasurement();

  bool measureDynamicColumns() {
    final dynamicColumns = <int, Extent>{};

    for (int column = 0; column < delegate.columnCount; column++) {
      final extent = delegate.getColumnExtent(column);
      if (extent.isDynamic) {
        dynamicColumns[column] = extent;
      }
    }

    if (dynamicColumns.isEmpty) return false;

    bool hasColumnMeasured = false;

    final headerRowExtent = delegate.getRowExtent(0);

    double columnLeading = 0;

    double maxRowHeight = 0;

    for (final entry in dynamicColumns.entries) {
      final column = entry.key;
      final colExtent = entry.value;

      final vicinity = ChildVicinity(xIndex: column, yIndex: 0);

      final (cell, _) = obtainCellForMeasurement(vicinity);

      if (cell == null) continue;

      hasColumnMeasured = true;

      final computedCellWidth = headerRowExtent.calculate(
        viewportDimension.height,
        remainingSpace: viewportDimension.height,
        pinned: delegate.pinnedRowCount > 0,
      );

      final minCellHeight =
          !headerRowExtent.isDynamic ? computedCellWidth : 0.0;
      final maxCellHeight =
          !headerRowExtent.isDynamic ? computedCellWidth : double.infinity;

      cell.layout(
        BoxConstraints(
          minHeight: minCellHeight,
          maxHeight: maxCellHeight,
          minWidth: verticalBorderWidth,
          maxWidth: double.infinity,
        ),
        parentUsesSize: true,
      );

      final data = parentDataOf(cell);

      data.layoutOffset = Offset(
        columnLeading + verticalBorderWidth,
        horizontalBorderWidth,
      );

      maxRowHeight = math.max(maxRowHeight, cell.size.height);

      columnLeading = data.layoutOffset!.dx + cell.size.width;

      final columnKey = delegate.tableFinder.getColumnKey(column);

      _measuredColumnExtents.update(
        columnKey,
        colExtent.accept(cell.size.width + verticalBorderWidth),
      );

      if (headerRowExtent.isDynamic) {
        _measuredRowExtents.update(null, headerRowExtent.accept(maxRowHeight));
      }
    }

    return hasColumnMeasured;
  }

  /// Measures the dynamic rows by laying out all cells in those rows to determine the max cell height,
  /// it is quite expensively, as it will force to schedule a new layout pass after the measurement is done,
  /// but it is necessary to support dynamic row height.
  bool measureDynamicRows() {
    if (_dynamicRows.isEmpty) return false;

    bool hasRowMeasured = false;

    for (final row in _dynamicRows) {
      if (row < 0 || row >= delegate.rowCount) {
        continue;
      }

      double maxCellHeight = 0;

      /// we need to layout all cells in this row to determine the max cell height,
      /// which will be used as the row extent for dynamic row.
      for (int column = 0; column < delegate.columnCount; column++) {
        final columnSpan = getColumnSpan(column);

        if (columnSpan == null) {
          continue;
        }

        final vicinity = ChildVicinity(xIndex: column, yIndex: row);

        final (cell, cached) = obtainCellForMeasurement(vicinity);

        if (cell == null) continue;

        hasRowMeasured = true;

        final cellWidth =
            math.max(0.0, columnSpan.extent - verticalBorderWidth);

        cell.layout(
          BoxConstraints(
            minWidth: cellWidth,
            maxWidth: cellWidth,
            minHeight: 0,
            maxHeight: double.infinity,
          ),
          parentUsesSize: true,
        );

        if (!cached) {
          /// It may have UI flicker if we set the layout offset for cells during the measurement phase,
          /// but it is necessary to ensure the correct layout of cells in dynamic rows,
          final data = parentDataOf(cell);
          final columnLeading = getColumnSpan(column)?.leadingOffset ?? 0;
          final rowLeading = getRowSpan(row)?.leadingOffset ?? 0;
          data.layoutOffset = Offset(
            columnLeading + verticalBorderWidth,
            rowLeading + horizontalBorderWidth,
          );
        }

        maxCellHeight = math.max(maxCellHeight, cell.size.height);
      }

      final oldExtent = delegate.getRowExtent(row);
      final newExtent = oldExtent.accept(maxCellHeight + horizontalBorderWidth);

      /// This is one-shot measurement and update,
      if (oldExtent != newExtent) {
        _measuredRowExtents.update(
          delegate.tableFinder.getRowKey(row),
          newExtent,
        );
      }
    }

    _dynamicRows.clear();

    return hasRowMeasured;
  }

  void markRowNeedsMeasurement(int row) {
    if (row < 0 || row >= delegate.rowCount) {
      return;
    }

    _dynamicRows.add(row);
  }
}

class _RowExtentMeasurement {
  final Map<RowKey, Extent> _measuredRowExtents = {};

  Extent? _measureHeaderRowExtent;

  void update(RowKey? rowKey, Extent extent) {
    assert(!extent.isDynamic, 'Measured extent cannot be dynamic.');

    if (rowKey == null) {
      _measureHeaderRowExtent = extent;
    } else {
      _measuredRowExtents[rowKey] = extent;
    }
  }

  Extent? get(RowKey? rowKey) {
    if (rowKey == null) {
      return _measureHeaderRowExtent;
    }

    return _measuredRowExtents[rowKey];
  }

  void evict(RowKey? rowKey) {
    if (rowKey == null) {
      _measureHeaderRowExtent = null;
    } else {
      _measuredRowExtents.remove(rowKey);
    }
  }

  void evictAll() {
    _measuredRowExtents.clear();
    _measureHeaderRowExtent = null;
  }
}

class _ColumnExtentMeasurement {
  final Map<ColumnKey, Extent> _measuredColumnExtents = {};

  void update(ColumnKey columnKey, Extent extent) {
    assert(!extent.isDynamic, 'Measured extent cannot be dynamic.');

    _measuredColumnExtents[columnKey] = extent;
  }

  Extent? get(ColumnKey columnKey) {
    return _measuredColumnExtents[columnKey];
  }

  void evict(ColumnKey columnKey) {
    _measuredColumnExtents.remove(columnKey);
  }

  void evictAll() {
    _measuredColumnExtents.clear();
  }
}
