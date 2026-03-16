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
  /// It only reset the measured pixels to the initial state, which means the resized result will be kept after reset.
  void resetColumnExtent(
    ColumnKey key, {
    bool shouldNotify = true,
  });

  /// reset the extent for the row with the given [index] or [key] to the provided row extent,
  /// which either the extent from the extent map or the default row extent.
  ///
  /// If [key] and [index] are null, this method does nothing.
  ///
  /// For example, during hot-reloading, we want to reset the row extents to ensure the row is measured again if needed,
  /// because the row data may change during development, which can lead to different layout results for the row
  ///
  /// It only reset the measured pixels to the initial state, which means the resized result will be kept after reset.
  void resetRowExtent({
    RowKey? key,
    int? index,
    bool shouldNotify = true,
  });

  /// reset all column and row extents to the initial state.
  ///
  /// For example, during hot-reloading, we want to reset all extents to ensure the table is measured again if needed,
  /// because the table data may change during development, which can lead to different layout results for the table.
  ///
  /// It only reset the measured pixels to the initial state, which means the resized result will be kept after reset.
  void resetAllExtents({bool shouldNotify = true});

  /// Resize the [ResizeTarget] set by [setResizeTarget] by the given [delta].
  ///
  /// If the [ResizeTarget] is null, this method does nothing.
  /// If [ResizeTarget]'s extent does not accept the [delta], it will not change the extent.
  void resize(double delta);

  /// Set the [ResizeTarget] to [resize] on the targeted column or row.
  void setResizeTarget(ResizeTarget? target);
}

final class TableExtentController extends TableSizer
    with
        TableControllerCoordinator,
        TableCursorDelegate,
        _ResizerImpl,
        _SizerNotificationListener {
  @override
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

  @override
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
  void resetColumnExtent(ColumnKey key, {bool shouldNotify = true}) {
    _columnExtents.resetMeasurement(key);

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void resetRowExtent({RowKey? key, int? index, bool shouldNotify = true}) {
    bool changed = false;

    if (index != null) {
      if (index == 0) {
        _headerRowExtent?.resetMeasurement();
        changed = true;
      } else {
        final rowKey = finder.getRowKey(index);

        if (rowKey != null) {
          _rowExtents.resetMeasurement(rowKey);
          changed = true;
        }
      }
    }

    if (key != null) {
      _rowExtents.resetMeasurement(key);
      changed = true;
    }

    if (changed && shouldNotify) {
      notify();
    }
  }

  @override
  void resetAllExtents({bool shouldNotify = true}) {
    final changed = _headerRowExtent != null ||
        !_rowExtents.isEmpty ||
        !_columnExtents.isEmpty;

    _headerRowExtent?.resetMeasurement();
    _rowExtents.resetAllMeasurement();
    _columnExtents.resetAllMeasurement();

    if (changed && shouldNotify) {
      notify();
    }
  }

  @override
  void dispose() {
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

  void resetMeasurement(T key) {
    _cache[key]?.resetMeasurement();
  }

  void resetAllMeasurement() {
    for (final extent in _cache.values) {
      extent.resetMeasurement();
    }
  }

  Extent? operator [](T key) => _cache[key];
}

mixin _ResizerImpl on TableSizer, TableControllerCoordinator {
  TableIndexFinder get finder;

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
    ColumnKey columnKey,
    ResizeDirection direction,
    double delta,
  ) {
    final actualKey = direction == ResizeDirection.left
        ? finder.previousColumn(columnKey)
        : columnKey;

    if (actualKey == null || finder.getColumnIndex(actualKey) == null) {
      setResizeTarget(null);
      return;
    }

    final extent = _getColumnExtent(actualKey);

    final updated = extent.resize(delta);

    if (updated) {
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

    final updated = extent.resize(delta);

    if (updated) {
      notify();
    }
  }

  Extent _getColumnExtent(ColumnKey key);

  @override
  void dispose() {
    _target = null;
    super.dispose();
  }
}

mixin _SizerNotificationListener on TableSizer, TableControllerCoordinator {
  @override
  void onNotification<T extends CoordinatorNotification>(T notification) {
    switch (notification) {
      /// as long as columns are added or removed, the extent of the table might need to be recalculated,
      /// so we execute a full reset.
      case ColumnRemovedNotification():
      case ColumnAddedNotification():
        resetAllExtents(shouldNotify: true);
        break;

      /// as long as rows are removed, the extent of the table might need to be recalculated,
      case RowRemovedNotification(:final rows):
        for (final row in rows) {
          resetRowExtent(key: row, shouldNotify: false);
        }
        notify();
        break;
    }
  }
}
