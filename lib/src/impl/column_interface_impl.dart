import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/components/column_manager.dart';
import 'package:simple_table_grid/src/controller.dart';
import 'package:simple_table_grid/src/models/cell_detail.dart';

base mixin TableColumnImplMixin on TableController {
  @protected
  TableColumnManager get columnManager;

  @override
  void addColumn(ColumnId column, {bool pinned = false}) {
    columnManager.add(column, pinned: pinned);
  }

  @override
  void removeColumn(ColumnId id) {
    columnManager.remove(id);
  }

  @override
  void pinColumn(ColumnId id) {
    columnManager.pin(id);
  }

  @override
  void unpinColumn(ColumnId id) {
    columnManager.unpin(id);
  }

  @override
  void reorderColumn(ColumnId id, int to) {
    columnManager.reorder(id, to);
  }

  @override
  int get columnCount => columnManager.columnCount;

  @override
  int get pinnedColumnCount => columnManager.pinnedColumnCount;

  @override
  List<ColumnId> get orderedColumns => columnManager.orderedColumns;
}
