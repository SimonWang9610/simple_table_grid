import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/layout_extent_delegate.dart';

// todo: resizing logic
// todo: metric calculation
// todo: layout logic
// todo: paint logic
class RenderTableGridViewport extends RenderTwoDimensionalViewport {
  RenderTableGridViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior,
    required CellLayoutExtentDelegate layoutDelegate,
  }) : _layoutDelegate = layoutDelegate;

  CellLayoutExtentDelegate _layoutDelegate;
  CellLayoutExtentDelegate get layoutDelegate => _layoutDelegate;

  set layoutDelegate(CellLayoutExtentDelegate value) {
    if (_layoutDelegate == value) return;
    _layoutDelegate = value;
    markNeedsLayout();
  }

  @override
  void layoutChildSequence() {}

  // final Map<int, BoxConstraints> _columnMetrics = {};
  // final Map<int, BoxConstraints> _rowMetrics = {};

  final Map<int, _Span> _headerCellMetrics = {};
  final Map<int, _Span> _dataCellMetrics = {};

  void _layoutHeaderCells({
    required Offset offset,
  }) {
    // layout pinned header cells
    int i = 0;

    final vExtent = layoutDelegate.getRowExtent(0);

    double remainingHorizontalSpace = viewportDimension.width;

    while (
        i < layoutDelegate.pinnedColumnCount && remainingHorizontalSpace > 0) {
      final hExtent = layoutDelegate.getColumnExtent(i);

      final cell = buildOrObtainChildFor(
        ChildVicinity(xIndex: 0, yIndex: i),
      );

      if (cell != null) {
        final cellParentData = parentDataOf(cell);

        // cell.layout(constraints, parentUsesSize: true);

        remainingHorizontalSpace -= cell.size.width;
      }
    }

    while (i < layoutDelegate.columnCount) {
      final hExtent = layoutDelegate.getColumnExtent(i);

      final cell = buildOrObtainChildFor(
        ChildVicinity(xIndex: 0, yIndex: i),
      );

      if (cell != null) {
        final cellParentData = parentDataOf(cell);

        // cell.layout(constraints, parentUsesSize: true);

        remainingHorizontalSpace -= cell.size.width;
      }
      i++;
    }
  }

  int? _firstNonPinnedRow;
  int? _firstNonPinnedColumn;
  int? _lastNonPinnedRow;
  int? _lastNonPinnedColumn;

  int? get _lastPinnedRow => _layoutDelegate.pinnedRowCount > 0
      ? _layoutDelegate.pinnedRowCount - 1
      : null;
  int? get _lastPinnedColumn => _layoutDelegate.pinnedColumnCount > 0
      ? _layoutDelegate.pinnedColumnCount - 1
      : null;

  double _pinnedColumnExtent = 0;
  double _pinnedRowExtent = 0;

  double get _targetColumnPixels {
    return cacheExtent +
        horizontalOffset.pixels +
        viewportDimension.width -
        _pinnedColumnExtent;
  }

  double get _targetRowPixels {
    return cacheExtent +
        verticalOffset.pixels +
        viewportDimension.height -
        _pinnedRowExtent;
  }

  void _updateColumnMetrics({bool appendColumns = false, int? toColumnIndex}) {}
}

class _Span {
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
