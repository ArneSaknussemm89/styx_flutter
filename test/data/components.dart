import 'package:equatable/equatable.dart';
import 'package:get/get.dart';
import 'package:styx/styx.dart';

/// Component representing a book.
class BookComponent extends Component with SerializableComponent, EquatableMixin {
  BookComponent({
    String title = '',
    String isbn = '',
    String guid = '',
    bool booked = false,
    required int id,
  }) {
    this.title(title);
    this.isbn(isbn);
    this.guid(guid);
    this.booked(booked);
    this.id(id);
  }

  final title = ''.obs;
  final isbn = ''.obs;
  final guid = ''.obs;
  final booked = false.obs;
  final id = 0.obs;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "title": title(),
      "isbn": isbn(),
      "guid": guid(),
      "booked": booked(),
      "id": id(),
    };
  }

  @override
  List<Object?> get props => [title(), isbn(), guid(), booked(), id()];
}

/// A component for an entity representing a book on hold.
class BookingComponent extends Component with SerializableComponent, EquatableMixin {
  BookingComponent({String guid = '', required String bookGuid}) {
    this.guid(guid);
    this.bookGuid(bookGuid);
  }

  final guid = ''.obs;
  final bookGuid = ''.obs;

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
