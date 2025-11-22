class Question {
  final String id;
  final String question;
  final String type; // 'multiple_choice', 'short_answer'
  final List<String> options;
  final int correctAnswer;
  final double points;

  Question({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.points = 1.0,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      type: map['type'] ?? 'multiple_choice',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 0,
      points: (map['points'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'points': points,
    };
  }
}

class QuizResponse {
  final String id;
  final String quizId;
  final String studentId;
  // answers can be int (selected index) for MCQ or String for short answer
  final List<dynamic> answers;
  final double score;
  final DateTime submittedAt;

  QuizResponse({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.answers,
    required this.score,
    required this.submittedAt,
  });

  factory QuizResponse.fromMap(Map<String, dynamic> map, String id) {
    return QuizResponse(
      id: id,
      quizId: map['quizId'] ?? '',
      studentId: map['studentId'] ?? '',
      answers: List<dynamic>.from(map['answers'] ?? []),
      score: (map['score'] ?? 0).toDouble(),
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'answers': answers,
      'score': score,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }
}

class Quiz {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<Question> questions;
  final int duration; // minutes
  final DateTime dueDate;
  final DateTime createdAt;
  final String createdBy;

  Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.questions,
    required this.duration,
    required this.dueDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory Quiz.fromMap(Map<String, dynamic> map, String id) {
    final qList = <Question>[];
    if (map['questions'] is List) {
      for (final q in (map['questions'] as List)) {
        if (q is Map<String, dynamic>) qList.add(Question.fromMap(q));
      }
    }
    return Quiz(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      questions: qList,
      duration: map['duration'] ?? 30,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'duration': duration,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  double getTotalPoints() => questions.fold(0, (s, q) => s + q.points);
}
