import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';
import 'package:simple_table_grid/src/components/reorder_interfaces.dart';

abstract base class TableColumnController
    with ChangeNotifier, TableKeyReorderMixin<ColumnKey> {
  /// Adds a list of columns to the controller.
  /// If a column already exists, it will be ignored.
  /// Notifies listeners if any new columns were added.
  ///
  void addAll(List<HeaderData> columns);

  /// Adds a single column to the controller.
  ///
  /// it is developer's responsibility to ensure that each row has the data for the newly added columns.
  void add(HeaderData column);

  /// Removes a list of columns from the controller.
  /// Notifies listeners if any columns were removed.
  /// If a column does not exist, it will be ignored.
  ///
  /// The corresponding data for the removed columns will not be removed from the row data implicitly.
  void removeAll(List<ColumnKey> columns);

  /// Removes a single column from the controller.
  ///
  /// The corresponding data for the removed columns will not be removed from the row data implicitly.
  void remove(ColumnKey column);

  /// Pins a column to the end of the pinned columns.
  void pin(ColumnKey column);

  /// Unpins a column, moving it to the start of the non-pinned columns.
  void unpin(ColumnKey column);

  /// the number of columns in the controller, including pinned and non-pinned.
  int get count;

  /// the number of pinned columns in the controller.
  int get pinnedCount;

  /// Returns the current ordering of columns.
  List<HeaderData> get ordered;

  dynamic getHeaderData(ColumnKey key);
}

final class TableHeaderController extends TableColumnController
    with TableControllerCoordinator {
  TableHeaderController(
    List<HeaderData>? columns,
    List<ColumnKey>? pinnedColumns,
  ) {
    assert(
      () {
        if (pinnedColumns == null || columns == null) return true;

        final allSet = columns.map((e) => e.key).toSet();

        for (final column in pinnedColumns) {
          if (!allSet.contains(column)) {
            return false; // Duplicate found
          }
        }

        return true;
      }(),
      "Duplicate columns found in pinned and non-pinned lists",
    );

    final nonPinned = <ColumnKey>[];

    for (final column in columns ?? <HeaderData>[]) {
      _columns[column.key] = column;

      if (pinnedColumns == null || !pinnedColumns.contains(column.key)) {
        nonPinned.add(column.key);
      }
    }

    _nonPinnedOrdering = KeyOrdering.efficient(nonPinned);
    _pinnedOrdering = KeyOrdering.efficient(pinnedColumns ?? <ColumnKey>[]);
  }

  final _columns = <ColumnKey, HeaderData>{};

  late final KeyOrdering<ColumnKey> _pinnedOrdering;
  late final KeyOrdering<ColumnKey> _nonPinnedOrdering;

  @override
  List<HeaderData> get ordered {
    final orderedColumns = <HeaderData>[];

    for (final key in _pinnedOrdering.keys) {
      orderedColumns.add(_columns[key]!);
    }

    for (final key in _nonPinnedOrdering.keys) {
      orderedColumns.add(_columns[key]!);
    }

    return orderedColumns;
  }

  @override
  int get count => _pinnedOrdering.length + _nonPinnedOrdering.length;

  @override
  int get pinnedCount => _pinnedOrdering.length;

  @override
  void addAll(List<HeaderData> columns) {
    if (columns.isEmpty) return;

    bool shouldNotify = false;

    for (final column in columns) {
      _columns[column.key] = column;

      if (_pinnedOrdering.contains(column.key) ||
          _nonPinnedOrdering.contains(column.key)) {
        continue; // Column already exists, skip adding
      }

      _nonPinnedOrdering.add(column.key);

      shouldNotify = true;
    }

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void add(HeaderData column) {
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

  ReorderPredicate? _reorderPredicate;

  @override
  ReorderPredicate? get reorderPredicate => _reorderPredicate;

  @override
  void predicateReorder(ColumnKey from, ColumnKey to) {
    final fromPinned = _pinnedOrdering.contains(from);
    final toPinned = _pinnedOrdering.contains(to);

    if (fromPinned && toPinned) {
      _reorderPredicate = _pinnedOrdering.predicate(from, to);
    } else if (!fromPinned && !toPinned) {
      _reorderPredicate = _nonPinnedOrdering.predicate(from, to);
    } else if (fromPinned && !toPinned) {
      _reorderPredicate =
          ReorderPredicate(candidate: to, afterCandidate: false);
    } else if (!fromPinned && toPinned) {
      _reorderPredicate =
          ReorderPredicate(candidate: to, afterCandidate: false);
    }

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
      _nonPinnedOrdering.add(from);
      _nonPinnedOrdering.reorder(from, to);
    } else if (!fromPinned && toPinned) {
      _nonPinnedOrdering.remove(from);
      _pinnedOrdering.add(from);
      _pinnedOrdering.reorder(from, to);
    }

    _reorderPredicate = null;

    notify();
  }

  @override
  void dispose() {
    _reorderPredicate = null;
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

  @override
  dynamic getHeaderData(ColumnKey key) {
    return _columns[key]?.data;
  }

  HeaderData? getHeader(ColumnKey key) {
    return _columns[key];
  }
}
