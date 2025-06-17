import 'package:simple_table_grid/simple_table_grid.dart';

final class ExtentManager with TableCoordinatorMixin {
  ExtentManager({
    required Extent defaultRowExtent,
    required Extent defaultColumnExtent,
    Map<int, Extent>? rowExtents,
    Map<ColumnKey, Extent>? columnExtents,
  })  : _defaultRowExtent = defaultRowExtent,
        _defaultColumnExtent = defaultColumnExtent {
    if (rowExtents != null) {
      _mutatedRowExtents.addAll(rowExtents);
    }

    if (columnExtents != null) {
      _mutatedColumnExtents.addAll(columnExtents);
    }
  }

  TableIndexFinder get finder => coordinator as TableIndexFinder;

  final Map<int, Extent> _mutatedRowExtents = {};
  final Map<ColumnKey, Extent> _mutatedColumnExtents = {};

  Extent _defaultRowExtent;
  Extent _defaultColumnExtent;

  set defaultRowExtent(Extent value) {
    if (_defaultRowExtent == value) return;

    _defaultRowExtent = value;
    coordinator.notifyRebuild();
  }

  set defaultColumnExtent(Extent value) {
    if (_defaultColumnExtent == value) return;

    _defaultColumnExtent = value;
    coordinator.notifyRebuild();
  }

  Extent getRowExtent(int index) {
    if (_mutatedRowExtents.containsKey(index)) {
      return _mutatedRowExtents[index]!;
    }

    return _defaultRowExtent;
  }

  Extent getColumnExtent(ColumnKey key) {
    if (_mutatedColumnExtents.containsKey(key)) {
      return _mutatedColumnExtents[key]!;
    }

    return _defaultColumnExtent;
  }

  void setRowExtent(int index, Extent extent) {
    if (_mutatedRowExtents[index] == extent) return;

    _mutatedRowExtents[index] = extent;
    coordinator.notifyRebuild();
  }

  void setColumnExtent(ColumnKey columnId, Extent extent) {
    if (_mutatedColumnExtents[columnId] == extent) return;

    _mutatedColumnExtents[columnId] = extent;
    coordinator.notifyRebuild();
  }

  ResizeTarget? _target;

  void setResizeTarget(ResizeTarget? target) {
    if (_target == target) return;
    _target = target;
    print('Resize target set to: $_target');
  }

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
    final extent = getColumnExtent(actualKey);

    final accepted = extent.accept(delta);

    if (accepted == extent) return;
    setColumnExtent(actualKey, accepted);
  }

  void _resizeRow(RowKey rowKey, ResizeDirection direction, double delta) {
    final actualKey =
        direction == ResizeDirection.up ? finder.previousRow(rowKey) : rowKey;

    if (actualKey == null) return;

    final index = finder.getRowIndex(actualKey);
    if (index == null) return;
    final extent = getRowExtent(index);

    final accepted = extent.accept(delta);

    if (accepted == extent) return;
    setRowExtent(index, accepted);
  }

  @override
  void dispose() {
    _target = null;
    _mutatedRowExtents.clear();
    _mutatedColumnExtents.clear();
    super.dispose();
  }

  Extent get defaultRowExtent => _defaultRowExtent;
  Extent get defaultColumnExtent => _defaultColumnExtent;

  Map<ColumnKey, Extent> get columnExtents => Map.unmodifiable(
        _mutatedColumnExtents,
      );

  Map<int, Extent> get rowExtents => Map.unmodifiable(_mutatedRowExtents);
}

class ResizeTarget<T extends TableKey> {
  final T key;
  final ResizeDirection direction;

  const ResizeTarget({
    required this.key,
    required this.direction,
  });

  @override
  String toString() {
    return 'ResizeTarget(key: $key, direction: $direction)';
  }
}

abstract mixin class TableIndexFinder {
  RowKey getRowKey(int index);
  RowKey? previousRow(RowKey key);
  RowKey? nextRow(RowKey key);

  /// Return the vicinity index of the row key.
  /// If the row key is not found and the header row is not shown, return null;
  /// If the row key is not found and the header row is shown, return 0;
  /// If the row key is found, return the index of the row key.
  int? getRowIndex(RowKey key);

  ColumnKey getColumnKey(int index);
  ColumnKey? previousColumn(ColumnKey key);
  ColumnKey? nextColumn(ColumnKey key);
}

abstract mixin class TableResizer {
  void setResizeTarget(ResizeTarget? target);

  void resize(double delta);
}
