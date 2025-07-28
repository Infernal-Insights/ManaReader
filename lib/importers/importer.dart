import "../models/book_model.dart";
abstract class Importer {
  Future<BookModel> import(String path);
}
