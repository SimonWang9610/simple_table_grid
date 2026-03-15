import 'package:flutter_test/flutter_test.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

void main() {
  final firstColumn = ColumnKey('c1');
  final secondColumn = ColumnKey('c2');
  final firstRow = RowKey('r1');

  TableController createController() {
    return TableController(
      columns: [
        HeaderData(key: firstColumn, data: 'Column 1'),
        HeaderData(key: secondColumn, data: 'Column 2'),
      ],
      initialRows: [
        RowData(
          firstRow,
          data: {
            firstColumn: 'A',
            secondColumn: 'B',
          },
        ),
      ],
      defaultRowExtent: Extent.ranged(min: 10, max: 120, pixels: 30),
      defaultColumnExtent: Extent.ranged(min: 40, max: 300, pixels: 100),
    );
  }

  group('reset notifications', () {
    test('resetColumnExtent notifies only when cache changes', () {
      final controller = createController();
      int notified = 0;

      controller.sizer.addListener(() {
        notified++;
      });

      controller.sizer.getColumnExtent(0);
      controller.sizer.resetColumnExtent(firstColumn);
      expect(notified, 1);

      controller.sizer.resetColumnExtent(firstColumn);
      expect(notified, 1);

      controller.dispose();
    });

    test('resetRowExtent notifies only when cache changes', () {
      final controller = createController();
      int notified = 0;

      controller.sizer.addListener(() {
        notified++;
      });

      controller.sizer.getRowExtent(1);
      controller.sizer.resetRowExtent(index: 1);
      expect(notified, 1);

      controller.sizer.resetRowExtent(index: 1);
      expect(notified, 1);

      controller.dispose();
    });

    test('resetAllExtents notifies only when state changes', () {
      final controller = createController();
      int notified = 0;

      controller.sizer.addListener(() {
        notified++;
      });

      controller.sizer.resetAllExtents();
      expect(notified, 0);

      controller.sizer.getRowExtent(0);
      controller.sizer.getRowExtent(1);
      controller.sizer.getColumnExtent(0);

      controller.sizer.resetAllExtents();
      expect(notified, 1);

      controller.dispose();
    });
  });

  group('stale resize target hardening', () {
    test('resizing removed row target does not mutate header extent', () {
      final controller = createController();

      final beforeHeaderMin = controller.sizer.getRowExtent(0).range.$1;

      controller.rows.remove(firstRow);
      controller.sizer.setResizeTarget(
        ResizeTarget(key: firstRow, direction: ResizeDirection.down),
      );
      controller.sizer.resize(20);

      final afterHeaderMin = controller.sizer.getRowExtent(0).range.$1;

      expect(afterHeaderMin, beforeHeaderMin);

      controller.dispose();
    });

    test('resizing up on first data row does not resize header row', () {
      final controller = createController();

      final beforeHeaderMin = controller.sizer.getRowExtent(0).range.$1;

      controller.sizer.setResizeTarget(
        ResizeTarget(key: firstRow, direction: ResizeDirection.up),
      );
      controller.sizer.resize(20);

      final afterHeaderMin = controller.sizer.getRowExtent(0).range.$1;

      expect(afterHeaderMin, beforeHeaderMin);

      controller.dispose();
    });

    test('resizing removed column target does not mutate other columns', () {
      final controller = createController();

      final beforeSecond = controller.sizer.getColumnExtent(1).range.$1;

      controller.columns.remove(firstColumn);
      controller.sizer.setResizeTarget(
        ResizeTarget(key: firstColumn, direction: ResizeDirection.right),
      );
      controller.sizer.resize(20);

      final afterSecond = controller.sizer.getColumnExtent(0).range.$1;

      expect(afterSecond, beforeSecond);

      controller.dispose();
    });
  });
}