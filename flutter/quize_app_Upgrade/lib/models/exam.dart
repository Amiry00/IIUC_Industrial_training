class Exam {
  final int? id;
  final String title;
  final int createdBy;

  Exam({
    this.id,
    required this.title,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_by': createdBy,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int?,
      title: map['title'] as String,
      createdBy: map['created_by'] as int,
    );
  }
}
