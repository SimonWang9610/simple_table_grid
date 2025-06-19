import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';

typedef RowDataComparator = int Function(RowData a, RowData b);

abstract base class TableRowController {
  /// Add all rows.
  /// Only new rows will be added, existing rows will be skipped
  void addAll(List<RowData> rows);

  /// Add a single row.
  /// If the row already exists, it will be skipped.
  void add(RowData row);

  /// Remove all rows with the given keys.
  /// If a row does not exist, it will be skipped.
  void removeAll(List<RowKey> rows);

  /// Remove a single row with the given key.
  void remove(RowKey row);

  /// Perform a sort on the rows by using the provided [compare] function.
  ///
  /// ALl pinned rows will be kept at the top of the list.
  ///
  /// Only non-pinned rows will be sorted.
  ///
  /// If [newRows] are provided, they will be added to the data source before sorting.
  void performSort({
    required RowDataComparator compare,
    List<RowData>? newRows,
  });

  /// Pin a row with the given key.
  void pin(RowKey row);

  /// Unpin a row with the given key.
  void unpin(RowKey row);

  /// Reorder a row from one key to another.
  ///
  /// If the index of [from] is less than the index of [to], [from] will come after [to].
  /// If the index of [from] is greater than the index of [to], [from] will come before [to].
  /// If [from] and [to] are the same, nothing will happen.
  void reorder(RowKey from, RowKey to);

  /// If always pinning the header row.
  ///
  /// if false and no other data rows are pinned, the header row will not be pinned.
  ///
  /// If there are pinned data rows, the header row will always be pinned.
  void setHeaderVisibility(bool alwaysShowHeader);

  bool get alwaysShowHeader;

  /// Convert a row index to a cell row index.
  int toDataRow(int row) {
    return row - 1;
  }

  /// Convert a cell row index to a vicinity row index.
  /// If [alwaysShowHeader] is true, the given [cellRow] will be incremented by 1 to differentiate
  /// between the header row and the data row.
  int toVicinityRow(int cellRow) {
    return cellRow + 1;
  }

  /// Check if the given [vicinityRow] is a column header.
  /// If [alwaysShowHeader] is true, the header row is always at index 0.
  /// If false, it will always return false as there is no header row.
  bool isHeaderRow(int vicinityRow) {
    return vicinityRow == 0;
  }

  /// The count of rows including the header row
  int get count;

  /// The count of pinned rows including the header row if [alwaysShowHeader] is true.
  int get pinnedCount;

  /// The count of data rows excluding the header row.
  int get dataCount;
}

final class TableDataController extends TableRowController
    with TableControllerCoordinator {
  TableDataController({
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

  @override
  int get dataCount => _rows.length;

  @override
  int get count => dataCount + 1;

  bool _alwaysShowHeader;

  @override
  bool get alwaysShowHeader => _alwaysShowHeader;

  @override
  void setHeaderVisibility(bool alwaysShowHeader) {
    if (_alwaysShowHeader == alwaysShowHeader) return;
    _alwaysShowHeader = alwaysShowHeader;
    notify();
  }

  int get _pinnedRowCount => _pinnedOrdering.length;

  @override
  int get pinnedCount {
    assert(
      _pinnedRowCount <= count,
      "Pinned rows $_pinnedRowCount must be less than or equal to row count $count",
    );

    if (_pinnedRowCount == 0) {
      return alwaysShowHeader ? 1 : 0;
    }

    return _pinnedRowCount + 1;
  }

  @override
  void addAll(List<RowData> rows) {
    if (rows.isEmpty) return;

    final shouldNotify = _addAll(rows);

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void add(RowData row) {
    addAll([row]);
  }

  @override
  void removeAll(List<RowKey> rows) {
    if (rows.isEmpty) return;

    bool shouldNotify = false;

    for (final rowKey in rows) {
      if (_rows.containsKey(rowKey)) {
        shouldNotify = true;
        _rows.remove(rowKey);

        if (_pinnedOrdering.contains(rowKey)) {
          _pinnedOrdering.remove(rowKey);
        } else {
          assert(
            _nonPinnedOrdering.contains(rowKey),
            "Row key $rowKey must be in the non-pinned ordering",
          );
          _nonPinnedOrdering.remove(rowKey);
        }
      }
    }

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void remove(RowKey row) {
    removeAll([row]);
  }

  @override
  void pin(RowKey row) {
    if (!_rows.containsKey(row) || _pinnedOrdering.contains(row)) return;

    _pinnedOrdering.add(row);
    _nonPinnedOrdering.remove(row);
    notify();
  }

  @override
  void unpin(RowKey row) {
    if (!_rows.containsKey(row) || !_pinnedOrdering.contains(row)) return;

    _pinnedOrdering.remove(row);
    _nonPinnedOrdering.insert(0, row);
    notify();
  }

  @override
  void reorder(RowKey from, RowKey to) {
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
    notify();
  }

  @override
  void performSort({
    required RowDataComparator compare,
    List<RowData>? newRows,
  }) {
    if (newRows != null) {
      _addAll(newRows);
    }

    final nonPinnedKeys = _nonPinnedOrdering.keys;

    nonPinnedKeys.sort(
      (a, b) {
        final rowA = _rows[a]!;
        final rowB = _rows[b]!;
        return compare(rowA, rowB);
      },
    );

    _nonPinnedOrdering.reset();

    for (final key in nonPinnedKeys) {
      _nonPinnedOrdering.add(key);
    }

    notify();
  }

  bool _addAll(List<RowData> rows) {
    if (rows.isEmpty) return false;

    bool shouldNotify = false;

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
      shouldNotify = true;
    }

    return shouldNotify;
  }

  @override
  void dispose() {
    super.dispose();
    _rows.clear();
    _pinnedOrdering.reset();
    _nonPinnedOrdering.reset();
  }

  RowKey? previous(RowKey key) {
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

  RowKey? next(RowKey key) {
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
    final dateIndex = toDataRow(index);

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

  int? getRowIndex(RowKey key) {
    if (!_rows.containsKey(key)) {
      return alwaysShowHeader ? 0 : null;
    }

    int? index;

    if (_pinnedOrdering.contains(key)) {
      index = _pinnedOrdering.indexOf(key);
    } else if (_nonPinnedOrdering.contains(key)) {
      index = (_nonPinnedOrdering.indexOf(key) ?? 0) + _pinnedRowCount;
    }

    assert(
      index != null,
      "Row key $key is not in the data source, cannot get index",
    );

    return index != null ? toVicinityRow(index) : null;
  }

  dynamic getCellData(RowKey rowKey, ColumnKey columnKey) {
    final rowData = _rows[rowKey];

    assert(
      rowData != null,
      "Row data for key $rowKey is null, which should not happen",
    );

    return rowData![columnKey];
  }
}
