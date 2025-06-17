// import 'package:flutter/widgets.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:simple_table_grid/src/components/coordinator.dart';
// import 'package:simple_table_grid/src/data_source.dart';
// import 'package:simple_table_grid/src/models/key.dart';

// final class _MockTableCoordinator with TableCoordinator {
//   @override
//   void notifyRebuild() {}
// }

// void main() async {
//   final coordinator = _MockTableCoordinator();

//   final columns = [
//     ColumnKey('col1'),
//     ColumnKey('col2'),
//     ColumnKey('col3'),
//   ];

//   final rows = List.generate(
//     10,
//     (index) => RowData(
//       RowKey(UniqueKey()),
//       {
//         for (final column in columns) column: 'Row $index, Column ${column.id}',
//       },
//     ),
//   );

//   group("Test date source normal functionalities", () {
//     final source = TableDataSource(
//       rows: rows,
//       alwaysShowHeader: true,
//     )..bindCoordinator(coordinator);

//     test('Initial row count', () {
//       expect(source.rowCount, 11); // 10 rows + 1 header
//     });

//     test('Data count', () {
//       expect(source.dataCount, 10);
//     });

//     test('Pinned row count', () {
//       expect(source.pinnedRowCount, 1); // Header is pinned
//     });

//     test('Ordered rows', () {
//       final orderedRows = source.orderedRows;
//       expect(orderedRows.length, 10);
//       expect(orderedRows.first.key.id, rows.first.key.id);
//     });

//     test('Reorder rows', () {
//       final firstRowKey = rows.first.key;
//       final lastRowKey = rows.last.key;
//       source.reorderByKey(firstRowKey, lastRowKey);
//       expect(source.orderedRows.last.key, firstRowKey);
//       expect(source.orderedRows.first.key, isNot(firstRowKey));
//     });

//     test('Add rows', () {
//       final newRow = RowData(
//         RowKey(UniqueKey()),
//         {for (final column in columns) column: 'New Row'},
//       );
//       source.add([newRow]);
//       expect(source.dataCount, 11);
//       expect(source.rowCount, 12);
//       expect(source.orderedRows.last.key, newRow.key);
//       expect(source.getRowKey(11), newRow.key);
//     });

//     test('Remove rows', () {
//       final initialCount = source.dataCount;
//       source.removeByKeys([rows.first.key]);
//       expect(source.dataCount, initialCount - 1);
//       expect(source.rowCount, initialCount); // Header remains
//     });
//   });

//   group("Test Date source pin", () {
//     final source = TableDataSource(
//       rows: rows,
//       alwaysShowHeader: true,
//     )..bindCoordinator(coordinator);

//     test('Pin row', () {
//       final rowKey = rows.last.key;
//       source.pinByKey(rowKey);
//       expect(source.pinnedRowCount, 2); // Header + pinned row
//       expect(source.orderedRows.first.key, rowKey);
//     });

//     test('Unpin row', () {
//       final rowKey = rows.last.key;
//       source.unpinByKey(rowKey);
//       expect(source.pinnedRowCount, 1); // Only header remains pinned
//       expect(source.orderedRows.first.key, rowKey);
//     });
//   });
// }
