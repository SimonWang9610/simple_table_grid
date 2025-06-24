import 'package:flutter/widgets.dart';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/models/extent.dart';

typedef CellExtentBuilder = Extent Function(int index);
typedef CellWidgetBuilder = Widget Function(
  BuildContext context,
  ChildVicinity vicinity,
);

mixin CellLayoutExtentDelegate on TwoDimensionalChildDelegate {
  int get rowCount;
  int get columnCount;
  int get pinnedRowCount;
  int get pinnedColumnCount;

  Extent getColumnExtent(int index);
  Extent getRowExtent(int index);
}

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

class TableGridSizedBuilderDelegate extends TwoDimensionalChildBuilderDelegate
    with CellLayoutExtentDelegate {
  int _pinnedColumnCount;
  int _pinnedRowCount;
  TableSizer _sizer;

  TableGridSizedBuilderDelegate({
    required int columnCount,
    required int rowCount,
    int pinnedColumnCount = 0,
    int pinnedRowCount = 0,
    required TableSizer sizer,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries = false,
    required super.builder,
  })  : assert(pinnedColumnCount >= 0),
        assert(pinnedRowCount >= 0),
        assert(rowCount >= 0),
        assert(columnCount >= 0),
        assert(pinnedColumnCount <= columnCount),
        assert(pinnedRowCount <= rowCount),
        _pinnedColumnCount = pinnedColumnCount,
        _pinnedRowCount = pinnedRowCount,
        _sizer = sizer,
        super(
          maxXIndex: columnCount - 1,
          maxYIndex: rowCount - 1,
        );

  @override
  int get columnCount => maxXIndex! + 1;

  @override
  int get pinnedColumnCount => _pinnedColumnCount;

  set columnCount(int value) {
    update(columnCount: value);
  }

  set pinnedColumnCount(int value) {
    update(pinnedColumnCount: value);
  }

  @override
  Extent getColumnExtent(int index) {
    assert(index >= 0);
    assert(index < columnCount);

    return _sizer.getColumnExtent(index);
  }

  @override
  int get rowCount => maxYIndex! + 1;

  @override
  int get pinnedRowCount => _pinnedRowCount;

  set rowCount(int value) {
    update(rowCount: value);
  }

  set pinnedRowCount(int value) {
    update(pinnedRowCount: value);
  }

  @override
  Extent getRowExtent(int index) {
    assert(index >= 0);
    assert(index < rowCount);

    return _sizer.getRowExtent(index);
  }

  set sizer(TableSizer value) {
    update(sizer: value);
  }

  void update({
    int? columnCount,
    int? rowCount,
    int? pinnedColumnCount,
    int? pinnedRowCount,
    TableSizer? sizer,
    bool alwaysNotify = false,
  }) {
    assert(
      columnCount == null || columnCount >= 0,
      "Column count must be non-negative",
    );

    assert(
      rowCount == null || rowCount >= 0,
      "Row count must be non-negative",
    );

    assert(
      pinnedColumnCount == null || pinnedColumnCount >= 0,
      "Pinned column count must be non-negative",
    );

    assert(
      pinnedRowCount == null || pinnedRowCount >= 0,
      "Pinned row count must be non-negative",
    );

    bool shouldNotify = alwaysNotify;

    if (columnCount != null && columnCount != this.columnCount) {
      assert(columnCount >= (pinnedColumnCount ?? _pinnedColumnCount));
      maxXIndex = columnCount - 1;
      shouldNotify = true;
    }

    if (pinnedColumnCount != null && pinnedColumnCount != _pinnedColumnCount) {
      assert(pinnedColumnCount <= this.columnCount);
      _pinnedColumnCount = pinnedColumnCount;
      shouldNotify = true;
    }

    if (rowCount != null && rowCount != this.rowCount) {
      assert(rowCount >= (pinnedRowCount ?? _pinnedRowCount));
      maxYIndex = rowCount - 1;
      shouldNotify = true;
    }

    if (pinnedRowCount != null && pinnedRowCount != _pinnedRowCount) {
      assert(pinnedRowCount <= this.rowCount);
      _pinnedRowCount = pinnedRowCount;
      shouldNotify = true;
    }

    if (sizer != null && sizer != _sizer) {
      _sizer = sizer;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }
}
