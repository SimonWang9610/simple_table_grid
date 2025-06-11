import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/components/column_manager.dart';
import 'package:simple_table_grid/src/controller.dart';
import 'package:simple_table_grid/src/models/key.dart';

base mixin TableColumnImplMixin on TableController {
  @protected
  TableColumnManager get columnManager;

  @override
  void addColumn(ColumnKey column, {bool pinned = false}) {
    columnManager.add(column, pinned: pinned);
  }

  @override
  void removeColumn(ColumnKey id) {
    columnManager.remove(id);
  }

  @override
  void pinColumn(ColumnKey id) {
    columnManager.pin(id);
  }

  @override
  void unpinColumn(ColumnKey id) {
    columnManager.unpin(id);
  }

  @override
  void reorderColumn(ColumnKey id, int to) {
    columnManager.reorder(id, to);
  }

  @override
  int get columnCount => columnManager.columnCount;

  @override
  int get pinnedColumnCount => columnManager.pinnedColumnCount;

  @override
  List<ColumnKey> get orderedColumns => columnManager.orderedColumns;
}
