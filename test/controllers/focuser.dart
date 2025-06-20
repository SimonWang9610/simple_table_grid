import 'package:flutter_test/flutter_test.dart';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/controllers/focuser.dart';

void main() {
  final rows = List.generate(2, (index) => RowKey('Row$index'));
  final columns = List.generate(2, (index) => ColumnKey('Column$index'));

  group("focus column", () {
    test("hover on column", () {
      final controller =
          TableFocusController(hoveringStrategies: [FocusStrategy.column]);

      controller.hoverOn(column: columns[0]);

      expect(controller.isColumnHovering(columns[0]), isTrue);
      expect(controller.isColumnHovering(columns[1]), isFalse);
    });

    test("hover off column", () {
      final controller =
          TableFocusController(hoveringStrategies: [FocusStrategy.column]);
      controller.hoverOn(column: columns[0]);
      controller.hoverOff(column: columns[0]);

      expect(controller.isColumnHovering(columns[0]), isFalse);
    });

    test("select column", () {
      final controller =
          TableFocusController(selectionStrategies: [FocusStrategy.column]);
      controller.select(columns: [columns[0]]);

      expect(controller.isColumnSelected(columns[0]), isTrue);
      expect(controller.isColumnSelected(columns[1]), isFalse);
    });

    test("unselect column", () {
      final controller =
          TableFocusController(selectionStrategies: [FocusStrategy.column]);
      controller.select(columns: [columns[0]]);
      controller.unselect(columns: [columns[0]]);

      expect(controller.isColumnSelected(columns[0]), isFalse);
      expect(controller.isColumnSelected(columns[1]), isFalse);
    });

    test("strategy disabled", () {
      final controller = TableFocusController();

      controller.hoverOn(column: columns[0]);
      controller.select(columns: [columns[0]]);

      expect(controller.isColumnHovering(columns[0]), isFalse);
      expect(controller.isColumnSelected(columns[0]), isFalse);
    });
  });

  group("focus row", () {
    test("hover on row", () {
      final controller =
          TableFocusController(hoveringStrategies: [FocusStrategy.row]);

      controller.hoverOn(row: rows[0]);

      expect(controller.isRowHovering(rows[0]), isTrue);
      expect(controller.isRowHovering(rows[1]), isFalse);
    });

    test("hover off row", () {
      final controller =
          TableFocusController(hoveringStrategies: [FocusStrategy.row]);
      controller.hoverOn(row: rows[0]);
      controller.hoverOff(row: rows[0]);

      expect(controller.isRowHovering(rows[0]), isFalse);
    });

    test("select row", () {
      final controller =
          TableFocusController(selectionStrategies: [FocusStrategy.row]);
      controller.select(rows: [rows[0]]);

      expect(controller.isRowSelected(rows[0]), isTrue);
      expect(controller.isRowSelected(rows[1]), isFalse);
    });

    test("unselect row", () {
      final controller =
          TableFocusController(selectionStrategies: [FocusStrategy.row]);
      controller.select(rows: [rows[0]]);
      controller.unselect(rows: [rows[0]]);

      expect(controller.isRowSelected(rows[0]), isFalse);
      expect(controller.isRowSelected(rows[1]), isFalse);
    });

    test("strategy disabled", () {
      final controller = TableFocusController();

      controller.hoverOn(row: rows[0]);
      controller.select(rows: [rows[0]]);

      expect(controller.isRowHovering(rows[0]), isFalse);
      expect(controller.isRowSelected(rows[0]), isFalse);
    });
  });

  group("focus cell", () {
    test("select cell", () {
      final controller = TableFocusController(
        selectionStrategies: [FocusStrategy.cell],
      );
      controller.select(cells: [
        CellKey(rows[0], columns[0]),
      ]);

      expect(
        controller.isCellSelected(rows[0], columns[0]),
        isTrue,
      );
      expect(
        controller.isCellSelected(rows[1], columns[1]),
        isFalse,
      );
    });

    test("unselect cell", () {
      final controller = TableFocusController(
        selectionStrategies: [FocusStrategy.cell],
      );
      controller.select(cells: [
        CellKey(rows[0], columns[0]),
      ]);
      controller.unselect(cells: [
        CellKey(rows[0], columns[0]),
      ]);

      expect(
        controller.isCellSelected(rows[0], columns[0]),
        isFalse,
      );
    });

    test("strategy disabled", () {
      final controller = TableFocusController();

      controller.hoverOn(row: rows[0], column: columns[0]);
      controller.select(rows: [
        rows[0]
      ], columns: [
        columns[0]
      ], cells: [
        CellKey(rows[0], columns[0]),
      ]);

      expect(
        controller.isCellHovering(rows[0], columns[0]),
        isFalse,
      );
      expect(
        controller.isCellSelected(rows[0], columns[0]),
        isFalse,
      );
    });
  });
}
