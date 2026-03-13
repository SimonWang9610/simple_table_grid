import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/delegate.dart';
import 'package:simple_table_grid/simple_table_grid.dart' hide TableIndexFinder;
import 'package:simple_table_grid/src/controllers/base.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';

/// TODO: evict all measurements when columns increase (the new columns may affect the layout of all rows and cause all measured row extents invalid).
/// TODO: evict some measurements when rows change
abstract base class TableSizer with ChangeNotifier, DynamicExtentMeasurer {
  /// set the extent at the given [index] for the row.
  void setRowExtent(int index, Extent extent);

  /// get the extent at the given [index] for the row.
  Extent getRowExtent(int index);

  /// set the extent for the column with the given [key].
  void setColumnExtent(ColumnKey key, Extent extent);

  /// get the extent for the column with the given [index].
  Extent getColumnExtent(int index);

  /// get the extent for the column with the given [key].
  Map<int, Extent> get rowExtents;

  /// get the extents for the columns with the given [key].
  Map<ColumnKey, Extent> get columnExtents;

  /// evict the measured row extent for the row with the given [rowKey] from the cache.
  void evictMeasuredRow(RowKey? rowKey);

  void evictAllMeasuredRows();

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

  TableExtentController({
    required this.finder,
    required Extent defaultRowExtent,
    required Extent defaultColumnExtent,
    Map<int, Extent>? rowExtents,
    Map<ColumnKey, Extent>? columnExtents,
  })  : _defaultRowExtent = defaultRowExtent,
        _defaultColumnExtent = defaultColumnExtent {
    // assert(!defaultColumnExtent.isDynamic,
    //     'Default column extent cannot be dynamic.');

    // assert(
    //     columnExtents == null ||
    //         !columnExtents.values.any((extent) => extent.isDynamic),
    //     "Column extents cannot be dynamic.");

    if (rowExtents != null) {
      _mutatedRowExtents.addAll(rowExtents);
    }

    if (columnExtents != null) {
      _mutatedColumnExtents.addAll(columnExtents);
    }
  }

  Extent _defaultRowExtent;
  Extent _defaultColumnExtent;

  set defaultRowExtent(Extent value) {
    if (_defaultRowExtent == value) return;

    _defaultRowExtent = value;
    notify();
  }

  set defaultColumnExtent(Extent value) {
    if (_defaultColumnExtent == value) return;

    _defaultColumnExtent = value;
    notify();
  }

  final Map<int, Extent> _mutatedRowExtents = {};
  final Map<ColumnKey, Extent> _mutatedColumnExtents = {};
  final _measuredRowExtents = _RowExtentMeasurement();
  final _measuredColumnExtents = _ColumnExtentMeasurement();

  Extent get defaultRowExtent => _defaultRowExtent;
  Extent get defaultColumnExtent => _defaultColumnExtent;

  @override
  Map<ColumnKey, Extent> get columnExtents => Map.unmodifiable(
        _mutatedColumnExtents,
      );

  @override
  Map<int, Extent> get rowExtents => Map.unmodifiable(_mutatedRowExtents);

  @override
  Extent getRowExtent(int index) {
    final extent = _mutatedRowExtents[index] ?? _defaultRowExtent;

    /// only when the extent is dynamic, the measured extent can be used,
    /// otherwise the measured extent is meaningless and should not be used.
    if (extent.isDynamic) {
      final rowKey = finder.getRowKey(index);
      final measured = _measuredRowExtents.get(rowKey);

      if (measured != null) return measured;
    }

    /// if no measured extent is available for dynamic extent,
    /// or the extent is not dynamic,
    /// it will be measured in the next layout pass if dynamic

    return extent;
  }

  @override
  Extent getColumnExtent(int index) {
    final key = finder.getColumnKey(index);

    return _getColumnExtent(key);
  }

  Extent _getColumnExtent(ColumnKey key) {
    final extent = _mutatedColumnExtents[key] ?? _defaultColumnExtent;

    if (extent.isDynamic) {
      final measured = _measuredColumnExtents.get(key);

      if (measured != null) return measured;
    }

    return extent;
  }

  @override
  void setRowExtent(int index, Extent extent) {
    if (_mutatedRowExtents[index] == extent) return;

    /// the extent should be updated, previously measured extent for this row may be invalid now,
    /// so evict it from the cache.
    /// otherwise the old measured extent may still be used and cause unexpected layout result.
    final rowKey = finder.getRowKey(index);
    _measuredRowExtents.evict(rowKey);

    _mutatedRowExtents[index] = extent;
    notify();
  }

  /// Purposely do not notify listeners in this method.
  /// Typically, this method is called during the measurement phase in the render object,
  /// and notifying listeners during that phase may cause unwanted side effects and assertions in the render object.
  @override
  void updateMeasuredRowExtent(int rowIndex, Extent extent) {
    assert(!extent.isDynamic, 'The new extent must not be dynamic.');

    /// typically, the measured extent is only for the current row,
    /// so we cache it with the row key, which is more stable than the row index,
    /// as pin/unpin/sorting/replacing may also change the row index of the row key.
    final rowKey = finder.getRowKey(rowIndex);
    _measuredRowExtents.update(rowKey, extent);
  }

  @override
  void updateMeasuredColumnExtent(int columnIndex, Extent extent) {
    assert(!extent.isDynamic, 'The new extent must not be dynamic.');

    final columnKey = finder.getColumnKey(columnIndex);
    _measuredColumnExtents.update(columnKey, extent);
  }

  @override
  void evictMeasuredRow(RowKey? rowKey) {
    _measuredRowExtents.evict(rowKey);
  }

  @override
  void evictAllMeasuredRows() {
    _measuredRowExtents.evictAll();
  }

  @override
  void setColumnExtent(ColumnKey key, Extent extent) {
    if (_mutatedColumnExtents[key] == extent) return;

    _mutatedColumnExtents[key] = extent;
    notify();
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

    if (actualKey == null) return;
    final extent = _getColumnExtent(actualKey);

    final accepted = extent.accept(delta);

    if (accepted == extent) return;
    setColumnExtent(actualKey, accepted);
  }

  void _resizeRow(RowKey rowKey, ResizeDirection direction, double delta) {
    final actualKey =
        direction == ResizeDirection.up ? finder.previousRow(rowKey) : rowKey;

    final index = actualKey != null ? finder.getRowIndex(actualKey) : 0;

    final extent = getRowExtent(index);

    final accepted = extent.accept(delta);

    if (accepted == extent) return;
    setRowExtent(index, accepted);
  }

  @override
  void dispose() {
    _target = null;
    _measuredRowExtents.evictAll();
    _mutatedRowExtents.clear();
    _mutatedColumnExtents.clear();
    super.dispose();
  }
}

