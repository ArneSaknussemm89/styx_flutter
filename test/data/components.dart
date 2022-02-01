import 'package:equatable/equatable.dart';
import 'package:styx/styx.dart';

/// Component representing a book.
class BookComponent extends Component with SerializableComponent, EquatableMixin {
  BookComponent({
    String title = '',
    String isbn = '',
    bool booked = false,
    required int id,
  }) {
    this.title(title);
    this.isbn(isbn);
    this.booked(booked);
    this.id(id);
  }

  final title = ''.bs;
  final isbn = ''.bs;
  final booked = false.bs;
  final id = 0.bs;

  @override
  void onRemoved() {
    title.close();
    isbn.close();
    booked.close();
    id.close();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "title": title(),
      "isbn": isbn(),
      "booked": booked(),
      "id": id(),
    };
  }

  @override
  List<Object?> get props => [title(), isbn(), booked(), id()];
}

/// A component for an entity representing a book on hold.
class BookingComponent extends Component with SerializableComponent, EquatableMixin {
  BookingComponent({String guid = '', required String bookGuid}) {
    this.guid(guid);
    this.bookGuid(bookGuid);
  }

  final guid = ''.bs;
  final bookGuid = ''.bs;

  @override
  void onRemoved() {
    guid.close();
    bookGuid.close();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "guid": guid,
      "bookGuid": bookGuid,
    };
  }

  @override
  List<Object?> get props => [guid(), bookGuid()];
}
