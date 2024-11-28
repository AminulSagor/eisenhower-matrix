class Note {
  final int id;
  final String title;
  final String content;
  final String type;
  final String createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
