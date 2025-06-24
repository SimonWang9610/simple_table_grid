import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/delegate.dart';

class RenderTableGridViewport extends RenderTwoDimensionalViewport {
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
  });

  @override
  CellLayoutExtentDelegate get delegate =>
      super.delegate as CellLayoutExtentDelegate;

  @override
  void layoutChildSequence() {
    if (needsDelegateRebuild || didResize) {
      _columnMetrics.clear();
      _rowMetrics.clear();
      _updateColumnMetrics();
      _updateRowMetrics();
      _updateScrollBounds();
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

        final cell = buildOrObtainChildFor(
          ChildVicinity(xIndex: column, yIndex: row),
        );

        if (cell != null) {
          final data = parentDataOf(cell);

          final constraints = BoxConstraints.tightFor(
            width: columnSpan.extent,
            height: rowSpan.extent,
          );

          cell.layout(constraints);
          data.layoutOffset = Offset(
            columnOffset,
            rowOffset,
          );
        }

        columnOffset += columnSpan.extent;
      }
      rowOffset += rowSpan.extent;
    }
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

  final _columnMetrics = _Metrics();
  final _rowMetrics = _Metrics();

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
        },
        clipBehavior: clipBehavior,
        oldLayer: _clipPinnedRowsHandle.layer,
      );
    } else {
      _clipPinnedRowsHandle.layer = null;
    }

    if (_lastPinnedRow != null && _lastPinnedColumn != null) {
      // Paint remaining visible pinned cells that represent the intersection of
      // both pinned rows and columns.
      _paintCells(
        context: context,
        offset: offset,
        start: ChildVicinity(xIndex: 0, yIndex: 0),
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
