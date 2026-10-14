
class Source {
  final int id;
  final String title;
  final String? author;
  final String? edition;
  final String? pageReference;
  final String reviewStatus;

  const Source({
    required this.id,
    required this.title,
    this.author,
    this.edition,
    this.pageReference,
    this.reviewStatus = 'pending',
  });

  factory Source.fromMap(Map<String, Object?> map) {
    return Source(
      id: map['id'] as int,
      title: map['title'] as String,
      author: map['author'] as String?,
      edition: map['edition'] as String?,
      pageReference: map['page_reference'] as String?,
      reviewStatus: map['review_status'] as String? ?? 'pending',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'edition': edition,
      'page_reference': pageReference,
      'review_status': reviewStatus,
    };
  }
}
