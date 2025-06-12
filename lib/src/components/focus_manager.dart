import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/table_focus_controller.dart';

final class TableFocusManager with TableCoordinatorMixin {
  final _selectedRows = LineFocusController<RowKey>();
  final _selectedColumns = LineFocusController<ColumnKey>();
  final _selectedCells = CellFocusController();

  final _hoveringRows = LineFocusController<RowKey>();
  final _hoveringColumns = LineFocusController<ColumnKey>();

  final Set<FocusStrategy> _selectionStrategies = {};
  final Set<FocusStrategy> _hoveringStrategies = {};

  TableFocusManager({
    List<FocusStrategy>? selectionStrategies,
    List<FocusStrategy>? hoveringStrategies,
  }) {
    if (selectionStrategies != null) {
      updateSelectionStrategy(selectionStrategies);
    }

    if (hoveringStrategies != null) {
      updateHoveringStrategy(hoveringStrategies);
    }
  }

  bool updateSelectionStrategy(
    List<FocusStrategy> strategies,
  ) {
    final updated = !_selectionStrategies.containsAll(strategies);

    _selectionStrategies.clear();
    _selectionStrategies.addAll(strategies);

    final hasAnySelection = _selectedRows.focused.isNotEmpty ||
        _selectedColumns.focused.isNotEmpty ||
        _selectedCells.focused.isNotEmpty;

    return updated && hasAnySelection;
  }

  bool updateHoveringStrategy(
    List<FocusStrategy> strategies,
  ) {
    final updated = !_hoveringStrategies.containsAll(strategies);

    _hoveringStrategies.clear();
    _hoveringStrategies.addAll(strategies);

    final hasAnyHovering =
        _hoveringRows.focused.isNotEmpty || _hoveringColumns.focused.isNotEmpty;

    return updated && hasAnyHovering;
  }

  void select({
    Iterable<RowKey>? rows,
    Iterable<ColumnKey>? columns,
    Iterable<CellKey>? cells,
  }) {
    if (cells != null && _selectionStrategies.canSelectCell) {
      _selectedCells.focusAll(cells);
    }

    if (columns != null && _selectionStrategies.canSelectColumn) {
      _selectedColumns.focusAll(columns);
    }

    if (rows != null && _selectionStrategies.canSelectRow) {
      _selectedRows.focusAll(rows);
    }
  }

  void unselect({
    Iterable<RowKey>? rows,
    Iterable<ColumnKey>? columns,
    Iterable<CellKey>? cells,
    bool shouldNotify = true,
  }) {
    if (cells != null) {
      _selectedCells.unfocusAll(
        cells,
        shouldNotify: shouldNotify,
      );
    }

    if (columns != null) {
      _selectedColumns.unfocusAll(
        columns,
        shouldNotify: shouldNotify,
      );
    }

    if (rows != null) {
      _selectedRows.unfocusAll(
        rows,
        shouldNotify: shouldNotify,
      );
    }
  }

  void hoverOn({RowKey? row, ColumnKey? column}) {
    if (row != null && _hoveringStrategies.canHoverRow) {
      _hoveringRows.focus(row);
    }

    if (column != null && _hoveringStrategies.canHoverColumn) {
      _hoveringColumns.focus(column);
    }
  }

  void hoverOff({RowKey? row, ColumnKey? column}) {
    if (row != null) {
      _hoveringRows.unfocus(row);
    }

    if (column != null) {
      _hoveringColumns.unfocus(column);
    }
  }

  bool isCellSelected(RowKey row, ColumnKey column) {
    return _selectionStrategies.canSelect
        ? _selectedCells.isFocused(CellKey(row, column)) ||
            isColumnSelected(column) ||
            isRowSelected(row)
        : false;
  }

  bool isCellHovering(RowKey row, ColumnKey column) {
    return _hoveringStrategies.canHover
        ? isRowHovering(row) || isColumnHovering(column)
        : false;
  }

  bool isColumnSelected(ColumnKey column) {
    return _selectionStrategies.canSelectColumn
        ? _selectedColumns.isFocused(column)
        : false;
  }

  bool isRowSelected(RowKey row) {
    return _selectionStrategies.canSelectRow
        ? _selectedRows.isFocused(row)
        : false;
  }

  bool isRowHovering(RowKey row) {
    return _hoveringStrategies.canHoverRow
        ? _hoveringRows.isFocused(row)
        : false;
  }

  bool isColumnHovering(ColumnKey column) {
    return _hoveringStrategies.canHoverColumn
        ? _hoveringColumns.isFocused(column)
        : false;
  }

  Listenable? get cellFocusNotifier {
    final notifiers = <Listenable>[];

    if (_selectionStrategies.canSelectCell) {
      notifiers.add(_selectedCells);
    }

    if (_selectionStrategies.canSelectColumn) {
      notifiers.add(_selectedColumns);
    }

    if (_selectionStrategies.canSelectRow) {
      notifiers.add(_selectedRows);
    }

    if (_hoveringStrategies.canHoverRow) {
      notifiers.add(_hoveringRows);
    }

    if (_hoveringStrategies.canHoverColumn) {
      notifiers.add(_hoveringColumns);
    }

    return notifiers.isNotEmpty ? Listenable.merge(notifiers) : null;
  }

  Listenable? get columnFocusNotifier {
    final notifiers = <Listenable>[];

    if (_selectionStrategies.canSelectColumn) {
      notifiers.add(_selectedColumns);
    }

    if (_hoveringStrategies.canHoverColumn) {
      notifiers.add(_hoveringColumns);
    }

    return notifiers.isNotEmpty ? Listenable.merge(notifiers) : null;
  }

  @override
  void dispose() {
    _selectedRows.dispose();
    _selectedColumns.dispose();
    _selectedCells.dispose();
    _hoveringRows.dispose();
    _hoveringColumns.dispose();
    super.dispose();
  }
}

extension on Set<FocusStrategy> {
  bool get canSelectColumn => contains(FocusStrategy.column);
  bool get canSelectRow => contains(FocusStrategy.row);
  bool get canSelectCell => contains(FocusStrategy.cell);

  bool get canHoverRow => contains(FocusStrategy.row);
  bool get canHoverColumn => contains(FocusStrategy.column);

  bool get canHover => canHoverRow || canHoverColumn;

  bool get canSelect => canSelectColumn || canSelectRow || canSelectCell;
}
