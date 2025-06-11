import 'package:flutter_test/flutter_test.dart';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';

void main() {
  final quick = QuickOrdering<ColumnKey>([]);
  final efficient = EfficientOrdering<ColumnKey>([]);
  final keys = [
    ColumnKey("A"),
    ColumnKey("B"),
    ColumnKey("C"),
    ColumnKey("D"),
    ColumnKey("E"),
  ];

  test("QuickOrdering basic operations", () {
    for (var key in keys) {
      quick.add(key);
    }

    expect(quick.keys, equals(keys));
    expect(quick.firstKey, equals(keys.first));
    expect(quick.lastKey, equals(keys.last));

    quick.remove(keys[2]);
    expect(quick.keys, equals([keys[0], keys[1], keys[3], keys[4]]));
    expect(quick.firstKey, equals(keys.first));
    expect(quick.lastKey, equals(keys.last));

    quick.reorder(keys[0], keys[3]);
    expect(quick.keys, equals([keys[1], keys[3], keys[0], keys[4]]));

    expect(quick.contains(keys[2]), isFalse);
    expect(quick.contains(keys[0]), isTrue);

    quick.insert(1, ColumnKey("Z"));
    expect(quick.keys,
        equals([keys[1], ColumnKey("Z"), keys[3], keys[0], keys[4]]));
  });

  test("EfficientOrdering basic operations", () {
    for (var key in keys) {
      efficient.add(key);
    }

    expect(efficient.keys, equals(keys));
    expect(efficient.firstKey, equals(keys.first));
    expect(efficient.lastKey, equals(keys.last));

    efficient.remove(keys[2]);
    expect(efficient.keys, equals([keys[0], keys[1], keys[3], keys[4]]));
    expect(efficient.firstKey, equals(keys.first));
    expect(efficient.lastKey, equals(keys.last));

    efficient.reorder(keys[0], keys[3]);
    expect(efficient.keys, equals([keys[1], keys[3], keys[0], keys[4]]));

    expect(efficient.contains(keys[2]), isFalse);
    expect(efficient.contains(keys[0]), isTrue);

    efficient.insert(1, ColumnKey("Z"));
    expect(efficient.keys,
        equals([keys[1], ColumnKey("Z"), keys[3], keys[0], keys[4]]));
  });
}
