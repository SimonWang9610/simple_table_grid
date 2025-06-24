import 'package:flutter_test/flutter_test.dart';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/focus_controller.dart';

void main() {
  test("focus", () {
    final controller = KeyFocuser<RowKey>(
      focusedLines: [
        RowKey("Row1"),
        RowKey("Row2"),
      ],
    );

    expect(controller.focused, contains(RowKey("Row1")));
    expect(controller.focused, contains(RowKey("Row2")));
    expect(controller.focused, hasLength(2));

    controller.focus(RowKey("Row3"));
    expect(controller.focused, contains(RowKey("Row3")));

    expect(controller.isFocused(RowKey("Row2")), isTrue);
  });

  test(
    "unfocus",
    () {
      final controller = KeyFocuser<RowKey>(
        focusedLines: [
          RowKey("Row1"),
          RowKey("Row2"),
        ],
      );

      expect(controller.focused, contains(RowKey("Row1")));
      expect(controller.focused, contains(RowKey("Row2")));

      controller.unfocus(RowKey("Row1"));
      expect(controller.focused, isNot(contains(RowKey("Row1"))));
      expect(controller.focused, contains(RowKey("Row2")));

      controller.unfocusAll([RowKey("Row2")]);
      expect(controller.focused, isEmpty);
    },
  );

  test("focus (CellKey)", () {
    final controller = KeyFocuser<CellKey>(
      focusedLines: [
        CellKey(RowKey("Row1"), ColumnKey("Column1")),
        CellKey(RowKey("Row2"), ColumnKey("Column2")),
      ],
    );

    expect(controller.focused,
        contains(CellKey(RowKey("Row1"), ColumnKey("Column1"))));
    expect(controller.focused,
        contains(CellKey(RowKey("Row2"), ColumnKey("Column2"))));
    expect(controller.focused, hasLength(2));

    controller.focus(CellKey(RowKey("Row3"), ColumnKey("Column3")));
    expect(controller.focused,
        contains(CellKey(RowKey("Row3"), ColumnKey("Column3"))));

    expect(controller.isFocused(CellKey(RowKey("Row2"), ColumnKey("Column2"))),
        isTrue);
  });

  test("unfocus (CellKey)", () {
    final controller = KeyFocuser<CellKey>(
      focusedLines: [
        CellKey(RowKey("Row1"), ColumnKey("Column1")),
        CellKey(RowKey("Row2"), ColumnKey("Column2")),
      ],
    );

    expect(controller.focused,
        contains(CellKey(RowKey("Row1"), ColumnKey("Column1"))));
    expect(controller.focused,
        contains(CellKey(RowKey("Row2"), ColumnKey("Column2"))));

    controller.unfocus(CellKey(RowKey("Row1"), ColumnKey("Column1")));
    expect(controller.focused,
        isNot(contains(CellKey(RowKey("Row1"), ColumnKey("Column1")))));
    expect(controller.focused,
        contains(CellKey(RowKey("Row2"), ColumnKey("Column2"))));

    controller.unfocusAll([
      CellKey(RowKey("Row2"), ColumnKey("Column2")),
    ]);
    expect(controller.focused, isEmpty);
  });
}
