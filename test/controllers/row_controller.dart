import 'package:flutter_test/flutter_test.dart';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/controllers/row_controller.dart';

void main() {
  final keys = List.generate(
    5,
    (index) => RowKey('Row$index'),
  );

  final rows = List.generate(
    5,
    (index) => RowData(
      keys[index],
      data: {
        ColumnKey('Column1'): 'C${index}1',
        ColumnKey('Column2'): 'C${index}2',
      },
    ),
  );

  group("header visibility", () {
    test("only header", () {
      final controller = TableDataController();

      expect(controller.dataCount, equals(0));
      expect(controller.count, equals(1));
      expect(controller.pinnedCount, equals(1));

      controller.setHeaderVisibility(false);

      expect(controller.pinnedCount, equals(0));
    });

    test("header with rows", () {
      final controller = TableDataController(rows: rows);

      expect(controller.dataCount, equals(5));
      expect(controller.count, equals(6));
      expect(controller.pinnedCount, equals(1));

      controller.setHeaderVisibility(false);

      expect(controller.pinnedCount, equals(0));

      controller.pin(RowKey('Row0'));
      expect(controller.pinnedCount, equals(2));
    });
  });

  group("addAll/removeAll", () {
    test("add rows", () {
      final controller = TableDataController();

      expect(controller.dataCount, equals(0));

      controller.addAll(rows);

      expect(controller.dataCount, equals(5));
      expect(controller.orderedRows, orderedEquals(rows));
    });

    test("remove rows", () {
      final controller = TableDataController(rows: rows);

      expect(controller.dataCount, equals(5));

      controller.removeAll([RowKey('Row0'), RowKey('Row1')]);

      expect(controller.dataCount, equals(3));
      expect(
        controller.orderedRows,
        orderedEquals(rows.sublist(2)),
      );
    });
  });

  group("pin/unpin", () {
    test("pin/unpin a row with header always", () {
      final controller = TableDataController(rows: rows);

      expect(controller.pinnedCount, equals(1));

      controller.pin(RowKey('Row0'));

      expect(controller.pinnedCount, equals(2));
      expect(controller.orderedRows.first.key, equals(RowKey('Row0')));

      controller.unpin(RowKey('Row0'));
      expect(controller.pinnedCount, equals(1));
      expect(controller.orderedRows.first.key, equals(RowKey('Row0')));
    });

    test("pin/unpin a row without header always", () {
      final controller =
          TableDataController(rows: rows, alwaysShowHeader: false);

      controller.pin(RowKey('Row0'));
      expect(controller.pinnedCount, equals(2));

      controller.unpin(RowKey('Row0'));

      expect(controller.pinnedCount, equals(0));
      expect(controller.orderedRows.first.key, equals(RowKey('Row0')));
    });
  });

  group("reorder", () {
    test("reorder pinned rows", () {
      final controller = TableDataController(rows: rows);

      controller.pin(RowKey('Row0'));
      controller.pin(RowKey('Row1'));

      expect(controller.pinnedCount, equals(3));

      controller.reorder(RowKey('Row0'), RowKey('Row1'));

      expect(controller.pinnedCount, equals(3));
      expect(controller.orderedRows.first.key, equals(RowKey('Row1')));
    });

    test("reorder non-pinned rows", () {
      final controller = TableDataController(rows: rows);

      controller.reorder(RowKey('Row0'), RowKey('Row1'));

      expect(controller.orderedRows.first.key, equals(RowKey('Row1')));
    });
  });

  group("performSort", () {
    test("sort without new data", () {
      final controller = TableDataController(rows: rows);

      expect(controller.dataCount, equals(5));

      controller.performSort(compare: _compare);

      expect(
        controller.orderedRows,
        orderedEquals(rows.reversed.toList()),
      );
    });

    test("sort with new data", () {
      final controller = TableDataController(rows: rows);

      expect(controller.dataCount, equals(5));

      controller.performSort(
        compare: _compare,
        newRows: [
          RowData(RowKey('Row5'), data: {
            ColumnKey('Column1'): 'C51',
            ColumnKey('Column2'): 'C52',
          }),
        ],
      );

      expect(
        controller.orderedRows,
        orderedEquals([
          RowData(RowKey('Row5'), data: {
            ColumnKey('Column1'): 'C51',
            ColumnKey('Column2'): 'C52',
          }),
          ...rows.reversed,
        ]),
      );
    });
  });

  group("performSearch", () {
    test("keyword", () {
      final controller = TableDataController(rows: rows);

      expect(controller.dataCount, equals(5));

      controller.performSearch(
        keyword: 'C11',
        matcher: _match,
      );

      expect(controller.dataCount, equals(1));
      expect(controller.orderedRows, orderedEquals([rows[1]]));
    });

    test("empty keyword", () {
      final controller = TableDataController(rows: rows);

      expect(controller.dataCount, equals(5));

      controller.performSearch(
        keyword: '',
        matcher: _match,
      );

      expect(controller.dataCount, equals(5));
      expect(controller.orderedRows, orderedEquals(rows));
    });
  });

  group("paginated controller", () {
    test("initial", () {
      final controller = PaginatedTableDataController(pageSize: 2, rows: rows);

      expect(controller.dataCount, equals(5));
      expect(controller.currentPage, equals(1));
      expect(controller.pages, equals(3));
      expect(controller.count, equals(3));
    });

    test("next page", () {
      final controller = PaginatedTableDataController(pageSize: 2, rows: rows);

      expect(controller.dataCount, equals(5));
      expect(controller.currentPage, equals(1));
      expect(controller.pages, equals(3));

      controller.nextPage();

      expect(controller.currentPage, equals(2));
      expect(controller.count, equals(3));
    });

    test("set page size", () {
      final controller = PaginatedTableDataController(pageSize: 2, rows: rows);

      expect(controller.dataCount, equals(5));
      expect(controller.currentPage, equals(1));
      expect(controller.pages, equals(3));

      controller.pageSize = 3;

      expect(controller.dataCount, equals(5));
      expect(controller.currentPage, equals(1));
      expect(controller.pages, equals(2));
      expect(controller.count, equals(4));
    });

    test("perform search", () {
      final controller = PaginatedTableDataController(pageSize: 2, rows: rows);

      controller.performSearch(
        keyword: 'C11',
        matcher: _match,
      );

      expect(controller.dataCount, equals(1));
      expect(controller.currentPage, equals(1));
      expect(controller.pages, equals(1));
      expect(controller.orderedRows, orderedEquals([rows[1]]));
      expect(controller.count, equals(2));
    });
  });
}

bool _match(String keyword, RowData row) {
  return row.data.values.any((value) => value.toString().contains(keyword));
}

int _compare(RowData a, RowData b) {
  return b.data[ColumnKey('Column1')]!.compareTo(a.data[ColumnKey('Column1')]!);
}
