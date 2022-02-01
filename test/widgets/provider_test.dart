import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:styx/styx.dart';
import 'package:styx_flutter/styx_flutter.dart';

import '../data/components.dart';
import '../data/systems.dart';

final bookTitle = 'Book Of All Things';
final bookTitle2 = 'Book Of No Things';
final bookTitle3 = 'Book Of Many Things';

void main() {
  testWidgets('Does Provider provide entities?', (WidgetTester tester) async {
    final booksSystem = BookSystem();
    var book = booksSystem.create();
    book.get<BookComponent>().title(bookTitle);

    await tester.pumpWidget(TestApp(system: booksSystem));
    await tester.pumpAndSettle();

    final textFinder = find.text(bookTitle);

    /// Expect to find the book title in the tree.
    expect(textFinder, findsOneWidget);
  });

  testWidgets('Multiple Providers', (WidgetTester tester) async {
    /// Systems and entities
    final booksSystem = BookSystem();
    final bookingSystem = BookingSystem();
    var book = booksSystem.create();
    var booking = bookingSystem.create();

    /// Finders
    final textFinder = find.text(bookTitle);
    final textFinder2 = find.text(bookTitle2);
    final textFinder3 = find.text(bookTitle3);
    final textFinderBooking = find.byIcon(Icons.bookmark);

    /// Set guid
    book.get<BookComponent>().title(bookTitle);

    /// Set booking reference
    booking += BookingComponent(bookGuid: book.guid);

    await tester.pumpWidget(TestApp2(booksSystem: booksSystem, bookingSystem: bookingSystem));
    await tester.pumpAndSettle();

    // Expect the book and the bookmark.
    expect(textFinder, findsOneWidget);
    expect(textFinderBooking, findsOneWidget);

    // New book with different title
    var book2 = booksSystem.create();
    book2.get<BookComponent>().title(bookTitle3);

    // Now change title and see if it updated.
    book.get<BookComponent>().title(bookTitle2);

    await tester.pumpAndSettle();

    /// Expect to find both books.
    expect(textFinder2, findsOneWidget);
    expect(textFinder3, findsOneWidget);

    /// Now remove the book and make sure it's disappeared from the watcher.
    book.destroy();

    await tester.pumpAndSettle();

    /// Book should not be in the list anymore.
    expect(textFinder2, findsNothing);
    expect(textFinderBooking, findsNothing);
  });
}

class TestApp extends StatelessWidget {
  const TestApp({required this.system});

  final BookSystem system;

  @override
  Widget build(BuildContext context) {
    return EntityProvider<BookSystem>(
      system: system,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: TesterWidget(),
          ),
        ),
      ),
    );
  }
}

class TesterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return context.entities<BookSystem>().styx(
          data: (books) {
            if (books.isEmpty) {
              return Text('No books');
            }

            return books.first.get<BookComponent>().title.styxData((data) => Text(data));
          },
          loading: () => Center(child: CircularProgressIndicator.adaptive()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
        );
  }
}

class TestApp2 extends StatelessWidget {
  const TestApp2({required this.booksSystem, required this.bookingSystem});

  final BookSystem booksSystem;
  final BookingSystem bookingSystem;

  @override
  Widget build(BuildContext context) {
    return EntityProvider(
      system: booksSystem,
      child: EntityProvider(
        system: bookingSystem,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: TesterWidget2(),
            ),
          ),
        ),
      ),
    );
  }
}

class TesterWidget2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return context.watchFilteredEntities<BookSystem>(
      matcher: EntityMatcher(all: Set.of([BookComponent])),
      builder: (context, matcher, books) {
        return Column(
          children: [
            ...books.map((book) {
              return Column(
                children: [
                  book.get<BookComponent>().title.styx(
                        data: (value) {
                          return Text(value);
                        },
                        loading: () => CircularProgressIndicator.adaptive(),
                        error: (error, stackTrace) => Text(error.toString()),
                      ),
                  context.watchFilteredEntities<BookingSystem>(
                    matcher: EntityMatcher(all: Set.of([BookingComponent])),
                    builder: (context, matcher, bookings) {
                      final booked = bookings
                          .where((booking) => booking.get<BookingComponent>().bookGuid() == book.guid)
                          .isNotEmpty;
                      if (booked) return Icon(Icons.bookmark);
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}
