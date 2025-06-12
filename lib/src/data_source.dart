import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';

final class TableDataSource with TableCoordinatorMixin {
  TableDataSource({
    List<RowData> rows = const [],
    bool alwaysShowHeader = true,
  }) : _alwaysShowHeader = alwaysShowHeader {
    for (final row in rows) {
      _rows[row.key] = row;
      _nonPinnedOrdering.add(row.key);
    }
  }

  final _rows = <RowKey, RowData>{};
  final _pinnedOrdering = KeyOrdering.efficient(<RowKey>[]);
  final _nonPinnedOrdering = KeyOrdering.quick(<RowKey>[]);

  List<RowData> get orderedRows {
    final ordered = <RowData>[];

    for (final key in _pinnedOrdering.keys) {
      ordered.add(_rows[key]!);
    }

    for (final key in _nonPinnedOrdering.keys) {
      ordered.add(_rows[key]!);
    }

    return ordered;
  }

  int get dataCount => _rows.length;

  int get rowCount => dataCount + (_alwaysShowHeader ? 1 : 0);

  bool _alwaysShowHeader;

  bool get alwaysShowHeader => _alwaysShowHeader;

  set alwaysShowHeader(bool value) {
    if (_alwaysShowHeader == value) return;
    _alwaysShowHeader = value;
    coordinator.notifyRebuild();
  }

  int get _pinnedRowCount => _pinnedOrdering.length;

  int get pinnedRowCount {
    assert(
      _pinnedRowCount <= rowCount,
      "Pinned rows $_pinnedRowCount must be less than or equal to row count $rowCount",
    );
    return alwaysShowHeader ? _pinnedRowCount + 1 : _pinnedRowCount;
  }

  void add(List<RowData> rows) {
    if (rows.isEmpty) return;

    for (final row in rows) {
      if (_rows.containsKey(row.key)) {
        // If the row already exists, skip it
        continue;
      }

      assert(
          !_pinnedOrdering.contains(row.key) &&
              !_nonPinnedOrdering.contains(row.key),
          "Row key ${row.key} must not be in either ordering");

      _rows[row.key] = row;
      _nonPinnedOrdering.add(row.key);
    }

    coordinator.notifyRebuild();
  }

  void removeByKeys(List<RowKey> rows) {
    if (rows.isEmpty) return;

    for (final rowKey in rows) {
      if (_rows.containsKey(rowKey)) {
        _rows.remove(rowKey);
        _nonPinnedOrdering.remove(rowKey);
        _pinnedOrdering.remove(rowKey);
      }
    }

    coordinator.notifyRebuild();
  }

  void remove(List<int> rows) {
    if (rows.isEmpty) return;

    final keys = <RowKey>[];

    for (final row in rows) {
      final RowKey? key;

      final dataIndex = toCellRow(row);

      if (dataIndex >= _pinnedRowCount) {
        key = _nonPinnedOrdering[dataIndex - _pinnedRowCount];
      } else {
        key = _pinnedOrdering[dataIndex];
      }

      if (key != null) {
        assert(
          _rows.containsKey(key),
          "Key $key is not in the data source",
        );
        keys.add(key);
      }
    }

    removeByKeys(keys);
  }

  void reorder(int from, int to) {
    if (from == to) return;

    final fromKey = from >= _pinnedRowCount
        ? _nonPinnedOrdering[from - _pinnedRowCount]
        : _pinnedOrdering[from];

    final toKey = to >= _pinnedRowCount
        ? _nonPinnedOrdering[to - _pinnedRowCount]
        : _pinnedOrdering[to];

    if (fromKey == null || toKey == null) {
      throw ArgumentError("Invalid row indices: from $from, to $to");
    }

    reorderByKey(fromKey, toKey);
  }

  void reorderByKey(RowKey from, RowKey to) {
    assert(
      _rows.containsKey(from),
      "From key $from is not in the data source",
    );
    assert(
      _rows.containsKey(to),
      "To key $to is not in the data source",
    );

    final fromPinned = _pinnedOrdering.contains(from);

    assert(
      fromPinned || _nonPinnedOrdering.contains(from),
      "From key $from is not in the pinned or non-pinned ordering",
    );

    final toPinned = _pinnedOrdering.contains(to);

    assert(
      toPinned || _nonPinnedOrdering.contains(to),
      "To key $to is not in the pinned or non-pinned ordering",
    );

    if (fromPinned && toPinned) {
      _pinnedOrdering.reorder(from, to);
    } else if (!fromPinned && !toPinned) {
      _nonPinnedOrdering.reorder(from, to);
    } else if (fromPinned && !toPinned) {
      _pinnedOrdering.remove(from);
      _nonPinnedOrdering.add(from);
      _nonPinnedOrdering.reorder(from, to);
    } else if (!fromPinned && toPinned) {
      _nonPinnedOrdering.remove(from);
      _pinnedOrdering.add(from);
      _pinnedOrdering.reorder(from, to);
    }

    coordinator.notifyRebuild();
  }

