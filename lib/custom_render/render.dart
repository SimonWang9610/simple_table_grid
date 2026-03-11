import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/delegate.dart';

class RenderTableGridViewport extends RenderTwoDimensionalViewport
    with _ViewportMetrics, _DynamicRowMeasurement, _GridBorderPainter {
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

  @override
  BorderSide _verticalBorderSide;

  BorderSide get verticalBorderSide => _verticalBorderSide;
  set verticalBorderSide(BorderSide value) {
    if (_verticalBorderSide == value) {
      return;
    }

    _verticalBorderSide = value;
    markNeedsLayout();
    markNeedsPaint();
  }

  @override
  BorderSide _horizontalBorderSide;
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
    _laidOutVicinities.clear();

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

    _measureDynamicRows();
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

        /// Remember the laid out vicinity so that we can skip building this cell
        /// during the measurement phase if this row is dynamic.
        _laidOutVicinities.add(vicinity);

        final cell = buildOrObtainChildFor(vicinity);

        if (cell != null) {
          final data = parentDataOf(cell);

          final cellWidth =
              math.max(0.0, columnSpan.extent - _verticalBorderWidth);
          final cellHeight =
              math.max(0.0, rowSpan.extent - _horizontalBorderWidth);

          final constraints = BoxConstraints.tightFor(
            width: cellWidth,
            height: cellHeight,
          );

          cell.layout(constraints);
          data.layoutOffset = Offset(
            columnOffset + _verticalBorderWidth,
            rowOffset + _horizontalBorderWidth,
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

    _Span updateSpan(int column, bool isPinned, double leadingOffset) {
      final span = _columnMetrics.remove(column) ?? _Span();
      final hExtent = delegate.getColumnExtent(column);

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

    _Span updateSpan(int row, bool isPinned, double leadingOffset) {
      final span = _rowMetrics.remove(row) ?? _Span();
      final vExtent = delegate.getRowExtent(row);

      /// If the row extent is dynamic, we need to measure the cells in that row to determine the actual extent.
      /// We will schedule a post-frame callback to do that after the layout is complete,
      /// as we cannot [markNeedsLayout] during performLayout.
      if (vExtent.isDynamic) {
        _dynamicRows.add(row);
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

          _paintGrid(
            context: context,
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

          _paintGrid(
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

          _paintGrid(
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

      _paintGrid(
        context: context,
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

class _Span with Diagnosticable {
  late double _leadingOffset;
  late double _extent;
  late bool _isPinned;

  double get leadingOffset => _leadingOffset;
  double get extent => _extent;

  double get trailingOffset => _leadingOffset + _extent;

  bool get isPinned => _isPinned;

  void update({
    required double leadingOffset,
    required double extent,
    required bool isPinned,
  }) {
    _leadingOffset = leadingOffset;
    _extent = extent;
    _isPinned = isPinned;
  }
}

class _Metrics {
  final Map<int, _Span> _metrics = {};

  int? _firstNonPinned;
  int? _lastNonPinned;

  _Span? remove(int index) {
    return _metrics.remove(index);
  }

  void set(int index, _Span span) {
    _metrics[index] = span;
  }

  void resetRange() {
    _firstNonPinned = null;
    _lastNonPinned = null;
  }

  void clear() {
    _metrics.clear();
    resetRange();
  }

  _Span? operator [](int index) {
    return _metrics[index];
  }

  int get length => _metrics.length;

  bool get isEmpty => _metrics.isEmpty;

  int? get firstNonPinned => _firstNonPinned;
  set firstNonPinned(int? value) {
    if (_firstNonPinned != null || value == null) {
      return;
    }

    _firstNonPinned = value;
  }

  int? get lastNonPinned => _lastNonPinned;
  set lastNonPinned(int? value) {
    if (_firstNonPinned == null || _lastNonPinned != null || value == null) {
      return;
    }

    assert(
      value >= _firstNonPinned!,
      "the last value must be greater than the first",
    );

    _lastNonPinned = value;
  }

  bool get isRangeEmpty => _firstNonPinned == null && _lastNonPinned == null;

  double? getNonPinnedOffset(double viewportOffset, double pinnedExtent) {
    if (_firstNonPinned == null) return null;

    return viewportOffset -
        _metrics[_firstNonPinned!]!.leadingOffset -
        pinnedExtent;
  }
}

mixin _ViewportMetrics on RenderTwoDimensionalViewport {
  final _rowMetrics = _Metrics();
  final _columnMetrics = _Metrics();

  BorderSide get _verticalBorderSide;
  BorderSide get _horizontalBorderSide;

  double get _verticalBorderWidth =>
      _verticalBorderSide.style == BorderStyle.none
          ? 0.0
          : _verticalBorderSide.width;

  double get _horizontalBorderWidth =>
      _horizontalBorderSide.style == BorderStyle.none
          ? 0.0
          : _horizontalBorderSide.width;

  @override
  CellLayoutExtentDelegate get delegate =>
      super.delegate as CellLayoutExtentDelegate;

  bool _needsMetricsRefresh = false;
}

mixin _DynamicRowMeasurement on RenderTwoDimensionalViewport, _ViewportMetrics {
  final _dynamicRows = <int>{};
  final _laidOutVicinities = <ChildVicinity>{};

  /// Measures the dynamic rows by laying out all cells in those rows to determine the max cell height,
  /// it is quite expensively, as it will force to schedule a new layout pass after the measurement is done,
  /// but it is necessary to support dynamic row height.
  void _measureDynamicRows() {
    if (_dynamicRows.isEmpty) return;

    bool hasRowMeasured = false;

    for (final row in _dynamicRows) {
      if (row < 0 || row >= delegate.rowCount) {
        continue;
      }

      double maxCellHeight = 0;

      /// we need to layout all cells in this row to determine the max cell height,
      /// which will be used as the row extent for dynamic row.
      for (int column = 0; column < delegate.columnCount; column++) {
        final columnSpan = _columnMetrics[column];

        if (columnSpan == null) {
          continue;
        }

        final vicinity = ChildVicinity(xIndex: column, yIndex: row);

        final RenderBox? cell;

        final bool needSetupParentData;

        if (_laidOutVicinities.contains(vicinity)) {
          cell = getChildFor(vicinity);
          needSetupParentData = false;
        } else {
          cell = buildOrObtainChildFor(vicinity);
          _laidOutVicinities.add(vicinity);
          needSetupParentData = true;
        }

        if (cell == null) {
          continue;
        }

        hasRowMeasured = true;

        final cellWidth =
            math.max(0.0, columnSpan.extent - _verticalBorderWidth);

        cell.layout(
          BoxConstraints(
            minWidth: cellWidth,
            maxWidth: cellWidth,
            minHeight: 0,
            maxHeight: double.infinity,
          ),
          parentUsesSize: true,
        );

        if (needSetupParentData) {
          /// It may have UI flicker if we set the layout offset for cells during the measurement phase,
          /// but it is necessary to ensure the correct layout of cells in dynamic rows,
          final data = parentDataOf(cell);
          final columnLeading = _columnMetrics[column]?.leadingOffset ?? 0;
          final rowLeading = _rowMetrics[row]?.leadingOffset ?? 0;
          data.layoutOffset = Offset(
            columnLeading + _verticalBorderWidth,
            rowLeading + _horizontalBorderWidth,
          );
        }

        maxCellHeight = math.max(maxCellHeight, cell.size.height);
      }

      final oldExtent = delegate.getRowExtent(row);
      final newExtent =
          oldExtent.accept(maxCellHeight + _horizontalBorderWidth);

      /// This is one-shot measurement and update,
      if (oldExtent != newExtent) {
        delegate.updateMeasuredRowExtent(row, newExtent);
      }
    }

    _dynamicRows.clear();

    /// If at least one row is measured, we need to schedule a new layout pass
    /// to update the row metrics and layout the cells with the correct row extent.
    if (hasRowMeasured) {
      _needsMetricsRefresh = true;
      _scheduleMetricsRefresh();
    }
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
}

mixin _GridBorderPainter on RenderTwoDimensionalViewport, _ViewportMetrics {
  /// Paints the grid lines for the given grid region defined by the [start] and [end] vicinities, with the given offset.
  ///
  /// Instead of drawing each grid line separately, we batch the lines into a single draw call
  /// for vertical and horizontal lines respectively, to improve the performance when there are many lines to draw.
  ///
  /// If the border width is zero, the corresponding grid lines will not be painted.
  void _paintGrid({
    required PaintingContext context,
    required ChildVicinity start,
    required ChildVicinity end,
    required Offset offset,
  }) {
    if (_verticalBorderWidth <= 0 && _horizontalBorderWidth <= 0) {
      return;
    }

    final columnTranslation = _resolveColumnTranslation(start, end);
    final rowTranslation = _resolveRowTranslation(start, end);

    if (columnTranslation == null || rowTranslation == null) {
      return;
    }

    final startX =
        _columnMetrics[start.xIndex]!.leadingOffset + columnTranslation;
    final endX = _columnMetrics[end.xIndex]!.trailingOffset + columnTranslation;
    final startY = _rowMetrics[start.yIndex]!.leadingOffset + rowTranslation;
    final endY = _rowMetrics[end.yIndex]!.trailingOffset + rowTranslation;
    final clipBounds = context.canvas.getLocalClipBounds();
    final clippedEndX = math.min(endX, clipBounds.right - offset.dx);
    final clippedEndY = math.min(endY, clipBounds.bottom - offset.dy);

    if (_verticalBorderWidth > 0) {
      final verticalPaint = Paint()
        ..color = _verticalBorderSide.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _verticalBorderWidth;

      /// line count = column count + 2 (including the leading and trailing border lines)
      final verticalSegmentCount = end.xIndex - start.xIndex + 2;
      final verticalPoints = Float32List(verticalSegmentCount * 4);
      int pointIndex = 0;
      final yStart = offset.dy + startY;
      final yEnd = offset.dy + clippedEndY;

      for (int column = start.xIndex; column <= end.xIndex; column++) {
        final x = _columnMetrics[column]!.leadingOffset +
            columnTranslation +
            _verticalBorderWidth / 2;
        final xOffset = offset.dx + x;

        verticalPoints[pointIndex++] = xOffset;
        verticalPoints[pointIndex++] = yStart;
        verticalPoints[pointIndex++] = xOffset;
        verticalPoints[pointIndex++] = yEnd;
      }

      final trailingX = math.max(
        startX + _verticalBorderWidth / 2,
        clippedEndX - _verticalBorderWidth / 2,
      );

      verticalPoints[pointIndex++] = offset.dx + trailingX;
      verticalPoints[pointIndex++] = yStart;
      verticalPoints[pointIndex++] = offset.dx + trailingX;
      verticalPoints[pointIndex++] = yEnd;

      context.canvas.drawRawPoints(
        PointMode.lines,
        verticalPoints,
        verticalPaint,
      );
    }

    if (_horizontalBorderWidth > 0) {
      final horizontalPaint = Paint()
        ..color = _horizontalBorderSide.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _horizontalBorderWidth;

      /// line count = row count + 2 (including the leading and trailing border lines)
      final horizontalSegmentCount = end.yIndex - start.yIndex + 2;
      final horizontalPoints = Float32List(horizontalSegmentCount * 4);
      int pointIndex = 0;
      final xStart = offset.dx + startX;
      final xEnd = offset.dx + clippedEndX;

      for (int row = start.yIndex; row <= end.yIndex; row++) {
        final y = _rowMetrics[row]!.leadingOffset +
            rowTranslation +
            _horizontalBorderWidth / 2;
        final yOffset = offset.dy + y;

        horizontalPoints[pointIndex++] = xStart;
        horizontalPoints[pointIndex++] = yOffset;
        horizontalPoints[pointIndex++] = xEnd;
        horizontalPoints[pointIndex++] = yOffset;
      }

      final trailingY = math.max(
        startY + _horizontalBorderWidth / 2,
        clippedEndY - _horizontalBorderWidth / 2,
      );

      horizontalPoints[pointIndex++] = xStart;
      horizontalPoints[pointIndex++] = offset.dy + trailingY;
      horizontalPoints[pointIndex++] = xEnd;
      horizontalPoints[pointIndex++] = offset.dy + trailingY;

      context.canvas.drawRawPoints(
        PointMode.lines,
        horizontalPoints,
        horizontalPaint,
      );
    }
  }

  double? _resolveColumnTranslation(ChildVicinity start, ChildVicinity end) {
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
          _verticalBorderWidth -
          _columnMetrics[start.xIndex]!.leadingOffset;
    }

    return null;
  }

  double? _resolveRowTranslation(ChildVicinity start, ChildVicinity end) {
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
          _horizontalBorderWidth -
          _rowMetrics[start.yIndex]!.leadingOffset;
    }

    return null;
  }
}
