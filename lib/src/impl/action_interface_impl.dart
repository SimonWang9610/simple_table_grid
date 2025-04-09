import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/components/action_manager.dart';
import 'package:simple_table_grid/src/components/coordinator.dart';
import 'package:simple_table_grid/src/controller.dart';
import 'package:simple_table_grid/src/models/cell_index.dart';
import 'package:simple_table_grid/src/models/misc.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

base mixin TableActionImplMixin on TableController, TableCoordinator {
  @protected
  ActionManager get actionManager;

  @override
  void updateStrategies({
    List<TableSelectionStrategy>? selectionStrategies,
    List<TableHoveringStrategy>? hoveringStrategies,
  }) {
    bool shouldNotify = false;

    if (selectionStrategies != null) {
      shouldNotify |=
          actionManager.updateSelectionStrategy(selectionStrategies);
    }

    if (hoveringStrategies != null) {
      shouldNotify |= actionManager.updateHoveringStrategy(hoveringStrategies);
    }

    if (shouldNotify) {
      notifyRebuild();
    }
  }

  @override
  void select({
    List<int>? rows,
    List<int>? columns,
    List<CellIndex>? cells,
  }) {
    final vicinityRows = rows?.map((row) => toVicinityRow(row));
    final vicinityColumns = columns?.map((column) => column);
    final vicinityCells = cells?.map(
      (cell) => CellIndex(
        toVicinityRow(cell.row),
        cell.column,
      ),
    );

    assert(
      () {
        if (vicinityRows != null) {
          return vicinityRows.every((r) => r < rowCount);
        }

        if (vicinityColumns != null) {
          return vicinityColumns.every((c) => c < columnCount);
        }

        if (vicinityCells != null) {
          return vicinityCells
              .every((c) => c.row < rowCount && c.column < columnCount);
        }

        return true;
      }(),
      "Provided row/column/cell indices are out of range",
    );

    actionManager.select(
      rows: vicinityRows?.where((row) => row < rowCount),
      columns: vicinityColumns?.where((column) => column < columnCount),
      cells: vicinityCells?.where(
        (cell) => cell.row < rowCount && cell.column < columnCount,
      ),
    );
  }

  @override
  void unselect({
    List<int>? rows,
    List<int>? columns,
    List<CellIndex>? cells,
  }) {
    final vicinityRows = rows?.map((row) => toVicinityRow(row));
    final vicinityColumns = columns?.map((column) => column);
    final vicinityCells = cells?.map(
      (cell) => CellIndex(
        toVicinityRow(cell.row),
        cell.column,
      ),
    );
    actionManager.unselect(
      rows: vicinityRows?.where((row) => row < rowCount),
      columns: vicinityColumns?.where((column) => column < columnCount),
      cells: vicinityCells?.where(
        (cell) => cell.row < rowCount && cell.column < columnCount,
      ),
    );
  }

  @override
  void hoverOn({int? row, int? column}) {
    actionManager.hoverOn(
      row: row != null ? toVicinityRow(row) : null,
      column: column,
    );
  }

  @override
  void hoverOff({int? row, int? column}) {
    actionManager.hoverOff(
      row: row != null ? toVicinityRow(row) : null,
      column: column,
    );
  }

  @override
  bool isCellSelected(int row, int column) {
    return actionManager.isCellSelected(
      toVicinityRow(row),
      column,
    );
  }

  @override
  bool isCellHovered(int row, int column) {
    return actionManager.isCellHovering(
      toVicinityRow(row),
      column,
    );
  }

  @override
  Listenable? getCellActionNotifier(TableVicinity vicinity) {
    return actionManager.getCellActionNotifier(vicinity.row, vicinity.column);
  }
}
