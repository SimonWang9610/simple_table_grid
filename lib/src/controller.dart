import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/impl/column_interface_impl.dart';
import 'package:simple_table_grid/src/impl/data_source_interface_impl.dart';

abstract base class TableController with ChangeNotifier {
  TableController._();

  factory TableController({
    required List<ColumnKey> columns,
    List<RowData> initialRows = const [],
    bool alwaysShowHeader = true,
    List<FocusStrategy> selectionStrategies = const [FocusStrategy.row],
    List<FocusStrategy> hoveringStrategies = const [FocusStrategy.row],
  }) =>
      _TableControllerImpl(
        columns: columns,
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

  int get columnCount;
  int get pinnedColumnCount;

  void reorderColumn(ColumnKey from, ColumnKey to);
  void addColumn(ColumnKey column, {bool pinned = false});
  void removeColumn(ColumnKey key);
  void pinColumn(ColumnKey key);
  void unpinColumn(ColumnKey key);

  int get rowCount;
  int get pinnedRowCount;
  int get dataCount;

  void addRows(List<RowData> rows);

  RowKey getRowKey(int index);
  RowKey? previousRow(RowKey key);
  RowKey? nextRow(RowKey key);

  ColumnKey getColumnKey(int index);
  ColumnKey? previousColumn(ColumnKey key);
  ColumnKey? nextColumn(ColumnKey key);

  void removeRows(List<RowKey> rows);

  void reorderRow(RowKey from, RowKey to);
  void pinRow(RowKey key);
  void unpinRow(RowKey key);

  void toggleHeaderVisibility(bool alwaysShowHeader);

  // Listenable get listenable;
  List<ColumnKey> get orderedColumns;

  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity);
}

final class _TableControllerImpl extends TableController
    with TableCoordinator, TableColumnImplMixin, TableDataSourceImplMixin {
  _TableControllerImpl({
    required List<ColumnKey> columns,
    List<RowData> initialRows = const [],
    bool alwaysShowHeader = true,
    List<FocusStrategy> selectionStrategies = const [FocusStrategy.row],
    List<FocusStrategy> hoveringStrategies = const [FocusStrategy.row],
  }) : super._() {
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
  }

  late final TableFocusManager focusManager;

  @override
  late final TableDataSource dataSource;

  @override
  late final TableColumnManager columnManager;

  @override
  @protected
  void notifyRebuild() {
    notifyListeners();
  }

  @override
  void dispose() {
    dataSource.dispose();
    columnManager.dispose();
    focusManager.dispose();
    super.dispose();
  }

  @override
  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity) {
    final columnKey = orderedColumns[vicinity.column];

    if (dataSource.isColumnHeader(vicinity.row)) {
      return ColumnHeaderDetail(
        columnKey: columnKey,
        isPinned: isColumnPinned(vicinity.column),
        selected: focusManager.isColumnSelected(columnKey),
        hovering: focusManager.isColumnHovering(columnKey),
      ) as T;
    }

    final rowKey = dataSource.getRowKey(vicinity.row);

    return TableCellDetail(
      columnKey: columnKey,
      rowKey: rowKey,
      isPinned: isRowPinned(vicinity.row),
      selected: focusManager.isCellSelected(
        rowKey,
        columnKey,
      ),
      hovering: focusManager.isCellHovering(
        rowKey,
        columnKey,
      ),
      cellData: dataSource.getCellData(
        rowKey,
        columnKey,
      ),
    ) as T;
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
    if (dataSource.isColumnHeader(vicinity.row)) {
      return focusManager.columnFocusNotifier;
    } else {
      return focusManager.cellFocusNotifier;
    }
  }

  bool isColumnPinned(int vicinityColumn) {
    return vicinityColumn < pinnedColumnCount;
  }

  bool isRowPinned(int vicinityRow) {
    return vicinityRow < pinnedRowCount;
  }
}
