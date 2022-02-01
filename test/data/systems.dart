import 'package:styx/styx.dart';

import '../data/components.dart';

/// Storing books.
class BookSystem extends EntitySystem {
  BookSystem();

  /// Internal iterator.
  int _iterator = 0;

  @override
  Entity create() {
    var entity = super.create();
    entity += BookComponent(id: _iterator);
    // Increment iterator
    _iterator++;
    return entity;
  }
}

/// Storing holds on books.
class BookingSystem extends EntitySystem {}
