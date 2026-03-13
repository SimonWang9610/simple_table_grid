import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/delegate.dart';
import 'package:simple_table_grid/custom_render/layout_metrics.dart';
import 'package:simple_table_grid/custom_render/mixins/base.dart';
import 'package:simple_table_grid/custom_render/mixins/dynamic_measure_mixin.dart';
import 'package:simple_table_grid/custom_render/mixins/table_grid_painting_mixin.dart';

class RenderTableGridViewport extends RenderTwoDimensionalViewport
    with
        TableViewportMetrics,
        _ViewportMetrics,
        TableDynamicExtentMeasurerMixin,
        TableGridPaintingMixin {
  RenderTableGridViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required CellLayoutExtentDelegate super.delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior,
    BorderSide verticalBorderSide = BorderSide.none,
    BorderSide horizontalBorderSide = BorderSide.none,
  })  : _verticalBorderSide = verticalBorderSide,
        _horizontalBorderSide = horizontalBorderSide;

  BorderSide _verticalBorderSide;

  @override
  BorderSide get verticalBorderSide => _verticalBorderSide;
  set verticalBorderSide(BorderSide value) {
    if (_verticalBorderSide == value) {
      return;
    }

    _verticalBorderSide = value;
    markNeedsLayout();
    markNeedsPaint();
  }

  BorderSide _horizontalBorderSide;

  @override
  BorderSide get horizontalBorderSide => _horizontalBorderSide;
  set horizontalBorderSide(BorderSide value) {
    if (_horizontalBorderSide == value) {
      return;
    }

    _horizontalBorderSide = value;
    _needsMetricsRefresh = true;
    markNeedsLayout();
    markNeedsPaint();
  }

  @override
  CellLayoutExtentDelegate get delegate =>
      super.delegate as CellLayoutExtentDelegate;

  int? get _lastPinnedRow =>
      delegate.pinnedRowCount > 0 ? delegate.pinnedRowCount - 1 : null;
  int? get _lastPinnedColumn =>
      delegate.pinnedColumnCount > 0 ? delegate.pinnedColumnCount - 1 : null;

  double get _pinnedColumnsExtent => _lastPinnedColumn != null
      ? _columnMetrics[_lastPinnedColumn!]!.trailingOffset
      : 0.0;
  double get _pinnedRowsExtent => _lastPinnedRow != null
      ? _rowMetrics[_lastPinnedRow!]!.trailingOffset
      : 0.0;

  ChildVicinity? get _firstNonPinnedCell {
    if (_rowMetrics.firstNonPinned == null ||
        _columnMetrics.firstNonPinned == null) {
      return null;
    }

    return ChildVicinity(
      xIndex: _columnMetrics.firstNonPinned!,
      yIndex: _rowMetrics.firstNonPinned!,
    );
  }

  ChildVicinity? get _lastNonPinnedCell {
    if (_rowMetrics.lastNonPinned == null ||
        _columnMetrics.lastNonPinned == null) {
      return null;
    }

    return ChildVicinity(
      xIndex: _columnMetrics.lastNonPinned!,
      yIndex: _rowMetrics.lastNonPinned!,
    );
  }

  double get _targetColumnPixels {
    return cacheExtent +
        horizontalOffset.pixels +
        viewportDimension.width -
        _pinnedColumnsExtent;
  }

  double get _targetRowPixels {
    return cacheExtent +
        verticalOffset.pixels +
        viewportDimension.height -
        _pinnedRowsExtent;
  }

  @override
  void layoutChildSequence() {
    _builtVicinities.clear();

    measureDynamicColumns();

    if (needsDelegateRebuild || didResize || _needsMetricsRefresh) {
      _columnMetrics.clear();
      _rowMetrics.clear();
      _updateColumnMetrics();
      _updateRowMetrics();
      _updateScrollBounds();
      _needsMetricsRefresh = false;
    } else {
      _updateFirstAndLastVisibleCell();
    }

    if (_lastPinnedColumn == null &&
        _lastPinnedRow == null &&
        _firstNonPinnedCell == null) {
      assert(_lastNonPinnedCell == null);
      return;
    }

    final offsetIntoColumn = _columnMetrics.getNonPinnedOffset(
      horizontalOffset.pixels,
      _pinnedColumnsExtent,
    );

    final offsetIntoRow = _rowMetrics.getNonPinnedOffset(
      verticalOffset.pixels,
      _pinnedRowsExtent,
    );

    // +----------+------------------+
    // |     A    |         B        |
    // |          |                  |
    // +----------+------------------+
    // |     C    |         D        |
    // |          |                  |
    // +----------+------------------+

    // A: pinned rows and columns
    if (_lastPinnedRow != null && _lastPinnedColumn != null) {
      _layoutCells(
        start: ChildVicinity(xIndex: 0, yIndex: 0),
        end: ChildVicinity(xIndex: _lastPinnedColumn!, yIndex: _lastPinnedRow!),
        offset: Offset.zero,
      );
    }

    // B: pinned rows and non pinned columns
    if (_lastPinnedRow != null && _columnMetrics.firstNonPinned != null) {
      assert(_columnMetrics.lastNonPinned != null);
      assert(offsetIntoColumn != null);

      _layoutCells(
        start: ChildVicinity(
          xIndex: _columnMetrics.firstNonPinned!,
          yIndex: 0,
        ),
        end: ChildVicinity(
          xIndex: _columnMetrics.lastNonPinned!,
          yIndex: _lastPinnedRow!,
        ),
        offset: Offset(offsetIntoColumn!, 0),
      );
    }

    // C: pinned columns and non pinned rows
    if (_lastPinnedColumn != null && _rowMetrics.firstNonPinned != null) {
      assert(_rowMetrics.lastNonPinned != null);
      assert(offsetIntoRow != null);

      _layoutCells(
        start: ChildVicinity(
          xIndex: 0,
          yIndex: _rowMetrics.firstNonPinned!,
        ),
        end: ChildVicinity(
          xIndex: _lastPinnedColumn!,
          yIndex: _rowMetrics.lastNonPinned!,
        ),
        offset: Offset(0, offsetIntoRow!),
      );
    }

    // D: non pinned rows and columns
    if (_firstNonPinnedCell != null) {
      assert(_lastNonPinnedCell != null);
      assert(offsetIntoColumn != null);
      assert(offsetIntoRow != null);

      _layoutCells(
        start: _firstNonPinnedCell!,
        end: _lastNonPinnedCell!,
        offset: Offset(offsetIntoColumn!, offsetIntoRow!),
      );
    }

    final hasRowMeasured = measureDynamicRows();

    if (hasRowMeasured) {
      _needsMetricsRefresh = true;
      _scheduleMetricsRefresh();
    }
  }

  void _layoutCells({
    required ChildVicinity start,
    required ChildVicinity end,
    required Offset offset,
  }) {
    double rowOffset = -offset.dy;

    for (int row = start.yIndex; row <= end.yIndex; row++) {
      assert(row < _rowMetrics.length);

      double columnOffset = -offset.dx;
      final rowSpan = _rowMetrics[row]!;

      for (int column = start.xIndex; column <= end.xIndex; column++) {
        assert(column < _columnMetrics.length);
        final columnSpan = _columnMetrics[column]!;
        final vicinity = ChildVicinity(xIndex: column, yIndex: row);

        final (cell, _) = obtainCellForMeasurement(vicinity);

        if (cell != null) {
          final data = parentDataOf(cell);

          final cellWidth =
              math.max(0.0, columnSpan.extent - verticalBorderWidth);
          final cellHeight =
              math.max(0.0, rowSpan.extent - horizontalBorderWidth);

          final constraints = BoxConstraints.tightFor(
            width: cellWidth,
            height: cellHeight,
          );

          cell.layout(constraints);
          data.layoutOffset = Offset(
            columnOffset + verticalBorderWidth,
            rowOffset + horizontalBorderWidth,
          );
        }

        columnOffset += columnSpan.extent;
      }
      rowOffset += rowSpan.extent;
    }
  }

  void _updateColumnMetrics() {
    assert(
      _columnMetrics.isRangeEmpty,
      "the column metrics non-pinned range must be empty before updating",
    );

    double startOfRegularColumn = 0;
    double startOfPinnedColumn = 0;

    int currentColumn = 0;

    double remainingSpace = viewportDimension.width;

    Span updateSpan(int column, bool isPinned, double leadingOffset) {
      final span = _columnMetrics.remove(column) ?? Span();
      final hExtent = delegate.getColumnExtent(column);

      assert(!hExtent.isDynamic,
          "all dynamic column should have been measured at this point");

      span.update(
        leadingOffset: leadingOffset,
        extent: hExtent.calculate(
          viewportDimension.width,
          remainingSpace: remainingSpace,
          pinned: isPinned,
        ),
        isPinned: isPinned,
      );

      _columnMetrics.set(column, span);

      return span;
    }

    /// Pinned columns
    while (currentColumn < delegate.pinnedColumnCount) {
      assert(
        remainingSpace > 0,
        "No available space for pinned columns",
      );

      final leadingOffset = startOfPinnedColumn;
      final span = updateSpan(currentColumn, true, leadingOffset);

      remainingSpace -= span.extent;
      startOfPinnedColumn = span.trailingOffset;
      currentColumn++;
    }

    if (remainingSpace <= 0) {
      return;
    }

    /// Non pinned columns
    while (currentColumn < delegate.columnCount) {
      final leadingOffset = startOfRegularColumn;

      final span = updateSpan(currentColumn, false, leadingOffset);

      if (span.trailingOffset >= horizontalOffset.pixels) {
        _columnMetrics.firstNonPinned = currentColumn;
      }

      if (span.trailingOffset >= _targetColumnPixels) {
        _columnMetrics.lastNonPinned = currentColumn;
      }

      startOfRegularColumn = span.trailingOffset;
      currentColumn++;
    }

    assert(
      _columnMetrics.length >= delegate.pinnedColumnCount,
      "All pinned columns's metrics must be updated",
    );
  }

  void _updateRowMetrics() {
    assert(
      _rowMetrics.isRangeEmpty,
      "the row metrics non-pinned range must be empty before updating",
    );

    double startOfRegularRow = 0;
    double startOfPinnedRow = 0;

    int currentRow = 0;

    double remainingSpace = viewportDimension.height;

    Span updateSpan(int row, bool isPinned, double leadingOffset) {
      final span = _rowMetrics.remove(row) ?? Span();
      final vExtent = delegate.getRowExtent(row);

      /// If the row extent is dynamic, we need to measure the cells in that row to determine the actual extent.
      /// We will schedule a post-frame callback to do that after the layout is complete,
      /// as we cannot [markNeedsLayout] during performLayout.
      if (vExtent.isDynamic) {
        markRowNeedsMeasurement(row);
      }

      span.update(
        leadingOffset: leadingOffset,
        extent: vExtent.calculate(
          viewportDimension.height,
          remainingSpace: remainingSpace,
          pinned: isPinned,
        ),
        isPinned: isPinned,
      );

      _rowMetrics.set(row, span);

      return span;
    }

    /// Pinned rows
    while (currentRow < delegate.pinnedRowCount) {
      assert(
        remainingSpace > 0,
        "No available space for remaining pinned rows",
      );

      final leadingOffset = startOfPinnedRow;
      final span = updateSpan(currentRow, true, leadingOffset);

      remainingSpace -= span.extent;
      startOfPinnedRow = span.trailingOffset;
      currentRow++;
    }

    if (remainingSpace <= 0) {
      return;
    }

    /// Non pinned rows
    while (currentRow < delegate.rowCount) {
      final leadingOffset = startOfRegularRow;

      final span = updateSpan(currentRow, false, leadingOffset);

      if (span.trailingOffset >= verticalOffset.pixels) {
        _rowMetrics.firstNonPinned = currentRow;
      }

      if (span.trailingOffset >= _targetRowPixels) {
        _rowMetrics.lastNonPinned = currentRow;
      }

      startOfRegularRow = span.trailingOffset;
      currentRow++;
    }

    assert(
      _rowMetrics.length >= delegate.pinnedRowCount,
      "All pinned rows's metrics must be updated",
    );
  }

  void _updateScrollBounds() {
    final double maxHorizontalScrollExtent;
    final double maxVerticalScrollExtent;

    if (_columnMetrics.length <= delegate.pinnedColumnCount) {
      assert(_columnMetrics.isRangeEmpty);
      maxHorizontalScrollExtent = 0;
    } else {
      final lastColumn = _columnMetrics.length - 1;

      if (_columnMetrics.firstNonPinned != null) {
        _columnMetrics.lastNonPinned = lastColumn;
      }

      maxHorizontalScrollExtent = math.max(
        0,
        _columnMetrics[lastColumn]!.trailingOffset -
            viewportDimension.width +
            _pinnedColumnsExtent,
      );
    }

    if (_rowMetrics.length <= delegate.pinnedRowCount) {
      assert(_rowMetrics.isRangeEmpty);
      maxVerticalScrollExtent = 0;
    } else {
      final lastRow = _rowMetrics.length - 1;

      if (_rowMetrics.firstNonPinned != null) {
        _rowMetrics.lastNonPinned = lastRow;
      }

      maxVerticalScrollExtent = math.max(
        0,
        _rowMetrics[lastRow]!.trailingOffset -
            viewportDimension.height +
            _pinnedRowsExtent,
      );
    }

    final bothAccepted = horizontalOffset.applyContentDimensions(
          0.0,
          maxHorizontalScrollExtent,
        ) &&
        verticalOffset.applyContentDimensions(
          0.0,
          maxVerticalScrollExtent,
        );

    if (!bothAccepted) {
      _updateFirstAndLastVisibleCell();
    }
  }

  void _updateFirstAndLastVisibleCell() {
    _columnMetrics.resetRange();

    for (int column = 0; column < _columnMetrics.length; column++) {
      if (_columnMetrics[column]!.isPinned) {
        continue;
      }
      final endOfColumn = _columnMetrics[column]!.trailingOffset;

      if (endOfColumn >= horizontalOffset.pixels) {
        _columnMetrics.firstNonPinned = column;
      }

      if (endOfColumn >= _targetColumnPixels &&
          _columnMetrics.lastNonPinned == null) {
        _columnMetrics.lastNonPinned = column;
        break;
      }
    }

    if (_columnMetrics.firstNonPinned != null) {
      _columnMetrics.lastNonPinned = _columnMetrics.length - 1;
    }

    _rowMetrics.resetRange();

    for (int row = 0; row < _rowMetrics.length; row++) {
      if (_rowMetrics[row]!.isPinned) {
        continue;
      }
      final endOfRow = _rowMetrics[row]!.trailingOffset;

      if (endOfRow >= verticalOffset.pixels) {
        _rowMetrics.firstNonPinned = row;
      }

      if (endOfRow >= _targetRowPixels && _rowMetrics.lastNonPinned == null) {
        _rowMetrics.lastNonPinned = row;
        break;
      }
    }

    if (_rowMetrics.firstNonPinned != null) {
      _rowMetrics.lastNonPinned = _rowMetrics.length - 1;
    }
  }

  final LayerHandle<ClipRectLayer> _clipPinnedRowsHandle =
      LayerHandle<ClipRectLayer>();
  final LayerHandle<ClipRectLayer> _clipPinnedColumnsHandle =
      LayerHandle<ClipRectLayer>();
  final LayerHandle<ClipRectLayer> _clipCellsHandle =
      LayerHandle<ClipRectLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_firstNonPinnedCell == null &&
        _lastPinnedRow == null &&
        _lastPinnedColumn == null) {
      assert(_lastNonPinnedCell == null);
      return;
    }

    if (_firstNonPinnedCell != null) {
      assert(_lastNonPinnedCell != null);

      _clipCellsHandle.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromLTWH(
          axisDirectionIsReversed(horizontalAxisDirection)
              ? 0.0
              : _pinnedColumnsExtent,
          axisDirectionIsReversed(verticalAxisDirection)
              ? 0.0
              : _pinnedRowsExtent,
          viewportDimension.width - _pinnedColumnsExtent,
          viewportDimension.height - _pinnedRowsExtent,
        ),
        (PaintingContext context, Offset offset) {
          _paintCells(
            context: context,
            offset: offset,
            start: _firstNonPinnedCell!,
            end: _lastNonPinnedCell!,
          );

          paintGrid(
            canvas: context.canvas,
            offset: offset,
            start: _firstNonPinnedCell!,
            end: _lastNonPinnedCell!,
          );
        },
        clipBehavior: clipBehavior,
        oldLayer: _clipCellsHandle.layer,
      );
    } else {
      _clipCellsHandle.layer = null;
    }

    if (_lastPinnedColumn != null && _rowMetrics.firstNonPinned != null) {
      // Paint all visible pinned column cells that do not intersect with pinned
      // row cells.
      _clipPinnedColumnsHandle.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromLTWH(
          axisDirectionIsReversed(horizontalAxisDirection)
              ? viewportDimension.width - _pinnedColumnsExtent
              : 0.0,
          axisDirectionIsReversed(verticalAxisDirection)
              ? 0.0
              : _pinnedRowsExtent,
          _pinnedColumnsExtent,
          viewportDimension.height - _pinnedRowsExtent,
        ),
        (PaintingContext context, Offset offset) {
          _paintCells(
            context: context,
            offset: offset,
            start: ChildVicinity(
              xIndex: 0,
              yIndex: _rowMetrics.firstNonPinned!,
            ),
            end: ChildVicinity(
              xIndex: _lastPinnedColumn!,
              yIndex: _rowMetrics.lastNonPinned!,
            ),
          );

          paintGrid(
            canvas: context.canvas,
            offset: offset,
            start: ChildVicinity(
              xIndex: 0,
              yIndex: _rowMetrics.firstNonPinned!,
            ),
            end: ChildVicinity(
              xIndex: _lastPinnedColumn!,
              yIndex: _rowMetrics.lastNonPinned!,
            ),
          );
        },
        clipBehavior: clipBehavior,
        oldLayer: _clipPinnedColumnsHandle.layer,
      );
    } else {
      _clipPinnedColumnsHandle.layer = null;
    }

    if (_lastPinnedRow != null && _columnMetrics.firstNonPinned != null) {
      // Paint all visible pinned row cells that do not intersect with pinned
      // column cells.
      _clipPinnedRowsHandle.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromLTWH(
          axisDirectionIsReversed(horizontalAxisDirection)
              ? 0.0
              : _pinnedColumnsExtent,
          axisDirectionIsReversed(verticalAxisDirection)
              ? viewportDimension.height - _pinnedRowsExtent
              : 0.0,
          viewportDimension.width - _pinnedColumnsExtent,
          _pinnedRowsExtent,
        ),
        (PaintingContext context, Offset offset) {
          _paintCells(
            context: context,
            offset: offset,
            start: ChildVicinity(
              xIndex: _columnMetrics.firstNonPinned!,
              yIndex: 0,
            ),
            end: ChildVicinity(
              xIndex: _columnMetrics.lastNonPinned!,
              yIndex: _lastPinnedRow!,
            ),
          );

          paintGrid(
            canvas: context.canvas,
            offset: offset,
            start: ChildVicinity(
              xIndex: _columnMetrics.firstNonPinned!,
              yIndex: 0,
            ),
            end: ChildVicinity(
              xIndex: _columnMetrics.lastNonPinned!,
              yIndex: _lastPinnedRow!,
            ),
          );
        },
        clipBehavior: clipBehavior,
        oldLayer: _clipPinnedRowsHandle.layer,
      );
    } else {
      _clipPinnedRowsHandle.layer = null;
    }

    if (_lastPinnedRow != null && _lastPinnedColumn != null) {
      _paintCells(
        context: context,
        offset: offset,
        start: ChildVicinity(xIndex: 0, yIndex: 0),
        end: ChildVicinity(xIndex: _lastPinnedColumn!, yIndex: _lastPinnedRow!),
      );

      paintGrid(
        canvas: context.canvas,
        offset: offset,
        start: const ChildVicinity(xIndex: 0, yIndex: 0),
        end: ChildVicinity(xIndex: _lastPinnedColumn!, yIndex: _lastPinnedRow!),
      );
    }
  }

  void _paintCells({
    required PaintingContext context,
    required ChildVicinity start,
    required ChildVicinity end,
    required Offset offset,
  }) {
    for (int column = start.xIndex; column <= end.xIndex; column++) {
      for (int row = start.yIndex; row <= end.yIndex; row++) {
        final cell = getChildFor(
          ChildVicinity(xIndex: column, yIndex: row),
        );

        if (cell != null) {
          final data = parentDataOf(cell);
          if (data.isVisible) {
            context.paintChild(cell, offset + data.paintOffset!);
          }
        }
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? cell = firstChild;
    while (cell != null) {
      final cellParentData = parentDataOf(cell);
      if (!cellParentData.isVisible) {
        // This cell is not visible, so it cannot be hit.
        cell = childAfter(cell);
        continue;
      }
      final Rect cellRect = cellParentData.paintOffset! & cell.size;
      if (cellRect.contains(position)) {
        result.addWithPaintOffset(
          offset: cellParentData.paintOffset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(transformed == position - cellParentData.paintOffset!);
            return cell!.hitTest(result, position: transformed);
          },
        );
        return true;
      }
      cell = childAfter(cell);
    }
    return false;
  }

  @override
  void dispose() {
    _clipPinnedRowsHandle.layer = null;
    _clipPinnedColumnsHandle.layer = null;
    _clipCellsHandle.layer = null;
    _rowMetrics.clear();
    _columnMetrics.clear();
    super.dispose();
  }
}

