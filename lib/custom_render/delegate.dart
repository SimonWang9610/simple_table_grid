import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/layout_extent_delegate.dart';

typedef CellExtentBuilder = Extent Function(int index);
typedef CellWidgetBuilder = Widget Function(
  BuildContext context,
  ChildVicinity vicinity,
);

class TableGridCellBuilderDelegate extends TwoDimensionalChildBuilderDelegate
    with CellLayoutExtentDelegate {
  final CellExtentBuilder rowExtentBuilder;
  final CellExtentBuilder columnExtentBuilder;

  int _pinnedColumnCount = 0;
  int _pinnedRowCount = 0;

  TableGridCellBuilderDelegate({
    required int columnCount,
    required int rowCount,
    int pinnedColumnCount = 0,
    int pinnedRowCount = 0,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries = false,
    required super.builder,
    required this.rowExtentBuilder,
    required this.columnExtentBuilder,
  })  : assert(pinnedColumnCount >= 0),
        assert(pinnedRowCount >= 0),
        assert(rowCount >= 0),
        assert(columnCount >= 0),
        assert(pinnedColumnCount <= columnCount),
        assert(pinnedRowCount <= rowCount),
        _pinnedColumnCount = pinnedColumnCount,
        _pinnedRowCount = pinnedRowCount,
        super(
          maxXIndex: columnCount - 1,
          maxYIndex: rowCount - 1,
        );

  @override
  int get columnCount => maxXIndex! + 1;

  @override
  int get pinnedColumnCount => _pinnedColumnCount;

  set columnCount(int value) {
    assert(value >= 0);
    assert(value >= pinnedColumnCount);
    maxXIndex = value - 1;
  }

  set pinnedColumnCount(int value) {
    if (value == _pinnedColumnCount) return;

    assert(value >= 0);
    assert(value <= columnCount);
    _pinnedColumnCount = value;
    print("pinnedColumnCount: $_pinnedColumnCount");
    notifyListeners();
  }

  @override
  Extent getColumnExtent(int index) {
    assert(index >= 0);
    assert(index < columnCount);

    return columnExtentBuilder(index);
  }

  @override
  int get rowCount => maxYIndex! + 1;

  @override
  int get pinnedRowCount => _pinnedRowCount;

  set rowCount(int value) {
    assert(value >= 0);
    assert(value >= pinnedRowCount);
    maxYIndex = value - 1;
  }

  set pinnedRowCount(int value) {
    if (value == _pinnedRowCount) return;

    assert(value >= 0);
    assert(value <= rowCount);
    _pinnedRowCount = value;
    notifyListeners();
  }

  @override
  Extent getRowExtent(int index) {
    assert(index >= 0);
    assert(index < rowCount);

    return rowExtentBuilder(index);
  }
}
