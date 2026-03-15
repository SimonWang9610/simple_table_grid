import 'package:flutter_test/flutter_test.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/controllers/sizer.dart';

void main() {
  final colA = ColumnKey('colA');
  final colB = ColumnKey('colB');
  final rowA = RowKey('rowA');
  final rowB = RowKey('rowB');

  _Fixture createFixture() {
    final finder = _FakeFinder(
      rowByIndex: {
        1: rowA,
        2: rowB,
      },
      columnByIndex: {
        0: colA,
        1: colB,
      },
    );

    final rowInitial = <int, Extent>{
      1: Extent.ranged(min: 10, max: 200, pixels: 50),
    };

    final columnInitial = <ColumnKey, Extent>{
      colA: Extent.ranged(min: 40, max: 300, pixels: 120),
    };

    final sizer = TableExtentController(
      finder: finder,
      defaultRowExtent: Extent.ranged(min: 10, max: 200, pixels: 30),
      defaultColumnExtent: Extent.ranged(min: 40, max: 300, pixels: 80),
      rowExtents: rowInitial,
      columnExtents: columnInitial,
    );

    return _Fixture(
      finder: finder,
      sizer: sizer,
      rowInitial: rowInitial,
      columnInitial: columnInitial,
    );
  }

  group('get/cache behavior', () {
    test('row extent is cloned and cached', () {
      final fixture = createFixture();
      final first = fixture.sizer.getRowExtent(1);
      final second = fixture.sizer.getRowExtent(1);

      expect(identical(first, second), isTrue);
      expect(identical(first, fixture.rowInitial[1]), isFalse);

      first.accept(10);
      expect(fixture.rowInitial[1]!.range.$1, 50);

      fixture.sizer.dispose();
    });

    test('header row uses dedicated header cache', () {
      final fixture = createFixture();

      final first = fixture.sizer.getRowExtent(0);
      final second = fixture.sizer.getRowExtent(0);

      expect(identical(first, second), isTrue);

      fixture.sizer.dispose();
    });

    test('column extent is cloned and cached', () {
      final fixture = createFixture();
      final first = fixture.sizer.getColumnExtent(0);
      final second = fixture.sizer.getColumnExtent(0);

      expect(identical(first, second), isTrue);
      expect(identical(first, fixture.columnInitial[colA]), isFalse);

      first.accept(10);
      expect(fixture.columnInitial[colA]!.range.$1, 120);

      fixture.sizer.dispose();
    });

    test('missing mapped row and column use default extents', () {
      final fixture = createFixture();

      final rowDefault = fixture.sizer.getRowExtent(2);
      final columnDefault = fixture.sizer.getColumnExtent(1);

      expect(rowDefault.range.$1, 30);
      expect(columnDefault.range.$1, 80);

      fixture.sizer.dispose();
    });
  });

  group('set and reset', () {
    test('setRowExtent updates header and data rows and notifies', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      final header = Extent.ranged(min: 10, max: 300, pixels: 70);
      final row = Extent.ranged(min: 10, max: 300, pixels: 90);

      fixture.sizer.setRowExtent(0, header);
      fixture.sizer.setRowExtent(1, row);

      expect(identical(fixture.sizer.getRowExtent(0), header), isTrue);
      expect(identical(fixture.sizer.getRowExtent(1), row), isTrue);
      expect(notified, 2);

      fixture.sizer.dispose();
    });

    test('setColumnExtent updates cache and notifies', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      final extent = Extent.ranged(min: 40, max: 300, pixels: 180);
      fixture.sizer.setColumnExtent(colA, extent);

      expect(identical(fixture.sizer.getColumnExtent(0), extent), isTrue);
      expect(notified, 1);

      fixture.sizer.dispose();
    });

    test('resetColumnExtent only notifies when removed', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      fixture.sizer.getColumnExtent(0);
      fixture.sizer.resetColumnExtent(colA);
      fixture.sizer.resetColumnExtent(colA);

      expect(notified, 1);

      fixture.sizer.dispose();
    });

    test('resetRowExtent works by index and key and handles header', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      fixture.sizer.getRowExtent(0);
      fixture.sizer.getRowExtent(1);
      fixture.sizer.getRowExtent(2);

      fixture.sizer.resetRowExtent(index: 0);
      fixture.sizer.resetRowExtent(index: 1);
      fixture.sizer.resetRowExtent(key: rowB);
      fixture.sizer.resetRowExtent(index: 1);

      expect(notified, 3);

      fixture.sizer.dispose();
    });

    test('resetAllExtents notifies only when there is cached state', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      fixture.sizer.resetAllExtents();
      expect(notified, 0);

      fixture.sizer.getRowExtent(0);
      fixture.sizer.getRowExtent(1);
      fixture.sizer.getColumnExtent(0);

      fixture.sizer.resetAllExtents();
      fixture.sizer.resetAllExtents();

      expect(notified, 1);

      fixture.sizer.dispose();
    });
  });

  group('default extent setters', () {
    test('defaultRowExtent clears data row cache and notifies', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      final rowMappedBefore = fixture.sizer.getRowExtent(1);
      final rowDefaultBefore = fixture.sizer.getRowExtent(2);
      final headerBefore = fixture.sizer.getRowExtent(0);

      fixture.sizer.defaultRowExtent =
          Extent.ranged(min: 10, max: 200, pixels: 66);

      final rowMappedAfter = fixture.sizer.getRowExtent(1);
      final rowDefaultAfter = fixture.sizer.getRowExtent(2);
      final headerAfter = fixture.sizer.getRowExtent(0);

      expect(notified, 1);
      expect(identical(rowMappedAfter, rowMappedBefore), isFalse);
      expect(identical(rowDefaultAfter, rowDefaultBefore), isFalse);
      expect(identical(headerAfter, headerBefore), isFalse);
      expect(rowDefaultAfter.range.$1, 66);

      fixture.sizer.dispose();
    });

    test('defaultColumnExtent clears column cache and notifies', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      final colMappedBefore = fixture.sizer.getColumnExtent(0);
      final colDefaultBefore = fixture.sizer.getColumnExtent(1);

      fixture.sizer.defaultColumnExtent =
          Extent.ranged(min: 40, max: 300, pixels: 140);

      final colMappedAfter = fixture.sizer.getColumnExtent(0);
      final colDefaultAfter = fixture.sizer.getColumnExtent(1);

      expect(notified, 1);
      expect(identical(colMappedAfter, colMappedBefore), isFalse);
      expect(identical(colDefaultAfter, colDefaultBefore), isFalse);
      expect(colDefaultAfter.range.$1, 140);

      fixture.sizer.dispose();
    });
  });

  group('resize behavior', () {
    test('resize without target does nothing', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      fixture.sizer.resize(20);

      expect(notified, 0);

      fixture.sizer.dispose();
    });

    test('column resize right updates target column', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      fixture.sizer.setResizeTarget(
        ResizeTarget(key: colA, direction: ResizeDirection.right),
      );
      fixture.sizer.resize(20);

      expect(fixture.sizer.getColumnExtent(0).range.$1, 140);
      expect(notified, 1);

      fixture.sizer.dispose();
    });

    test('column resize left updates previous column', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      fixture.sizer.setResizeTarget(
        ResizeTarget(key: colB, direction: ResizeDirection.left),
      );
      fixture.sizer.resize(10);

      expect(fixture.sizer.getColumnExtent(0).range.$1, 130);
      expect(notified, 1);

      fixture.sizer.dispose();
    });

    test('row resize down updates target row', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      fixture.sizer.setResizeTarget(
        ResizeTarget(key: rowA, direction: ResizeDirection.down),
      );
      fixture.sizer.resize(10);

      expect(fixture.sizer.getRowExtent(1).range.$1, 60);
      expect(notified, 1);

      fixture.sizer.dispose();
    });

    test('invalid targets are ignored and clear active target', () {
      final fixture = createFixture();
      int notified = 0;
      fixture.sizer.addListener(() => notified++);

      fixture.sizer.setResizeTarget(
        ResizeTarget(key: rowA, direction: ResizeDirection.up),
      );
      fixture.sizer.resize(10);

      fixture.finder.rowByIndex.remove(1);
      fixture.sizer.setResizeTarget(
        ResizeTarget(key: rowA, direction: ResizeDirection.down),
      );
      fixture.sizer.resize(10);

      fixture.finder.columnByIndex.remove(0);
      fixture.sizer.setResizeTarget(
        ResizeTarget(key: colA, direction: ResizeDirection.right),
      );
      fixture.sizer.resize(10);

      expect(notified, 0);

      fixture.sizer.dispose();
    });
  });

  group('integration with TableController', () {
    TableController createController() {
      return TableController(
        columns: [
          HeaderData(key: colA, data: 'A'),
          HeaderData(key: colB, data: 'B'),
        ],
        initialRows: [
          RowData(
            rowA,
            data: {
              colA: 'r1a',
              colB: 'r1b',
            },
          ),
          RowData(
            rowB,
            data: {
              colA: 'r2a',
              colB: 'r2b',
            },
          ),
        ],
        defaultRowExtent: Extent.ranged(min: 10, max: 200, pixels: 30),
        defaultColumnExtent: Extent.ranged(min: 40, max: 300, pixels: 80),
        rowExtents: {
          1: Extent.ranged(min: 10, max: 200, pixels: 55),
        },
        columnExtents: {
          colA: Extent.ranged(min: 40, max: 300, pixels: 120),
        },
      );
    }

    test('public sizer reset APIs work through controller facade', () {
      final controller = createController();
      final sizer = controller.sizer;

      final rowBefore = sizer.getRowExtent(1);
      final columnBefore = sizer.getColumnExtent(0);

      sizer.resetRowExtent(index: 1);
      sizer.resetColumnExtent(colA);

      final rowAfter = sizer.getRowExtent(1);
      final columnAfter = sizer.getColumnExtent(0);

      expect(identical(rowAfter, rowBefore), isFalse);
      expect(identical(columnAfter, columnBefore), isFalse);

      controller.dispose();
    });

    test('default extent setters invalidate caches in controller-backed sizer',
        () {
      final controller = createController();
      final sizer = controller.sizer as TableExtentController;

      final headerBefore = sizer.getRowExtent(0);
      final rowBefore = sizer.getRowExtent(1);
      final defaultRowBefore = sizer.getRowExtent(2);
      final colBefore = sizer.getColumnExtent(0);
      final defaultColBefore = sizer.getColumnExtent(1);

      sizer.defaultRowExtent = Extent.ranged(min: 10, max: 200, pixels: 70);
      sizer.defaultColumnExtent = Extent.ranged(min: 40, max: 300, pixels: 140);

      final headerAfter = sizer.getRowExtent(0);
      final rowAfter = sizer.getRowExtent(1);
      final defaultRowAfter = sizer.getRowExtent(2);
      final colAfter = sizer.getColumnExtent(0);
      final defaultColAfter = sizer.getColumnExtent(1);

      expect(identical(headerAfter, headerBefore), isFalse);
      expect(identical(rowAfter, rowBefore), isFalse);
      expect(identical(defaultRowAfter, defaultRowBefore), isFalse);
      expect(identical(colAfter, colBefore), isFalse);
      expect(identical(defaultColAfter, defaultColBefore), isFalse);
      expect(defaultRowAfter.range.$1, 70);
      expect(defaultColAfter.range.$1, 140);

      controller.dispose();
    });
  });
}