mixin _ViewportMetrics on RenderTwoDimensionalViewport, TableViewportMetrics {
  final _rowMetrics = LayoutMetrics();
  final _columnMetrics = LayoutMetrics();

  @override
  Span? getRowSpan(int row) => _rowMetrics[row];

  @override
  Span? getColumnSpan(int column) => _columnMetrics[column];

  bool _needsMetricsRefresh = false;

  double? resolveColumnTranslation(ChildVicinity start, ChildVicinity end) {
    for (int row = start.yIndex; row <= end.yIndex; row++) {
      final cell =
          getChildFor(ChildVicinity(xIndex: start.xIndex, yIndex: row));
      if (cell == null) {
        continue;
      }

      final data = parentDataOf(cell);
      if (data.paintOffset == null) {
        continue;
      }

      return data.paintOffset!.dx -
          verticalBorderWidth -
          _columnMetrics[start.xIndex]!.leadingOffset;
    }

    return null;
  }

  double? resolveRowTranslation(ChildVicinity start, ChildVicinity end) {
    for (int column = start.xIndex; column <= end.xIndex; column++) {
      final cell =
          getChildFor(ChildVicinity(xIndex: column, yIndex: start.yIndex));
      if (cell == null) {
        continue;
      }

      final data = parentDataOf(cell);
      if (data.paintOffset == null) {
        continue;
      }

      return data.paintOffset!.dy -
          horizontalBorderWidth -
          _rowMetrics[start.yIndex]!.leadingOffset;
    }

    return null;
  }

  bool _metricsRefreshScheduled = false;

  void _scheduleMetricsRefresh() {
    if (_metricsRefreshScheduled) {
      return;
    }

    _metricsRefreshScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _metricsRefreshScheduled = false;

      if (!attached || !_needsMetricsRefresh) {
        return;
      }

      markNeedsLayout();
    });
  }

  final _builtVicinities = <ChildVicinity>{};

  (RenderBox?, bool) obtainCellForMeasurement(ChildVicinity vicinity) {
    RenderBox? cell;

    if (_builtVicinities.contains(vicinity)) {
      cell = getChildFor(vicinity);
      if (cell != null) {
        return (cell, true);
      }
    }

    cell = buildOrObtainChildFor(vicinity);
    _builtVicinities.add(vicinity);

    return (cell, false);
  }
}
