import 'dart:async';
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/user.dart';
import '../../models/question.dart';
import '../../models/result.dart' as model;
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final User user;
  final int examId;
  final String examTitle;

  const QuizScreen({
    super.key,
    required this.user,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final DBHelper _dbHelper = DBHelper();

  List<Question> _questions = [];
  int _currentQuestion = 0;
  int _score = 0;
  int _timeLeft = 10;
  Timer? _timer;
  int? _selectedIndex;
  bool _answerChecked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await _dbHelper.getQuestionsByExam(widget.examId);
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
    _startTimer();
  }

  // Starts/restarts the 10-second countdown timer. Auto-skips when time runs out.
  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = 10);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _nextQuestion();
      }
    });
  }

  void _checkAnswer(int index) {
    if (_answerChecked) return;
    _timer?.cancel();

    setState(() {
      _selectedIndex = index;
      _answerChecked = true;
    });

    if (index == _questions[_currentQuestion].correctIndex) {
      _score++;
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    _timer?.cancel();

    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedIndex = null;
        _answerChecked = false;
      });
      _startTimer();
    } else {
      _saveResult();
    }
  }

  Future<void> _saveResult() async {
    final result = model.Result(
      userId: widget.user.id!,
      examId: widget.examId,
      score: _score,
      total: _questions.length,
      date: DateTime.now().toString().split(' ')[0],
    );

    await _dbHelper.insertResult(result);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          score: _score,
          total: _questions.length,
          userName: widget.user.name,
        ),
      ),
    );
  }

  // Returns green for the correct answer, red for the wrong answer if selected, or null.
  Color? _getOptionColor(int index) {
    if (!_answerChecked) return null;
    final correctIdx = _questions[_currentQuestion].correctIndex;
    if (index == correctIdx) return const Color(0xFF4CAF50);
    if (index == _selectedIndex) return const Color(0xFFE53935);
    return null;
  }

  Color _getOptionBorderColor(int index) {
    if (!_answerChecked) return const Color(0xFFE8EAF6);
    final correctIdx = _questions[_currentQuestion].correctIndex;
    if (index == correctIdx) return const Color(0xFF4CAF50);
    if (index == _selectedIndex) return const Color(0xFFE53935);
    return const Color(0xFFE8EAF6);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.examTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentQuestion];

    return Scaffold(
      appBar: AppBar(title: Text(widget.examTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${_currentQuestion + 1} of ${_questions.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_currentQuestion + 1) / _questions.length,
                          backgroundColor: const Color(0xFFE8EAF6),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF3F51B5)),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _timeLeft <= 3
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFF3F51B5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        size: 18,
                        color: _timeLeft <= 3
                            ? const Color(0xFFE53935)
                            : const Color(0xFF3F51B5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_timeLeft}s',
                        style: TextStyle(
                          fontSize: 16,
                          color: _timeLeft <= 3
                              ? const Color(0xFFE53935)
                              : const Color(0xFF3F51B5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(question.options.length, (index) {
              final optionColor = _getOptionColor(index);
              final borderColor = _getOptionBorderColor(index);
              final label = ['A', 'B', 'C', 'D'][index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: _answerChecked ? null : () => _checkAnswer(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: optionColor?.withValues(alpha: 0.08) ?? Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                        width: optionColor != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: optionColor?.withValues(alpha: 0.15) ??
                                const Color(0xFFF0F2F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color:
                                    optionColor ?? const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: optionColor ?? const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        if (_answerChecked &&
                            index ==
                                _questions[_currentQuestion].correctIndex)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF4CAF50), size: 22),
                        if (_answerChecked &&
                            index == _selectedIndex &&
                            index !=
                                _questions[_currentQuestion].correctIndex)
                          const Icon(Icons.cancel_rounded,
                              color: Color(0xFFE53935), size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
