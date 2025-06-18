import 'package:simple_table_grid/simple_table_grid.dart' hide TableIndexFinder;
import 'package:simple_table_grid/src/controllers/base.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';

abstract base class TableSizer {
  void setRowExtent(int index, Extent extent);
  Extent getRowExtent(int index);

  void setColumnExtent(ColumnKey key, Extent extent);
  Extent getColumnExtent(int index);

  Map<int, Extent> get rowExtents;
  Map<ColumnKey, Extent> get columnExtents;

  void resize(double delta);
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
    if (_mutatedRowExtents.containsKey(index)) {
      return _mutatedRowExtents[index]!;
    }

    return _defaultRowExtent;
  }

  @override
  Extent getColumnExtent(int index) {
    final key = finder.getColumnKey(index);

    return _getColumnExtent(key);
  }

  Extent _getColumnExtent(ColumnKey key) {
    if (_mutatedColumnExtents.containsKey(key)) {
      return _mutatedColumnExtents[key]!;
    }

    return _defaultColumnExtent;
  }

  @override
  void setRowExtent(int index, Extent extent) {
    if (_mutatedRowExtents[index] == extent) return;

    _mutatedRowExtents[index] = extent;
    notify();
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
}
