import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:styx/styx.dart';
import 'package:styx_flutter/styx_flutter.dart';

import '../data/components.dart';
import '../data/systems.dart';

final bookTitle = 'Book Of All Things';
final bookTitle2 = 'Book Of No Things';
final bookTitle3 = 'Book Of Some Things';
final bookTitle4 = 'Book Of A Few Things';

void main() {
  testWidgets('Does Entity Builder rebuild?', (WidgetTester tester) async {
    final booksSystem = BookSystem();
    var book = booksSystem.create();
    var book2 = booksSystem.create();
    var book3 = booksSystem.create();

    book.get<BookComponent>().title(bookTitle);
    book2.get<BookComponent>().title(bookTitle2);
    book3.get<BookComponent>().title(bookTitle3);

    await tester.pumpWidget(TestEntityBuilderApp(system: booksSystem));
    await tester.pumpAndSettle();

    final textFinder = find.text(bookTitle);
    final booksFinder = find.byType(ListTile);

    /// Expect to find the book title in the tree.
    expect(textFinder, findsOneWidget);
    expect(booksFinder, findsNWidgets(3));

    // Change the book the be booked.
    book.get<BookComponent>().booked(true);

    await tester.pumpAndSettle();

    // Make sure the booking shows up.
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    // Change the title of the book.
    book.get<BookComponent>().title(bookTitle4);

    await tester.pumpAndSettle();

    // Make sure list tile updated.
    expect(find.text(bookTitle4), findsOneWidget);
    expect(find.text(bookTitle), findsNothing);
  });
}

class TestEntityBuilderApp extends StatelessWidget {
  const TestEntityBuilderApp({Key? key, required this.system}) : super(key: key);

  final BookSystem system;

  @override
  Widget build(BuildContext context) {
    return EntityProvider(
      system: system,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: BuilderTesterWidget(),
          ),
        ),
      ),
    );
  }
}

class BuilderTesterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return context.watchFilteredEntities<BookSystem>(
      matcher: EntityMatcher(any: Set.of([BookComponent])),
      builder: (context, matcher, entities) {
        return Column(
          children: [
            ...entities.map((entity) {
              return EntityBuilder<BookWithBookingModel>(
                streams: [
                  entity.get<BookComponent>().title,
                  entity.get<BookComponent>().booked,
                ],
                merge: (String title, bool booked) => BookWithBookingModel(title: title, booked: booked),
                builder: (context, model) {
                  return model.when(
                    data: (data) => ListTile(
                      title: Text(data.title),
                      trailing: data.booked ? Icon(Icons.bookmark) : const SizedBox.shrink(),
                    ),
                    error: (error, trace) {
                      return ListTile(
                        key: ValueKey(model),
                        title: Text(error.toString()),
                      );
                    },
                    loading: () => CircularProgressIndicator.adaptive(),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}

class BookWithBookingModel extends Equatable {
  const BookWithBookingModel({required this.title, this.booked = false});

  final String title;
  final bool booked;

  @override
  List<Object?> get props => [title, booked];
}