  void pin(int index) {
    if (index < _pinnedRowCount) return;

    final key = index >= _pinnedRowCount
        ? _nonPinnedOrdering[index - _pinnedRowCount]
        : _pinnedOrdering[index];

    if (key != null) {
      pinByKey(key);
    }
  }

  void pinByKey(RowKey key) {
    if (!_rows.containsKey(key) || _pinnedOrdering.contains(key)) return;

    _pinnedOrdering.add(key);
    _nonPinnedOrdering.remove(key);

    coordinator.notifyRebuild();
  }

  void unpin(int index) {
    if (index >= _pinnedRowCount) return;

    final key = index >= _pinnedRowCount
        ? _nonPinnedOrdering[index - _pinnedRowCount]
        : _pinnedOrdering[index];

    if (key != null) {
      unpinByKey(key);
    }
  }

  void unpinByKey(RowKey key) {
    if (!_rows.containsKey(key) || !_pinnedOrdering.contains(key)) return;

    _pinnedOrdering.remove(key);
    _nonPinnedOrdering.insert(0, key);

    coordinator.notifyRebuild();
  }

  @override
  void dispose() {
    super.dispose();
    _nonPinnedOrdering.reset();
    _pinnedOrdering.reset();
  }

  RowKey? previousRow(RowKey key) {
    assert(
      _rows.containsKey(key),
      "Row key $key is not in the data source",
    );

    final pinnedIndex = _pinnedOrdering.indexOf(key);

    if (pinnedIndex != null) {
      return _pinnedOrdering.firstKey != key
          ? _pinnedOrdering[pinnedIndex - 1]
          : null;
    }

    final nonPinnedIndex = _nonPinnedOrdering.indexOf(key);
    if (nonPinnedIndex != null) {
      if (_nonPinnedOrdering.firstKey == key) {
        return _pinnedOrdering.lastKey;
      } else {
        return _nonPinnedOrdering[nonPinnedIndex - 1];
      }
    }

    return null; // Key not found in either ordering
  }

  RowKey? nextRow(RowKey key) {
    assert(
      _rows.containsKey(key),
      "Row key $key is not in the data source",
    );

    final pinnedIndex = _pinnedOrdering.indexOf(key);

    if (pinnedIndex != null) {
      return _pinnedOrdering.lastKey != key
          ? _pinnedOrdering[pinnedIndex + 1]
          : _nonPinnedOrdering.firstKey;
    }

    final nonPinnedIndex = _nonPinnedOrdering.indexOf(key);

    if (nonPinnedIndex != null) {
      if (_nonPinnedOrdering.lastKey != key) {
        return _nonPinnedOrdering[nonPinnedIndex + 1];
      } else {
        return null;
      }
    }

    return null; // Key not found in either ordering
  }

  RowKey getRowKey(int index) {
    final dateIndex = toCellRow(index);

    assert(
      dateIndex >= 0 && dateIndex < dataCount,
      "Data index $dateIndex is out of bounds for rows of length $dataCount",
    );

    final key = dateIndex >= _pinnedRowCount
        ? _nonPinnedOrdering[dateIndex - _pinnedRowCount]
        : _pinnedOrdering[dateIndex];

    assert(
      key != null && _rows.containsKey(key),
      "Row key at index $index is null, which should not happen",
    );

    return key!;
  }

  dynamic getCellData(RowKey rowKey, ColumnKey columnKey) {
    final rowData = _rows[rowKey];

    assert(
      rowData != null,
      "Row data for key $rowKey is null, which should not happen",
    );

    return rowData![columnKey];
  }

  /// Convert a vicinity row to a cell row.
  /// when [alwaysShowHeader] is true, the table column headers are the first row logically during rendering.
  /// This method adjusts the row index to account for the header row.
  int toCellRow(int row) {
    return alwaysShowHeader ? row - 1 : row;
  }

  int toVicinityRow(int cellRow) {
    return alwaysShowHeader ? cellRow + 1 : cellRow;
  }

  bool isColumnHeader(int vicinityRow) {
    return alwaysShowHeader ? vicinityRow == 0 : false;
  }
}
