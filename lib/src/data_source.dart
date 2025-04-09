import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/coordinator.dart';

final class TableDataSource with TableCoordinatorMixin {
  TableDataSource({
    List<TableRowData> rows = const [],
    bool alwaysShowHeader = true,
  }) : _alwaysShowHeader = alwaysShowHeader {
    add(rows);
  }

  final _rows = <TableRowData>[];

  int get dataCount => _rows.length;

  int get rowCount => dataCount + (_alwaysShowHeader ? 1 : 0);

  bool _alwaysShowHeader;
  bool get alwaysShowHeader => _alwaysShowHeader;

  set alwaysShowHeader(bool value) {
    if (_alwaysShowHeader == value) return;
    _alwaysShowHeader = value;
    coordinator.notifyRebuild();
  }

  int _pinnedRowCount = 0;

  int get pinnedRowCount {
    assert(
      _pinnedRowCount <= rowCount,
      "Pinned rows $_pinnedRowCount must be less than or equal to row count $rowCount",
    );
    return alwaysShowHeader ? _pinnedRowCount + 1 : _pinnedRowCount;
  }

  void add(
    List<TableRowData> rows, {
    bool skipDuplicates = false,
  }) {
    if (rows.isEmpty) return;

    assert(
      () {
        final columns = coordinator.orderedColumns;

        for (final row in rows) {
          for (final column in columns) {
            if (!row.containsKey(column)) {
              return false;
            }
          }
        }

        return true;
      }(),
      "Some row data do not contain all columns",
    );

    bool shouldNotify = rows.isNotEmpty;

    if (!skipDuplicates) {
      _rows.addAll(rows);
    } else {
      for (final row in rows) {
        if (!_rows.contains(row)) {
          _rows.add(row);
        }
      }
    }

    if (shouldNotify) {
      coordinator.notifyRebuild();
    }
  }

  void remove(List<int> rows) {
    if (rows.isEmpty) return;

    bool shouldNotify = rows.isNotEmpty;

    final indexMapped = Map<int, dynamic>.from(_rows.asMap());
    final newIndices = <int, int>{};

    for (final row in rows) {
      if (row < pinnedRowCount) continue;

      /// the index mapped's key is cell row
      /// which is the index of the actual row data,
      /// while the given row is vicinity row
      /// which is the index of the row in the table
      final dataIndex = toCellRow(row);

      if (indexMapped.containsKey(dataIndex)) {
        indexMapped.remove(dataIndex);
        shouldNotify = true;
      }
    }

    final newValues = <TableRowData>[];
    final oldIndices = indexMapped.keys.toList();

    for (int i = 0; i < oldIndices.length; i++) {
      final oldDataIndex = oldIndices[i];
      newValues.add(indexMapped[oldDataIndex]);
      newIndices[toVicinityRow(oldDataIndex)] = toVicinityRow(i);
    }

    _rows.clear();
    _rows.addAll(newValues);

    coordinator.afterReindex(newRowIndices: newIndices);

    if (shouldNotify) {
      coordinator.notifyRebuild();
    }
  }

  void reorder(int from, int to) {
    if (from == to) return;

    _reorderWithChecker(
      from,
      to,
      (from, to) {
        final left = pinnedRowCount - 1;

        return from != to &&
            (from >= left && from < rowCount) &&
            (to >= left && to < rowCount);
      },
    );
  }

  void pin(int index) {
    assert(index >= 0 && index < _rows.length,
        'Index $index is out of bounds for rows of length ${_rows.length}');

    if (index < pinnedRowCount) return;
    _pinnedRowCount++;

    _reorderWithChecker(
      index,
      pinnedRowCount - 1,
      (from, to) => true,
    );
  }

  void unpin(int index) {
    assert(index >= 0 && index < _rows.length,
        'Index $index is out of bounds for rows of length ${_rows.length}');

    if (index >= pinnedRowCount) return;
    _pinnedRowCount--;

    _reorderWithChecker(
      index,
      pinnedRowCount - 1,
      (from, to) => true,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _rows.clear();
    _pinnedRowCount = 0;
  }

  dynamic operator [](int index) {
    assert(
      index >= 0 && index < dataCount,
      "Index $index is out of bounds for rows of length $dataCount",
    );
    return _rows[index];
  }

  bool _reorderWithChecker(
    int from,
    int to,
    bool Function(int from, int to) canReorder,
  ) {
    if (from == to) return false;

    if (!canReorder(from, to)) return false;

    final row = _rows.removeAt(from);
    _rows.insert(to, row);

    coordinator.afterReorder(
      from: from,
      to: to,
      forColumn: false,
    );

    coordinator.notifyRebuild();

    return true;
  }

  // Convert a cell row (index of the actual data list)
  // to a vicinity row (index of the table)
  int toVicinityRow(int row) {
    return alwaysShowHeader ? row + 1 : row;
  }

  // Convert a vicinity row to a cell row
  int toCellRow(int row) {
    return alwaysShowHeader ? row - 1 : row;
  }
}