final class _Fixture {
  final _FakeFinder finder;
  final TableExtentController sizer;
  final Map<int, Extent> rowInitial;
  final Map<ColumnKey, Extent> columnInitial;

  const _Fixture({
    required this.finder,
    required this.sizer,
    required this.rowInitial,
    required this.columnInitial,
  });
}

final class _FakeFinder implements TableIndexFinder {
  final Map<int, RowKey> rowByIndex;
  final Map<int, ColumnKey> columnByIndex;

  _FakeFinder({
    required this.rowByIndex,
    required this.columnByIndex,
  });

  @override
  int getRowIndex(RowKey key) {
    final entry = rowByIndex.entries.where((entry) => entry.value == key);

    if (entry.isEmpty) {
      return 0;
    }

    return entry.first.key;
  }

  @override
  RowKey? getRowKey(int index) => index == 0 ? null : rowByIndex[index];

  @override
  RowKey? nextRow(RowKey key) {
    final index = getRowIndex(key);

    if (index <= 0) return null;

    return rowByIndex[index + 1];
  }

  @override
  RowKey? previousRow(RowKey key) {
    final index = getRowIndex(key);

    if (index <= 1) return null;

    return rowByIndex[index - 1];
  }

  @override
  int? getColumnIndex(ColumnKey key) {
    final entry = columnByIndex.entries.where((entry) => entry.value == key);

    if (entry.isEmpty) {
      return null;
    }

    return entry.first.key;
  }

  @override
  ColumnKey getColumnKey(int index) => columnByIndex[index]!;

  @override
  ColumnKey? nextColumn(ColumnKey key) {
    final index = getColumnIndex(key);

    if (index == null) return null;

    return columnByIndex[index + 1];
  }

  @override
  ColumnKey? previousColumn(ColumnKey key) {
    final index = getColumnIndex(key);

    if (index == null || index <= 0) return null;

    return columnByIndex[index - 1];
  }
}
