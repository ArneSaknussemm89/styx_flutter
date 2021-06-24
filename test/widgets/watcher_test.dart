import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:styx/styx.dart';
import 'package:styx_flutter/styx_flutter.dart';

import '../data/components.dart';
import '../data/systems.dart';

final booksSystem = BookSystem();
final bookingSystem = BookingSystem();
final bookTitle = 'Book Of All Things';
final bookTitle2 = 'Book Of No Things';

void main() {
  testWidgets('Does Watcher rebuild?', (WidgetTester tester) async {
    var book = booksSystem.create();
    book.get<BookComponent>().title.value = bookTitle;

    await tester.pumpWidget(TestWatcherApp());

    final textFinder = find.text(bookTitle);
    final textFinder2 = find.text(bookTitle2);

    /// Expect to find the book title in the tree.
    expect(textFinder, findsOneWidget);

    var book2 = booksSystem.create();
    book2.update((val) {
      val!.get<BookComponent>().title.value = bookTitle2;
    });

    await tester.pump();

    expect(textFinder2, findsOneWidget);
  });
}

class TestWatcherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EntityProvider(
      system: booksSystem,
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
      matcher: EntityMatcher(all: Set.of([BookComponent])),
      builder: (context, matcher, entities) {
        return Column(
          children: [
            ...entities.map(
              (element) => Obx(() {
                return Text(element.get<BookComponent>().title());
              }),
            ),
          ],
        );
      },
    );
  }
}
