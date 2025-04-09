import 'dart:collection';

import 'package:simple_table_grid/src/components/coordinator.dart';
import 'package:simple_table_grid/src/models/cell_detail.dart';

final class TableColumnManager with TableCoordinatorMixin {
  TableColumnManager();

  final LinkedHashSet<ColumnId> _columns = LinkedHashSet<ColumnId>();

  List<ColumnId> get orderedColumns => _columns.toList();

  int get columnCount => _columns.length;

  int _pinnedColumnCount = 0;

  int get pinnedColumnCount {
    assert(
      _pinnedColumnCount <= columnCount,
      "Pinned columns $_pinnedColumnCount must be less than or equal to column count $columnCount",
    );
    return _pinnedColumnCount;
  }

  void reorder(ColumnId id, int to) {
    _reorderWithChecker(
      id,
      to,
      (from, to) {
        final left = _pinnedColumnCount - 1;

        // ensure only non-pinned columns [left, columnCount) can be reordered
        return from != to &&
            (from >= left && from < columnCount) &&
            (to >= left && to < columnCount);
      },
    );
  }

  void remove(ColumnId id) {
    if (!_columns.contains(id)) return;

    int? index;

    final newIndices = <int, int>{};

    for (int i = 0; i < _columns.length; i++) {
      if (_columns.elementAt(i) == id) {
        index = i;
      }

      if (index == null) {
        newIndices[i] = i;
      } else if (i > index) {
        newIndices[i] = i - 1;
      }
    }

    _columns.remove(id);

    assert(
      index != null,
      "Column $id not found in columns $_columns",
    );

    if (index! < _pinnedColumnCount) {
      _pinnedColumnCount--;
    }

    coordinator.adaptRemoval(newColumnIndices: newIndices);

    coordinator.notifyRebuild();
  }

  void add(ColumnId id, {bool pinned = false}) {
    if (pinned) {
      _columns.add(id);
      pin(id);
    } else {
      if (!_columns.contains(id)) {
        _columns.add(id);
        coordinator.notifyRebuild();
      }
    }
  }

  void pin(ColumnId id) {
    final index = orderedColumns.indexWhere((c) => c == id);
    if (index == -1 || index < _pinnedColumnCount) return;

    _pinnedColumnCount++;

    _reorderWithChecker(
      id,
      _pinnedColumnCount - 1,
      (from, to) => true,
    );
  }

  void unpin(ColumnId id) {
    final index = orderedColumns.indexWhere((c) => c == id);
    if (index == -1 || index >= _pinnedColumnCount) return;

    _pinnedColumnCount--;

    _reorderWithChecker(
      id,
      _pinnedColumnCount,
      (from, to) => true,
    );
  }

  void setColumns(List<ColumnId> columns) {
    _columns.clear();
    _columns.addAll(columns);

    coordinator.notifyRebuild();
  }

  bool _reorderWithChecker(
    ColumnId id,
    int to,
    bool Function(int, int) canReorder,
  ) {
    assert(
      to >= 0 && to < columnCount,
      "Invalid index $to, must be between 0 and $columnCount",
    );

    final oldOrderedColumns = orderedColumns;

    final from = oldOrderedColumns.indexWhere((c) => c == id);

    if (from == -1) return false;

    if (!canReorder(from, to)) return false;

    oldOrderedColumns.removeAt(from);
    oldOrderedColumns.insert(to, id);

    coordinator.adaptReordering(from: from, to: to, forColumn: true);
    setColumns(oldOrderedColumns);

    return true;
  }

  @override
  void dispose() {
    super.dispose();
    _columns.clear();
    _pinnedColumnCount = 0;
  }
}
