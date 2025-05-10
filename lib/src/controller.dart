import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/table_grid_view.dart';
import 'package:simple_table_grid/src/components/action_manager.dart';
import 'package:simple_table_grid/src/components/column_manager.dart';
import 'package:simple_table_grid/src/components/coordinator.dart';
import 'package:simple_table_grid/src/components/extent_manager.dart';
import 'package:simple_table_grid/src/data_source.dart';
import 'package:simple_table_grid/src/impl/action_interface_impl.dart';
import 'package:simple_table_grid/src/impl/column_interface_impl.dart';
import 'package:simple_table_grid/src/impl/data_source_interface_impl.dart';
import 'package:simple_table_grid/src/models/cell_detail.dart';
import 'package:simple_table_grid/src/models/cell_index.dart';
import 'package:simple_table_grid/src/models/misc.dart';
import 'package:simple_table_grid/src/models/table_grid_border.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

abstract base class TableController with ChangeNotifier {
  TableController._();

  factory TableController({
    required List<ColumnId> columns,
    required TableExtentManager extentManager,
    List<TableRowData> initialRows = const [],
    bool alwaysShowHeader = true,
    List<TableSelectionStrategy> selectionStrategies = const [
      TableSelectionStrategy.row
    ],
    List<TableHoveringStrategy> hoveringStrategies = const [
      TableHoveringStrategy.row
    ],
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
    List<TableSelectionStrategy>? selectionStrategies,
    List<TableHoveringStrategy>? hoveringStrategies,
  });

  void select({
    List<int>? rows,
    List<int>? columns,
    List<CellIndex>? cells,
  });
  void unselect({List<int>? rows, List<int>? columns, List<CellIndex>? cells});

  void hoverOn({int? row, int? column});
  void hoverOff({int? row, int? column});

  bool isCellSelected(int row, int column);
  bool isCellHovered(int row, int column);

  int get columnCount;
  int get pinnedColumnCount;
  void reorderColumn(ColumnId id, int to);
  void addColumn(ColumnId column, {bool pinned = false});
  void removeColumn(ColumnId id);
  void pinColumn(ColumnId id);
  void unpinColumn(ColumnId id);
  bool isColumnHeader(int vicinityRow);

  int get rowCount;
  int get pinnedRowCount;
  int get dataCount;

  void addRows(
    List<TableRowData> rows, {
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
  List<ColumnId> get orderedColumns;

  TableSpan buildRowSpan(int index, TableGridBorder border);
  TableSpan buildColumnSpan(int index, TableGridBorder border);

  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity);
  Listenable? getCellActionNotifier(ChildVicinity vicinity);
  CellIndex getCellIndex(ChildVicinity vicinity);

  int toVicinityRow(int row);

  set extentManager(TableExtentManager value);
}

final class _TableControllerImpl extends TableController
    with
        TableCoordinator,
        TableActionImplMixin,
        TableColumnImplMixin,
        TableDataSourceImplMixin {
  _TableControllerImpl({
    required List<ColumnId> columns,
    required TableExtentManager extentManager,
    List<TableRowData> initialRows = const [],
    bool alwaysShowHeader = true,
    List<TableSelectionStrategy> selectionStrategies = const [
      TableSelectionStrategy.row
    ],
    List<TableHoveringStrategy> hoveringStrategies = const [
      TableHoveringStrategy.row
    ],
  })  : _extentManager = extentManager,
        super._() {
    actionManager = ActionManager(
      hoveringStrategies: hoveringStrategies,
      selectionStrategies: selectionStrategies,
    )..bindCoordinator(this);

    dataSource = TableDataSource(
      alwaysShowHeader: alwaysShowHeader,
    )
      ..bindCoordinator(this)
      ..add(initialRows);

    columnManager = TableColumnManager()
      ..bindCoordinator(this)
      ..setColumns(columns);

    _extentManager.bindCoordinator(this);
  }

  @override
  late final ActionManager actionManager;

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
  void afterReorder({
    required int from,
    required int to,
    required bool forColumn,
  }) {
    actionManager.adapt(
      from,
      to,
      forColumn: forColumn,
    );
  }

  @override
  void afterReindex({
    Map<int, int>? newRowIndices,
    Map<int, int>? newColumnIndices,
  }) {
    actionManager.reindex(
      newRowIndices: newRowIndices,
      newColumnIndices: newColumnIndices,
    );
  }

  @override
  void dispose() {
    _extentManager.dispose();
    dataSource.dispose();
    columnManager.dispose();
    actionManager.dispose();
    super.dispose();
  }

  @override
  bool isColumnHeader(int vicinityRow) {
    return dataSource.alwaysShowHeader ? vicinityRow == 0 : false;
  }

  @override
  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity) {
    final selected =
        actionManager.isCellSelected(vicinity.row, vicinity.column);
    final hovering =
        actionManager.isCellHovering(vicinity.row, vicinity.column);

    final columnId = orderedColumns[vicinity.column];
    final isPinned = vicinity.column < pinnedColumnCount;

    if (isColumnHeader(vicinity.row)) {
      return ColumnHeaderDetail(
        columnId: columnId,
        column: vicinity.column,
        isPinned: isPinned,
        selected: selected,
        hovering: hovering,
      ) as T;
    }

    final cellIndex = getCellIndex(vicinity);

    return TableCellDetail(
      columnId: columnId,
      index: cellIndex,
      isPinned: isPinned,
      selected: selected,
      hovering: hovering,
      cellData: dataSource.getCellData(cellIndex.row, columnId),
    ) as T;
  }

  @override
  TableSpan buildColumnSpan(int index, TableGridBorder border) {
    final columnId = orderedColumns[index];
    final extent = _extentManager.getColumnExtent(columnId);
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
}
