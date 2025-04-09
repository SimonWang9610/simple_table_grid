import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/models/cell_index.dart';

sealed class TableSelection<T> extends ChangeNotifier
    implements _TableSelection<T> {
  TableSelection();

  static TableSelection<int> lines({
    List<int>? selectedLines,
  }) {
    return _LineSelection(selectedLines: selectedLines);
  }

  static TableSelection<CellIndex> cells({
    List<CellIndex>? cells,
  }) {
    return _CellSelection(selectedCells: cells);
  }

  bool get hasSelection;
  List<T> get selected;

  bool isSelected(T value);

  /// Update the selection by column-axis if [forColumn] is true
  /// or by row-axis if [forColumn] is false.
  ///
  /// [forColumn] is ignored if the selection is not a cell selection.
  ///
  /// Tow cases:
  /// 1. [from, to]
  ///   - all selected item in (from, to] should be sifted to the left (-1)
  ///   - [from] would be unselected and [to] would be selected
  /// 2. [to, from]
  ///   - all selected item in [to, from) should be sifted to the right (+1)
  ///   - [to] would be unselected and [from] would be selected
  ///
  /// This operation would not notify the listeners.
  /// This is useful when the user is dragging the header to reorder it.
  void adopt(int from, int to, {bool forColumn = true});

  void replace(Map<int, int> newIndices, {bool byColumn = false});

  void select(
    T value, {
    bool shouldNotify = true,
  }) {
    if (_select(value) && shouldNotify) {
      notifyListeners();
    }
  }

  void unselect(
    T value, {
    bool shouldNotify = true,
  }) {
    if (_unselect(value) && shouldNotify) {
      notifyListeners();
    }
  }

  void selectAll(
    Iterable<T> items, {
    bool shouldNotify = true,
  }) {
    bool anySelected = false;

    for (final value in items) {
      anySelected |= _select(value);
    }

    if (shouldNotify && anySelected) {
      notifyListeners();
    }
  }

  void unselectAll(Iterable<T> items, {bool shouldNotify = true}) {
    bool anyUnselected = false;

    for (final value in items) {
      anyUnselected |= _unselect(value);
    }

    if (shouldNotify && anyUnselected) {
      notifyListeners();
    }
  }

  void clear({
    bool shouldNotify = true,
  }) {
    if (_clear() && shouldNotify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }
}

abstract interface class _TableSelection<T> {
  bool _clear();
  bool _select(T value);
  bool _unselect(T value);
}

final class _LineSelection extends TableSelection<int> {
  _LineSelection({
    List<int>? selectedLines,
  }) {
    if (selectedLines != null) {
      selectedLines.addAll(selectedLines);
    }
  }

  final Set<int> _selectedLines = <int>{};

  @override
  List<int> get selected => _selectedLines.toList(growable: false);

  @override
  bool isSelected(int row) {
    return _selectedLines.contains(row);
  }

  @override
  bool get hasSelection => _selectedLines.isNotEmpty;

  @override
  void adopt(int from, int to, {bool forColumn = true}) {
    if (from == to) return;

    final shift = from < to ? -1 : 1;

    final oldSelected = selected;

    bool shouldShift(int line) {
      if (from < to) {
        return line > from && line <= to;
      } else {
        return line >= to && line < from;
      }
    }

    for (final line in oldSelected) {
      if (shouldShift(line)) {
        _selectedLines.remove(line);
        _selectedLines.add(line + shift);
      } else if (line == from) {
        _selectedLines.remove(line);
        _selectedLines.add(to);
      }
    }
  }

  @override
  void replace(Map<int, int> newIndices, {bool byColumn = false}) {
    final oldSelected = selected;
    _selectedLines.clear();

    for (final line in oldSelected) {
      final newline = newIndices[line];

      if (newline != null) {
        _selectedLines.add(newline);
      }
    }
  }

  @override
  bool _select(int row) => _selectedLines.add(row);

  @override
  bool _unselect(int row) => _selectedLines.remove(row);

  @override
  bool _clear() {
    if (_selectedLines.isNotEmpty) {
      _selectedLines.clear();
      return true;
    }
    return false;
  }
}

final class _CellSelection extends TableSelection<CellIndex> {
  _CellSelection({
    List<CellIndex>? selectedCells,
  }) {
    if (selectedCells != null) {
      _selectedCells.addAll(selectedCells);
    }
  }

  final Set<CellIndex> _selectedCells = <CellIndex>{};

  @override
  bool get hasSelection => _selectedCells.isNotEmpty;

  @override
  List<CellIndex> get selected => _selectedCells.toList(growable: false);

  @override
  bool isSelected(CellIndex cell) {
    return _selectedCells.contains(cell);
  }

  @override
  void adopt(int from, int to, {bool forColumn = true}) {
    if (from == to) return;

    final shift = from < to ? -1 : 1;

    final oldSelected = selected;

    bool shouldShift(CellIndex cell) {
      final target = forColumn ? cell.column : cell.row;

      if (from < to) {
        return target > from && target <= to;
      } else {
        return target >= to && target < from;
      }
    }

    for (final cell in oldSelected) {
      if (shouldShift(cell)) {
        _selectedCells.remove(cell);
        _selectedCells.add(CellIndex(
          cell.row,
          cell.column + shift,
        ));
      } else {
        final target = forColumn ? cell.column : cell.row;

        if (target == from) {
          final newCell = CellIndex(
            forColumn ? cell.row : to,
            forColumn ? to : cell.column,
          );

          _selectedCells.remove(cell);
          _selectedCells.add(newCell);
        }
      }
    }
  }

  @override
  void replace(Map<int, int> newIndices, {bool byColumn = false}) {
    final oldSelected = selected;
    _selectedCells.clear();

    for (final cell in oldSelected) {
      final target = byColumn ? cell.column : cell.row;

      if (newIndices.containsKey(target)) {
        final newCell = CellIndex(
          byColumn ? cell.row : newIndices[target]!,
          byColumn ? newIndices[target]! : cell.column,
        );

        _selectedCells.add(newCell);
      }
    }
  }

  @override
  bool _select(CellIndex cell) => _selectedCells.add(cell);

  @override
  bool _unselect(CellIndex cell) => _selectedCells.remove(cell);

  @override
  bool _clear() {
    if (_selectedCells.isNotEmpty) {
      _selectedCells.clear();
      return true;
    }
    return false;
  }
}