class _RowExtentMeasurement {
  final Map<RowKey, Extent> _measuredRowExtents = {};

  Extent? _measureHeaderRowExtent;

  void update(RowKey? rowKey, Extent extent) {
    assert(!extent.isDynamic, 'Measured extent cannot be dynamic.');

    if (rowKey == null) {
      _measureHeaderRowExtent = extent;
    } else {
      _measuredRowExtents[rowKey] = extent;
    }
  }

  Extent? get(RowKey? rowKey) {
    if (rowKey == null) {
      return _measureHeaderRowExtent;
    }

    return _measuredRowExtents[rowKey];
  }

  void evict(RowKey? rowKey) {
    if (rowKey == null) {
      _measureHeaderRowExtent = null;
    } else {
      _measuredRowExtents.remove(rowKey);
    }
  }

  void evictAll() {
    _measuredRowExtents.clear();
    _measureHeaderRowExtent = null;
  }
}

class _ColumnExtentMeasurement {
  final Map<ColumnKey, Extent> _measuredColumnExtents = {};

  void update(ColumnKey columnKey, Extent extent) {
    assert(!extent.isDynamic, 'Measured extent cannot be dynamic.');

    _measuredColumnExtents[columnKey] = extent;
  }

  Extent? get(ColumnKey columnKey) {
    return _measuredColumnExtents[columnKey];
  }

  void evict(ColumnKey columnKey) {
    _measuredColumnExtents.remove(columnKey);
  }

  void evictAll() {
    _measuredColumnExtents.clear();
  }
}
