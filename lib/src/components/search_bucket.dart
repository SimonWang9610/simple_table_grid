import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/search_snapshot.dart';

abstract mixin class RowDataSource {
  Map<RowKey, RowData> get rows;
}

typedef RowDataMatcher = bool Function(
  String keyword,
  RowData row,
);

class _Query {
  final String query;
  final RowDataMatcher matcher;

  _Query(this.query, this.matcher);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _Query) return false;
    return query == other.query && matcher == other.matcher;
  }

  @override
  int get hashCode => query.hashCode ^ matcher.hashCode;
}

class DataSearchBucket {
  final RowDataSource source;

  late final SearchSnapshot _alwaysSnapshot;

  SearchSnapshot? _searchSnapshot;

  DataSearchBucket(this.source) {
    _alwaysSnapshot = SearchSnapshot([], source.rows.keys.toList());
  }

  _Query? _query;

  bool perform(
    String keyword, {
    required RowDataMatcher matcher,
  }) {
    if (keyword.isEmpty) {
      return undo();
    }

    final query = _Query(keyword, matcher);

    if (_query == query && _searchSnapshot != null) {
      return false; // No change in query
    }

    final pinnedRows = <RowKey>[];
    final nonPinnedRows = <RowKey>[];

    for (final key in _alwaysSnapshot.pinnedKeys) {
      final row = source.rows[key];
      if (row != null && matcher(keyword, row)) {
        pinnedRows.add(key);
      }
    }

    for (final key in _alwaysSnapshot.nonPinnedKeys) {
      final row = source.rows[key];
      if (row != null && matcher(keyword, row)) {
        nonPinnedRows.add(key);
      }
    }

    _searchSnapshot?.clear();
    _searchSnapshot = SearchSnapshot(pinnedRows, nonPinnedRows);
    _query = query;

    return true; // Search was successful and snapshot updated
  }

  bool undo() {
    final cleared = _query != null;

    _query = null;
    _searchSnapshot?.clear();
    _searchSnapshot = null;

    return cleared;
  }

  void add(RowData row) {
    _alwaysSnapshot.add(row.key);

    if (_query != null && _query!.matcher(_query!.query, row)) {
      _searchSnapshot?.add(row.key);
    }
  }

  void remove(RowKey key) {
    _alwaysSnapshot.remove(key);
    _searchSnapshot?.remove(key);
  }

  void pin(RowKey key) {
    _alwaysSnapshot.pin(key);
    _searchSnapshot?.pin(key);
  }

  void unpin(RowKey key) {
    _alwaysSnapshot.unpin(key);
    _searchSnapshot?.unpin(key);
  }

  void performSort({
    required RowDataComparator compare,
  }) {
    final allNonPinnedSorted = _alwaysSnapshot.nonPinnedKeys
      ..sort(
        (a, b) => compare(
          source.rows[a]!,
          source.rows[b]!,
        ),
      );

    _alwaysSnapshot.afterSort(allNonPinnedSorted);

    if (_searchSnapshot != null) {
      final currentNonPinnedSorted = allNonPinnedSorted
          .where(
            (key) => _searchSnapshot!.contains(key),
          )
          .toList();

      _searchSnapshot!.afterSort(currentNonPinnedSorted);
    }
  }

  void clear() {
    _alwaysSnapshot.clear();
    _searchSnapshot?.clear();
    _searchSnapshot = null;
    _query = null;
  }

  int get pinnedCount => current.pinnedCount;
  int get nonPinnedCount => current.nonPinnedCount;

  int get dataCount => pinnedCount + nonPinnedCount;

  SearchSnapshot get current {
    return _searchSnapshot ?? _alwaysSnapshot;
  }
}
