// import 'package:simple_table_grid/simple_table_grid.dart';

// class TableDynamicExtentMeasurer {
//   final TableIndexFinder finder;

//   TableDynamicExtentMeasurer(this.finder);

//   final _measuredRowExtents = _RowExtentMeasurement();
//   final _measuredColumnExtents = _ColumnExtentMeasurement();

//   void updateMeasuredRowExtent(int rowIndex, Extent extent) {
//     assert(extent.isMeasured, 'Extent must be measured.');
//     _measuredRowExtents.update(finder.getRowKey(rowIndex), extent);
//   }

//   void updateMeasuredColumnExtent(int columnIndex, Extent extent) {
//     assert(extent.isMeasured, 'Extent must be measured.');
//     _measuredColumnExtents.update(finder.getColumnKey(columnIndex), extent);
//   }

//   void dispose() {
//     _measuredRowExtents.evictAll();
//     _measuredColumnExtents.evictAll();
//   }
// }

// class _RowExtentMeasurement {
//   final Map<RowKey, Extent> _measuredRowExtents = {};

//   Extent? _measureHeaderRowExtent;

//   void update(RowKey? rowKey, Extent extent) {
//     if (rowKey == null) {
//       _measureHeaderRowExtent = extent;
//     } else {
//       _measuredRowExtents[rowKey] = extent;
//     }
//   }

//   Extent? get(RowKey? rowKey) {
//     if (rowKey == null) {
//       return _measureHeaderRowExtent;
//     }

//     return _measuredRowExtents[rowKey];
//   }

//   void evict(RowKey? rowKey) {
//     Extent? evicted;

//     if (rowKey == null) {
//       evicted = _measureHeaderRowExtent;
//       _measureHeaderRowExtent = null;
//     } else {
//       evicted = _measuredRowExtents.remove(rowKey);
//     }

//     evicted?.reset();
//   }

//   void evictAll() {
//     evict(null);

//     for (final rowKey in _measuredRowExtents.keys.toList()) {
//       evict(rowKey);
//     }
//   }
// }

// class _ColumnExtentMeasurement {
//   final Map<ColumnKey, Extent> _measuredColumnExtents = {};

//   void update(ColumnKey columnKey, Extent extent) {
//     _measuredColumnExtents[columnKey] = extent;
//   }

//   Extent? get(ColumnKey columnKey) {
//     return _measuredColumnExtents[columnKey];
//   }

//   void evict(ColumnKey columnKey) {
//     final extent = _measuredColumnExtents.remove(columnKey);
//     extent?.reset();
//   }

//   void evictAll() {
//     for (final columnKey in _measuredColumnExtents.keys.toList()) {
//       evict(columnKey);
//     }
//   }
// }
