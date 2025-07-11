import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';

class SearchSnapshot {
  late final KeyOrdering<RowKey> _pinnedOrdering;
  late final KeyOrdering<RowKey> _nonPinnedOrdering;

  SearchSnapshot(
    List<RowKey> pinnedRows,
    List<RowKey> nonPinnedRows,
  ) {
    _pinnedOrdering = KeyOrdering<RowKey>.efficient(pinnedRows);
    _nonPinnedOrdering = KeyOrdering<RowKey>.quick(nonPinnedRows);
  }

  void clear() {
    _pinnedOrdering.reset();
    _nonPinnedOrdering.reset();
  }

  void add(RowKey key) {
    if (_nonPinnedOrdering.contains(key)) {
      return; // Already exists in non-pinned ordering
    }

    _nonPinnedOrdering.add(key);
  }

  void remove(RowKey key) {
    if (_pinnedOrdering.contains(key)) {
      _pinnedOrdering.remove(key);
    } else if (_nonPinnedOrdering.contains(key)) {
      _nonPinnedOrdering.remove(key);
    }
  }

  void pin(RowKey key) {
    if (_pinnedOrdering.contains(key) || !_nonPinnedOrdering.contains(key)) {
      return;
    }

    _pinnedOrdering.add(key);
    _nonPinnedOrdering.remove(key);
  }

  void unpin(RowKey key) {
    if (_nonPinnedOrdering.contains(key) || !_pinnedOrdering.contains(key)) {
      return;
    }

    _nonPinnedOrdering.insert(0, key);
    _pinnedOrdering.remove(key);
  }

  void afterSort(List<RowKey> sorted) {
    _nonPinnedOrdering.reset();

    for (final key in sorted) {
      if (_pinnedOrdering.contains(key)) continue;
      _nonPinnedOrdering.add(key);
    }
  }

  void reorder(RowKey from, RowKey to) {
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
      _nonPinnedOrdering.insert(0, from);
      _nonPinnedOrdering.reorder(from, to);
    } else if (!fromPinned && toPinned) {
      _nonPinnedOrdering.remove(from);
      _pinnedOrdering.add(from);
      _pinnedOrdering.reorder(from, to);
    }
  }

  RowKey? previous(RowKey key) {
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

  /// Get the row key at the given index in the data source.
  ///
  /// [index] is the index of the row in the table including the header row.
  RowKey getRowKey(int dataIndex) {
    assert(
      dataIndex >= 0 && dataIndex < dataCount,
      "Data index $dataIndex is out of bounds for rows of length $dataCount",
    );

    final key = dataIndex >= pinnedCount
        ? _nonPinnedOrdering[dataIndex - pinnedCount]
        : _pinnedOrdering[dataIndex];

    return key!;
  }

  int? getRowIndex(RowKey key) {
    if (_pinnedOrdering.contains(key)) {
      return _pinnedOrdering.indexOf(key);
    }

    if (_nonPinnedOrdering.contains(key)) {
      return _pinnedOrdering.length + (_nonPinnedOrdering.indexOf(key) ?? 0);
    }

    return null; // Key not found in either ordering
  }

  int get pinnedCount => _pinnedOrdering.length;
  int get nonPinnedCount => _nonPinnedOrdering.length;

  int get dataCount => pinnedCount + nonPinnedCount;

  List<RowKey> get ordered =>
      [..._pinnedOrdering.keys, ..._nonPinnedOrdering.keys];

  List<RowKey> get pinnedKeys => _pinnedOrdering.keys;
  List<RowKey> get nonPinnedKeys => _nonPinnedOrdering.keys;

  bool contains(RowKey key) {
    return _nonPinnedOrdering.contains(key);
  }
}
