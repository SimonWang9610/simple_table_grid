import 'package:flutter/material.dart';
import 'package:simple_table_grid/src/components/coordinator.dart';
import 'package:simple_table_grid/src/components/table_selection.dart';
import 'package:simple_table_grid/src/models/cell_index.dart';
import 'package:simple_table_grid/src/models/misc.dart';

final class ActionManager with TableCoordinatorMixin {
  ActionManager({
    List<TableSelectionStrategy>? selectionStrategies,
    List<TableHoveringStrategy>? hoveringStrategies,
  }) {
    if (selectionStrategies != null) {
      updateSelectionStrategy(selectionStrategies);
    }

    if (hoveringStrategies != null) {
      updateHoveringStrategy(hoveringStrategies);
    }
  }

  final _selectedRows = TableSelection.lines();
  final _selectedColumns = TableSelection.lines();
  final _selectedCells = TableSelection.cells();

  final _hoveringRows = TableSelection.lines();
  final _hoveringColumns = TableSelection.lines();

  final Set<TableSelectionStrategy> _selectionStrategies = {};
  final Set<TableHoveringStrategy> _hoveringStrategies = {};

  bool updateSelectionStrategy(List<TableSelectionStrategy> strategies) {
    final updated = !_selectionStrategies.containsAll(strategies);

    _selectionStrategies.clear();
    _selectionStrategies.addAll(strategies);

    final hasAnySelection = _selectedRows.hasSelection ||
        _selectedColumns.hasSelection ||
        _selectedCells.hasSelection;

    return updated && hasAnySelection;
  }

  bool updateHoveringStrategy(List<TableHoveringStrategy> strategies) {
    final updated = !_hoveringStrategies.containsAll(strategies);

    _hoveringStrategies.clear();
    _hoveringStrategies.addAll(strategies);

    final hasAnyHovering =
        _hoveringRows.hasSelection || _hoveringColumns.hasSelection;

    return updated && hasAnyHovering;
  }

  void select({
    Iterable<int>? rows,
    Iterable<int>? columns,
    Iterable<CellIndex>? cells,
  }) {
    if (cells != null && _selectionStrategies.canSelectCell) {
      _selectedCells.selectAll(cells);
    }

    if (columns != null && _selectionStrategies.canSelectColumn) {
      _selectedColumns.selectAll(columns);
    }

    if (rows != null && _selectionStrategies.canSelectRow) {
      _selectedRows.selectAll(rows);
    }
  }

  void unselect({
    Iterable<int>? rows,
    Iterable<int>? columns,
    Iterable<CellIndex>? cells,
    bool shouldNotify = true,
  }) {
    if (cells != null) {
      _selectedCells.unselectAll(
        cells,
        shouldNotify: shouldNotify,
      );
    }

    if (columns != null) {
      _selectedColumns.unselectAll(
        columns,
        shouldNotify: shouldNotify,
      );
    }

    if (rows != null) {
      print('Unselecting rows: $rows');
      _selectedRows.unselectAll(
        rows,
        shouldNotify: shouldNotify,
      );
    }
  }

  void hoverOn({int? row, int? column}) {
    if (row != null && _hoveringStrategies.canHoverRow) {
      _hoveringRows.select(row);
    }

    if (column != null && _hoveringStrategies.canHoverColumn) {
      _hoveringColumns.select(column);
    }
  }

  void hoverOff({
    int? row,
    int? column,
    bool shouldNotify = true,
  }) {
    if (row != null) {
      _hoveringRows.unselect(
        row,
        shouldNotify: shouldNotify,
      );
    }

    if (column != null) {
      _hoveringColumns.unselect(
        column,
        shouldNotify: shouldNotify,
      );
    }
  }

  void hoverOffAll({
    List<int>? rows,
    List<int>? columns,
    bool shouldNotify = true,
  }) {
    if (rows != null) {
      _hoveringRows.unselectAll(
        rows,
        shouldNotify: shouldNotify,
      );
    }

    if (columns != null) {
      _hoveringColumns.unselectAll(
        columns,
        shouldNotify: shouldNotify,
      );
    }
  }

  bool isCellHovering(int row, int column) {
    return _hoveringStrategies.canHover
        ? (_hoveringRows.isSelected(row) || _hoveringColumns.isSelected(column))
        : false;
  }

  bool isCellSelected(int row, int column) {
    return _selectionStrategies.canSelect
        ? (_selectedRows.isSelected(row) ||
            _selectedColumns.isSelected(column) ||
            _selectedCells.isSelected(CellIndex(row, column)))
        : false;
  }

  @override
  void dispose() {
    super.dispose();
    _hoveringRows.dispose();
    _hoveringColumns.dispose();
    _selectedRows.dispose();
    _selectedColumns.dispose();
    _selectedCells.dispose();
  }

  Listenable? getCellActionNotifier(int row, int column) {
    final notifiers = <Listenable>[];

    if (_hoveringStrategies.canHoverColumn) {
      notifiers.add(_hoveringColumns);
    }

    if (_selectionStrategies.canSelectColumn) {
      notifiers.add(_selectedColumns);
    }

    if (!coordinator.isColumnHeader(row)) {
      if (_hoveringStrategies.canHoverRow) {
        notifiers.add(_hoveringRows);
      }

      if (_selectionStrategies.canSelectRow) {
        notifiers.add(_selectedRows);
      }

      if (_selectionStrategies.canSelectCell) {
        notifiers.add(_selectedCells);
      }
    }

    if (notifiers.isEmpty) return null;

    if (notifiers.length == 1) {
      return notifiers.first;
    } else {
      return Listenable.merge(notifiers);
    }
  }

  void adapt(
    int from,
    int to, {
    bool forColumn = true,
  }) {
    if (forColumn) {
      _selectedColumns.adopt(from, to);
      _hoveringColumns.adopt(from, to);
    } else {
      _selectedRows.adopt(from, to);
      _hoveringRows.adopt(from, to);
    }

    _selectedCells.adopt(from, to, forColumn: forColumn);
  }

  void replace({
    Map<int, int>? newRowIndices,
    Map<int, int>? newColumnIndices,
  }) {
    if (newRowIndices != null) {
      _selectedRows.replace(newRowIndices);
      _hoveringRows.replace(newRowIndices);
    }

    if (newColumnIndices != null) {
      _selectedColumns.replace(newColumnIndices);
      _hoveringColumns.replace(newColumnIndices);
    }
  }
}

extension on Set<TableSelectionStrategy> {
  bool get canSelectColumn => contains(TableSelectionStrategy.column);
  bool get canSelectRow => contains(TableSelectionStrategy.row);
  bool get canSelectCell => contains(TableSelectionStrategy.cell);

  bool get canSelect => canSelectColumn || canSelectRow || canSelectCell;
}

extension on Set<TableHoveringStrategy> {
  bool get canHoverRow => contains(TableHoveringStrategy.row);
  bool get canHoverColumn => contains(TableHoveringStrategy.column);

  bool get canHover => canHoverRow || canHoverColumn;
}
