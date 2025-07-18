import 'package:flutter_test/flutter_test.dart';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/search_snapshot.dart';

void main() async {
  final pinnedKeys = [
    RowKey("Pinned1"),
    RowKey("Pinned2"),
  ];

  final nonPinnedKeys = [
    RowKey("NonPinned1"),
    RowKey("NonPinned2"),
    RowKey("NonPinned3"),
  ];

  group("next", () {
    final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

    test("next", () {
      expect(snapshot.next(RowKey("Pinned2")), equals(RowKey("NonPinned1")));
    });

    test("next2", () {
      expect(snapshot.next(RowKey("NonPinned1")), equals(RowKey("NonPinned2")));
    });

    test("next3", () {
      expect(snapshot.next(RowKey("Pinned1")), equals(RowKey("Pinned2")));
    });

    test("next4", () {
      expect(snapshot.next(RowKey("NonPinned3")), isNull);
    });
  });

  group("previous", () {
    final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

    test("previous", () {
      expect(snapshot.previous(RowKey("NonPinned2")),
          equals(RowKey("NonPinned1")));
    });

    test("previous2", () {
      expect(
          snapshot.previous(RowKey("NonPinned1")), equals(RowKey("Pinned2")));
    });

    test("previous3", () {
      expect(snapshot.previous(RowKey("Pinned2")), equals(RowKey("Pinned1")));
    });

    test("previous4", () {
      expect(snapshot.previous(RowKey("Pinned1")), isNull);
    });
  });

  group("SearchSnapshot add/remove", () {
    final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

    test("Add a new key", () {
      final newKey = RowKey("NewKey");
      snapshot.add(newKey);
      expect(snapshot.nonPinnedKeys.contains(newKey), isTrue);
    });

    test("Remove an existing key", () {
      final keyToRemove = RowKey("NonPinned2");
      snapshot.remove(keyToRemove);
      expect(snapshot.nonPinnedKeys.contains(keyToRemove), isFalse);
    });
  });

  group("pin/unpin", () {
    test("Pin a non-pinned key", () {
      final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

      final keyToPin = RowKey("NonPinned3");
      snapshot.pin(keyToPin);
      expect(snapshot.pinnedKeys.contains(keyToPin), isTrue);
      expect(snapshot.nonPinnedKeys.contains(keyToPin), isFalse);
      expect(snapshot.pinnedKeys.last, equals(keyToPin));
    });

    test("Unpin a pinned key", () {
      final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

      final keyToUnpin = RowKey("Pinned1");
      snapshot.unpin(keyToUnpin);
      expect(snapshot.nonPinnedKeys.contains(keyToUnpin), isTrue);
      expect(snapshot.pinnedKeys.contains(keyToUnpin), isFalse);
      expect(snapshot.nonPinnedKeys.first, equals(keyToUnpin));
    });
  });

  group("index", () {
    final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

    test("getRowKey", () {
      expect(snapshot.getRowKey(0), equals(RowKey("Pinned1")));
      expect(snapshot.getRowKey(1), equals(RowKey("Pinned2")));
      expect(snapshot.getRowKey(2), equals(RowKey("NonPinned1")));
      expect(snapshot.getRowKey(3), equals(RowKey("NonPinned2")));
      expect(snapshot.getRowKey(4), equals(RowKey("NonPinned3")));
    });

    test("getRowIndex", () {
      expect(snapshot.getRowIndex(RowKey("Pinned1")), equals(0));
      expect(snapshot.getRowIndex(RowKey("Pinned2")), equals(1));
      expect(snapshot.getRowIndex(RowKey("NonPinned1")), equals(2));
      expect(snapshot.getRowIndex(RowKey("NonPinned2")), equals(3));
      expect(snapshot.getRowIndex(RowKey("NonPinned3")), equals(4));
    });

    test("pinCount", () {
      expect(snapshot.pinnedCount, equals(2));
    });

    test("nonPinCount", () {
      expect(snapshot.nonPinnedCount, equals(3));
    });
  });

  group("reorder", () {
    test("Reorder pinned keys", () {
      final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

      final predicate =
          snapshot.predicate(RowKey("Pinned1"), RowKey("Pinned2"));

      snapshot.applyReorder(predicate!);

      expect(snapshot.pinnedKeys[0], equals(RowKey("Pinned2")));
      expect(snapshot.pinnedKeys[1], equals(RowKey("Pinned1")));
    });

    test("Reorder non-pinned keys", () {
      final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

      final predicate =
          snapshot.predicate(RowKey("NonPinned1"), RowKey("NonPinned2"));

      snapshot.applyReorder(predicate!);

      expect(snapshot.nonPinnedKeys[0], equals(RowKey("NonPinned2")));
      expect(snapshot.nonPinnedKeys[1], equals(RowKey("NonPinned1")));
    });

    test("Reorder pinned to non-pinned", () {
      final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);
      final predicate =
          snapshot.predicate(RowKey("Pinned1"), RowKey("NonPinned1"));

      snapshot.applyReorder(predicate!);

      expect(snapshot.nonPinnedKeys.contains(RowKey("Pinned1")), isTrue);
      expect(snapshot.pinnedKeys.contains(RowKey("Pinned1")), isFalse);
      expect(snapshot.next(RowKey("NonPinned1")), equals(RowKey("Pinned1")));
    });

    test("Reorder non-pinned to pinned", () {
      final snapshot = SearchSnapshot(pinnedKeys, nonPinnedKeys);

      final predicate =
          snapshot.predicate(RowKey("NonPinned3"), RowKey("Pinned2"));

      snapshot.applyReorder(predicate!);

      expect(snapshot.nonPinnedKeys.contains(RowKey("NonPinned3")), isFalse);
      expect(snapshot.pinnedKeys.contains(RowKey("NonPinned3")), isTrue);
      expect(
          snapshot.previous(RowKey("Pinned2")), equals(RowKey("NonPinned3")));
    });
  });
}
