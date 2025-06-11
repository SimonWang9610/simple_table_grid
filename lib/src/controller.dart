import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/table_grid_view.dart';
import 'package:simple_table_grid/src/components/column_manager.dart';
import 'package:simple_table_grid/src/components/coordinator.dart';
import 'package:simple_table_grid/src/components/extent_manager.dart';
import 'package:simple_table_grid/src/components/focus_manager.dart';
import 'package:simple_table_grid/src/data_source.dart';
import 'package:simple_table_grid/src/impl/column_interface_impl.dart';
import 'package:simple_table_grid/src/impl/data_source_interface_impl.dart';
import 'package:simple_table_grid/src/models/cell_detail.dart';
import 'package:simple_table_grid/src/models/cell_index.dart';
import 'package:simple_table_grid/src/models/key.dart';
import 'package:simple_table_grid/src/models/table_grid_border.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

abstract base class TableController with ChangeNotifier {
  TableController._();

  factory TableController({
    required List<ColumnKey> columns,
    required TableExtentManager extentManager,
    List<RowData> initialRows = const [],
    bool alwaysShowHeader = true,
    List<FocusStrategy> selectionStrategies = const [FocusStrategy.row],
    List<FocusStrategy> hoveringStrategies = const [FocusStrategy.row],
  }) =>
      _TableControllerImpl(
        columns: columns,
        extentManager: extentManager,
        initialRows: initialRows,
        alwaysShowHeader: alwaysShowHeader,
        selectionStrategies: selectionStrategies,
        hoveringStrategies: hoveringStrategies,
      );

  void updateStrategies({
    List<FocusStrategy>? selectionStrategies,
    List<FocusStrategy>? hoveringStrategies,
  });

  void select({
    List<RowKey>? rows,
    List<ColumnKey>? columns,
    List<CellKey>? cells,
  });
  void unselect({
    List<RowKey>? rows,
    List<ColumnKey>? columns,
    List<CellKey>? cells,
  });

  void hoverOn({RowKey? row, ColumnKey? column});
  void hoverOff({RowKey? row, ColumnKey? column});
  Listenable? getCellFocusNotifier(ChildVicinity vicinity);

  // bool isCellSelected(CellKey key);
  // bool isCellHovering(CellKey key);

  int get columnCount;
  int get pinnedColumnCount;
  void reorderColumn(ColumnKey id, int to);
  void addColumn(ColumnKey column, {bool pinned = false});
  void removeColumn(ColumnKey id);
  void pinColumn(ColumnKey id);
  void unpinColumn(ColumnKey id);
  bool isColumnHeader(int vicinityRow);

  int get rowCount;
  int get pinnedRowCount;
  int get dataCount;

  void addRows(
    List<RowData> rows, {
    bool skipDuplicates = false,
    bool removePlaceholder = true,
  });
  void removeRows(
    List<int> rows, {
    bool showPlaceholder = false,
  });
  void reorderRow(int fromDataIndex, int toDataIndex);
  void pinRow(int dataIndex);
  void unpinRow(int dataIndex);

  void toggleHeaderVisibility(bool alwaysShowHeader);

  // Listenable get listenable;
  List<ColumnKey> get orderedColumns;

  TableSpan buildRowSpan(int index, TableGridBorder border);
  TableSpan buildColumnSpan(int index, TableGridBorder border);

  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity);
  CellIndex getCellIndex(ChildVicinity vicinity);

  int toVicinityRow(int row);

  set extentManager(TableExtentManager value);
}

