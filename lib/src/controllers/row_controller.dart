import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/reorder_interfaces.dart';
import 'package:simple_table_grid/src/components/search_bucket.dart';

typedef RowDataComparator = int Function(RowData a, RowData b);

abstract base class TableRowController
    with ChangeNotifier, TableKeyReorderMixin<RowKey> {
  /// Add all rows.
  /// Only new rows will be added, existing rows will be skipped
  void addAll(List<RowData> rows);

  /// Add a single row.
  /// If the row already exists, it will be skipped.
  void add(RowData row);

  /// Remove all rows with the given keys.
  /// If a row does not exist, it will be skipped.
  void removeAll(List<RowKey> rows);

  /// Remove a single row with the given key.
  void remove(RowKey row);

  /// Replace all existing rows with the given [rows].
  void replaceAll(List<RowData> rows);

  /// Perform a sort on the rows by using the provided [compare] function.
  ///
  /// ALl pinned rows will be kept at the top of the list.
  ///
  /// Only non-pinned rows will be sorted.
  ///
  /// If [newRows] are provided, they will be added to the data source before sorting.
  void performSort({
    required RowDataComparator compare,
    List<RowData>? newRows,
  });

  /// Perform a search on the existing rows by using the provided [keyword] and [matcher].
  /// if [keyword] is empty, the search will behave like [undoSearch].
  void performSearch({
    required String keyword,
    required RowDataMatcher matcher,
  });

  /// Use the given [update] to edit a row,
  /// [shouldNotify] indicates whether the controller should notify listeners if [update] is applied.
  ///
  /// Typically, when you add/remove a [ColumnKey], you may also want to update the corresponding columns of the existing rows.
  /// if you operate on multiple rows, you could set [shouldNotify] to false
  /// and call [markAsDirty] at the end to notify the controller.
  void updateRow(
    RowUpdate update, {
    bool shouldNotify = true,
  });

  /// Undo the last search operation.
  void undoSearch();

  /// Pin a row with the given key.
  void pin(RowKey row);

  /// Unpin a row with the given key.
  void unpin(RowKey row);

  /// If always pinning the header row.
  ///
  /// if false and no other data rows are pinned, the header row will not be pinned.
  ///
  /// If there are pinned data rows, the header row will always be pinned.
  void setHeaderVisibility(bool alwaysShowHeader);

  bool get alwaysShowHeader;

  /// Convert a row index to a cell row index.
  ///
  /// [vicinityRow] is the index of the row in the table including the header row.
  int toDataRow(int vicinityRow) {
    return vicinityRow - 1;
  }

  /// Convert a cell row index to a vicinity row index.
  ///
  /// [dataRow] is the index of the row in the table excluding the header row.
  int toVicinityRow(int dataRow) {
    return dataRow + 1;
  }

  /// Check if the given [vicinityRow] is a column header.
  /// If [alwaysShowHeader] is true, the header row is always at index 0.
  /// If false, it will always return false as there is no header row.
  bool isHeaderRow(int vicinityRow) {
    return vicinityRow == 0;
  }

  /// The count of rows including the header row
  int get count;

  /// The count of pinned rows including the header row if [alwaysShowHeader] is true.
  int get pinnedCount;

  /// The count of data rows excluding the header row.
  int get dataCount;

  /// Manually notify the controller that the data has changed.
  ///
  /// Typically it happens when some [RowData] are changed outside of the controller context,
  /// like when a row is edited in a dialog or a cell is updated.
  ///
  /// This will trigger a rebuild of the table widget to reflect the changes.
  void markAsDirty();
}

