import 'package:flutter_test/flutter_test.dart';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/search_bucket.dart';

class _MockRowDataSource implements RowDataSource {
  final Map<RowKey, RowData> _rows;

  _MockRowDataSource(this._rows);

  @override
  Map<RowKey, RowData> get rows => _rows;
}

void main() {
  final rows = List.generate(
    5,
    (index) => RowData(
      RowKey('Row$index'),
      data: {
        ColumnKey('Column1'): 'C${index}1',
        ColumnKey('Column2'): 'C${index}2',
      },
    ),
  ).map((e) => MapEntry(e.key, e));

  final source = _MockRowDataSource(Map.fromEntries(rows));

  bool match(String keyword, RowData row) {
    return row.data.values.any((value) => value.toString().contains(keyword));
  }

  group("perform/undo", () {
    test("empty keyword", () {
      final bucket = DataSearchBucket(source);

      expect(bucket.perform('', matcher: match), isFalse);
      expect(bucket.nonPinnedCount, equals(5));

      expect(bucket.undo(), isFalse);
    });

    test("keyword", () {
      final bucket = DataSearchBucket(source);

      expect(bucket.perform('C11', matcher: match), isTrue);
      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));

      expect(bucket.undo(), isTrue);
    });
  });

  group("add", () {
    test("add only", () {
      final bucket = DataSearchBucket(source);

      bucket.add(
        RowData(RowKey('Row5'), data: {
          ColumnKey('Column1'): 'C51',
          ColumnKey('Column2'): 'C52',
        }),
      );

      expect(bucket.nonPinnedCount, equals(6));
      expect(bucket.dataCount, equals(6));
    });

    test("add with search", () {
      final bucket = DataSearchBucket(source);

      expect(bucket.perform('C11', matcher: match), isTrue);
      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));

      bucket.add(
        RowData(RowKey('Row5'), data: {
          ColumnKey('Column1'): 'C11',
          ColumnKey('Column2'): 'C52',
        }),
      );

      expect(bucket.nonPinnedCount, equals(2));
      expect(bucket.dataCount, equals(2));
    });
  });

  group("remove", () {
    test("remove only", () {
      final bucket = DataSearchBucket(source);

      bucket.remove(RowKey('Row0'));

      expect(bucket.nonPinnedCount, equals(4));
      expect(bucket.dataCount, equals(4));
    });

    test("remove the row not in the search result", () {
      final bucket = DataSearchBucket(source);

      expect(bucket.perform('C11', matcher: match), isTrue);
      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));

      bucket.remove(RowKey('Row0'));

      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));
    });

    test("remove the row in the search result", () {
      final bucket = DataSearchBucket(source);

      expect(bucket.perform('C11', matcher: match), isTrue);
      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));

      bucket.remove(RowKey('Row1'));

      expect(bucket.nonPinnedCount, equals(0));
      expect(bucket.dataCount, equals(0));
    });
  });

  group("pin/unpin", () {
    test("pin/unpin a row not in the search result", () {
      final bucket = DataSearchBucket(source);

      expect(bucket.perform('C11', matcher: match), isTrue);
      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));

      final rowKey = RowKey('Row0');
      bucket.pin(rowKey);

      expect(bucket.pinnedCount, equals(0));
      expect(bucket.nonPinnedCount, equals(1));

      bucket.unpin(rowKey);

      expect(bucket.pinnedCount, equals(0));
      expect(bucket.nonPinnedCount, equals(1));
    });

    test("Pin/unpin a row in the search result", () {
      final bucket = DataSearchBucket(source);

      expect(bucket.perform('C11', matcher: match), isTrue);
      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));

      final rowKey = RowKey('Row1');
      bucket.pin(rowKey);

      expect(bucket.pinnedCount, equals(1));
      expect(bucket.nonPinnedCount, equals(0));

      bucket.unpin(rowKey);

      expect(bucket.pinnedCount, equals(0));
      expect(bucket.nonPinnedCount, equals(1));
    });
  });

  group("performSort", () {
    test("sort without search query", () {
      final bucket = DataSearchBucket(source);

      bucket.performSort(
        compare: (a, b) => b.data[ColumnKey('Column1')]!
            .compareTo(a.data[ColumnKey('Column1')]!),
      );

      expect(bucket.nonPinnedCount, equals(5));
      expect(bucket.dataCount, equals(5));

      final sortedKeys = bucket.current.nonPinnedKeys;
      expect(
          sortedKeys,
          orderedEquals([
            RowKey('Row4'),
            RowKey('Row3'),
            RowKey('Row2'),
            RowKey('Row1'),
            RowKey('Row0')
          ]));
    });

    test("sort with search query", () {
      final bucket = DataSearchBucket(source);

      expect(bucket.perform('C11', matcher: match), isTrue);
      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));

      bucket.performSort(
        compare: (a, b) => b.data[ColumnKey('Column1')]!
            .compareTo(a.data[ColumnKey('Column1')]!),
      );

      expect(bucket.nonPinnedCount, equals(1));
      expect(bucket.dataCount, equals(1));

      final sortedKeys = bucket.current.nonPinnedKeys;
      expect(sortedKeys, orderedEquals([RowKey('Row1')]));
    });
  });
}
