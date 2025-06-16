import 'package:simple_table_grid/simple_table_grid.dart';

import 'package:simple_table_grid/src/components/key_ordering.dart';

final class TableColumnManager with TableCoordinatorMixin {
  TableColumnManager(List<ColumnKey>? columns) {
    _nonPinnedOrdering = KeyOrdering.efficient(columns ?? <ColumnKey>[]);
  }

  final _pinnedOrdering = KeyOrdering.efficient(<ColumnKey>[]);
  late final KeyOrdering<ColumnKey> _nonPinnedOrdering;

  List<ColumnKey> get orderedColumns => [
        ..._pinnedOrdering.keys,
        ..._nonPinnedOrdering.keys,
      ];

  int get columnCount => _pinnedOrdering.length + _nonPinnedOrdering.length;

  int get pinnedColumnCount => _pinnedOrdering.length;

  ColumnKey? previousColumn(ColumnKey key) {
    final pinnedIndex = _pinnedOrdering.indexOf(key);
    final nonPinnedIndex = _nonPinnedOrdering.indexOf(key);

    if (pinnedIndex != null) {
      return _pinnedOrdering.firstKey != key
          ? _pinnedOrdering[pinnedIndex - 1]
          : null;
    }

    if (nonPinnedIndex != null) {
      if (_nonPinnedOrdering.firstKey == key) {
        return _pinnedOrdering.lastKey;
      } else {
        return _nonPinnedOrdering[nonPinnedIndex - 1];
      }
    }

    return null; // Key not found in either ordering
  }

  ColumnKey? nextColumn(ColumnKey key) {
    final pinnedIndex = _pinnedOrdering.indexOf(key);
    final nonPinnedIndex = _nonPinnedOrdering.indexOf(key);

    if (pinnedIndex != null) {
      return _pinnedOrdering.lastKey != key
          ? _pinnedOrdering[pinnedIndex + 1]
          : _nonPinnedOrdering.firstKey;
    }

    if (nonPinnedIndex != null) {
      if (_nonPinnedOrdering.lastKey != key) {
        return _nonPinnedOrdering[nonPinnedIndex + 1];
      } else {
        return null;
      }
    }

    return null; // Key not found in either ordering
  }

  void reorder(ColumnKey from, ColumnKey to) {
    final fromPinned = _pinnedOrdering.contains(from);
    final toPinned = _pinnedOrdering.contains(to);

    if (fromPinned && toPinned) {
      _pinnedOrdering.reorder(from, to);
    } else if (!fromPinned && !toPinned) {
      _nonPinnedOrdering.reorder(from, to);
    } else if (fromPinned && !toPinned) {
      _pinnedOrdering.remove(from);
      _nonPinnedOrdering.add(to);
    } else if (!fromPinned && toPinned) {
      _nonPinnedOrdering.remove(from);
      _pinnedOrdering.add(to);
    }

    coordinator.notifyRebuild();
  }

  void remove(ColumnKey key) {
    if (!_pinnedOrdering.contains(key) && !_nonPinnedOrdering.contains(key)) {
      return; // Key not found, nothing to remove
    }

    _pinnedOrdering.remove(key);
    _nonPinnedOrdering.remove(key);

    coordinator.notifyRebuild();
  }

  void add(ColumnKey key, {bool pinned = false}) {
    if (_pinnedOrdering.contains(key) || _nonPinnedOrdering.contains(key)) {
      return;
    }

    if (pinned) {
      _pinnedOrdering.add(key);
    } else {
      _nonPinnedOrdering.add(key);
    }

    coordinator.notifyRebuild();
  }

  void pin(ColumnKey key) {
    if (_pinnedOrdering.contains(key)) return;

    _nonPinnedOrdering.remove(key);
    _pinnedOrdering.add(key);

    coordinator.notifyRebuild();
  }

  void unpin(ColumnKey key) {
    if (_nonPinnedOrdering.contains(key)) return;

    _pinnedOrdering.remove(key);
    _nonPinnedOrdering.insert(0, key);

    coordinator.notifyRebuild();
  }

  @override
  void dispose() {
    super.dispose();
    _pinnedOrdering.reset();
    _nonPinnedOrdering.reset();
  }
}

base mixin TableColumnDelegateMixin on TableController, TableIndexFinder {
  TableColumnManager get columnManager;

  @override
  void addColumn(ColumnKey column, {bool pinned = false}) {
    columnManager.add(column, pinned: pinned);
  }

  @override
  void removeColumn(ColumnKey key) {
    columnManager.remove(key);
  }

  @override
  void pinColumn(ColumnKey key) {
    columnManager.pin(key);
  }

  @override
  void unpinColumn(ColumnKey key) {
    columnManager.unpin(key);
  }

  @override
  void reorderColumn(ColumnKey from, ColumnKey to) {
    columnManager.reorder(from, to);
  }

  @override
  int get columnCount => columnManager.columnCount;

  @override
  int get pinnedColumnCount => columnManager.pinnedColumnCount;

  @override
  List<ColumnKey> get orderedColumns => columnManager.orderedColumns;

  @override
  ColumnKey getColumnKey(int index) {
    if (index < 0 || index >= columnManager.columnCount) {
      throw RangeError.index(index, columnManager.orderedColumns, 'index');
    }
    return columnManager.orderedColumns[index];
  }

  @override
  ColumnKey? previousColumn(ColumnKey key) {
    return columnManager.previousColumn(key);
  }

  @override
  ColumnKey? nextColumn(ColumnKey key) {
    return columnManager.nextColumn(key);
  }
}
