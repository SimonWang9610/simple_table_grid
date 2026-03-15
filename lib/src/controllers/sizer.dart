import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart' hide TableIndexFinder;
import 'package:simple_table_grid/src/controllers/base.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';

abstract interface class TableSizer with ChangeNotifier {
  /// set the extent at the given [index] for the row.
  void setRowExtent(int index, Extent extent);

  /// get the extent at the given [index] for the row.
  Extent getRowExtent(int index);

  /// set the extent for the column with the given [key].
  void setColumnExtent(ColumnKey key, Extent extent);

  /// get the extent for the column with the given [index].
  Extent getColumnExtent(int index);

  /// reset the extent for the column with the given [key] to the provided column extent,
  /// which either the extent from the extent map or the default column extent.
  ///
  /// For example, during hot-reloading, we want to reset the column extents to ensure the column is measured again if needed,
  /// because the column data may change during development, which can lead to different layout results for the column
  ///
  /// NOTE: resized column extent will also be reset by this method,
  /// because the resized extent is stored in the column extent map, which will be cleared by this method.
  void resetColumnExtent(ColumnKey key);

  /// reset the extent for the row with the given [index] or [key] to the provided row extent,
  /// which either the extent from the extent map or the default row extent.
  ///
  /// If [key] and [index] are null, this method does nothing.
  ///
  /// For example, during hot-reloading, we want to reset the row extents to ensure the row is measured again if needed,
  /// because the row data may change during development, which can lead to different layout results for the row
  ///
  /// NOTE: resized row extent will also be reset by this method,
  /// because the resized extent is stored in the row extent map, which will be cleared by
  void resetRowExtent({RowKey? key, int? index});

  /// reset all column and row extents to the initial state.
  ///
  /// For example, during hot-reloading, we want to reset all extents to ensure the table is measured again if needed,
  /// because the table data may change during development, which can lead to different layout results for the table.
  ///
  /// NOTE: all resized results will also be reset by this method,
  /// because the resized extents are stored in the column and row extent maps, which will be cleared by this method.
  void resetAllExtents();

  /// Resize the [ResizeTarget] set by [setResizeTarget] by the given [delta].
  ///
  /// If the [ResizeTarget] is null, this method does nothing.
  /// If [ResizeTarget]'s extent does not accept the [delta], it will not change the extent.
  void resize(double delta);

  /// Set the [ResizeTarget] to [resize] on the targeted column or row.
  void setResizeTarget(ResizeTarget? target);
}

