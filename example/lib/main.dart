import 'package:example/examples/auto_row_extent_example.dart';
import 'package:example/examples/infinite_scroll_example.dart';
import 'package:example/examples/paginated_example.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examples'),
      ),
      body: Center(
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InfiniteScrollExample(),
                  ),
                );
              },
              child: const Text('Infinite Scroll Example'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaginatedExample(),
                  ),
                );
              },
              child: const Text('Paginated Example'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AutoRowExtentExample(),
                  ),
                );
              },
              child: const Text('Auto Row Extent Example'),
            ),
          ],
        ),
      ),
    );
  }
}