final class _TableControllerImpl extends TableController
    with TableCoordinator, TableColumnImplMixin, TableDataSourceImplMixin {
  _TableControllerImpl({
    required List<ColumnKey> columns,
    required TableExtentManager extentManager,
    List<RowData> initialRows = const [],
    bool alwaysShowHeader = true,
    List<FocusStrategy> selectionStrategies = const [FocusStrategy.row],
    List<FocusStrategy> hoveringStrategies = const [FocusStrategy.row],
  })  : _extentManager = extentManager,
        super._() {
    focusManager = TableFocusManager(
      hoveringStrategies: hoveringStrategies,
      selectionStrategies: selectionStrategies,
    )..bindCoordinator(this);

    dataSource = TableDataSource(
      alwaysShowHeader: alwaysShowHeader,
    )
      ..bindCoordinator(this)
      ..add(initialRows);

    columnManager = TableColumnManager(columns)..bindCoordinator(this);

    _extentManager.bindCoordinator(this);
  }

  late final TableFocusManager focusManager;

  @override
  late final TableDataSource dataSource;

  @override
  late final TableColumnManager columnManager;

  TableExtentManager _extentManager;

  @override
  set extentManager(TableExtentManager value) {
    if (_extentManager == value) return;
    _extentManager.dispose();
    _extentManager = value;
    _extentManager.bindCoordinator(this);
    notifyRebuild();
  }

  @override
  @protected
  void notifyRebuild() {
    notifyListeners();
  }

  @override
  void dispose() {
    _extentManager.dispose();
    dataSource.dispose();
    columnManager.dispose();
    focusManager.dispose();
    super.dispose();
  }

  @override
  bool isColumnHeader(int vicinityRow) {
    return dataSource.alwaysShowHeader ? vicinityRow == 0 : false;
  }

  @override
  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity) {
    final columnKey = orderedColumns[vicinity.column];
    final isPinned = vicinity.column < pinnedColumnCount;

    if (isColumnHeader(vicinity.row)) {
      return ColumnHeaderDetail(
        columnKey: columnKey,
        column: vicinity.column,
        isPinned: isPinned,
        selected: focusManager.isColumnSelected(columnKey),
        hovering: focusManager.isColumnHovering(columnKey),
      ) as T;
    }

    final cellIndex = getCellIndex(vicinity);
    final rowData = dataSource.getRowData(cellIndex.row);

    return TableCellDetail(
      index: cellIndex,
      columnKey: columnKey,
      rowKey: rowData.key,
      isPinned: isPinned,
      selected: focusManager.isCellSelected(
        rowData.key,
        columnKey,
      ),
      hovering: focusManager.isCellHovering(
        rowData.key,
        columnKey,
      ),
      cellData: rowData[columnKey],
    ) as T;
  }

  @override
  TableSpan buildColumnSpan(int index, TableGridBorder border) {
    final columnKey = orderedColumns[index];
    final extent = _extentManager.getColumnExtent(columnKey);
    return border.build(
      axis: Axis.vertical,
      extent: extent,
      last: index == columnCount - 1,
    );
  }

  @override
  TableSpan buildRowSpan(int index, TableGridBorder border) {
    final extent = _extentManager.getRowExtent(index);
    return border.build(
      axis: Axis.horizontal,
      extent: extent,
      last: index == rowCount - 1,
    );
  }

  @override
  void updateStrategies({
    List<FocusStrategy>? selectionStrategies,
    List<FocusStrategy>? hoveringStrategies,
  }) {
    bool shouldNotify = false;

    if (selectionStrategies != null) {
      shouldNotify |= focusManager.updateSelectionStrategy(selectionStrategies);
    }

    if (hoveringStrategies != null) {
      shouldNotify |= focusManager.updateHoveringStrategy(hoveringStrategies);
    }

    if (shouldNotify) {
      notifyRebuild();
    }
  }

  @override
  void select({
    List<RowKey>? rows,
    List<ColumnKey>? columns,
    List<CellKey>? cells,
  }) {
    focusManager.select(
      rows: rows,
      columns: columns,
      cells: cells,
    );
  }

  @override
  void unselect({
    List<RowKey>? rows,
    List<ColumnKey>? columns,
    List<CellKey>? cells,
  }) {
    focusManager.unselect(
      rows: rows,
      columns: columns,
      cells: cells,
    );
  }

  @override
  void hoverOn({RowKey? row, ColumnKey? column}) {
    focusManager.hoverOn(row: row, column: column);
  }

  @override
  void hoverOff({RowKey? row, ColumnKey? column}) {
    focusManager.hoverOff(row: row, column: column);
  }

  @override
  Listenable? getCellFocusNotifier(ChildVicinity vicinity) {
    if (isColumnHeader(vicinity.row)) {
      return focusManager.columnFocusNotifier;
    } else {
      return focusManager.cellFocusNotifier;
    }
  }
}
