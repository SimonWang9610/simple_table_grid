import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';

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

class MatchSnapshot {
  late final KeyOrdering<RowKey> _pinnedOrdering;
  late final KeyOrdering<RowKey> _nonPinnedOrdering;

  MatchSnapshot(
    List<RowKey> pinnedRows,
    List<RowKey> nonPinnedRows,
  ) {
    _pinnedOrdering = KeyOrdering<RowKey>.efficient(pinnedRows);
    _nonPinnedOrdering = KeyOrdering<RowKey>.quick(nonPinnedRows);
  }

  void dispose() {
    _pinnedOrdering.reset();
    _nonPinnedOrdering.reset();
  }

  void add(RowKey key, {bool pinned = false}) {
    if (pinned) {
      if (_pinnedOrdering.contains(key)) {
        return; // Already exists in pinned ordering
      }

      _pinnedOrdering.add(key);
    } else {
      if (_nonPinnedOrdering.contains(key)) {
        return; // Already exists in non-pinned ordering
      }

      _nonPinnedOrdering.add(key);
    }
  }

  void remove(RowKey key) {
    if (_pinnedOrdering.contains(key)) {
      _pinnedOrdering.remove(key);
    } else if (_nonPinnedOrdering.contains(key)) {
      _nonPinnedOrdering.remove(key);
    }
  }

  void pin(RowKey key) {
    if (_pinnedOrdering.contains(key)) return;

    _pinnedOrdering.add(key);
    _nonPinnedOrdering.remove(key);
  }

  void unpin(RowKey key) {
    if (_nonPinnedOrdering.contains(key)) return;

    _nonPinnedOrdering.add(key);
    _pinnedOrdering.remove(key);
  }

  void afterSort(List<RowKey> sorted) {
    _nonPinnedOrdering.reset();

    for (final key in sorted) {
      if (_pinnedOrdering.contains(key)) continue;
      _nonPinnedOrdering.add(key);
    }
  }

  void reorder(RowKey from, RowKey to) {
    final fromPinned = _pinnedOrdering.contains(from);

    assert(
      fromPinned || _nonPinnedOrdering.contains(from),
      "From key $from is not in the pinned or non-pinned ordering",
    );

    final toPinned = _pinnedOrdering.contains(to);

    assert(
      toPinned || _nonPinnedOrdering.contains(to),
      "To key $to is not in the pinned or non-pinned ordering",
    );

    if (fromPinned && toPinned) {
      _pinnedOrdering.reorder(from, to);
    } else if (!fromPinned && !toPinned) {
      _nonPinnedOrdering.reorder(from, to);
    } else if (fromPinned && !toPinned) {
      _pinnedOrdering.remove(from);
      _nonPinnedOrdering.add(from);
      _nonPinnedOrdering.reorder(from, to);
    } else if (!fromPinned && toPinned) {
      _nonPinnedOrdering.remove(from);
      _pinnedOrdering.add(from);
      _pinnedOrdering.reorder(from, to);
    }
  }

  RowKey? previous(RowKey key) {
    final pinnedIndex = _pinnedOrdering.indexOf(key);

    if (pinnedIndex != null) {
      return _pinnedOrdering.firstKey != key
          ? _pinnedOrdering[pinnedIndex - 1]
          : null;
    }

    final nonPinnedIndex = _nonPinnedOrdering.indexOf(key);
    if (nonPinnedIndex != null) {
      if (_nonPinnedOrdering.firstKey == key) {
        return _pinnedOrdering.lastKey;
      } else {
        return _nonPinnedOrdering[nonPinnedIndex - 1];
      }
    }

    return null; // Key not found in either ordering
  }

  RowKey? next(RowKey key) {
    final pinnedIndex = _pinnedOrdering.indexOf(key);

    if (pinnedIndex != null) {
      return _pinnedOrdering.lastKey != key
          ? _pinnedOrdering[pinnedIndex + 1]
          : _nonPinnedOrdering.firstKey;
    }

    final nonPinnedIndex = _nonPinnedOrdering.indexOf(key);

    if (nonPinnedIndex != null) {
      if (_nonPinnedOrdering.lastKey != key) {
        return _nonPinnedOrdering[nonPinnedIndex + 1];
      } else {
        return null;
      }
    }

    return null; // Key not found in either ordering
  }