final class TableDataController extends TableRowController
    with TableControllerCoordinator, RowDataSource {
  TableDataController({
    List<RowData> rows = const [],
    bool alwaysShowHeader = true,
  }) : _alwaysShowHeader = alwaysShowHeader {
    for (final row in rows) {
      _rows[row.key] = row;
      _searcher.add(row);
    }
  }

  final _rows = <RowKey, RowData>{};
  // final _pinnedOrdering = KeyOrdering.efficient(<RowKey>[]);
  // final _nonPinnedOrdering = KeyOrdering.quick(<RowKey>[]);

  late final _searcher = DataSearchBucket(this);

  @override
  Map<RowKey, RowData> get rows => _rows;

  List<RowData> get orderedRows {
    final ordered = _searcher.current.ordered;

    return ordered.map((key) => _rows[key]!).toList();
  }

  @override
  int get dataCount => _searcher.dataCount;

  @override
  int get count => dataCount + 1;

  bool _alwaysShowHeader;

  @override
  bool get alwaysShowHeader => _alwaysShowHeader;

  @override
  void setHeaderVisibility(bool alwaysShowHeader) {
    if (_alwaysShowHeader == alwaysShowHeader) return;
    _alwaysShowHeader = alwaysShowHeader;
    notify();
  }

  int get _pinnedRowCount => _searcher.pinnedCount;

  @override
  int get pinnedCount {
    assert(
      _pinnedRowCount <= count,
      "Pinned rows $_pinnedRowCount must be less than or equal to row count $count",
    );

    if (_pinnedRowCount == 0) {
      return alwaysShowHeader ? 1 : 0;
    }

    return _pinnedRowCount + 1;
  }

  @override
  void addAll(List<RowData> rows) {
    if (rows.isEmpty) return;

    final shouldNotify = _addAll(rows);

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void add(RowData row) {
    addAll([row]);
  }

  @override
  void removeAll(List<RowKey> rows) {
    if (rows.isEmpty) return;

    bool shouldNotify = false;

    for (final rowKey in rows) {
      if (_rows.containsKey(rowKey)) {
        shouldNotify = true;
        _rows.remove(rowKey);
        _searcher.remove(rowKey);
      }
    }

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void remove(RowKey row) {
    removeAll([row]);
  }

  @override
  void replaceAll(List<RowData> rows) {
    _rows.clear();
    _searcher.clear();

    _addAll(rows);

    notify();
  }

  @override
  void pin(RowKey row) {
    if (!_rows.containsKey(row)) return;
    _searcher.pin(row);
    notify();
  }

  @override
  void unpin(RowKey row) {
    if (!_rows.containsKey(row)) return;

    _searcher.unpin(row);
    notify();
  }

  ReorderPredicate<RowKey>? _reorderPredicate;

  @override
  ReorderPredicate<RowKey>? get reorderPredicate => _reorderPredicate;

  @override
  void reordering(RowKey from, RowKey? to) {
    assert(
      _rows.containsKey(from),
      "From key $from is not in the data source",
    );
    assert(
      _rows.containsKey(to),
      "To key $to is not in the data source",
    );

    if (to == null) {
      if (_reorderPredicate == null) return;
      _reorderPredicate = null; // reset the predicate if no target
      notify();
      return;
    }

    final predicate = _searcher.current.predicate(from, to);

    if (_reorderPredicate != predicate) {
      _reorderPredicate = predicate;
      notify();
    }
  }

  @override
  void confirmReordering(bool apply) {
    if (apply && _reorderPredicate != null) {
      _searcher.current.applyReorder(_reorderPredicate!);
      _reorderPredicate = null; // reset the predicate after applying
      notify();
    }
  }

  @override
  void performSort({
    required RowDataComparator compare,
    List<RowData>? newRows,
  }) {
    if (newRows != null) {
      _addAll(newRows);
    }

    _searcher.performSort(compare: compare);

    notify();
  }

  bool _addAll(List<RowData> rows) {
    if (rows.isEmpty) return false;

    bool shouldNotify = false;

    for (final row in rows) {
      _rows[row.key] = row;
      _searcher.add(row);

      shouldNotify = true;
    }

    return shouldNotify;
  }

  @override
  void performSearch({
    required String keyword,
    required RowDataMatcher matcher,
  }) {
    final shouldNotify = _searcher.perform(
      keyword,
      matcher: matcher,
    );

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void undoSearch() {
    final shouldNotify = _searcher.undo();

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void markAsDirty() {
    notify();
  }

  @override
  void updateRow(
    RowUpdate update, {
    bool shouldNotify = true,
  }) {
    assert(
      _rows.containsKey(update.key),
      "Row key ${update.key} is not in the data source",
    );

    final row = _rows[update.key]!;

    final applied = update.apply(row);

    if (applied == row) return;

    _rows[update.key] = applied;

    if (shouldNotify) {
      notify();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _rows.clear();
    _searcher.clear();
  }

  RowKey? previous(RowKey key) {
    assert(
      _rows.containsKey(key),
      "Row key $key is not in the data source",
    );

    return _searcher.current.previous(key);
  }

  RowKey? next(RowKey key) {
    assert(
      _rows.containsKey(key),
      "Row key $key is not in the data source",
    );

    return _searcher.current.next(key);
  }

  /// Get the row key at the given index in the data source.
  ///
  /// [index] is the index of the row in the table including the header row.
  RowKey getRowKey(int index) {
    final dateIndex = toDataRow(index);

    return _searcher.current.getRowKey(dateIndex);
  }

  /// Get the index of the row in the table including the header row.
  ///
  /// if [key] is not in the data source, we will treat it as the header row and return 0.
  int getRowIndex(RowKey key) {
    if (!_rows.containsKey(key)) {
      return 0;
    }

    final index = _searcher.current.getRowIndex(key);

    assert(
      index != null,
      "Row key $key is not in the data source",
    );

    return toVicinityRow(index!);
  }

  dynamic getCellData(RowKey rowKey, ColumnKey columnKey) {
    final rowData = _rows[rowKey];

    assert(
      rowData != null,
      "Row data for key $rowKey is null, which should not happen",
    );

    return rowData![columnKey];
  }

  List<RowKey> get allRowKeys {
    return _searcher.always.ordered;
  }

  List<RowKey> get currentRowKeys {
    return _searcher.current.ordered;
  }

  RowData? getRow(RowKey rowKey) {
    return _rows[rowKey];
  }
}

abstract interface class Paginator {
  int get pageSize;
  int get currentPage;
  int get pages;

  set pageSize(int value);

  void goToPage(int page);
  void nextPage();
  void previousPage();
}

final class PaginatedTableDataController extends TableDataController
    implements Paginator {
  PaginatedTableDataController({super.rows, required int pageSize})
      : _pageSize = pageSize,
        super(alwaysShowHeader: true);

  List<RowKey> get currentPageKeys {
    return _searcher.current.ordered
        .skip(_currentPage * _pageSize)
        .take(count - 1)
        .toList();
  }

  @override
  void pin(RowKey row) {}

  @override
  void unpin(RowKey row) {}

  @override
  void setHeaderVisibility(bool alwaysShowHeader) {}

  int _currentPage = 0;

  @override
  int get currentPage => pages == 0 ? 0 : _currentPage + 1;

  int _pageSize;

  @override
  int get pageSize => _pageSize;

  @override
  set pageSize(int value) {
    if (value == _pageSize) return;

    if (value <= 0) {
      throw ArgumentError('Page size must be greater than zero.');
    }

    _currentPage = 0; // reset to the first page when changing page size
    _pageSize = value;
    notify();
  }

  @override
  void performSearch({
    required String keyword,
    required RowDataMatcher matcher,
  }) {
    final shouldNotify = _searcher.perform(
      keyword,
      matcher: matcher,
    );

    if (!shouldNotify) return;

    // always reset to the first page after searching
    // reduce the complexity of syncing the pagination state with the search results
    _currentPage = 0;
    notify();
  }

  @override
  void replaceAll(List<RowData> rows) {
    _currentPage = 0; // reset to the first page when updating rows
    super.replaceAll(rows);
  }

  @override
  int get pages {
    return (dataCount + _pageSize - 1) ~/ _pageSize;
  }

  @override
  int toDataRow(int vicinityRow) {
    return _currentPage * pageSize + vicinityRow - 1;
  }

  @override
  int toVicinityRow(int dataRow) {
    return (dataRow % pageSize) + 1;
  }

  @override
  int get count {
    if (dataCount == 0) {
      return 1; // only the header row
    }

    final int currentPageDataCount;

    if ((_currentPage + 1) * pageSize <= dataCount) {
      currentPageDataCount = pageSize;
    } else {
      currentPageDataCount = dataCount % pageSize;
    }

    return currentPageDataCount + 1; // +1 for the header row
  }

  @override
  void goToPage(int page) {
    final legalPage = page.clamp(0, pages - 1);
    if (legalPage == _currentPage) return;

    _currentPage = legalPage;
    notify();
  }

  @override
  void nextPage() {
    final next = _currentPage + 1;

    if (next < pages) {
      goToPage(next);
    }
  }

  @override
  void previousPage() {
    final previous = _currentPage - 1;

    if (previous >= 0) {
      goToPage(previous);
    }
  }
}
