// import 'package:simple_table_grid/simple_table_grid.dart';

// base mixin ExtentDelegateMixin on TableController {
//   ExtentManager get extentManager;

//   @override
//   Extent getRowExtent(int index) {
//     return extentManager.getRowExtent(index);
//   }

//   @override
//   Extent getColumnExtent(ColumnKey key) {
//     return extentManager.getColumnExtent(key);
//   }

//   void setRowExtent(int index, Extent extent) {
//     extentManager.setRowExtent(index, extent);
//   }

//   void setColumnExtent(ColumnKey columnId, Extent extent) {
//     extentManager.setColumnExtent(columnId, extent);
//   }

//   @override
//   void setResizeTarget(ResizeTarget? target) {
//     extentManager.setResizeTarget(target);
//   }

//   @override
//   void resize(double delta) {
//     extentManager.resize(delta);
//   }

//   @override
//   Map<ColumnKey, Extent> get columnExtents {
//     return extentManager.columnExtents;
//   }

//   @override
//   Map<int, Extent> get rowExtents {
//     return extentManager.rowExtents;
//   }
// }

// base mixin TableFocusDelegateMixin on TableController {
//   TableFocusManager get focusManager;

//   @override
//   void hoverOn({RowKey? row, ColumnKey? column}) {
//     focusManager.hoverOn(row: row, column: column);
//   }

//   @override
//   void hoverOff({RowKey? row, ColumnKey? column}) {
//     focusManager.hoverOff(row: row, column: column);
//   }

//   @override
//   void select({
//     List<RowKey>? rows,
//     List<ColumnKey>? columns,
//     List<CellKey>? cells,
//   }) {
//     focusManager.select(
//       rows: rows,
//       columns: columns,
//       cells: cells,
//     );
//   }

//   @override
//   void unselect({
//     List<RowKey>? rows,
//     List<ColumnKey>? columns,
//     List<CellKey>? cells,
//   }) {
//     focusManager.unselect(
//       rows: rows,
//       columns: columns,
//       cells: cells,
//     );
//   }
// }

// base mixin TableDataSourceDelegateMixin on TableController {
//   TableDataSource get dataSource;

//   @override
//   void addRows(
//     List<RowData> rows, {
//     bool skipDuplicates = false,
//     bool removePlaceholder = true,
//   }) {
//     dataSource.add(rows);
//   }

//   @override
//   void removeRows(List<RowKey> rows) {
//     dataSource.removeByKeys(rows);
//   }

//   @override
//   void reorderRow(RowKey from, RowKey to) {
//     dataSource.reorderByKey(from, to);
//   }

//   @override
//   void pinRow(RowKey key) {
//     dataSource.pinByKey(key);
//   }

//   @override
//   void unpinRow(RowKey key) {
//     dataSource.unpinByKey(key);
//   }

//   @override
//   void toggleHeaderVisibility(bool alwaysShowHeader) {
//     dataSource.alwaysShowHeader = alwaysShowHeader;
//   }

//   @override
//   int get rowCount => dataSource.rowCount;

//   @override
//   int get pinnedRowCount => dataSource.pinnedRowCount;

//   @override
//   int get dataCount => dataSource.dataCount;

//   @override
//   RowKey getRowKey(int index) {
//     return dataSource.getRowKey(index);
//   }

//   @override
//   RowKey? previousRow(RowKey key) {
//     return dataSource.previousRow(key);
//   }

//   @override
//   RowKey? nextRow(RowKey key) {
//     return dataSource.nextRow(key);
//   }

//   @override
//   int? getRowIndex(RowKey key) {
//     return dataSource.getRowIndex(key);
//   }
// }
