import 'package:simple_table_grid/src/components/coordinator.dart';
import 'package:simple_table_grid/src/models/key.dart';
import 'package:simple_table_grid/src/models/table_extent.dart';

final class TableExtentManager with TableCoordinatorMixin {
  TableExtentManager({
    required TableExtent defaultRowExtent,
    required TableExtent defaultColumnExtent,
    Map<int, TableExtent>? rowExtents,
    Map<ColumnKey, TableExtent>? columnExtents,
  })  : _defaultRowExtent = defaultRowExtent,
        _defaultColumnExtent = defaultColumnExtent {
    if (rowExtents != null) {
      _mutatedRowExtents.addAll(rowExtents);
    }

    if (columnExtents != null) {
      _mutatedColumnExtents.addAll(columnExtents);
    }
  }

  final Map<int, TableExtent> _mutatedRowExtents = {};
  final Map<ColumnKey, TableExtent> _mutatedColumnExtents = {};

  TableExtent _defaultRowExtent;
  TableExtent _defaultColumnExtent;

  set defaultRowExtent(TableExtent value) {
    if (_defaultRowExtent == value) return;

    _defaultRowExtent = value;
    coordinator.notifyRebuild();
  }

  set defaultColumnExtent(TableExtent value) {
    if (_defaultColumnExtent == value) return;

    _defaultColumnExtent = value;
    coordinator.notifyRebuild();
  }

  TableExtent getRowExtent(int index) {
    if (_mutatedRowExtents.containsKey(index)) {
      return _mutatedRowExtents[index]!;
    }

    return _defaultRowExtent;
  }

  TableExtent getColumnExtent(ColumnKey columnId) {
    if (_mutatedColumnExtents.containsKey(columnId)) {
      return _mutatedColumnExtents[columnId]!;
    }

    return _defaultColumnExtent;
  }

  void setRowExtent(int index, TableExtent extent) {
    if (_mutatedRowExtents[index] == extent) return;

    _mutatedRowExtents[index] = extent;
    coordinator.notifyRebuild();
  }

  void setColumnExtent(ColumnKey columnId, TableExtent extent) {
    if (_mutatedColumnExtents[columnId] == extent) return;

    _mutatedColumnExtents[columnId] = extent;
    coordinator.notifyRebuild();
  }

  @override
  void dispose() {
    _mutatedRowExtents.clear();
    _mutatedColumnExtents.clear();
    super.dispose();
  }

  TableExtentManager copyWith({
    TableExtent? defaultRowExtent,
    TableExtent? defaultColumnExtent,
    Map<int, TableExtent>? rowExtents,
    Map<ColumnKey, TableExtent>? columnExtents,
    bool rebuildImmediately = true,
  }) {
    final newManager = TableExtentManager(
      defaultRowExtent: defaultRowExtent ?? _defaultRowExtent,
      defaultColumnExtent: defaultColumnExtent ?? _defaultColumnExtent,
      rowExtents: rowExtents ?? _mutatedRowExtents,
      columnExtents: columnExtents ?? _mutatedColumnExtents,
    )..bindCoordinator(coordinator);

    dispose();

    if (rebuildImmediately) {
      newManager.coordinator.notifyRebuild();
    }

    return newManager;
  }

  TableExtent get defaultRowExtent => _defaultRowExtent;
  TableExtent get defaultColumnExtent => _defaultColumnExtent;

  Map<ColumnKey, TableExtent> get columnExtents => Map.unmodifiable(
        _mutatedColumnExtents,
      );

  Map<int, TableExtent> get rowExtents => Map.unmodifiable(_mutatedRowExtents);
}
