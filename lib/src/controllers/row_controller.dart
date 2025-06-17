import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';

abstract base class TableRowController {
  void addAll(List<RowData> rows);
  void add(RowData row);

  void removeAll(List<RowKey> rows);
  void remove(RowKey row);

  void pin(RowKey row);
  void unpin(RowKey row);

  void reorder(RowKey from, RowKey to);

  void setHeaderVisibility(bool alwaysShowHeader);

  bool get alwaysShowHeader;

  int toCellRow(int row) {
    return alwaysShowHeader ? row - 1 : row;
  }

  int toVicinityRow(int cellRow) {
    return alwaysShowHeader ? cellRow + 1 : cellRow;
  }

  bool isColumnHeader(int vicinityRow) {
    return alwaysShowHeader ? vicinityRow == 0 : false;
  }

  int get count;
  int get pinnedCount;

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
  int get count => dataCount + (_alwaysShowHeader ? 1 : 0);

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
    return alwaysShowHeader ? _pinnedRowCount + 1 : _pinnedRowCount;
  }

  @override
  void addAll(List<RowData> rows) {
    if (rows.isEmpty) return;

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

    for (final rowKey in rows) {
      if (_rows.containsKey(rowKey)) {
        _rows.remove(rowKey);
        _nonPinnedOrdering.remove(rowKey);
        _pinnedOrdering.remove(rowKey);
      }
    }

    notify();
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
