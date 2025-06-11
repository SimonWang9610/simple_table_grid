import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/models/key.dart';

final class TableDataSource with TableCoordinatorMixin {
  TableDataSource({
    List<RowData> rows = const [],
    bool alwaysShowHeader = true,
  }) : _alwaysShowHeader = alwaysShowHeader {
    add(rows);
  }

  final _nonPinnedRows = <RowData>[];
  final _pinnedRows = <RowData>[];

  List<RowData> get orderedRows => [..._pinnedRows, ..._nonPinnedRows];

  int get dataCount => _nonPinnedRows.length + _pinnedRows.length;

  int get rowCount => dataCount + (_alwaysShowHeader ? 1 : 0);

  bool _alwaysShowHeader;

  bool get alwaysShowHeader => _alwaysShowHeader;

  set alwaysShowHeader(bool value) {
    if (_alwaysShowHeader == value) return;
    _alwaysShowHeader = value;
    coordinator.notifyRebuild();
  }

  int get _pinnedRowCount => _pinnedRows.length;

  int get pinnedRowCount {
    assert(
      _pinnedRowCount <= rowCount,
      "Pinned rows $_pinnedRowCount must be less than or equal to row count $rowCount",
    );
    return alwaysShowHeader ? _pinnedRowCount + 1 : _pinnedRowCount;
  }

  void add(List<RowData> rows) {
    if (rows.isEmpty) return;

    assert(
      () {
        final columns = coordinator.orderedColumns.toSet();

        for (final row in rows) {
          if (columns.difference(row.columns).isNotEmpty) {
            return false;
          }
        }

        return true;
      }(),
      "Some row data do not contain all columns",
    );

    bool shouldNotify = rows.isNotEmpty;

    final mapped = _nonPinnedRows.asMap().map(
          (index, row) => MapEntry(row.key, index),
        );

    for (final row in rows) {
      if (!mapped.containsKey(row.key)) {
        _nonPinnedRows.add(row);
      } else {
        _nonPinnedRows[mapped[row.key]!] = row;
      }
    }

    if (shouldNotify) {
      coordinator.notifyRebuild();
    }
  }

  // void remove(List<RowKey> rows) {
  //   if (rows.isEmpty) return;

  //   bool shouldNotify = false;

  //   final mappedNonPinned = _nonPinnedRows.asMap().map(
  //         (index, row) => MapEntry(row.key, index),
  //       );
  //   final mappedPinned = _pinnedRows.asMap().map(
  //         (index, row) => MapEntry(row.key, index),
  //       );

  //   for (final row in rows) {
  //     if (mappedNonPinned.containsKey(row)) {
  //       _nonPinnedRows.removeAt(mappedNonPinned[row]!);
  //       shouldNotify = true;
  //     } else if (mappedPinned.containsKey(row)) {
  //       _pinnedRows.removeAt(mappedPinned[row]!);
  //       shouldNotify = true;
  //     }
  //   }

  //   if (shouldNotify) {
  //     coordinator.notifyRebuild();
  //   }
  // }

  void remove(List<int> rows) {
    if (rows.isEmpty) return;

    for (final row in rows) {
      if (row < _pinnedRowCount) {
        _pinnedRows.removeAt(row);
      } else {
        _nonPinnedRows.removeAt(row - _pinnedRowCount);
      }
    }

    coordinator.notifyRebuild();
  }

  void reorder(int from, int to) {
    if (from == to) return;

    assert(
      from >= 0 && from < dataCount,
      "From index $from is out of bounds for rows of length $dataCount",
    );

    assert(
      to >= 0 && to < dataCount,
      "To index $to is out of bounds for rows of length $dataCount",
    );

    final fromPinned = from < _pinnedRowCount;
    final toPinned = to < _pinnedRowCount;

    if (fromPinned && toPinned) {
      final data = _pinnedRows.removeAt(from);
      _pinnedRows.insert(to, data);
    } else if (!fromPinned && !toPinned) {
      final data = _nonPinnedRows.removeAt(from - _pinnedRowCount);
      _nonPinnedRows.insert(to - _pinnedRowCount, data);
    } else if (fromPinned && !toPinned) {
      final data = _pinnedRows.removeAt(from);
      _nonPinnedRows.insert(to - _pinnedRowCount, data);
    } else if (!fromPinned && toPinned) {
      final data = _nonPinnedRows.removeAt(from - _pinnedRowCount);
      _pinnedRows.insert(to, data);
    }

    coordinator.notifyRebuild();
  }

  void pin(int index) {
    if (index < _pinnedRowCount) return;

    final data = _nonPinnedRows.removeAt(index - _pinnedRowCount);

    _pinnedRows.add(data);
    coordinator.notifyRebuild();
  }

  void unpin(int index) {
    if (index >= _pinnedRowCount) return;

    final data = _pinnedRows.removeAt(index);

    _nonPinnedRows.insert(0, data);
    coordinator.notifyRebuild();
  }

  @override
  void dispose() {
    super.dispose();
    _nonPinnedRows.clear();
    _pinnedRows.clear();
  }

  RowData getRowData(int index) {
    assert(
      index >= 0 && index < dataCount,
      "Data index $index is out of bounds for rows of length $dataCount",
    );

    if (index < _pinnedRowCount) {
      return _pinnedRows[index];
    } else {
      return _nonPinnedRows[index - _pinnedRowCount];
    }
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
