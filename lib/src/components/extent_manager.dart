import 'package:flutter/foundation.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

final class ExtentManager with ChangeNotifier {
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

  final Map<int, Extent> _mutatedRowExtents = {};
  final Map<ColumnKey, Extent> _mutatedColumnExtents = {};

  Extent _defaultRowExtent;
  Extent _defaultColumnExtent;

  set defaultRowExtent(Extent value) {
    if (_defaultRowExtent == value) return;

    _defaultRowExtent = value;
    notifyListeners();
  }

  set defaultColumnExtent(Extent value) {
    if (_defaultColumnExtent == value) return;

    _defaultColumnExtent = value;
    notifyListeners();
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
    notifyListeners();
  }

  void setColumnExtent(ColumnKey columnId, Extent extent) {
    if (_mutatedColumnExtents[columnId] == extent) return;

    _mutatedColumnExtents[columnId] = extent;
    notifyListeners();
  }

  void updateRowDelta(int index, double delta) {
    final extent = getRowExtent(index);

    final accepted = extent.accept(delta);

    if (accepted == extent) return;
    setRowExtent(index, accepted);
  }

  void updateColumnDelta(ColumnKey key, double delta) {
    final extent = getColumnExtent(key);

    final accepted = extent.accept(delta);

    if (accepted == extent) return;
    setColumnExtent(key, accepted);
  }

  @override
  void dispose() {
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
