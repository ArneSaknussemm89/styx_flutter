import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:styx/styx.dart';
import 'package:styx_flutter/styx_flutter.dart';

import '../data/components.dart';
import '../data/systems.dart';

final bookTitle = 'Book Of All Things';
final bookTitle2 = 'Book Of No Things';

void main() {
  testWidgets('Does Watcher rebuild?', (WidgetTester tester) async {
    final booksSystem = BookSystem();
    var book = booksSystem.create();
    book.get<BookComponent>().title(bookTitle);

    await tester.pumpWidget(TestWatcherApp(system: booksSystem));

    await tester.pumpAndSettle();

    final textFinder = find.text(bookTitle);
    final textFinder2 = find.text(bookTitle2);

    /// Expect to find the book title in the tree.
    expect(textFinder, findsOneWidget);

    var book2 = booksSystem.create();
    book2.get<BookComponent>().title(bookTitle2);

    await tester.pumpAndSettle();

    expect(textFinder2, findsOneWidget);
  });
}

class TestWatcherApp extends StatelessWidget {
  const TestWatcherApp({Key? key, required this.system}) : super(key: key);

  final BookSystem system;

  @override
  Widget build(BuildContext context) {
    return EntityProvider(
      system: system,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: WatcherTesterWidget(),
          ),
        ),
      ),
    );
  }
}

class WatcherTesterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return context.watchFilteredEntities<BookSystem>(
      matcher: EntityMatcher(any: Set.of([BookComponent])),
      builder: (context, matcher, entities) {
        return Column(
          children: [
            ...entities.map(
              (element) => element.get<BookComponent>().title.styx(
                    data: (data) => Text(data),
                    error: (error, stackTrace) => Center(child: Text('Error: $error')),
                    loading: () => Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }
}