final class TableExtentController extends TableSizer
    with TableControllerCoordinator, TableCursorDelegate {
  final TableIndexFinder finder;
  final Map<int, Extent>? rowExtents;
  final Map<ColumnKey, Extent>? columnExtents;

  TableExtentController({
    required this.finder,
    required Extent defaultRowExtent,
    required Extent defaultColumnExtent,
    this.rowExtents,
    this.columnExtents,
  })  : _defaultRowExtent = defaultRowExtent,
        _defaultColumnExtent = defaultColumnExtent;

  Extent _defaultRowExtent;
  Extent _defaultColumnExtent;

  set defaultRowExtent(Extent value) {
    if (_defaultRowExtent == value) return;

    _headerRowExtent = null;
    _rowExtents.clear();
    _defaultRowExtent = value;

    notify();
  }

  set defaultColumnExtent(Extent value) {
    if (_defaultColumnExtent == value) return;
    _columnExtents.clear();
    _defaultColumnExtent = value;
    notify();
  }

  /// Clone the initial extent for the row at the given [index] based on the provided row extents or default row extent.
  /// Any updates to the cloned extent will not affect the initial extents stored in the row extents or default row extent,
  /// which are used as the source of truth for resetting the row extent.
  Extent _cloneInitialRowExtent(int index) {
    return rowExtents?[index]?.clone() ?? _defaultRowExtent.clone();
  }

  /// Clone the initial extent for the column with the given [key] based on the provided column extents or default column extent.
  /// Any updates to the cloned extent will not affect the initial extents stored in the column extents or default column extent,
  /// which are used as the source of truth for resetting the column extent.
  Extent _cloneInitialColumnExtent(ColumnKey key) {
    return columnExtents?[key]?.clone() ?? _defaultColumnExtent.clone();
  }

  final _columnExtents = _ExtentCache<ColumnKey>();
  final _rowExtents = _ExtentCache<RowKey>();

  Extent? _headerRowExtent;

  @override
  Extent getRowExtent(int index) {
    final rowKey = finder.getRowKey(index);

    if (rowKey == null) {
      _headerRowExtent ??= _cloneInitialRowExtent(index);
      return _headerRowExtent!;
    }

    return _rowExtents.get(
      rowKey,
      ifAbsent: () => _cloneInitialRowExtent(index),
    );
  }

  @override
  Extent getColumnExtent(int index) {
    final key = finder.getColumnKey(index);

    return _getColumnExtent(key);
  }

  Extent _getColumnExtent(ColumnKey key) => _columnExtents.get(
        key,
        ifAbsent: () => _cloneInitialColumnExtent(key),
      );

  @override
  void setRowExtent(int index, Extent extent) {
    final rowKey = finder.getRowKey(index);

    if (rowKey == null) {
      _headerRowExtent = extent;
    } else {
      _rowExtents.set(rowKey, extent);
    }

    notify();
  }

  @override
  void setColumnExtent(ColumnKey key, Extent extent) {
    _columnExtents.set(key, extent);

    notify();
  }

  @override
  void resetColumnExtent(ColumnKey key) {
    final removed = _columnExtents.remove(key);

    if (removed) {
      notify();
    }
  }

  @override
  void resetRowExtent({RowKey? key, int? index}) {
    bool changed = false;

    if (index != null) {
      if (index == 0) {
        changed = _headerRowExtent != null || changed;
        _headerRowExtent = null;
      } else {
        final rowKey = finder.getRowKey(index);

        if (rowKey != null) {
          changed = _rowExtents.remove(rowKey) || changed;
        }
      }
    }

    if (key != null) {
      changed = _rowExtents.remove(key) || changed;
    }

    if (changed) {
      notify();
    }
  }

  @override
  void resetAllExtents() {
    final changed = _headerRowExtent != null ||
        !_rowExtents.isEmpty ||
        !_columnExtents.isEmpty;

    _headerRowExtent = null;
    _rowExtents.clear();
    _columnExtents.clear();

    if (changed) {
      notify();
    }
  }

  ResizeTarget? _target;

  @override
  void setResizeTarget(ResizeTarget? target) {
    if (_target == target) return;
    _target = target;
  }

  @override
  void resize(double delta) {
    if (_target == null) return;

    final direction = _target!.direction;

    switch (_target!.key) {
      case ColumnKey columnKey:
        _resizeColumn(columnKey, direction, delta);
        break;
      case RowKey rowKey:
        _resizeRow(rowKey, direction, delta);
        break;
      default:
        break;
    }
  }

  void _resizeColumn(
      ColumnKey columnKey, ResizeDirection direction, double delta) {
    final actualKey = direction == ResizeDirection.left
        ? finder.previousColumn(columnKey)
        : columnKey;

    if (actualKey == null || finder.getColumnIndex(actualKey) == null) {
      setResizeTarget(null);
      return;
    }

    final extent = _getColumnExtent(actualKey);

    final accepted = extent.accept(delta);

    if (accepted) {
      notify();
    }
  }

  void _resizeRow(RowKey rowKey, ResizeDirection direction, double delta) {
    final actualKey =
        direction == ResizeDirection.up ? finder.previousRow(rowKey) : rowKey;

    if (actualKey == null) {
      setResizeTarget(null);
      return;
    }

    final index = finder.getRowIndex(actualKey);

    if (index <= 0) {
      setResizeTarget(null);
      return;
    }

    final extent = getRowExtent(index);

    final accepted = extent.accept(delta);

    if (accepted) {
      notify();
    }
  }

  @override
  void dispose() {
    _target = null;
    _headerRowExtent = null;
    _rowExtents.clear();
    _columnExtents.clear();
    super.dispose();
  }
}

class _ExtentCache<T extends TableKey> {
  final Map<T, Extent> _cache = {};

  bool get isEmpty => _cache.isEmpty;

  Extent get(T key, {required Extent Function() ifAbsent}) {
    return _cache.putIfAbsent(key, ifAbsent);
  }

  void set(T key, Extent extent) {
    _cache[key] = extent;
  }

  bool remove(T key) {
    return _cache.remove(key) != null;
  }

  void clear() {
    _cache.clear();
  }

  Extent? operator [](T key) => _cache[key];
}
