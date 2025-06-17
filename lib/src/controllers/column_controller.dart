import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';

abstract base class TableColumnController {
  void addAll(List<ColumnKey> columns);
  void add(ColumnKey column);

  void removeAll(List<ColumnKey> columns);
  void remove(ColumnKey column);

  void pin(ColumnKey column);
  void unpin(ColumnKey column);

  void reorder(ColumnKey from, ColumnKey to);

  int get count;
  int get pinnedCount;

  List<ColumnKey> get ordered;
}

final class TableHeaderController extends TableColumnController
    with TableControllerCoordinator {
  TableHeaderController(List<ColumnKey>? columns) {
    _nonPinnedOrdering = KeyOrdering.efficient(columns ?? <ColumnKey>[]);
  }

  final _pinnedOrdering = KeyOrdering.efficient(<ColumnKey>[]);
  late final KeyOrdering<ColumnKey> _nonPinnedOrdering;

  @override
  List<ColumnKey> get ordered => [
        ..._pinnedOrdering.keys,
        ..._nonPinnedOrdering.keys,
      ];

  @override
  int get count => _pinnedOrdering.length + _nonPinnedOrdering.length;

  @override
  int get pinnedCount => _pinnedOrdering.length;

  @override
  void addAll(List<ColumnKey> columns) {
    if (columns.isEmpty) return;

    bool shouldNotify = false;

    for (final key in columns) {
      if (_pinnedOrdering.contains(key) || _nonPinnedOrdering.contains(key)) {
        continue;
      }

      _nonPinnedOrdering.add(key);
      shouldNotify = true;
    }

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void add(ColumnKey column) {
    addAll([column]);
  }

  @override
  void removeAll(List<ColumnKey> columns) {
    if (columns.isEmpty) return;

    bool shouldNotify = false;

    for (final key in columns) {
      if (_pinnedOrdering.contains(key)) {
        _pinnedOrdering.remove(key);
        shouldNotify = true;
      } else if (_nonPinnedOrdering.contains(key)) {
        _nonPinnedOrdering.remove(key);
        shouldNotify = true;
      }
    }

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void remove(ColumnKey column) {
    removeAll([column]);
  }

  @override
  void pin(ColumnKey column) {
    if (_pinnedOrdering.contains(column)) return;

    _nonPinnedOrdering.remove(column);
    _pinnedOrdering.add(column);

    notify();
  }

  @override
  void unpin(ColumnKey column) {
    if (_nonPinnedOrdering.contains(column)) return;
    _pinnedOrdering.remove(column);
    _nonPinnedOrdering.insert(0, column);
    notify();
  }

  @override
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

    notify();
  }

  @override
  void dispose() {
    _pinnedOrdering.reset();
    _nonPinnedOrdering.reset();
    super.dispose();
  }

  ColumnKey? previous(ColumnKey key) {
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

  ColumnKey? next(ColumnKey key) {
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

  ColumnKey getColumnKey(int index) {
    if (index < 0 || index >= count) {
      throw RangeError.index(index, this, 'index', 'Index out of range');
    }

    if (index < pinnedCount) {
      return _pinnedOrdering[index]!;
    } else {
      return _nonPinnedOrdering[index - pinnedCount]!;
    }
  }

  int? getColumnIndex(ColumnKey key) {
    if (_pinnedOrdering.contains(key)) {
      return _pinnedOrdering.indexOf(key);
    } else if (_nonPinnedOrdering.contains(key)) {
      return _pinnedOrdering.length + _nonPinnedOrdering.indexOf(key)!;
    }

    return null; // Key not found
  }
}
