import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

abstract base class TableController with ChangeNotifier {
  TableRowController get rows;
  TableColumnController get columns;
  TableFocuser get focuser;
  TableSizer get sizer;
  TableIndexFinder get finder;

  TableInternalController get internal;

  int get columnCount => columns.count;
  int get pinnedColumnCount => columns.pinnedCount;

  int get rowCount => rows.count;
  int get pinnedRowCount => rows.pinnedCount;

  void _notify() {
    notifyListeners();
  }

  TableController._();

  factory TableController({
    required List<ColumnKey> columns,
    List<RowData> initialRows = const [],
    bool alwaysShowHeader = true,
    required Extent defaultRowExtent,
    required Extent defaultColumnExtent,
    Map<int, Extent>? rowExtents,
    Map<ColumnKey, Extent>? columnExtents,
    List<FocusStrategy> selectionStrategies = const [FocusStrategy.row],
    List<FocusStrategy> hoveringStrategies = const [FocusStrategy.row],
  }) =>
      _ControllerImpl(
        columns: columns,
        initialRows: initialRows,
        alwaysShowHeader: alwaysShowHeader,
        defaultRowExtent: defaultRowExtent,
        defaultColumnExtent: defaultColumnExtent,
        rowExtents: rowExtents,
        columnExtents: columnExtents,
        selectionStrategies: selectionStrategies,
        hoveringStrategies: hoveringStrategies,
      );
}

abstract interface class TableInternalController {
  Listenable? getCellFocusNotifier(ChildVicinity vicinity);
  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity);
}

abstract mixin class TableControllerCoordinator {
  TableController? _controller;

  void bind(TableController controller) {
    _controller = controller;
  }

  void notify() {
    _controller?._notify();
  }

  @mustCallSuper
  @protected
  void dispose() {
    _controller = null;
  }
}

abstract interface class TableIndexFinder {
  int? getRowIndex(RowKey key);
  RowKey? getRowKey(int index);
  RowKey? previousRow(RowKey key);
  RowKey? nextRow(RowKey key);

  int? getColumnIndex(ColumnKey key);
  ColumnKey getColumnKey(int index);
  ColumnKey? previousColumn(ColumnKey key);
  ColumnKey? nextColumn(ColumnKey key);
}

final class _ControllerImpl extends TableController
    implements TableInternalController, TableIndexFinder {
  late final TableDataController data;
  late final TableHeaderController header;
  late final TableExtentController extent;
  late final TableFocusController focus;

  _ControllerImpl({
    required List<ColumnKey> columns,
    List<RowData> initialRows = const [],
    bool alwaysShowHeader = true,
    required Extent defaultRowExtent,
    required Extent defaultColumnExtent,
    Map<int, Extent>? rowExtents,
    Map<ColumnKey, Extent>? columnExtents,
    List<FocusStrategy> selectionStrategies = const [FocusStrategy.row],
    List<FocusStrategy> hoveringStrategies = const [FocusStrategy.row],
  }) : super._() {
    extent = TableExtentController(
      finder: this,
      defaultRowExtent: defaultRowExtent,
      defaultColumnExtent: defaultColumnExtent,
      rowExtents: rowExtents,
      columnExtents: columnExtents,
    )..bind(this);

    data = TableDataController(
      alwaysShowHeader: alwaysShowHeader,
      rows: initialRows,
    )..bind(this);

    header = TableHeaderController(columns)..bind(this);

    focus = TableFocusController(
      selectionStrategies: selectionStrategies,
      hoveringStrategies: hoveringStrategies,
    )..bind(this);
  }

  @override
  void dispose() {
    extent.dispose();
    data.dispose();
    header.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  TableRowController get rows => data;

  @override
  TableColumnController get columns => header;

  @override
  TableFocusController get focuser => focus;

  @override
  TableSizer get sizer => extent;

  @override
  TableInternalController get internal => this;

  @override
  TableIndexFinder get finder => this;

  @override
  Listenable? getCellFocusNotifier(ChildVicinity vicinity) {
    if (data.isColumnHeader(vicinity.row)) {
      return focus.columnFocusNotifier;
    } else {
      return focus.cellFocusNotifier;
    }
  }

  @override
  T getCellDetail<T extends CellDetail>(ChildVicinity vicinity) {
    final columnKey = getColumnKey(vicinity.column);

    if (data.isColumnHeader(vicinity.row)) {
      return ColumnHeaderDetail(
        columnKey: columnKey,
        isPinned: isColumnPinned(vicinity.column),
        selected: focus.isColumnSelected(columnKey),
        hovering: focus.isColumnHovering(columnKey),
      ) as T;
    }

    final rowKey = data.getRowKey(vicinity.row);

    return TableCellDetail(
      columnKey: columnKey,
      rowKey: rowKey,
      isPinned: isRowPinned(vicinity.row),
      selected: focus.isCellSelected(
        rowKey,
        columnKey,
      ),
      hovering: focus.isCellHovering(
        rowKey,
        columnKey,
      ),
      cellData: data.getCellData(
        rowKey,
        columnKey,
      ),
    ) as T;
  }

  @override
  int? getRowIndex(RowKey key) {
    return data.getRowIndex(key);
  }

  @override
  RowKey? getRowKey(int index) {
    return data.getRowKey(index);
  }

  @override
  RowKey? previousRow(RowKey key) {
    return data.previous(key);
  }

  @override
  RowKey? nextRow(RowKey key) {
    return data.next(key);
  }

  @override
  int? getColumnIndex(ColumnKey key) {
    return header.getColumnIndex(key);
  }

  @override
  ColumnKey getColumnKey(int index) {
    return header.getColumnKey(index);
  }

  @override
  ColumnKey? previousColumn(ColumnKey key) {
    return header.previous(key);
  }

  @override
  ColumnKey? nextColumn(ColumnKey key) {
    return header.next(key);
  }

  bool isColumnPinned(int vicinityColumn) {
    return vicinityColumn < header.pinnedCount;
  }

  bool isRowPinned(int vicinityRow) {
    return vicinityRow < data.pinnedCount;
  }
}
