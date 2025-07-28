class BookModel {
  final int? id;
  final String title;
  final String path;
  final String author;
  final String language;
  final List<String> tags;
  final int lastPage;

  BookModel({
    this.id,
    required this.title,
    required this.path,
    this.author = '',
    required this.language,
    this.tags = const [],
    this.lastPage = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'author': author,
      'language': language,
      'tags': tags.join(','),
      'last_page': lastPage,
    }..removeWhere((key, value) => value == null);
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      path: map['path'] as String,
      author: map['author'] as String? ?? '',
      language: map['language'] as String? ?? 'unknown',
      tags: (map['tags'] as String? ?? '').split(',').where((t) => t.isNotEmpty).toList(),
      lastPage: map['last_page'] as int? ?? 0,
    );
  }
}
