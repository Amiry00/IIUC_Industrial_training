class Result {
  final int? id;
  final int userId;
  final int examId;
  final int score;
  final int total;
  final String date;

  Result({
    this.id,
    required this.userId,
    required this.examId,
    required this.score,
    required this.total,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'exam_id': examId,
      'score': score,
      'total': total,
      'date': date,
    };
  }

  factory Result.fromMap(Map<String, dynamic> map) {
    return Result(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      examId: map['exam_id'] as int,
      score: map['score'] as int,
      total: map['total'] as int,
      date: map['date'] as String,
    );
  }
}
