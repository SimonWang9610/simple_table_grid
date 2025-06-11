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
import 'package:simple_table_grid/src/models/key.dart';

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

  ColumnKey getColumnKey(int index);

  void removeRows(List<RowKey> rows);

  void reorderRow(RowKey from, RowKey to);
  void pinRow(RowKey key);
  void unpinRow(RowKey key);

  void toggleHeaderVisibility(bool alwaysShowHeader);

  // Listenable get listenable;
  List<ColumnKey> get orderedColumns;

  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity);

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