  /// Get the row key at the given index in the data source.
  ///
  /// [index] is the index of the row in the table including the header row.
  RowKey getRowKey(int dataIndex) {
    assert(
      dataIndex >= 0 && dataIndex < dataCount,
      "Data index $dataIndex is out of bounds for rows of length $dataCount",
    );

    final key = dataIndex >= pinnedCount
        ? _nonPinnedOrdering[dataIndex - pinnedCount]
        : _pinnedOrdering[dataIndex];

    return key!;
  }

  int? getRowIndex(RowKey key) {
    if (_pinnedOrdering.contains(key)) {
      return _pinnedOrdering.indexOf(key);
    }

    if (_nonPinnedOrdering.contains(key)) {
      return _pinnedOrdering.length + (_nonPinnedOrdering.indexOf(key) ?? 0);
    }

    return null; // Key not found in either ordering
  }

  int get pinnedCount => _pinnedOrdering.length;
  int get nonPinnedCount => _nonPinnedOrdering.length;

  int get dataCount => pinnedCount + nonPinnedCount;

  List<RowKey> get ordered =>
      [..._pinnedOrdering.keys, ..._nonPinnedOrdering.keys];
}

abstract mixin class RowDataSource {
  Map<RowKey, RowData> get rows;
}

class DataSearchSnapshots {
  final RowDataSource source;

  late final MatchSnapshot _alwaysSnapshot;

  MatchSnapshot? _searchSnapshot;

  DataSearchSnapshots(this.source) {
    _alwaysSnapshot = MatchSnapshot(
      source.rows.keys.toList(),
      [],
    );
  }

  _Query? _query;

  bool search(
    String keyword, {
    required RowDataMatcher matcher,
  }) {
    if (keyword.isEmpty) {
      return clearSearch();
    }

    final query = _Query(keyword, matcher);

    if (_query == query && _searchSnapshot != null) {
      return false; // No change in query
    }

    final pinnedRows = <RowKey>[];
    final nonPinnedRows = <RowKey>[];

    for (final key in _alwaysSnapshot._pinnedOrdering.keys) {
      final row = source.rows[key];
      if (row != null && matcher(keyword, row)) {
        pinnedRows.add(key);
      }
    }

    for (final key in _alwaysSnapshot._nonPinnedOrdering.keys) {
      final row = source.rows[key];
      if (row != null && matcher(keyword, row)) {
        nonPinnedRows.add(key);
      }
    }

    _searchSnapshot?.dispose();
    _searchSnapshot = MatchSnapshot(pinnedRows, nonPinnedRows);
    _query = query;

    return true; // Search was successful and snapshot updated
  }

  bool clearSearch() {
    final cleared = _query != null;

    _query = null;
    _searchSnapshot?.dispose();
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
    final allNonPinnedSorted = _alwaysSnapshot._nonPinnedOrdering.keys
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
            (key) => _searchSnapshot!._nonPinnedOrdering.contains(key),
          )
          .toList();

      _searchSnapshot!.afterSort(currentNonPinnedSorted);
    }
  }

  void dispose() {
    _alwaysSnapshot.dispose();
    _searchSnapshot?.dispose();
    _searchSnapshot = null;
    _query = null;
  }

  int get pinnedCount =>
      _searchSnapshot?.pinnedCount ?? _alwaysSnapshot.pinnedCount;
  int get nonPinnedCount =>
      _searchSnapshot?.nonPinnedCount ?? _alwaysSnapshot.nonPinnedCount;

  int get dataCount => pinnedCount + nonPinnedCount;

  MatchSnapshot get current {
    return _searchSnapshot ?? _alwaysSnapshot;
  }
}
