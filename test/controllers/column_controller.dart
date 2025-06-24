import 'package:flutter_test/flutter_test.dart';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/controllers/column_controller.dart';

void main() {
  final pinned = List.generate(2, (index) => ColumnKey('Pinned$index'));
  final nonPinned = List.generate(3, (index) => ColumnKey('NonPinned$index'));

  group("addAll", () {
    test("addAll without preset pinned", () {
      final controller = TableHeaderController(null, null);

      expect(controller.pinnedCount, equals(0));
      expect(controller.count, equals(0));

      controller.addAll(nonPinned);
      expect(controller.pinnedCount, equals(0));
      expect(controller.count, equals(3));

      expect(
          controller.ordered,
          orderedEquals([
            ...nonPinned,
          ]));
    });

    test("addAll with preset pinned", () {
      final controller = TableHeaderController(null, pinned);

      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(2));

      controller.addAll(nonPinned);
      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(5));

      expect(
          controller.ordered,
          orderedEquals([
            ...pinned,
            ...nonPinned,
          ]));
    });
  });

  group("removeAll", () {
    test("removeAll without preset pinned", () {
      final controller = TableHeaderController(nonPinned, null);

      expect(controller.pinnedCount, equals(0));
      expect(controller.count, equals(3));

      controller.removeAll(nonPinned);
      expect(controller.pinnedCount, equals(0));
      expect(controller.count, equals(0));
    });

    test("removeAll with preset pinned", () {
      final controller = TableHeaderController(nonPinned, pinned);

      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(5));

      controller.removeAll(nonPinned);
      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(2));

      controller.removeAll(pinned);
      expect(controller.pinnedCount, equals(0));
      expect(controller.count, equals(0));
    });
  });

  group("pin/unpin", () {
    test("pin a column", () {
      final controller = TableHeaderController(nonPinned, null);

      expect(controller.pinnedCount, equals(0));
      expect(controller.count, equals(3));

      controller.pin(ColumnKey('NonPinned1'));
      expect(controller.pinnedCount, equals(1));
      expect(controller.count, equals(3));
      expect(controller.ordered.first, equals(ColumnKey('NonPinned1')));
    });

    test("unpin a column", () {
      final controller = TableHeaderController(nonPinned, pinned);

      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(5));

      controller.unpin(ColumnKey('Pinned0'));
      expect(controller.pinnedCount, equals(1));
      expect(controller.count, equals(5));
      expect(controller.ordered.first, equals(ColumnKey('Pinned1')));
      expect(
          controller.ordered,
          orderedEquals(
            [
              ColumnKey('Pinned1'),
              ColumnKey("Pinned0"),
              ...nonPinned,
            ],
          ));
    });
  });

  group("reorder", () {
    test("reorder pinned columns", () {
      final controller = TableHeaderController(nonPinned, pinned);

      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(5));

      controller.reorder(ColumnKey('Pinned0'), ColumnKey('Pinned1'));
      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(5));
      expect(
          controller.ordered,
          orderedEquals([
            ColumnKey('Pinned1'),
            ColumnKey('Pinned0'),
            ...nonPinned,
          ]));
    });

    test("reorder non-pinned columns", () {
      final controller = TableHeaderController(nonPinned, pinned);

      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(5));

      controller.reorder(ColumnKey('NonPinned0'), ColumnKey('NonPinned1'));
      expect(controller.pinnedCount, equals(2));
      expect(controller.count, equals(5));
      expect(
          controller.ordered,
          orderedEquals([
            ...pinned,
            ColumnKey('NonPinned1'),
            ColumnKey('NonPinned0'),
            ColumnKey('NonPinned2'),
          ]));
    });
  });

  group("index", () {
    final controller = TableHeaderController(nonPinned, pinned);

    test("index of pinned column", () {
      expect(controller.previous(pinned[1]), equals(pinned[0]));
      expect(controller.next(pinned[0]), equals(pinned[1]));
    });

    test("index of non-pinned column", () {
      expect(controller.previous(nonPinned[1]), equals(nonPinned[0]));
      expect(controller.next(nonPinned[0]), equals(nonPinned[1]));
    });

    test("index of crossed area", () {
      expect(controller.previous(nonPinned[0]), equals(pinned[1]));
      expect(controller.next(pinned[1]), equals(nonPinned[0]));
    });

    test("getColumnKey by index", () {
      expect(controller.getColumnKey(0), equals(pinned[0]));
      expect(controller.getColumnKey(1), equals(pinned[1]));
      expect(controller.getColumnKey(2), equals(nonPinned[0]));
      expect(controller.getColumnKey(3), equals(nonPinned[1]));
      expect(controller.getColumnKey(4), equals(nonPinned[2]));
    });

    test("getColumnIndex by key", () {
      expect(controller.getColumnIndex(pinned[0]), equals(0));
      expect(controller.getColumnIndex(pinned[1]), equals(1));
      expect(controller.getColumnIndex(nonPinned[0]), equals(2));
      expect(controller.getColumnIndex(nonPinned[1]), equals(3));
      expect(controller.getColumnIndex(nonPinned[2]), equals(4));
    });
  });
}
